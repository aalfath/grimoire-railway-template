#!/usr/bin/env bash
# Railway start script for Grimoire.
# - keeps all state (SQLite database, settings, backups) on the Railway volume at /data,
# - trusts the Railway public domain as the browser origin (plus CORS_ORIGINS, if set),
# - runs Grimoire on loopback and a Caddy front on $PORT that asks for a password,
# - exits non-zero if either process stops, so Railway's ON_FAILURE policy restarts it.
set -euo pipefail

log() { echo "railway-start: $*" >&2; }
RUN_UID=999

if [ "$(id -u)" = "0" ]; then
  mkdir -p /data
  # Railway mounts volumes owned by root: hand it to the image's user (littleimp).
  find /data -xdev \( ! -user "$RUN_UID" -o ! -group "$RUN_UID" \) -exec chown "$RUN_UID:$RUN_UID" {} + 2>/dev/null || true
  exec setpriv --reuid="$RUN_UID" --regid="$RUN_UID" --clear-groups "$0" "$@"
fi

# ---- checks -----------------------------------------------------------------
pw="${GRIMOIRE_PASSWORD:-}"
if [ "${#pw}" -lt 12 ]; then
  log "GRIMOIRE_PASSWORD must be set and at least 12 characters; refusing to start without a login."
  exit 1
fi
export GRIMOIRE_USERNAME="${GRIMOIRE_USERNAME:-admin}"
case "$GRIMOIRE_USERNAME" in
  *[!A-Za-z0-9._@-]*|"") log "GRIMOIRE_USERNAME may only use letters, digits and ._@-"; exit 1 ;;
esac
export PORT="${PORT:-8080}"
export GRIMOIRE_INTERNAL_PORT="${GRIMOIRE_INTERNAL_PORT:-3210}"
if [ "$PORT" = "$GRIMOIRE_INTERNAL_PORT" ]; then
  log "PORT must not be $GRIMOIRE_INTERNAL_PORT (Grimoire's internal port)"; exit 1
fi

# ---- browser origins ---------------------------------------------------------
# Grimoire rejects browser writes from origins it doesn't know. Trust the Railway
# domain automatically; add custom domains through CORS_ORIGINS (comma-separated).
origins="${CORS_ORIGINS:-}"
if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  origins="https://${RAILWAY_PUBLIC_DOMAIN}${origins:+,$origins}"
fi
if [ -n "$origins" ]; then export CORS_ORIGINS="$origins"; else unset CORS_ORIGINS; fi
log "trusted browser origins: ${CORS_ORIGINS:-built-in loopback defaults}"

mkdir -p /data/config

# ---- start ------------------------------------------------------------------
GRIMOIRE_PASSWORD_HASH="$(printf '%s' "$pw" | caddy hash-password)"
pw=""

# Grimoire never sees the login password.
env -u GRIMOIRE_PASSWORD HOST=127.0.0.1 PORT="$GRIMOIRE_INTERNAL_PORT" \
  bun run --cwd /app/daemon start &
app_pid=$!

# Caddy gets only what it needs.
env -i PATH="$PATH" HOME=/tmp XDG_DATA_HOME=/tmp/caddy XDG_CONFIG_HOME=/tmp/caddy \
  PORT="$PORT" GRIMOIRE_INTERNAL_PORT="$GRIMOIRE_INTERNAL_PORT" \
  GRIMOIRE_USERNAME="$GRIMOIRE_USERNAME" GRIMOIRE_PASSWORD_HASH="$GRIMOIRE_PASSWORD_HASH" \
  caddy run --config /etc/grimoire-railway/Caddyfile --adapter caddyfile &
caddy_pid=$!
unset GRIMOIRE_PASSWORD_HASH

stopping=0
on_term() {
  stopping=1
  kill -TERM "$app_pid" "$caddy_pid" 2>/dev/null || true
}
trap on_term TERM INT

# Poll (don't rely on `wait -n`): if either process stops, stop the other and
# exit non-zero so Railway restarts the service.
while :; do
  if ! kill -0 "$app_pid" 2>/dev/null || ! kill -0 "$caddy_pid" 2>/dev/null; then
    break
  fi
  sleep 2 & wait $! || true
done
kill -TERM "$app_pid" "$caddy_pid" 2>/dev/null || true
wait "$app_pid" 2>/dev/null || true
wait "$caddy_pid" 2>/dev/null || true
if [ "$stopping" = 1 ]; then
  log "stopped on signal"
  exit 0
fi
log "Grimoire or Caddy stopped unexpectedly; exiting 1 so Railway restarts the service"
exit 1
