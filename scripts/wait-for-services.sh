#!/usr/bin/env bash
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL not set — has the Dokku mariadb service been linked?}"
: "${REDIS_URL:?REDIS_URL not set — has the Dokku redis service been linked?}"

wait_for() {
  local host="$1" port="$2" name="$3" timeout="${4:-90}"
  local waited=0
  until (exec 3<>"/dev/tcp/${host}/${port}") >/dev/null 2>&1; do
    waited=$((waited + 2))
    if [ "$waited" -ge "$timeout" ]; then
      echo "-----> Timed out waiting for $name at $host:$port" >&2
      exit 1
    fi
    echo "-----> Waiting for $name ($host:$port)..."
    sleep 2
  done
  exec 3<&- 2>/dev/null || true
  echo "-----> $name is up ($host:$port)"
}

DB_HOST=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${DATABASE_URL}').hostname)")
DB_PORT=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${DATABASE_URL}').port or 3306)")
REDIS_HOST=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${REDIS_URL}').hostname)")
REDIS_PORT=$(python3 -c "from urllib.parse import urlparse; print(urlparse('${REDIS_URL}').port or 6379)")

wait_for "$DB_HOST" "$DB_PORT" "MariaDB"
wait_for "$REDIS_HOST" "$REDIS_PORT" "Redis"
