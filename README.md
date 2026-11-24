[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/grimoire?utm_medium=integration&utm_source=button&utm_campaign=grimoire)

# Grimoire on Railway

One-click Railway template for [Grimoire](https://github.com/goniszewski/grimoire), an open-source (MIT) bookmark manager with tags, categories, full-text search, automatic page metadata, optional AI tagging and a built-in MCP server.

## What this deploys

- **One service, `Grimoire`**, built from this repo's `Dockerfile`:
  - the official image `goniszewski/grimoire:1.4.0@sha256:1d68f454d84cc692ece63ef71959ab528ca113b6480cdd739b2648cd390980de`, listening on `127.0.0.1:3210` inside the container;
  - a [Caddy](https://caddyserver.com) 2.11.9 front (`caddy:2.11.9@sha256:4851e54a…a75b`) on `$PORT` (8080), which asks for a login before the web app and REST API, because Grimoire has no login of its own.
- **One volume at `/data`**: the SQLite database, settings, media cache and backups.
- Health check `GET /health` (300 s timeout), restart policy *on failure*. The start script exits non-zero if Grimoire or Caddy stops, so Railway restarts it.

## Variables

| Variable | Default | What it is |
|---|---|---|
| `GRIMOIRE_PASSWORD` | `${{secret(24)}}` | Login password for the web app (generated). Change it any time; the service restarts. |
| `GRIMOIRE_USERNAME` | `admin` | Login user name. |
| `PORT` | `8080` | Port Caddy listens on (Railway routes the public domain here). |
| `CORS_ORIGINS` | *(not set)* | Optional. Extra browser origins, comma-separated, such as `https://bookmarks.example.com` when you add a custom domain. The Railway domain is always trusted. |

There are no prompts. AI features (OpenAI, Anthropic, OpenRouter, Ollama or any OpenAI-compatible API) are optional and set in Grimoire's Settings, AI.

## After deploy

1. Open the public URL and sign in as `admin` with `GRIMOIRE_PASSWORD` from the service's Variables tab.
2. Save links, import a browser bookmarks file, or install the browser extension.
3. For the browser extension, scripts or an AI assistant, create an integration token under Settings, Integrations. These routes use the token instead of the password: `/mcp`, `POST /capture`, `/integrations/browser/v1/*`. `/health` is open for Railway's health check.

MCP client config (streamable HTTP):

```json
{
  "mcpServers": {
    "grimoire": {
      "url": "https://YOUR-DOMAIN/mcp",
      "headers": { "Authorization": "Bearer YOUR-INTEGRATION-TOKEN" }
    }
  }
}
```

## Resources

About 85 MB of RAM at idle and about 120 MB while it fetches pages, in our tests on Railway with a 0.5 GB / 1 vCPU limit, so it fits Railway's Free and Trial plans. Keep one replica: the data lives on the volume.

## Updates

This template builds from this repo, so Railway shows deployers an "update available" notice when a change is merged to `main`. Each update bumps the pinned tag and digest and adds a `CHANGELOG.md` entry; read it before you apply an update. Your data on the volume is kept. Grimoire 0.5 (the old SvelteKit app) and 1.x store data differently; this template starts on 1.x.

## Files

- `Dockerfile`: the pinned Grimoire and Caddy images.
- `Caddyfile`: the login front and the routes that bypass it.
- `railway-start.sh`: hands the volume to the app user, sets the trusted browser origin, starts Grimoire and Caddy, and exits non-zero if either stops.
- `overview.md`: the Railway marketplace overview.

Not affiliated with the Grimoire project. Grimoire is © Robert Goniszewski, MIT licence.
