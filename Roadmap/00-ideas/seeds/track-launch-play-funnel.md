---
title: "Track the launch play funnel"
slug: track-launch-play-funnel
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
hypothesis: "We believe measuring each step from first open through a later-day completed match for new Battle for La Roma players will reveal where the first experience loses them; we'll know when the event counts reconcile and at least 15% of first-match completers finish another eligible match on a different day within seven days."
persona: "A new Battle for La Roma player testing whether this RTS is worth returning to."
grounded: false
grounded_reason: "The return-rate baseline does not exist until the first playable cohort completes its seven-day window."
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

# Pitch — Track the launch play funnel

Moves: `return_to_match` · Tests: Value proposition.

## The ask, as given

> A is great, just consider that this is brand new launch so lets ensure the funnel is setup correctly so we can track it all along

### Claims

1. Use Returning commanders as the North Star.
2. Set up the launch funnel so the whole player journey is measurable from the beginning.

## Problem

Without events from the first playable build, the team cannot tell whether new players reach a complete match, return on a later day, or meet the Returning commanders goal. Missing early events cannot be reconstructed reliably after launch.

## Outcome & signal

The first player cohorts have a complete, auditable path from first open to later-day match completion. The provisional goal is at least 15% later-day match completion among first-match completers; its baseline is the first measured cohort, reviewed 30 days after the first playable launch or once 100 eligible first-match completers have matured, whichever comes later.

## First build scope

- Emit first open, match start, and authoritative match completion events with stable pseudonymous player IDs and match IDs.
- Derive first-match and later-day completion milestones, excluding test traffic, bots, tutorials, abandoned matches, and duplicate events.
- Show every funnel stage as a count and a cohort conversion rate, with incomplete seven-day windows marked pending.
- Calculate Returning commanders and the four North Star input readings from the same deduplicated data; push daily input readings as specified in `Roadmap/00-strategy/north-star.md`.
- Reconcile a scripted first match, later-day finish, abandoned match, and duplicate completion against raw events and the dashboard before inviting players.

## Open decisions for refinement

- Choose the game runtime, server authority, storage, and analytics delivery points when product code exists.
- Observe the first eligible cohort before writing a numeric `target_from`; the 15% goal stays visible in this pitch until then.
- Decide the first playable launch date; the read point is relative to that launch, not the date this idea was written.
