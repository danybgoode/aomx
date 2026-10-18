---
epic: deepen-strategic-play
sprint: 3
title: "Integrated two-faction match"
risk: high
phase: Verifying
stories_total: 1
stories:
  - id: S3.1
    title: "Finish a four-age match against legal AI"
    as_a: "returning skirmish player"
    i_want: "a capable opponent on the same economy and progression rules"
    so_that: "the new decisions matter through a complete battle"
    risk: high
    status: in-progress
---

# Deepen strategic play — Sprint 3

### Story 3.1 — Finish a four-age match against legal AI

As a player, I can reach the fourth age and finish a two-faction match by either existing route. The opponent gathers, builds, researches and advances through the same validated commands, costs and prerequisites. The HUD explains resources, population, queues, age and unavailable actions without hiding the board.

**Acceptance:** Seeded scenarios prove AI legality, both terminal routes and at least two viable economic plans. Save/replay and one test-tagged start/completion per match remain intact. A signed downloaded build passes both factions, both victory routes and save/quit/resume; record build ID and limitations before epic close.

## Sprint QA

Run the full Godot and Node contract suite, cross-platform hash, rendered desktop/enlarged-zoom smoke, and downloaded Restricted owner preview checks. The signed build is required for final acceptance; headless wins alone do not close the story.

## Sprint 3 — Smoke walkthrough

1. On the signed downloaded preview, play Regios to Gentrificación and win by destroying the opposing command post.
   → The match ends once with a command-post win and one test-tagged completion.
2. Play Poblanos to Gentrificación and hold La Roma uncontested for 60 seconds.
   → The match ends once with a district win; a contested hold resets.
3. Save an unfinished match, quit the app, reopen the same downloaded build and resume.
   → Match ID, age, research, stockpiles, worker cargo and queue state are unchanged; no duplicate start event appears.
4. Replay controlled AI/economy scenarios for both factions and check normal and enlarged zoom.
   → The opponent pays valid costs and the board, selection and command reasons remain readable.

## QA record, 2026-10-17

Both AI faction fixtures reached Gentrificación and completed research. The normal idle-match test confirms fourth-age progression before AI district pressure wins; district contest, post loss and deterministic replay still pass. The full Godot CI script list, Node suite, ingest contract and art manifest passed locally. Independent high-risk review rechecked cancellation, AI pacing, path obstruction and stale modal fixes. Signed Restricted build upload, downloaded-build wins for both factions/routes and release outbox QA remain open.

The Restricted upload completed as `preview-9053c3808441`, itch build `#2150671`; the authenticated fetch matched the signed source archive. Four downloaded match combinations, save/quit/resume and synced test receipts remain open. The owner download made before this upload is the previous build.

On 2026-10-17 the VM was updated to `aomx-ingest:8fe3152` and became healthy. Its restricted HTTPS health endpoint and live `alpha:smoke` passed for `godot-4.7.2-skirmish-2` / `la-roma-strategy-2`; audit rows were excluded or rejected, and the temporary invite was revoked. A direct attempt to attach app control to the exact Downloads app returned `Running application not found`, so the downloaded-build match and save/resume acceptance remains open.
