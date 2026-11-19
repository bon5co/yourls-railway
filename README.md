# yourls-railway

Wrapper image for [YOURLS](https://github.com/YOURLS/YOURLS) 1.10.6 (the official `yourls` Apache image, pinned by digest) on [Railway](https://railway.com).

Upstream's Apache listens on a fixed 8080 instead of Railway's injected `PORT`, accepts any admin password, falls back to a random cookie key at every start (so a redeploy signs everyone out), and leaves the database tables for a human to create by clicking "Install" on `/admin/install.php`, which any visitor can do first. The wrapper refuses to start without a strong login (`YOURLS_PASS`, 12 characters or more) and a fixed `YOURLS_COOKIEKEY`, listens on `PORT`, derives `YOURLS_SITE` from `RAILWAY_PUBLIC_DOMAIN`, waits for the database, creates the tables at boot if they are missing, and serves a plain `/healthz` file.

- Variables: `YOURLS_USER`, `YOURLS_PASS`, `YOURLS_COOKIEKEY`, `YOURLS_DB_HOST`, `YOURLS_DB_USER`, `YOURLS_DB_PASS`, `YOURLS_DB_NAME` (required). Optional: `YOURLS_SITE`, `YOURLS_PRIVATE`, `YOURLS_UNIQUE_URLS`, `YOURLS_URL_CONVERT`.
- Database: MySQL or MariaDB reachable at `YOURLS_DB_HOST`. All data lives there; the container keeps no state.
- Health: `GET /healthz` returns 200 `ok`

Published as `ghcr.io/bon5co/yourls-railway`. Template: see the Railway marketplace listing.
- Source in this repo: `Dockerfile`, `boot.sh`, `init.sh`, `railway.toml`; the same files live in [bon5co/yourls-railway](https://github.com/bon5co/yourls-railway), which builds `ghcr.io/bon5co/yourls-railway`.
