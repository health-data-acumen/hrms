#!/usr/bin/env bash
# One-time site bootstrap. Do NOT wire this into the automatic release
# phase — it must only ever run once. Trigger it manually after the first
# successful deploy:
#
#   dokku run frappe ./scripts/init-site.sh
#
set -euo pipefail
cd /home/frappe/frappe-bench

./scripts/wait-for-services.sh
./scripts/configure.sh

: "${DEFAULT_SITE:?Set with: dokku config:set frappe DEFAULT_SITE=hr.company.com}"
: "${ADMIN_PASSWORD:?Set with: dokku config:set frappe ADMIN_PASSWORD=...}"

# --- Read this before running ---
# Frappe/bench assumes the MariaDB database name and username are IDENTICAL
# for a site. The account Dokku's `mariadb:create` auto-provisions doesn't
# follow that convention (generic username, service-named database), so it
# can't be reused directly here -- passing it to `bench new-site` makes
# bench try to create its own separate database+user instead (what you hit
# earlier).
#
# The fix: pre-create ONE dedicated db+user pair yourself, where the
# username equals the database name, using your MariaDB root access. Do
# this once, manually, before running this script:
#
#   dokku mariadb:enter frappe-db
#   MariaDB> CREATE DATABASE IF NOT EXISTS `hr_site`
#              CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
#   MariaDB> CREATE USER IF NOT EXISTS 'hr_site'@'%' IDENTIFIED BY 'SOME_STRONG_PASSWORD';
#   MariaDB> GRANT ALL PRIVILEGES ON `hr_site`.* TO 'hr_site'@'%';
#   MariaDB> FLUSH PRIVILEGES;
#   MariaDB> exit
#
# Then set SITE_DB_NAME=hr_site and SITE_DB_PASSWORD=SOME_STRONG_PASSWORD
# via `dokku config:set frappe ...` before running this script.
#
# Because we're passing --db-name/--db-password WITHOUT --mariadb-root-password,
# bench treats the database+user as already existing and skips trying to
# create them -- it just installs the Frappe schema into it directly.

: "${DATABASE_URL:?DATABASE_URL not set}"

DB_NAME=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${DATABASE_URL}').path[1:])")
DB_USER=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${DATABASE_URL}').username)")
DB_PASSWORD=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${DATABASE_URL}').password)")

bench new-site "$DEFAULT_SITE" \
  --db-name "$DB_NAME" \
  --db-user "$DB_USER" \
  --db-password "$DB_PASSWORD" \
  --admin-password "$ADMIN_PASSWORD" \
  --mariadb-user-host-login-scope '%'

bench --site "$DEFAULT_SITE" install-app erpnext
bench --site "$DEFAULT_SITE" install-app hrms
# bench --site "$DEFAULT_SITE" install-app my_app   # if you added a custom app to apps.json

bench --site "$DEFAULT_SITE" enable-scheduler
bench use "$DEFAULT_SITE"

echo "-----> Site $DEFAULT_SITE created, erpnext + hrms installed"
