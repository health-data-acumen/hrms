#!/usr/bin/env bash
# Derives bench's global config from the DATABASE_URL / REDIS_URL that Dokku
# injects when you `mariadb:link` / `redis:link` this app. Never writes
# common_site_config.json directly — bench owns that file.
set -euo pipefail
cd /home/frappe/frappe-bench

: "${DATABASE_URL:?DATABASE_URL not set}"
: "${REDIS_URL:?REDIS_URL not set}"

DB_HOST=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${DATABASE_URL}').hostname)")
DB_PORT=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${DATABASE_URL}').port or 3306)")

REDIS_HOST=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${REDIS_URL}').hostname)")
REDIS_PORT=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${REDIS_URL}').port or 6379)")
REDIS_PASS=$(python3 -c "from urllib.parse import urlparse; p=urlparse('${REDIS_URL}').password; print(p or '')")

REDIS_AUTH=""
if [ -n "$REDIS_PASS" ]; then
  REDIS_AUTH=":${REDIS_PASS}@"
fi

# One Redis instance, three logical DBs (0=cache, 1=queue, 2=socketio).
REDIS_CACHE_URL="redis://${REDIS_AUTH}${REDIS_HOST}:${REDIS_PORT}/0"
REDIS_QUEUE_URL="redis://${REDIS_AUTH}${REDIS_HOST}:${REDIS_PORT}/1"
REDIS_SOCKETIO_URL="redis://${REDIS_AUTH}${REDIS_HOST}:${REDIS_PORT}/2"

echo "-----> Writing global bench config"
bench set-config -g db_host "$DB_HOST"
bench set-config -gp db_port "$DB_PORT"
bench set-config -g redis_cache "$REDIS_CACHE_URL"
bench set-config -g redis_queue "$REDIS_QUEUE_URL"
bench set-config -g redis_socketio "$REDIS_SOCKETIO_URL"
bench set-config -gp socketio_port 9000
bench set-config -gp webserver_port 8000

if [ "${DEVELOPER_MODE:-0}" = "1" ]; then
  bench set-config -gp developer_mode 1
fi

if [ "${MAINTENANCE_MODE:-0}" = "1" ]; then
  bench set-config -gp maintenance_mode 1
else
  bench set-config -gp maintenance_mode 0
fi

echo "-----> configure.sh done"
