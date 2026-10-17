---
epic: deepen-strategic-play
sprint: 3
title: "Integrated two-faction match"
risk: high
phase: Locking architecture
stories_total: 1
stories:
  - id: S3.1
    title: "Finish a four-age match against legal AI"
    as_a: "returning skirmish player"
    i_want: "a capable opponent on the same economy and progression rules"
    so_that: "the new decisions matter through a complete battle"
    risk: high
    status: planned
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
