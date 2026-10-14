---
title: "Finish a solo skirmish"
slug: finish-solo-skirmish
status: raw
area: "01"
type: feature
appetite: null
underwritten_by: null
risk: low
epic: null
build_order: null
updated: 2026-10-13
intent_ask: proxy
hypothesis: "A classic RTS player needs a complete battle to judge Battle for La Roma's economy and combat. A small solo skirmish against an authored computer opponent should expose whether the core choices and win condition are satisfying."
persona: "A classic RTS player trying a complete solo match."
grounded: false
grounded_reason: "No match can finish yet, so first-match completion has no observed baseline."
target_metric: null
target_from: null
target_to: null
read_date: null
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
intent_match: null
---

# Idea — Finish a solo skirmish (E2 candidate)

**Why it is in the backlog:** The owner chose a traditional play-against-the-computer experience, using authored rules rather than a generative model. The first match may use fewer resources and ages than the full design. E2 should be shaped after [E1's](../../01-core-play/prove-rts-core/README.md) worker, resource, building and engine review.

## Candidate outcome

A human can gather, build, produce and command units, win or lose against a rule-based computer opponent, understand the result and restart. The opponent uses the same validated command interface and economy rules as the human. Internal matches have stable test-tagged IDs and one terminal result, but do not enter public cohorts.

## Candidate iterations

- **B1:** Produce workers and at least two combat roles through the economy.
- **B2:** Resolve counterable unit combat and literal building destruction.
- **B3:** Add the authored opponent, explicit conquest win/loss, one terminal result and restart.

## Decisions to make when refining

- Use E1's measured engine and replay result to set the match architecture and appetite.
- Define the first conquest defeat rule, stalemate behavior and opponent opening plan.
- Select the minimal resource and age subset and the two combat roles without treating proposed design-bible numbers as final balance.
- Keep local match records compatible with the [North Star](../../00-strategy/north-star.md) while leaving accepted offline sync to E4.

This idea stays in the [generated build order](../BUILD-ORDER.md) as a raw seed until E1's engine review informs its scope and the owner approves a specific bet.
