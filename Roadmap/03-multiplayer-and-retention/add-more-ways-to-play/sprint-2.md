---
epic: add-more-ways-to-play
sprint: 2
title: "Build and measure Wonder"
risk: high
phase: Verifying
stories_total: 2
stories:
  - id: S2.1
    title: "Build and contest a Wonder"
    as_a: "solo skirmish player"
    i_want: "a build-and-defend victory against fair AI"
    so_that: "my next match demands a different plan"
    risk: high
    status: done
  - id: S2.2
    title: "Control and measure Wonder access"
    as_a: "alpha operator"
    i_want: "a served rollout decision and accepted mode result"
    so_that: "I can verify usage without inflating retention"
    risk: high
    status: done
---

# Add more ways to play — Sprint 2: Build and measure Wonder

**Status:** 🟨 Builder verified — independent review and signed Restricted owner walkthrough owed.

### Story 2.1 — Build and contest a Wonder ✅

**As a** solo skirmish player, **I want** to build and defend a Wonder or destroy my opponent's, **so that** another match rewards an economic and tactical plan.

**Acceptance:** The [approved rule card](../../00-ideas/seeds/add-more-ways-to-play.md#scope) applies on the 28×28 La Roma map: age, four-resource cost, one project per side, build and hold ticks, destruction/reset/rebuild, post precedence and simultaneous finish. The AI pays, builds, guards and attacks through legal commands and normal sight. Placement/reachability are validated. Mode and timer state round-trip through save/replay with cross-platform hashes; legacy modes and campaign/private 1v1 stay unchanged.

**Risk:** high — deterministic rules, AI, persistence and online isolation.

### Story 2.2 — Control and measure Wonder access ✅

**As an** alpha operator, **I want** Wonder to stay off until a served decision and to count only accepted full matches, **so that** a rollout can be checked without distorting the agreed funnel.

**Acceptance:** `modes.wonder_enabled` is created off with a served version in development, preview and production. The existing alpha backend resolves it for the pseudonymous player ID and reports a user-level evaluation; the client caches decision/version without a provider key. First use defaults off; a later served off blocks new starts without altering a pinned running match. Accepted Wonder start/completion events carry mode and objective with versioned allowlists; `wonder_match_completed` is recorded only after a real eligible accepted completion. Test accounts, abandoned games, replay and duplicate results do not count.

**Risk:** high — flag, identity and North Star integrity.

## Sprint QA

- **Headless specs:** four-faction Wonder cost/build/destroy/timer/terminal fixtures, AI legal-order matrix, map validation, save/replay and macOS/Linux hashes.
- **Node/Godot contract:** served off and on decisions, same-user evaluation, mode-tagged acceptance, duplicate/abandon/replay exclusion and no bundled provider key.
- **Rendered smoke:** native Wonder construction, progress, contest and result at both target windows; off-choice copy readable. Independent high-risk simulation and data-integrity review.

## Sprint 2 — Smoke walkthrough

Environment: local Godot 4.7.2 and project alpha backend in test mode; record source commit, game/content versions and served flag versions.

1. With a served off decision, open solo setup. → Wonder is visibly unavailable; Conquest and La Roma still start.
2. Serve Wonder on for the test identity and reopen setup. → Wonder is selectable, and a user-level evaluation is recorded.
3. Start Wonder, reach `godin`, pay the four-resource cost and complete construction. → The HUD shows both sides' public objective timing without revealing fogged units.
4. Destroy a counting Wonder and rebuild it. → Its old countdown is gone; the new project must complete before a fresh 900-tick hold.
5. Complete one Wonder match, then replay or retry its result. → One accepted test-tagged completion and one adoption record exist; no duplicate or public cohort count appears.

**Builder checkpoint · 2026-10-27:** Godot 4.7.2 with `la-roma-wonder-1` content. `wonder_mode_test.gd` passed four-faction cost, one-project, destruction/rebuild, 900-tick terminal, simultaneous finish, post precedence, AI legal orders, save/replay and outbox. `wonder_ai_match_test.gd` finished a standard AI match by Wonder at tick 2621. The four-faction normal-match hash fixture passed on macOS; Linux CI parity is pending. `npm test` passed 48, with 3 PostgreSQL integration cases skipped; `npm run skirmish:contract` passed. Native 1024×700 and 1280×800 setup/progress/result captures were inspected, including public countdowns with the enemy project still hidden by fog. Golden Frijoles `modes.wonder_enabled` serves off v1 in development, preview and production. The backend's user-level flag evaluation and accepted adoption contract are covered by Node tests. This is test-only evidence, not an observed public cohort.
