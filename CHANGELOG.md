# Changelog

Each entry lists breaking changes first. Deployers: read the entry before you apply an update from Railway.

## 1.4.0-railway.1 (2026-11-24)

- First release of the template: Grimoire 1.4.0 (`goniszewski/grimoire:1.4.0@sha256:1d68f454d84cc692ece63ef71959ab528ca113b6480cdd739b2648cd390980de`) behind Caddy 2.11.9 (`caddy:2.11.9@sha256:4851e54a46b206517c574821bb5cc67f170d2156041e9fbc4c9193b45e84a75b`).
- The web app and REST API ask for a login (user `admin`, generated `GRIMOIRE_PASSWORD`). `/health`, `/mcp`, `POST /capture` and `/integrations/browser/v1/*` use Grimoire's own integration bearer tokens.
- All data (SQLite database, settings, backups) lives on the Railway volume at `/data`.
