#!/bin/bash
# Runs inside the upstream entrypoint, after YOURLS and user/config.php are in place and before Apache starts. Waits for the
# database, creates the tables if they are not there yet (the step upstream leaves to whoever opens /admin/install.php first), and
# writes the plain /healthz file Railway's healthcheck reads. Safe to run on every boot.
set -u
cd /var/www/html || exit 1
echo ok > healthz
php -d display_errors=1 -r '
$h = getenv("YOURLS_DB_HOST"); $n = getenv("YOURLS_DB_NAME") ?: "yourls"; $u = getenv("YOURLS_DB_USER") ?: "root"; $p = getenv("YOURLS_DB_PASS");
for ($i = 0; $i < 150; $i++) {
  try { new PDO("mysql:host=$h;dbname=$n", $u, $p, [PDO::ATTR_TIMEOUT => 3]); fwrite(STDERR, "[railway] database answered\n"); exit(0); }
  catch (Throwable $e) { if ($i % 10 == 0) fwrite(STDERR, "[railway] waiting for database: " . $e->getMessage() . "\n"); sleep(2); }
}
fwrite(STDERR, "[railway] database never answered\n"); exit(1);
' || exit 1
php -d display_errors=1 -r '
define("YOURLS_ADMIN", true); define("YOURLS_INSTALLING", true);
require_once "/var/www/html/includes/load-yourls.php";
if (yourls_is_installed()) { echo "[railway] YOURLS tables already present\n"; exit(0); }
$r = yourls_create_sql_tables();
if (!empty($r["error"])) { fwrite(STDERR, "[railway] install failed: " . implode(" | ", $r["error"]) . "\n"); exit(1); }
echo "[railway] YOURLS tables created\n";
' || exit 1
chown -R www-data:www-data /var/www/html/user 2>/dev/null || true
exit 0
