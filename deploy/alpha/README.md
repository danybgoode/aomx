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
   second security/data review. The owner enabled the Golden Frijoles flag in
   development, preview and production on 2026-10-15. Keep internal builds
   test-tagged; verify served state and eligibility before any external release.

## Prepare and start

On the VM, after copying the reviewed aomx commit (checkout or archive) to
`/opt/aomx/repo`, set its short commit ID explicitly. An archive has no `.git`
directory, and Compose needs the image tag even when starting only Postgres.
Install the locked production Node dependencies in **each new release directory**
before moving the `/opt/aomx/repo` symlink. The backup, health, report and
retention timers resolve their scripts through that symlink; copying source alone
leaves them unable to import `pg`. After switching the symlink, run a backup with
`--restore-test` against a cleared, dedicated disposable restore database and
check the health timer. Never clear the live database for this test.

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
`POST /v1/campaign/flag` uses the same operator allowlist and rate limit as
`/v1/events`, then checks that the invite is already bound to the requested
pseudonymous player ID. Its response contains only the served decision and
version. The ingest server needs its independently verified aomx growth key
and flag read key to expose an enabled chapter; otherwise it serves off.
The Godot client keeps the last served choice for offline starts, and a served
off version stops new starts after the next online check. Do not put either
server key in a game export.
`POST /v1/modes/flag` uses the same bound invite and returns the served
`modes.wonder_enabled` decision/version. The client caches it by player and
environment, and Wonder starts carry that version. The ingest accepts a Wonder
adoption only after a matched, accepted Wonder finish. Run
`npm run alpha:wonder-publish` to preview eligible adoption rows, then use
`AOMX_WONDER_CURSOR_PATH=/opt/aomx/wonder-publish-cursor.json npm run
alpha:wonder-publish -- --send` from the operator environment after verifying
the aomx growth key. This publisher uses an independent cursor and a stable
event ID. Keep the flag served off until the Restricted pilot walkthrough.
The current restricted preview site is live at
`alpha-api.159.54.158.4.sslip.io`; access is limited to the operator's
current `/32`. The Caddyfile and `aomx_proxy` attachment are tracked in
`danybgoode/justread#29`, merged and deployed through panfleto's `update.sh`
on 2026-10-15. The operator must update the `/32` when the residential IP
rotates. After the deploy, both panfleto sites returned 200, alpha `/healthz`
returned `{"ok":true}` from the allowlisted Mac, a missing invite returned
401, and public audit/report routes returned 404.

The running image tag is the reviewed commit. To roll back, set
`AOMX_IMAGE_TAG` to a previously built tag and run the same `compose up` command.
The database migration is additive, so older images remain compatible with it.

## Restricted private-match host

The private-match service runs the pinned Godot 4.7.2 rules in a separate
container. It accepts **one two-player match per process**; restart the match
service between completed or expired walkthroughs. It does not make a public
game release or create an eligible cohort. Its enablement flag defaults off.
The image selects the official checksum-verified Godot binary for the host's
`amd64` or `arm64` architecture; the Oracle VM uses `arm64`. Verify the native
authority hash against the macOS and amd64 reference before opening admission.
Each player needs a different existing alpha invite code, bound to their
installation ID. Do not put match database credentials or flag read keys in a
client build.

Before starting the match service, inspect VM headroom and restore a backup to
a disposable database. On the existing Postgres volume, create its role once
with `docker compose -p aomx -f deploy/alpha/compose.yml exec postgres psql -U
aomx_admin -d aomx`; inside psql run `CREATE ROLE aomx_match LOGIN;` followed
by `\password aomx_match` and enter a new distinct password. Match that value
in `/opt/aomx/match.env` (mode 600), using `match.env.example` as the shape.
Create a separate `aomx_retention` login with `CREATE ROLE aomx_retention LOGIN;`
and `\password aomx_retention`, using a different
password in `/opt/aomx/retention.env` (mode 600, shape in
`retention.env.example`). Fresh volumes instead create both roles from
`AOMX_MATCH_PASSWORD` and `AOMX_RETENTION_PASSWORD` in `db.env`
through `init-role.sh`. Never pass a password on a command line. Apply the
additive migration before starting the container:

