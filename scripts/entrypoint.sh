#!/usr/bin/env bash
# Generic entrypoint for every process type (web, socketio, workers,
# scheduler, and the one-off release container). Keeps things simple:
# wait for infra, wait for the release phase to have run once, then exec
# whatever command Dokku/the Procfile asked for.
set -euo pipefail

cd /home/frappe/frappe-bench

./scripts/wait-for-services.sh

COMMON_CONFIG="sites/common_site_config.json"
ATTEMPTS=0
MAX_ATTEMPTS=30
until [ -f "$COMMON_CONFIG" ] || [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; do
  echo "-----> Waiting for $COMMON_CONFIG (release phase writes this)..."
  sleep 2
  ATTEMPTS=$((ATTEMPTS + 1))
done

if [ ! -f "$COMMON_CONFIG" ]; then
  echo "-----> WARNING: $COMMON_CONFIG still missing after ${MAX_ATTEMPTS} attempts." >&2
  echo "-----> Has the 'release' process type run at least once for this app?" >&2
fi

exec "$@"
