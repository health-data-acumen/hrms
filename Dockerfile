# This Dockerfile does NOT build Frappe/ERPNext/HRMS itself. That happens
# separately in CI using frappe_docker's own images/layered/Containerfile
# (see .github/workflows/deploy.yml). This Dockerfile only adds our Dokku
# deployment metadata (Procfile, app.json, CHECKS, nginx.conf.sigil) and our
# small operational scripts on top of that already-built image, so that
# `dokku git:from-image` can find them at the image's WORKDIR.
ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER root

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
