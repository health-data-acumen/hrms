#!/usr/bin/env bash
set -euo pipefail
cd /home/frappe/frappe-bench
exec node apps/frappe/socketio.js
