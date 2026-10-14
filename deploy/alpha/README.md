# aomx alpha deployment

This is a **prepared** deployment for the existing Oracle VM. It has not been
started or routed publicly. The VM's panfleto stack owns Caddy; aomx gets a
separate compose project, database, networks, secrets and resource limits.
Never join aomx to the panfleto default network, which contains its database.

## Preconditions

1. Confirm live VM CPU, memory, disk and backup headroom. The 2 OCPU / 12 GB
   VM is already the full Always Free allowance; no resize is authorized.
2. Prepare `/opt/aomx/db.env` and `/opt/aomx/ingest.env` from the examples,
   with distinct random administrator and ingest passwords (mode 600). The
   aomx Postgres container is separate from panfleto and publishes only on
   VM loopback for backup/restore. Its init script creates a limited ingest
   role. Apply both migrations as `aomx_admin` before starting ingest.
3. Confirm daily OCI backup and disposable restore, DNS ownership, TLS, and a
   second security/data review. Keep the Golden Frijoles flag off.

## Prepare and start

On the VM, after copying a reviewed aomx checkout to `/opt/aomx/repo`:

```sh
sudo install -d -m 700 -o ubuntu -g ubuntu /opt/aomx
sudo install -d -m 700 -o ubuntu -g ubuntu /data/aomx/postgres
docker network create aomx_proxy
cd /opt/aomx/repo
SHA=$(git rev-parse --short=12 HEAD)
docker build -f deploy/alpha/Dockerfile -t "aomx-ingest:$SHA" .
AOMX_IMAGE_TAG="$SHA" docker compose -p aomx -f deploy/alpha/compose.yml up -d postgres
# Apply the migration with the administrator, then start the service.
docker compose -p aomx -f deploy/alpha/compose.yml exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U aomx_admin -d aomx < db/001_alpha_audit.sql
docker compose -p aomx -f deploy/alpha/compose.yml exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U aomx_admin -d aomx < db/002_ingest_grants.sql
AOMX_IMAGE_TAG="$SHA" docker compose -p aomx -f deploy/alpha/compose.yml up -d --no-build
```

The Caddy service must join `aomx_proxy` *in its own compose file* while
retaining its existing default network. Add the reviewed site from
`Caddyfile.example` with the real hostname, reload Caddy, and confirm its
certificate before pointing a game build at the route. Do not edit panfleto's
Postgres, backup retention, or other site blocks. `GET /healthz` is the only
public read route; `/v1/audit` and `/v1/report` return 404 in public mode.

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

The creator project is `danybgoode/battle-for-la-roma`. Keep it **Draft**
while testing the export. Then set **Restricted**, use individual itch.io
download keys for approved testers, and verify access from a second account.
Do not share the draft secret URL; it bypasses the intended per-tester gate.
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
