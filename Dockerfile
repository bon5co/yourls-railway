# YOURLS wrapper for Railway. Upstream's Apache listens on a fixed 8080 instead of Railway's injected PORT, takes its admin login from
# YOURLS_USER / YOURLS_PASS with no minimum and falls back to a random cookie key at every start (so every redeploy signs everyone
# out), and leaves the database tables for a human to create by clicking "Install" on /admin/install.php, which any visitor can do
# first. The wrapper refuses to start without a strong login and a fixed cookie key, listens on PORT, installs the tables at boot
# and serves a plain /healthz file.
# upstream: YOURLS/YOURLS
FROM yourls:1.10.6@sha256:3631239a8cc0f3911f0cdae00f5475f48a65b9f2c9f120ba137766bba28c945c

COPY --chmod=0755 boot.sh /railway-boot.sh
COPY --chmod=0755 init.sh /docker-entrypoint-init.d/10-railway.sh

ENV PORT=8080 YOURLS_DB_USER=yourls YOURLS_DB_NAME=yourls
EXPOSE 8080
ENTRYPOINT ["/railway-boot.sh"]
CMD ["apache2-foreground"]
