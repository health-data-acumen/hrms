# This Dockerfile does NOT build Frappe/ERPNext/HRMS itself. That happens
# separately in CI using frappe_docker's own images/layered/Containerfile
# (see .github/workflows/deploy.yml). This Dockerfile only adds our Dokku
# deployment metadata (Procfile, app.json, CHECKS, nginx.conf.sigil) and our
# small operational scripts on top of that already-built image, so that
# `dokku git:from-image` can find them at the image's WORKDIR.
ARG BASE_IMAGE=ghcr.io/health-data-acumen/hrms
FROM ${BASE_IMAGE}

USER root

# The Dokku persistent volume gets mounted at /home/frappe/frappe-bench/sites
# at *runtime*, which shadows the apps.txt and assets/ that frappe_docker
# baked in there at *build* time (bench build runs during image build).
# Preserve a pristine copy now, while sites/ still has the real build output,
# so entrypoint.sh can re-seed the (otherwise empty) mounted volume on every
# container start.
RUN cp -r /home/frappe/frappe-bench/sites /home/frappe/frappe-bench/sites-seed

COPY --chown=frappe:frappe scripts/ /home/frappe/frappe-bench/scripts/
COPY --chown=frappe:frappe Procfile /home/frappe/frappe-bench/Procfile
COPY --chown=frappe:frappe app.json /home/frappe/frappe-bench/app.json
COPY --chown=frappe:frappe CHECKS /home/frappe/frappe-bench/CHECKS
COPY --chown=frappe:frappe nginx.conf.sigil /home/frappe/frappe-bench/nginx.conf.sigil

RUN chmod +x /home/frappe/frappe-bench/scripts/*.sh

USER frappe
WORKDIR /home/frappe/frappe-bench

ENTRYPOINT ["/home/frappe/frappe-bench/scripts/entrypoint.sh"]
CMD ["./scripts/web.sh"]