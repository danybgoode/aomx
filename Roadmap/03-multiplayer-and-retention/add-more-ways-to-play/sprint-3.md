---
epic: add-more-ways-to-play
sprint: 3
title: "Prove whole matches"
risk: high
phase: Verifying
stories_total: 1
stories:
  - id: S3.1
    title: "Finish every solo objective on a Restricted build"
    as_a: "returning skirmish player"
    i_want: "three readable, finishable objectives"
    so_that: "I can choose a fresh battle without breaking existing play"
    risk: high
    status: in-progress
---

# Add more ways to play — Sprint 3: Prove whole matches

**Status:** 🟨 Signed Restricted pilot ready — downloaded owner walkthrough owed.

### Story 3.1 — Finish every solo objective on a Restricted build

**As a** returning skirmish player, **I want** Conquest, La Roma and Wonder to finish as described on a downloaded build, **so that** I can choose another battle with confidence.

**Acceptance:** Reviewed source passes Godot/Node contracts and a normal AI full-match matrix across four factions and all offered modes. A signed Restricted macOS export is uploaded, independently fetched, byte compared, signature checked and started. The owner completes each objective on the downloaded app, saves/quits/resumes Wonder, confirms campaign isolation and the old Restricted channel's private-match behavior, and reads setup/progress/result at 1024×700 and 1280×800. The new pilot channel reports an explicit incompatible private-match entry until its host receives the new simulation hash. Record any uncoached comprehension separately; no public release or retention lift is inferred.

**Risk:** high — whole-game behavior and measurement contract.

## Sprint QA

- **Headless:** content, terminal, AI scenario, save/replay/hash, cross-platform, outbox/ingest and full `npm run skirmish:contract`.
- **Rendered:** native setup, Wonder progress, contest, disabled choice and results at both target windows.
- **Restricted download:** owner walkthrough with exact source commit, archive hash, itch build ID, expected/actual observations and open limitations. Independent high-risk review before merge.

**Builder checkpoint · 2026-10-28:** Godot 4.7.2 finished all four faction starts in La Roma and Conquest in normal AI matches and replay-verified each terminal state. La Roma ended by district at ticks 1673–1772. Conquest ended once by command-post loss at tick 3114 and three times by the existing 9000-tick draw limit; center control never ended Conquest. These draws reveal a pacing/pathing limit, so this matrix proves termination and objective isolation, not that AI can consistently win Conquest. The Wonder client integration test passed a legal build, 120 held ticks, save, served-off decision, resume with the same match ID and state hash, and exactly one completion/adoption pair. The new pilot client explains a private-host version mismatch explicitly.

**Release checkpoint · 2026-10-28:** [PR #97](https://github.com/danybgoode/aomx/pull/97) merged after Linux verify, CodeQL and an independent verifier found no blocker. The full signed export gate from `master` `f49a1ce1b62c` passed. Restricted Butler build **#2234135** on the isolated `mac-ways-to-play-pilot` channel was independently fetched, byte-compared to the source extraction, signature-checked and started headlessly. The compatible ingest image is healthy and denies an unauthenticated Wonder flag request; the old private-match host remains unchanged. See the [release and owner QA record](../../../docs/ways-to-play-qa-2026-10-28.md). Wonder is still served off; downloaded gameplay, cold quit/reopen, excluded receipt and owner comprehension remain open.

## Sprint 3 — Smoke walkthrough

Environment: signed Restricted owner download, following `deploy/alpha/README.md` and `docs/alpha-local-qa.md`; record build ID and verified archive hash.

1. Start Conquest as two different factions and hold the center, then destroy the opposing post. → Center alone never ends the match; post victory does.
2. Start La Roma as two different factions and complete its center hold. → The old route ends once with the correct result reason.
3. With Wonder served on for the owner identity, start Wonder on 28×28 La Roma and build, guard and finish it against AI. → Cost, 900-tick public countdown, result and readable copy match the rule card.
4. Start a second Wonder match, save, quit and resume, then destroy the opponent's Wonder. → The same match ID and timer restore, and the opponent timer resets.
5. Open the campaign chapter and the old Restricted channel's private-match entry. → Their prior objectives and access behavior remain. The new pilot channel shows explicit host incompatibility. Turn Wonder off, refresh the decision and reopen setup. → New Wonder starts are blocked while the other solo choices remain.
6. Inspect excluded test receipts and the provider evaluation. → Each finished player-match contributes once; replay, duplicate and abandoned paths contribute nothing to public retention.
