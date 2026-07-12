#!/usr/bin/env bash
# Production web process. NOT `bench serve` (Werkzeug dev server) — this
# mirrors what frappe_docker's own `backend` service runs in production.
set -euo pipefail
cd /home/frappe/frappe-bench

exec gunicorn \
  --chdir=/home/frappe/frappe-bench/sites \
  --bind=0.0.0.0:8000 \
  --workers="${GUNICORN_WORKERS:-2}" \
  --worker-class=gthread \
  --threads="${GUNICORN_THREADS:-4}" \
  --worker-tmp-dir=/dev/shm \
  --timeout=120 \
  --preload \
  frappe.app:application
