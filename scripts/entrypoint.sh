#!/usr/bin/env bash
# Generic entrypoint for every process type (web, socketio, workers,
# scheduler, and the one-off release container). Keeps things simple:
# wait for infra, wait for the release phase to have run once, then exec
# whatever command Dokku/the Procfile asked for.
set -euo pipefail

cd /home/frappe/frappe-bench

# The Dokku volume mounted at sites/ shadows what frappe_docker baked in
# there at image-build time (apps.txt, assets/). Re-sync both from the
# pristine build-time copy on every start — they're pure build artifacts
# tied to this image, never user data, so always overwriting is correct
# and keeps them in sync across upgrades.
SEED_DIR="/home/frappe/frappe-bench/sites-seed"
SITES_DIR="/home/frappe/frappe-bench/sites"

if [ -f "$SEED_DIR/apps.txt" ]; then
  echo "-----> Syncing sites/apps.txt from image"
  cp "$SEED_DIR/apps.txt" "$SITES_DIR/apps.txt"
fi

if [ -d "$SEED_DIR/assets" ]; then
  echo "-----> Syncing sites/assets from image"
  mkdir -p "$SITES_DIR/assets"
  cp -r "$SEED_DIR/assets/." "$SITES_DIR/assets/"
fi

# Unlike apps.txt/assets, common_site_config.json holds live state written
# by `bench set-config` (db_host, redis_*, etc.) — never overwrite it once
# it exists. Only seed a starting copy on a genuinely fresh/empty volume.
if [ ! -f "$SITES_DIR/common_site_config.json" ] && [ -f "$SEED_DIR/common_site_config.json" ]; then
  echo "-----> Seeding sites/common_site_config.json from image (first boot)"
  cp "$SEED_DIR/common_site_config.json" "$SITES_DIR/common_site_config.json"
fi

./scripts/wait-for-services.sh

# release.sh / configure.sh / init-site.sh are the scripts responsible for
# CREATING common_site_config.json. Never block them on its own existence —
# doing so is a deadlock, since nothing would ever be allowed to create it.
case "$(basename "${1:-}")" in
  release.sh|configure.sh|init-site.sh)
    exec "$@"
    ;;
esac

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
