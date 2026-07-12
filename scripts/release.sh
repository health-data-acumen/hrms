#!/usr/bin/env bash
# Invoked automatically by Dokku's Procfile "release" process type: runs
# once per deploy, after the image is built and before web/worker
# containers are (re)scheduled. Do not call this from entrypoint.sh — it
# would otherwise run once per container, racing concurrent writes to the
# shared common_site_config.json.
set -euo pipefail
cd /home/frappe/frappe-bench

./scripts/wait-for-services.sh
./scripts/configure.sh

# On a brand-new app there's no site yet — nothing to migrate. Bail out
# cleanly and point at the manual bootstrap step instead of failing the
# deploy.
has_site=false
for d in sites/*/; do
  site_name="$(basename "$d")"
  if [ -f "${d}site_config.json" ]; then
    has_site=true
    break
  fi
done

if [ "$has_site" = false ]; then
  echo "-----> No site found under sites/ yet. Skipping migrate."
  echo "-----> Run this once to bootstrap: dokku run <app> ./scripts/init-site.sh"
  exit 0
fi

if [ -n "${DEFAULT_SITE:-}" ]; then
  bench --site "$DEFAULT_SITE" migrate
  bench --site "$DEFAULT_SITE" clear-cache
  bench --site "$DEFAULT_SITE" clear-website-cache
else
  echo "-----> DEFAULT_SITE not set; migrating all sites"
  bench --site all migrate
  bench --site all clear-cache
  bench --site all clear-website-cache
fi

echo "-----> release.sh complete"
