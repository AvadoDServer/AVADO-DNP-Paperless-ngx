# AVADO Paperless-ngx

`paperless.avado.dnp.dappnode.eth`: [Paperless-ngx](https://docs.paperless-ngx.com) 3.4.2, a
document archive that reads (OCR), files and indexes scanned letters, bills and contracts,
packaged for AVADO.

- Page: **https://paperless.my.ava.do** (plain http goes to the https page).
- Image: the official `ghcr.io/paperless-ngx/paperless-ngx:3.4.2`, pinned by digest, plus nginx
  for HTTPS and Redis for the task queue.

## How it is put together

Paperless's own compose files run Paperless and Redis as two containers (plus optional
PostgreSQL, Gotenberg and Tika). An AVADO package is one container, so:

| Part | What |
|---|---|
| `build/Dockerfile` | Official image + `nginx-light` + `redis-server` from Debian. Paperless listens on `127.0.0.1:8000`; nginx serves 80 and 443. No host ports. |
| `build/avado/app-prestart.sh` | Run before Paperless starts: makes the secret key once (kept in the data volume), takes the box's time zone, starts Redis on `127.0.0.1:6379` with no disk writes (the queue only holds work in progress). |
| `build/avado/avado-start.sh` | Start wrapper shared by the AVADO app packages: nginx, the certificate check (15 s after start, then daily), `nice 10` for the app. Paperless's own `/init` (s6) stays PID 1. |
| `build/avado/avado-certs.sh` | The `*.my.ava.do` certificate: the box's DAPPMANAGER copy (`http://dappmanager.my.ava.do/my.ava.do.crt`, as AVADO-DNP-Nethermind uses), else `http://iso.ava.do`, else the copy taken at build time. |
| `build/avado/nginx.conf.in` | nginx: uploads up to 1000 MB, no request buffering. |

The database is Paperless's built-in SQLite (in the data volume), which the Paperless docs
recommend for a single household. Office documents (Word, e-mail files) need the optional Tika
and Gotenberg services and are not converted in this version; PDF files and photos are.

Volumes: `data` (database, search index, secret key), `media` (the documents),
`consume` (Paperless's watched folder), `export` (Paperless's exporter).

Settings the owner can change in the Admin (package > Settings):

| Variable | Default | What |
|---|---|---|
| `PAPERLESS_OCR_LANGUAGE` | `eng` | Language(s) of the documents: `eng`, `deu`, `fra`, `ita`, `spa`, or a combination such as `deu+eng`. These five are in the image; others need `PAPERLESS_OCR_LANGUAGES` (installed at each start, needs the internet). |

Fixed in the image: `PAPERLESS_URL=https://paperless.my.ava.do`, the allowed hosts and CSRF origins
for `paperless.my.ava.do`, `PAPERLESS_TASK_WORKERS=1`, `PAPERLESS_THREADS_PER_WORKER=2`,
`PAPERLESS_WEBSERVER_WORKERS=1`.

## Resource use and the Ethereum node

AVADO's package format has no memory or CPU limits (the DAPPMANAGER's compose generator does not
pass `mem_limit`/`cpus`). Paperless reads one document at a time with two threads, at `nice 10`.
Measured on local Docker: about 800 MB of memory idle.

## Who can reach it

Every device that can open `my.ava.do`: on the AVADO network (AVADO WiFi) or through Remote
Access. No port is opened on the home network. While no account exists, the page asks for the
first one (it becomes the administrator); after that only accounts it creates can sign in.

## Updating

Bump the digest and tag in `build/Dockerfile`, `upstream` and `version` in
`dappnode_package.json` and the image tag in `docker-compose.yml`. Read the Paperless release
notes first; the database is migrated automatically on start.

## Licence

The packaging files in this repository are GPL-3.0 (see `LICENSE`). Paperless-ngx is GPL-3.0 and
is used unchanged from its official image. The avatar is the Paperless-ngx logo.
