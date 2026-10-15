---
epic: enable-measured-private-alpha
sprint: 2
title: "Host accepted ingest and durable audit"
risk: high
phase: Building
stories_total: 3
stories:
  - id: S2.1
    title: "Persist accepted events and receipts"
    as_a: "measurement operator"
    i_want: "a separate durable aomx event audit"
    so_that: "offline retries cannot inflate or erase a cohort"
    risk: high
    status: in-progress
  - id: S2.2
    title: "Serve the ingest through HTTPS"
    as_a: "invited player"
    i_want: "my saved events to sync to an available endpoint"
    so_that: "a finished match is eligible after accepted upload"
    risk: high
    status: in-progress
  - id: S2.3
    title: "Recover and monitor the isolated database"
    as_a: "measurement operator"
    i_want: "a verified independent backup and outage response"
    so_that: "a free-tier pause or storage failure does not silently lose the cohort"
    risk: high
    status: in-progress
---

# Enable a measured private alpha — Sprint 2: Host accepted ingest and durable audit

**Status:** Building. The isolated VM Postgres and ingest containers are healthy behind allowlisted HTTPS. Daily OCI backup, health and report timers ran once; an off-project download restored with matching counts after an isolated ingest outage and outbox retry rehearsal. The alert destination is active and a test email arrived. The sibling Caddy durability PR remains open, and the owner Mac's current IP receives HTTP 403 until its route change is reviewed and deployed. Independent code review and recheck passed; final deployment review remains required.

## Stories

### Story 2.1 — Persist accepted events and receipts

**As a** measurement operator, **I want** a separate durable aomx event audit, **so that** offline retries cannot inflate or erase a cohort.

**Acceptance:** Create a dedicated Postgres container on the Oracle VM and least-privilege server role, separate from panfleto's database and network. Move the accepted/rejected audit, stable receipt, flag decision and report history off JSONL without changing the event contract. Unique event ID plus player/match/type constraints make retry idempotent. Restart the service, resend an event and observe the original receipt and unchanged eligible count. Test, bot, tutorial, invalid-transition and unresolved-clock events remain excluded or quarantined.

**Risk:** high: player data, database migration and reporting integrity.

### Story 2.2 — Serve the ingest through HTTPS

**As an** invited player, **I want** my saved events to sync to an available endpoint, **so that** a finished match is eligible after accepted upload.

**Acceptance:** Check the Oracle VM's live capacity and existing panfleto deployment before touching it. Run an isolated aomx service with separate secrets, resource limits, health checks, release/rollback commands and Caddy HTTPS routing. Configure the game endpoint by build environment rather than hardcoded loopback. Put abuse controls at the public boundary; no shared ingest secret is bundled in the client. A staging build uploads ordered offline events and handles explicit rejection without dropping later pending events.

**Risk:** high: shared VM and public ingest boundary. If capacity or isolation fails, return the host choice to the owner before deployment.

### Story 2.3 — Recover and monitor the isolated database

**As a** measurement operator, **I want** a verified independent backup and outage response, **so that** a free-tier pause or storage failure does not silently lose the cohort.

**Acceptance:** Run a daily logical export into an aomx-specific OCI Object Storage bucket, retain off-project copies, alert on missed backups and prove a restore to a disposable database. Verify the loopback backup connection and isolated volume. Run a daily cohort/health read that serves a real operator purpose, monitor VM disk and database size, alert at 50% of the 500 MB alpha planning quota and stop new invitations at 80% or on write failure. An outage/recovery rehearsal preserves client outbox events, and the operator can reconcile after service recovery.

**Risk:** high: recovery and shared infrastructure.

## Sprint QA

- **Deterministic gate:** `npm test`, database migration/unique-key integration checks, restart-and-retry checks and a backup/restore exercise against disposable resources.
- **Hosted smoke owed:** A second reviewer inspects the HTTPS staging route, rate limits, secret placement, excluded-event audit and recovery evidence. Use a named staging URL in the execution log once provisioned.
- **Security review:** Server role, database connection, network exposure, Caddy route and separate panfleto/aomx resource limits.

## Sprint 2 — Smoke walkthrough

Environment: staging game build, isolated aomx HTTPS ingest, dedicated VM Postgres and disposable restore target. Record real endpoints in the execution log when provisioned.

1. Start ingest unavailable, finish a test-tagged match, then restore it. The saved event ID receives one stable receipt; a retry leaves the accepted count unchanged.
2. Send duplicate, bot, unsupported-version, incomplete-match and clock-anomaly fixtures. Each has the expected excluded, rejected or quarantined state and changes no public cohort count.
3. Trigger a logical backup and restore it into the disposable database. Event and receipt counts match; the original database remains untouched.
4. Simulate an unavailable database and resume it. Client events remain pending, then reconcile after recovery; the health alert and runbook name the failure.

If any step fails, do not issue invitations or release an eligible client. The owner enabled the flag in all environments on 2026-10-15; confirm its served state again before a release decision.
