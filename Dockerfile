# Grimoire on Railway: the official Grimoire image, pinned by version and digest,
# plus a pinned Caddy binary that puts a password in front of the web app and REST API.
# Upstream: https://github.com/goniszewski/grimoire (release v1.4.0, MIT)
# Update: bump the tag and digest below, add a CHANGELOG.md entry, merge to main.
FROM caddy:2.11.9@sha256:4851e54a46b206517c574821bb5cc67f170d2156041e9fbc4c9193b45e84a75b AS caddy

FROM goniszewski/grimoire:1.4.0@sha256:1d68f454d84cc692ece63ef71959ab528ca113b6480cdd739b2648cd390980de

# Start as root only to hand the Railway volume to the image's user (littleimp,
# uid 999), then drop privileges (see railway-start.sh).
USER root
COPY --from=caddy /usr/bin/caddy /usr/local/bin/caddy
COPY --chmod=0644 Caddyfile /etc/grimoire-railway/Caddyfile
COPY --chmod=0755 railway-start.sh /usr/local/bin/railway-start.sh
RUN caddy version

# Grimoire listens on loopback only; Caddy is the public listener on $PORT.
ENV HOST=127.0.0.1 \
    GRIMOIRE_INTERNAL_PORT=3210 \
    PORT=8080 \
    DATA_DIR=/data \
    XDG_CONFIG_HOME=/data/config \
    HOME=/data \
    NODE_ENV=production \
    LOG_FORMAT=json \
    LITTLEIMP_IN_CONTAINER=1

# No VOLUME here: Railway rejects it. The template attaches a Railway volume at /data.
EXPOSE 8080
HEALTHCHECK NONE
WORKDIR /app
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
