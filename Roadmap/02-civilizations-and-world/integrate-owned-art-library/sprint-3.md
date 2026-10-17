---
epic: integrate-owned-art-library
sprint: 3
title: "Match integration and verification"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S3.1
    title: "Use a safe owned prop and verify the match"
    as_a: "solo skirmish player"
    i_want: "owned decoration without changed commands or rules"
    so_that: "the battle remains readable and finishable"
    risk: low
    status: in-progress
---
# Integrate the owned art library — Sprint 3

### Story 3.1 — Use a safe owned prop and verify the match

**Acceptance:** An owner-supplied flower tile is drawn through the manifest in two nonblocking locations. Existing tests pass; normal and enlarged zoom, selection, placement, save, test-tagged sync and both victory routes remain usable. Record actual full-match and owner visual results rather than inferring them from headless checks.

## Sprint QA

Run `npm run skirmish:contract`, Godot client and save tests, and the rendered walkthrough. Record a screenshot and exact unresolved checks.

## Sprint 3 — Smoke walkthrough

1. Run Godot with `--path game` and choose either faction.
   → Flowers appear near the battlefield edge and units remain selectable.
2. Select a worker, gather gold, build a post and recruit fighters.
   → Orders, placement and selection remain tile based.
3. Complete a command-post or La Roma district victory, save and restart offline.
   → The correct result is queued once and the save retains its match ID.

## Downloaded-build QA, 2026-10-17

The signed Downloads app identified itself as `preview-0d2b90f67f91`. Regios rendered the owned flowers and accepted gather, build, recruit and attack orders; that match ended in a command-post loss at 02:08. An unfinished Poblanos match saved at 00:13 resumed at 00:13 after quitting and reopening the downloaded app. The local outbox recorded exactly one pending test-tagged start for the resumed match, and one pending test-tagged start/completion pair for the Regios loss. No invite code was entered or events synced.

Still open: downloaded-build wins with both factions and both victory routes, plus accepted test-event receipt if the private sync gate is intentionally exercised. A loss and a successful offline resume do not complete Story 3.1.
