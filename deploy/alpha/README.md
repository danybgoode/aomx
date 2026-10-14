# aomx alpha deployment

This deployment runs on the existing Oracle VM. The VM's panfleto stack owns Caddy; aomx gets a
separate compose project, database, networks, secrets and resource limits.
Never join aomx to the panfleto default network, which contains its database.
`aomx_db` keeps ingest traffic internal; `aomx_ops` lets the database publish
only to VM loopback for private backup/report commands. Docker does not honor
a published host port when the container has only an `internal: true` network.

## Preconditions

1. Confirm live VM CPU, memory, disk and backup headroom. The 2 OCPU / 12 GB
   VM is already the full Always Free allowance; no resize is authorized.
2. Prepare `/opt/aomx/db.env` and `/opt/aomx/ingest.env` from the examples,
   with distinct random administrator and ingest passwords (mode 600). The
   aomx Postgres container is separate from panfleto and publishes only on
   VM loopback for backup/restore. Its init script creates a limited ingest
   role. Apply all three migrations as `aomx_admin` before starting ingest.
3. Confirm daily OCI backup and disposable restore, DNS ownership, TLS, and a
   second security/data review. Keep the Golden Frijoles flag off.

## Prepare and start

On the VM, after copying the reviewed aomx commit (checkout or archive) to
`/opt/aomx/repo`, set its short commit ID explicitly. An archive has no `.git`
directory, and Compose needs the image tag even when starting only Postgres.

```sh
sudo install -d -m 700 -o ubuntu -g ubuntu /opt/aomx
sudo install -d -m 700 -o ubuntu -g ubuntu /data/aomx/postgres
docker network inspect aomx_proxy >/dev/null 2>&1 || docker network create aomx_proxy
cd /opt/aomx/repo
export AOMX_IMAGE_TAG=REVIEWED_COMMIT_SHORT_SHA
docker build -f deploy/alpha/Dockerfile -t "aomx-ingest:$AOMX_IMAGE_TAG" .
docker compose -p aomx -f deploy/alpha/compose.yml up -d postgres
# Apply the migration with the administrator, then start the service.
docker compose -p aomx -f deploy/alpha/compose.yml exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U aomx_admin -d aomx < db/001_alpha_audit.sql
docker compose -p aomx -f deploy/alpha/compose.yml exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U aomx_admin -d aomx < db/002_ingest_grants.sql
docker compose -p aomx -f deploy/alpha/compose.yml exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U aomx_admin -d aomx < db/003_publication_reading_hash.sql
docker compose -p aomx -f deploy/alpha/compose.yml up -d --no-build
```

The Caddy service must join `aomx_proxy` *in its own compose file* while
retaining its existing default network. Add the reviewed site from
`Caddyfile.example` with the real hostname, reload Caddy, and confirm its
certificate before pointing a game build at the route. Do not edit panfleto's
Postgres, backup retention, or other site blocks. `GET /healthz` is the only
public read route; `/v1/audit` and `/v1/report` return 404 in public mode.
The current restricted preview site is live at
`alpha-api.159.54.158.4.sslip.io`; access is limited to the operator's
current `/32`. The live Caddyfile and network attachment were applied
manually. Panfleto's `update.sh` resets tracked configuration, so
`danybgoode/justread#29` must be reviewed, merged and deployed before this
route is considered durable. Recheck panfleto sites and the alpha route after
that update.

The running image tag is the reviewed commit. To roll back, set
`AOMX_IMAGE_TAG` to a previously built tag and run the same `compose up` command.
The database migration is additive, so older images remain compatible with it.

## Operator schedule

Run `npm run alpha:backup` daily on the VM using the loopback administrator
URL and OCI instance-principal authentication, and `npm run alpha:health` after
it. Use an aomx-specific Object Storage bucket
and `aomx/db/` prefix. At least one backup must pass
`npm run alpha:backup -- --restore-test` against a distinct disposable database
before invitation. Set `AOMX_ALERT_WEBHOOK_URL` for health alerts and monitor
VM disk and database growth. A failed backup, unavailable ingest/database or
80% of the configured 500 MB alpha quota stops new invitations; 50% warns.
Check a missed timer
with the VM's systemd journal. The game outbox retries after an outage.

Install an isolated Node 24 binary at `/opt/aomx/node` and run `npm ci
--omit=dev` inside `/opt/aomx/repo`. Put operator-only connection details in
`/opt/aomx/operator.env` (example in this directory; mode 600, owner ubuntu).
Set `AOMX_PG_DOCKER_CONTAINER=aomx-postgres-1` so backup and restore use the
matching Postgres 17 client in that container; the VM's package client may be
older than the database.
Set `AOMX_INGEST_DOCKER_CONTAINER=aomx-ingest-1` for the VM's internal health
timer; test HTTPS externally during release smoke because the staging site
allowlist intentionally excludes the VM's outbound address.
Install `aomx-{backup,health,report}.{service,timer}` into
`/etc/systemd/system/`, then `sudo systemctl daemon-reload` and enable the
three timers. Run each service manually once and inspect the journal before
relying on the schedule. The backup timer is daily, the health timer every 15
minutes, and the report timer daily. The optional alert webhook must be an
owner-controlled destination.

Use `npm run alpha:observe-day -- --complete YYYY-MM-DD` only after reviewing
full ingest coverage and set `AOMX_COVERAGE_NOTE` to the evidence. Run
`npm run alpha:report -- --record` daily to append an auditable report snapshot
and show corrections. A changed published day needs a reviewed backfill; the
publisher refuses to silently replace it. Run
`npm run alpha:publish` to inspect pending mature readings and conflicts.
`--send` also requires an independently verified aomx key fingerprint.

## Restricted itch.io distribution

The creator project is `danybgoode/battle-for-la-roma`. It is **Restricted**;
the owner account can download the preview. Use individual itch.io download
keys for approved testers after the invitation gate, and verify access from a
second account before distribution. Do not share a draft secret URL if the
page is returned to Draft; it bypasses the intended per-tester gate.
The macOS Butler CLI can upload the versioned ZIP with:

```sh
butler push dist/alpha/battle-for-la-roma-BUILD_ID-macos.zip \
  danybgoode/battle-for-la-roma:mac-private-alpha --userversion BUILD_ID
butler status danybgoode/battle-for-la-roma
```

The page and channel are not an invitation by themselves. Confirm its
visibility and install the downloaded build on another Mac before any keys
are distributed. Butler marks a completed push downloadable immediately to
people with access, so check page restriction before uploading.

## Release and invitation gate

The restricted download page, second-Mac install, participant notice, La Roma
objective, data review, production flag decision and owner-approved first
invitation are separate required evidence. A merge to `master` is not a deploy.