```sh
docker compose -p aomx -f deploy/alpha/compose.yml exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U aomx_admin -d aomx < db/004_private_matches.sql
docker compose -p aomx -f deploy/alpha/compose.yml exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U aomx_admin -d aomx < db/005_retention.sql
docker compose -p aomx -f deploy/alpha/compose.yml exec -T postgres \
  psql -v ON_ERROR_STOP=1 -U aomx_admin -d aomx < db/006_invite_rotation.sql
docker build --platform linux/arm64 -f deploy/alpha/match.Dockerfile -t "aomx-match:$AOMX_IMAGE_TAG" .
docker compose -p aomx -f deploy/alpha/compose.yml up -d --no-build match
docker compose -p aomx -f deploy/alpha/compose.yml ps match
```

Migration 006 replaces the original one-code-ever player constraint with a
unique index on **active** bindings. A revoked code keeps its historical
player binding for audit, while that same installation can claim one fresh
active code. Apply it before inviting a returning owner or tester; an active
code still blocks a second code for the same installation.

Copy the `/v1/match/*` route from `Caddyfile.example` into panfleto's alpha
site, keeping the existing operator allowlist for every other path. Reload
Caddy, verify HTTPS and confirm anonymous access to `/v1/events` is still
forbidden. The match route is address-reachable, but disabled admissions,
individual codes, slot binding and server-side validation gate play. Rotate
or revoke codes with the existing `alpha:invite` operator tool. A code
revocation blocks future joins; it does not interrupt an already connected
player. Toggle `multiplayer.private_match_enabled` in Golden Frijoles preview
only for the bounded smoke, verify the served flag version, then refresh the
match process before testing a new admission: its flag provider can
hold the previous snapshot. After the match finishes or expires, turn the flag
off, restart the one-room process, and verify a current-version join returns
`403 match_disabled` before leaving the host unattended. A flag switch itself
does not interrupt an already connected match.

Build the signed Restricted preview with `AOMX_MATCH_URL` set to the HTTPS
origin and `AOMX_INGEST_URL` set to its `/v1/events` endpoint. Verify the
manifest commit, checksum, signature, fresh download and both clients'
version labels. The client reports private results as test-tagged events; the
ingest still treats all client results as `client_reported`. Only the match
database has the authoritative terminal record. Restart `match` between the
baseline and impaired-profile runs, and record image tag, VM load, connection
profile, terminal outcomes and participant replay verification in the epic QA
record. Keep invite values in operator-only files, delete plaintext files after
delivery, and never keep them longer than 30 days. The daily job expires
database invite bindings after 30 days. Do not send an external
invitation until the daily retention timer and request deletion path below are
installed, observed and checked against the participant notice.

For a disposable Linux client that bind-mounts a mode-600 operator code file,
run the client under that file owner's unprivileged UID/GID. A different
container UID cannot read the code and will fail before joining; keep the file
private instead of making it world-readable. Restart the match process after
an intentional no-result session before starting a new single-room smoke.

## Operator schedule

Run `npm run alpha:backup` daily on the VM using the loopback administrator
URL and OCI instance-principal authentication, and `npm run alpha:health` after
it. Use an aomx-specific Object Storage bucket
and `aomx/db/` prefix. At least one backup must pass
`npm run alpha:backup -- --restore-test` against a distinct disposable database
before invitation. Set `AOMX_ALERT_TOPIC_ID` and `AOMX_ALERT_STATE_PATH` for
OCI email alerts (or use `AOMX_ALERT_WEBHOOK_URL` with the same state path) and
confirm the subscription before relying on delivery. The health timer sends
on issue changes and at most one reminder per 24 hours while an issue persists;
it also sends one recovery notice. Monitor VM disk and database growth. A failed backup, unavailable ingest/database or
80% of the configured 500 MB alpha quota stops new invitations; 50% warns.
Check a missed timer
with the VM's systemd journal. The game outbox retries after an outage.

