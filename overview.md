# Deploy and Host Grimoire on Railway

Grimoire is an open-source (MIT) bookmark manager. It saves links, fetches each page's title, description and readable text, and lets you organise them with tags and categories and find them again with full-text search. Optional AI tagging and semantic search use an OpenAI-compatible API key you add in Settings.

## About Hosting Grimoire

This template runs the official Grimoire 1.4.0 image as one Railway service, built from a public GitHub repo so you get Railway's update notices when a new version ships. Grimoire's web app has no login of its own, so a small Caddy front on the public URL asks for a username (`admin`) and a generated password before anything else. Grimoire keeps its SQLite database, settings and backups on a Railway volume at `/data`, so bookmarks survive restarts and redeploys. There are no prompts: the password and browser origin are set for you. Keep one replica, because the data lives on the volume.

## Common Use Cases

* A private, searchable library of articles, docs and references you can open from any browser
* Importing an exported browser bookmarks file and finding old links again by keyword or tag
* Letting an AI assistant search and add bookmarks through Grimoire's built-in MCP server

## Dependencies for Grimoire Hosting

* One Railway service (Grimoire plus the Caddy login front), built from `aalfath/grimoire-railway-template`
* One Railway volume at `/data` for the SQLite database, settings and backups

### Deployment Dependencies

* Grimoire source and releases: https://github.com/goniszewski/grimoire (v1.4.0)
* Grimoire Docker guide: https://github.com/goniszewski/grimoire/blob/v1.4.0/docs/docker-deployment.md
* Template repo, Dockerfile and changelog: https://github.com/aalfath/grimoire-railway-template
* Caddy web server: https://caddyserver.com/docs/

### Implementation Details

**After deploy:** open the service's public URL and sign in as `admin` with the `GRIMOIRE_PASSWORD` value from the service's Variables tab. Change the password there at any time; the service restarts with the new one.

**What is open without the password:** `/health` (for Railway's health check), and the integration routes `/mcp`, `POST /capture` and `/integrations/browser/v1/*`, which require one of Grimoire's own bearer tokens. Create those under Settings, Integrations.

**MCP client config** (streamable HTTP), with a token from Settings, Integrations:

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

**AI features are optional.** Add an OpenAI, Anthropic, OpenRouter, Ollama or other OpenAI-compatible key under Settings, AI. Without one, saving, tagging and full-text search still work.

**Custom domain:** the Railway domain is trusted automatically. If you add your own domain, set `CORS_ORIGINS` to `https://YOUR-DOMAIN` (comma-separate more than one), or browser saves from that domain are refused.

**Resources:** in our tests Grimoire used about 70 to 120 MB of RAM and runs on Railway's smallest (0.5 GB) plan.

**Updates:** when a new Grimoire release is tested, we merge it to the template repo and Railway shows you an "update available" notice. Read `CHANGELOG.md` in the repo before you apply it. Your data on the volume is kept.

## Why Deploy Grimoire on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Grimoire on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
