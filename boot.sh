#!/bin/bash
# Railway boot for YOURLS.
#
# Refuses to start without a strong admin login, a fixed cookie key and a database password, points Apache at Railway's injected
# PORT, derives YOURLS_SITE from the public domain, then hands over to the upstream entrypoint (which copies YOURLS into place,
# writes user/config.php from the environment and runs /docker-entrypoint-init.d/10-railway.sh before Apache starts).
set -u
: "${PORT:=8080}"
export YOURLS_USER="${YOURLS_USER:-admin}"
fail() { echo "[railway] $1" >&2; exit 1; }
[ -n "${YOURLS_PASS:-}" ] || fail "YOURLS_PASS is not set; refusing to start a URL shortener without an admin login"
[ "${#YOURLS_PASS}" -ge 12 ] || fail "YOURLS_PASS must be at least 12 characters"
[ -n "${YOURLS_COOKIEKEY:-}" ] || fail "YOURLS_COOKIEKEY is not set; a random key per start would sign everyone out on every redeploy"
[ -n "${YOURLS_DB_HOST:-}" ] || fail "YOURLS_DB_HOST is not set"
[ -n "${YOURLS_DB_PASS:-}" ] || fail "YOURLS_DB_PASS is not set"
if [ -z "${YOURLS_SITE:-}" ]; then
  [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ] || fail "YOURLS_SITE is not set and there is no RAILWAY_PUBLIC_DOMAIN to derive it from"
  export YOURLS_SITE="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
# The upstream image runs a2dismod mpm_event in a later layer. Railway ignores that whiteout, so mpm_event returns beside mpm_prefork
# and Apache dies with "AH00534: More than one MPM loaded". Disable the others at boot.
a2dismod -f mpm_event mpm_worker >/dev/null 2>&1 || true
a2enmod mpm_prefork >/dev/null 2>&1 || true
case "$PORT" in ''|*[!0-9]*) fail "PORT must be a number, got '$PORT'";; esac
sed -i "s/^Listen 8080\$/Listen ${PORT}/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost 127.0.0.1:8080 \*:8080>/<VirtualHost *:${PORT}>/" /etc/apache2/sites-enabled/000-default.conf
echo "[railway] YOURLS on :$PORT, site $YOURLS_SITE, database $YOURLS_DB_HOST"
exec container-entrypoint.sh "$@"
