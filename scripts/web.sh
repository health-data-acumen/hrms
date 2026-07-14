#!/usr/bin/env bash
# Production web process. NOT `bench serve` (Werkzeug dev server) — this
# mirrors what frappe_docker's own `backend` service runs in production.
set -euo pipefail
cd /home/frappe/frappe-bench

exec /home/frappe/frappe-bench/env/bin/gunicorn \
  --chdir=/home/frappe/frappe-bench/sites \
  --pythonpath=/home/frappe/frappe-bench/scripts \
  --bind=0.0.0.0:8000 \
  --workers="${GUNICORN_WORKERS:-2}" \
  --worker-class=gthread \
  --threads="${GUNICORN_THREADS:-4}" \
  --worker-tmp-dir=/dev/shm \
  --timeout=120 \
  --preload \
  wsgi:application
