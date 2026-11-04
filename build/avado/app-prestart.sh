# Paperless-ngx on AVADO: sourced by avado-start.sh before the app starts.

# Paperless needs a secret key of its own: made once, kept in the data volume.
AVADO_SECRET_FILE=/usr/src/paperless/data/avado-secret-key
if [ -z "${PAPERLESS_SECRET_KEY:-}" ]; then
  if [ ! -s "$AVADO_SECRET_FILE" ]; then
    mkdir -p /usr/src/paperless/data
    python3 -c "import secrets; print(secrets.token_urlsafe(64))" > "$AVADO_SECRET_FILE"
    chmod 600 "$AVADO_SECRET_FILE"
  fi
  PAPERLESS_SECRET_KEY=$(cat "$AVADO_SECRET_FILE")
  export PAPERLESS_SECRET_KEY
fi

# Time zone of the box, unless one is set in Settings.
if [ -z "${PAPERLESS_TIME_ZONE:-}" ] && [ -s /etc/timezone ]; then
  PAPERLESS_TIME_ZONE=$(head -n 1 /etc/timezone)
  export PAPERLESS_TIME_ZONE
fi

# Redis for Paperless's task queue: inside this container, on the loopback
# address only, nothing written to disk (as in Paperless's own examples, the
# queue is only work in progress; documents are kept by Paperless itself).
(
  while :; do
    nice -n 10 runuser -u redis -- redis-server --bind 127.0.0.1 --port 6379 \
      --protected-mode yes --save "" --appendonly no --dir /tmp --loglevel warning
    echo "[avado] Redis stopped; starting it again in 3 s" >&2
    sleep 3
  done
) &
