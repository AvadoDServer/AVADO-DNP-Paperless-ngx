# Paperless-ngx 3.5.1, the official image (Debian 13), pinned by digest.
FROM --platform=linux/amd64 ghcr.io/paperless-ngx/paperless-ngx:3.5.1@sha256:8508853b8a0f8394074260957d0be186c8c64f346973b24a7583de4580f306b9

# nginx for the HTTPS front, Redis for Paperless's task queue.
RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx-light redis-server \
 && rm -rf /var/lib/apt/lists/* /etc/nginx/sites-enabled/default

# HTTPS front: the *.my.ava.do certificate, refreshed at start from the box.
RUN mkdir -p /etc/avado/certs \
 && curl -fsS -o /etc/avado/certs/build.crt http://iso.ava.do/my.ava.do.crt \
 && curl -fsS -o /etc/avado/certs/build.key http://iso.ava.do/my.ava.do.key \
 && openssl x509 -in /etc/avado/certs/build.crt -noout -subject
COPY avado/ /etc/avado/
RUN chmod +x /etc/avado/*.sh

# Paperless listens on the container's loopback only; nginx serves 80/443.
# One worker with two threads keeps document processing gentle on the box.
ENV PAPERLESS_REDIS=redis://127.0.0.1:6379 \
    PAPERLESS_BIND_ADDR=127.0.0.1 \
    PAPERLESS_PORT=8000 \
    PAPERLESS_URL=https://paperless.my.ava.do \
    PAPERLESS_CSRF_TRUSTED_ORIGINS=https://paperless.my.ava.do,http://paperless.my.ava.do \
    PAPERLESS_ALLOWED_HOSTS=paperless.my.ava.do,localhost,127.0.0.1 \
    PAPERLESS_USE_X_FORWARD_HOST=true \
    PAPERLESS_PROXY_SSL_HEADER='["HTTP_X_FORWARDED_PROTO", "https"]' \
    PAPERLESS_TASK_WORKERS=1 \
    PAPERLESS_THREADS_PER_WORKER=2 \
    PAPERLESS_WEBSERVER_WORKERS=1

ENTRYPOINT ["/etc/avado/avado-start.sh"]
CMD ["/init"]
