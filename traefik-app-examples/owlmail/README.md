# OwlMail 0.13.0 with Traefik

[English](README.md) | [中文](README.zh.md)

This profile pins the published OwlMail 0.13.0 image. SMTP captures development mail; Traefik serves the Web UI through HTTPS. Native REST is `/api/v1`; the optional MailDev `/api` facade is not Socket.IO or universal drop-in compatibility. See the [current API compatibility guide](https://github.com/soulteary/owlmail/blob/v0.13.0/docs/en/Comparison-and-Migration.md).

## Configure and start

Edit the adjacent `.env` before starting:

```sh
SERVICE_NAME=owlmail
SERVICE_PREFIX=owlmail
SERVICE_DOMAIN=mail.example.com
SERVICE_PORT=1080
DOCKER_IMAGE=ghcr.io/soulteary/owlmail:0.13.0
SMTP_PORT=1025
SMTP_HOST=0.0.0.0
DATA_DIR=./owlmail-data
```

Create the external `traefik` network and start the chosen Traefik configuration first. Then run from this checkout:

```sh
docker compose --env-file traefik-app-examples/owlmail/.env -f traefik-app-examples/owlmail/docker-compose.yml up -d
```

Visit `https://mail.example.com`; send SMTP to the configured host port. SMTP is currently published on every host interface: restrict it with a firewall/private network or bind its host side to 127.0.0.1 before shared/public use. HTTPS or Web Basic Auth does not protect SMTP. Keep outbound forwarding disabled unless explicitly configured.

## Storage, configuration and compatibility

The complete `${DATA_DIR}` is mounted at `/app/mail`, the image's actual mail directory; the healthcheck uses `owlmail healthcheck` and the same startup environment. Retain readable/writable ownership for the image's owlmail user. Compose `.env` is interpolation input, not automatic container environment: optional Web Basic Auth, allowed browser origins or outgoing SMTP fields must also be explicitly forwarded under the service's `environment`. Use the [configuration reference](https://github.com/soulteary/owlmail/blob/v0.13.0/docs/en/Configuration-Reference.md), without using `*` to suppress origin checks.

When external HTTPS/browser origins differ from the backend origin, the profile sets `OWLMAIL_WEB_EXTERNAL_URL=https://mail.example.com`; adjust it to the chosen domain and narrowly scoped allowed origins where needed. Native `/api/v1/emails` can verify capture; SMTP-only mode, read-only MCP and optional MailDev facade retain their documented configuration boundaries.

## Upgrade from 0.3.0 and rollback

Stop SMTP admission and the old process; back up the complete old mail directory and any external stores plus configuration and the old image digest. The previous profile mounted `/data/mails` without enabling that mail directory: inspect the old effective configuration and copy any actual container-layer mail before replacing it. Merely adding the corrected mount does not migrate lost or previously in-memory messages.

Rehearse 0.13.0 on an isolated data copy with real outgoing destinations disabled. Verify old mail and attachment reads, a new SMTP capture, health/readiness, the HTTPS UI/API and container recreation. Durable Relay recovery can resume pending tasks; delivery remains at least once and can duplicate around crashes. Read [0.13.0 upgrade and rollback](https://github.com/soulteary/owlmail/blob/v0.13.0/docs/en/Release-0.13.0.md#upgrade-compatibility-and-rollback).

Rollback stops the new process and restores the old image with its matching complete pre-upgrade backup and external state. Reconcile downstream acceptance receipts before re-enabling outbound delivery; preserve new captures separately. Do not run old/new versions against one writable directory. Routine cleanup uses `docker compose down` with the same env/file arguments, without deleting data or volumes.