The current alert topic lives in the dedicated `aomx-alpha-alerts` OCI
compartment; the VM dynamic group's publish grant is scoped to that
compartment. The owner email subscription is ACTIVE, a test publish was
accepted, and the owner confirmed inbox receipt on 2026-10-14. The one-use
`owner_qa_20261014` code synced 18 test events on 2026-10-15, then was
revoked; its plaintext files were removed. Create a distinct scoped code for
any later internal walkthrough. Keep invite codes in mode-600 operator files.

Install an isolated Node 24 binary at `/opt/aomx/node` and run `npm ci
--omit=dev` inside `/opt/aomx/repo`. Put operator-only connection details in
`/opt/aomx/operator.env` (example in this directory; mode 600, owner ubuntu).
Set `AOMX_PG_DOCKER_CONTAINER=aomx-postgres-1` so backup and restore use the
matching Postgres 17 client in that container; the VM's package client may be
older than the database.
Set `AOMX_INGEST_DOCKER_CONTAINER=aomx-ingest-1` for the VM's internal health
timer; test HTTPS externally during release smoke because the staging site
allowlist intentionally excludes the VM's outbound address.
Install `aomx-{backup,health,report,retention}.{service,timer}` into
`/etc/systemd/system/`, then `sudo systemctl daemon-reload` and enable the
four timers. Run each service manually once and inspect the journal before
relying on the schedule. The backup timer is daily, the health timer every 15
minutes, and the report and retention timers are daily. The optional alert webhook must be an
owner-controlled destination.

With `AOMX_DATABASE_URL` from `retention.env`, `npm run alpha:retention`
previews the 30-day live audit, private-match, invite-binding, and withdrawal
marker deletion counts; `npm run alpha:retention -- --apply` performs it. For a
verified deletion request, use `npm run alpha:retention -- --delete-player
SUPPORT_ID` to preview and add `--apply` to remove matching live audit and match
records plus the bound invite row, and adds a temporary withdrawal marker to
block late writes. Confirm that an active match and replay stop. Never paste support IDs or codes in a public
issue. Backups expire under the existing 30-day OCI lifecycle, so a deletion
request may remain in a backup until that copy expires.

Use `npm run alpha:observe-day -- --complete YYYY-MM-DD` only after reviewing
full ingest coverage and set `AOMX_COVERAGE_NOTE` to the evidence. Run
`npm run alpha:report -- --record` daily to append an auditable report snapshot
and show corrections. A changed published day needs a reviewed backfill; the
publisher refuses to silently replace it. Run
`npm run alpha:publish` to inspect pending mature readings and conflicts.
`--send` also requires an independently verified aomx key fingerprint.

For the campaign, verify that the growth key belongs to `aomx` in a separate
operator step, then derive its scrypt attestation into
`AOMX_VERIFIED_CAMPAIGN_KEY_SCRYPT` in both `ingest.env` and `operator.env`.
Use the same `AOMX_GROWTH_ENGINE_API_KEY` in both files; keep both mode 600.
With the key already loaded in the operator shell, this prints only the derived
attestation:

```sh
node -e "const {scryptSync}=require('node:crypto'); process.stdout.write(scryptSync(process.env.AOMX_GROWTH_ENGINE_API_KEY,'aomx-growth-project-attestation-v1',32).toString('hex')+'\n')"
```

Run `npm run alpha:campaign-publish` to preview at most 100 mission completion
rows, then `npm run alpha:campaign-publish -- --send` with
`AOMX_CAMPAIGN_CURSOR_PATH=/opt/aomx/campaign-publish-cursor.json` to send them.
The cursor advances only after the batch succeeds. Repeat while
`more_may_remain` is true. This publisher runs outside the ingest transaction
lock and uses the event ID for retry-safe Golden Frijoles writes. The server
serves campaign off if the key attestation or exposure report is unavailable.

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
visibility and complete the [local download QA walkthrough](../../docs/alpha-local-qa.md)
before any keys are distributed. The owner waived a separate-Mac check.
Butler marks a completed push downloadable immediately to people with access,
so check page restriction before uploading.

## Release and invitation gate

The restricted download page, owner-Mac download QA, participant notice, La Roma
objective, data review, production flag decision and owner-approved first
invitation are separate required evidence. A merge to `master` is not a deploy.
