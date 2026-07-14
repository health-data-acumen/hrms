"""
Thin WSGI wrapper around frappe.app:application.

Gunicorn running frappe.app:application directly does NOT serve /assets/* --
that only happens via bench serve's dev-server wrapper (SharedDataMiddleware),
which production deliberately bypasses. Rather than hardcode the storage
host path into nginx.conf.sigil (fragile: has to stay in sync with whatever
`dokku storage:mount` path is actually in use), just wrap the app here so it
serves assets from wherever sites/assets actually is, whatever that is.
"""
import os

from frappe.app import application as _frappe_application
from werkzeug.middleware.shared_data import SharedDataMiddleware

BENCH_DIR = "/home/frappe/frappe-bench"
ASSETS_DIR = os.path.join(BENCH_DIR, "sites", "assets")

application = SharedDataMiddleware(_frappe_application, {"/assets": ASSETS_DIR})