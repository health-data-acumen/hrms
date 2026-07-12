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
# `dokku mariadb:create` provisions ONE database + user, scoped to that
# database, and that's what DATABASE_URL points at. `bench new-site`
# normally expects MariaDB *root* credentials so it can CREATE DATABASE /
# CREATE USER for the new site itself — a scoped user typically can't do
# that. Pick one before running this script:
#
#   (a) [used below] Get the real MariaDB root password for the linked
#       service and pass it as --mariadb-root-password. bench will then
#       create its OWN database on the same MariaDB server (not the one
#       named in DATABASE_URL). Check your dokku-mariadb plugin version's
#       docs/`dokku mariadb:info frappe-db` output for how to obtain this.
#   (b) Manually create/grant the site's database yourself via
#       `dokku mariadb:connect frappe-db`, then create the site with
#       --no-mariadb-socket and --db-name/--db-password pointed at the
#       existing DATABASE_URL-provided database instead.
#
# This script assumes (a). Set MARIADB_ROOT_PASSWORD accordingly, or
# rewrite the `bench new-site` call below to use approach (b).

: "${MARIADB_ROOT_PASSWORD:?Set MARIADB_ROOT_PASSWORD — see the note above before running this script}"

bench new-site "$DEFAULT_SITE" \
  --mariadb-root-password "$MARIADB_ROOT_PASSWORD" \
  --mariadb-user-host-login-scope='%' \
  --admin-password "$ADMIN_PASSWORD" \
  --no-mariadb-socket

bench --site "$DEFAULT_SITE" install-app erpnext
bench --site "$DEFAULT_SITE" install-app hrms
# bench --site "$DEFAULT_SITE" install-app my_app   # if you added a custom app to apps.json

bench --site "$DEFAULT_SITE" enable-scheduler
bench use "$DEFAULT_SITE"

echo "-----> Site $DEFAULT_SITE created, erpnext + hrms installed"
