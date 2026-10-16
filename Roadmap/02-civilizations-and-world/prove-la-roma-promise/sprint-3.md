---
epic: prove-la-roma-promise
sprint: 3
title: "Read the playtest"
risk: low
phase: Building
stories_total: 1
stories:
  - id: S3.1
    title: "Test the promise with players"
    as_a: "product owner"
    i_want: "an uncoached comparison across cultural-context groups"
    so_that: "I can decide whether the prototype merits a wider alpha"
    risk: low
    status: planned
---
# Prove the La Roma promise — Sprint 3: Read the playtest

**Status:** 🟨 local candidate ready; delivery and playtest pending

## Player outcome

The owner receives a small, readable test of the approved value proposition: can classic RTS players understand the two win routes and meaningful faction counterplay, whether or not they know the Mexican references?

## Stories

### Story 3.1 — Test the promise with players

**As the** product owner, **I want** an uncoached comparison across cultural-context groups, **so that** I can decide whether the prototype merits a wider alpha.

**Acceptance:**

- Before any invitation, the builder supplies a numbered smoke walkthrough, a versioned preview or local build, a question script and an anonymous tally. The owner authorizes invitations and verifies the private alpha delivery gates separately. Preview events remain test-tagged and excluded from public cohorts.
- Recruit eight classic RTS players: four who self-report familiarity with the references and four who self-report unfamiliarity. This classifies cultural context, not ethnicity or nationality. Do not store names, contact details, stable player IDs or verbatim identifying comments in the roadmap.
- Before coaching, ask each player to explain both ways to win, describe one faction advantage and weakness, and name a counterplay choice. After their first match, observe whether they voluntarily start another without prompting. Record the build version, faction, result and any confusing moment using anonymous test IDs.
- Use the marks set before testing: at least three of four in each group correctly state both win routes; at least six of eight name a trade-off and counter; at least four of eight voluntarily start another match. Record exact numerators and denominators, including incomplete tests and failures. Do not change the marks after seeing results.
- Write a short verdict: proceed toward wider alpha, reshape the faction or district rules, or unclear with the next test needed. Do not call these eight people a North Star cohort or use their same-day replay choice as the provisional 15% later-day target.

**Risk:** low. The roadmap stores anonymized observations only; participant access and release decisions remain the owner's separate gates.

## Test script and record

1. Show the same build and setup to every tester. Ask: “What are the two ways to win?” Do not explain the answer first.
2. After faction choice, ask: “What is this faction good at, what does it give up, and what would the other side do about it?”
3. Let the player finish or abandon a match. Observe the result, confusion and any voluntary second-match start without suggesting a replay.
4. Record anonymous counts below. Add short paraphrased observations and the build/content version, then state a verdict against each predeclared mark.

| Measure | Familiar with references | Unfamiliar with references | Pass mark |
|---|---:|---:|---|
| Both win routes explained before coaching | pending / 4 | pending / 4 | at least 3 / 4 in each group |
| Faction trade-off and counter named | pending / 4 | pending / 4 | at least 6 / 8 overall |
| Voluntary second-match start | pending / 4 | pending / 4 | at least 4 / 8 overall |

**Build/content version:** local signed candidate `preview-eb3c7d9012a3` / `la-roma-prototype-1`. **Invitation authorization and delivery QA:** pending. **Verdict and reasons:** pending.

## Candidate build record · 2026-10-15

- `npm run alpha:export` passed the Node suite, six Godot headless checks, the Godot-to-ingest contract, Godot import, macOS export and strict code-sign verification. The final local ZIP is `dist/alpha/battle-for-la-roma-preview-eb3c7d9012a3-macos.zip`; SHA-256 `3d68b6457c6eb8bed7f8f6559bd882c0a3412f26a500246bbca3b07e0f4a97c7` matches its manifest.
- The final signed ZIP was extracted and opened locally. Its setup displayed both faction trade-offs, both win routes and the private invite field without clipping. After choosing Poblanos, the HUD showed build ID `preview-eb3c7d9012a3`, the marked neutral district and the opponent goal. Preview traffic is test-tagged; no build has been uploaded or sent to participants.
- Staging must run the new version allowlist and pass an invited HTTPS receipt/exclusion smoke before this candidate can sync there. Downloaded-build Gatekeeper QA, distribution access checks and owner-authorized invitations remain open. The eight-person tally is intentionally blank.
- Independent security review found that preview exclusion had trusted the client marker. The candidate server policy now forces exclusion in the `preview` environment, even when a client claims `test_account: false` and the flag is on. Node policy and Postgres-adapter checks pass with zero accepted public events; the reviewer must clear the updated diff before merge.

## Sprint QA

- **Headless and contract checks:** Rerun Godot rules/client checks, `npm run skirmish:contract`, and the preview exclusion check. Verify the chosen faction and content version survive outbox retry and that a test-tagged completion cannot enter public reporting.
- **Rendered smoke:** Builder and owner follow the walkthrough below on the exact build intended for the test. The owner performs the moderated protocol after explicit participant authorization; no browser smoke is owed for the local Godot scene.
- **Review:** A second reviewer checks any change to event eligibility or player data handling before merge, per [Ways of Working](../../WAYS-OF-WORKING.md#review--merge). The playtest verdict is a product-owner decision.

## Sprint 3 — Smoke walkthrough (do these in order)

Env: local Godot 4.7.2 · project `game/` · scene `res://skirmish_main.tscn`, or the exact versioned restricted preview after its delivery checks. The owner controls participant access.

1. Launch the intended test build.
   → The faction setup names both choices, their trade-offs and the two win routes.
2. Choose either faction and play to a terminal result.
   → The result is visible once and the game offers a way to start another match.
3. Restart the build and inspect its local sync status.
   → The prior start and completion remain saved or show stable receipts, and preview play is marked as test traffic.
4. Give a tester the build only after the owner authorizes their invitation.
   → The tester can describe both win routes before receiving coaching.
5. Ask the faction question from the script before explaining mechanics.
   → The anonymous tally captures the answer and a counterplay choice.
6. Observe what the tester does after their first match without suggesting a replay.
   → A voluntary second-match start is recorded as yes or no.
7. Repeat steps 4–6 until both self-reported familiarity groups have four completed tests.
   → The table shows exact counts for all three measures and a verdict against the original marks.

If a step fails, record its number and what appeared. An incomplete test stays incomplete; it is never counted as a pass.
