---
kind: north-star
status: agreed
updated: 2026-10-13
---

# North Star — Battle for La Roma

## The game

Attention: players gain value through repeated strategic play, whether a match is solo or shared. (assumed)

## Launch goal

**Goal for `return_to_match`:** At least 15% of first-match completers finish another eligible match on a different UTC date within seven days; this is a launch target chosen for planning, not an observed baseline or a directly comparable industry benchmark. (your words)
**Baseline:** Measure the first launch cohort after its seven-day return window closes; report the numerator, denominator, and rate, leaving the baseline unknown until then. (assumed)
**Read point:** Review the goal 30 days after the first playable launch, with at least 100 first-match completers whose seven-day windows have closed; if fewer qualify, report the rate as directional and review again when 100 qualify. (assumed)

## Launch funnel

The funnel must be part of the first playable build, before inviting players, so the first cohorts have complete event histories. (your words)

| Stage | Signal | Definition |
|---|---|---|
| 1 · First open | `game_opened` | First observed open for a stable, pseudonymous `player_id`; retain the first timestamp for cohort assignment. (assumed) |
| 2 · First match start | `match_started` | First eligible match started by that player within seven days of first open. (assumed) |
| 3 · First match finish | `match_completed` and `first_match_completed` | First eligible match with a terminal result for that player within seven days of first open. (assumed) |
| 4 · Later-day return | `game_opened` | An open on a later UTC date after first completion, within seven days of that completion. (assumed) |
| 5 · Later-day match start | `match_started` | An eligible match started on a later UTC date, within seven days of first completion. (assumed) |
| 6 · Later-day match finish | `match_completed` and `later_day_match_completed` | An eligible match finished on a later UTC date, within seven days of first completion; each player enters this stage once. (assumed) |

An eligible match is a real playable solo or multiplayer match that starts and reaches a terminal result; tutorials, abandoned matches, bots, and developer or test accounts do not count. (assumed)
`match_started` and `match_completed` are authoritative game outcomes emitted through the product backend; a client button press alone cannot prove a start or completion. (assumed)
Each event needs an event ID, event time in UTC, stable pseudonymous player ID, match ID when relevant, game version, mode, faction, and test-account flag; completed matches also need the terminal result. (assumed)
Deduplicate by event ID and by player ID plus match ID plus event type; one match can contribute once for each human participant. (assumed)
Use mature seven-day cohorts for conversion rates, and show the count at every stage so a small launch cannot hide behind percentages. (assumed)
The North Star counts distinct eligible players with completions on two distinct UTC dates inside one rolling seven-day window, after deduplication and test traffic exclusion. (assumed)
Calculate the three input rates from those deduplicated events and send one daily numeric reading for each through Golden Frijoles `external_push`; use percentage points from 0 to 100 and keep the raw event stream for stage counts and audits. (assumed)
Date cohort readings by the first-open or first-completion date, and publish their seven-day rates only after that cohort's full window closes; show “pending” instead of zero for immature cohorts. (assumed)
Calculate the North Star's unique-player count from the same data and show it alongside the rates, so a rising percentage cannot conceal a falling player count. (assumed)

**First-build check:** Exercise a first open, a completed match, a later-day completed match, an abandoned match, and a duplicate completion; inspect the raw events and dashboard to confirm the first player enters each eligible stage once, the abandoned match does not finish, and the duplicate does not raise any count. (assumed)

## North Star statement

Our path to sustainable growth is a function of our ability to make players finish a satisfying first battle and return to finish another on a later day. (assumed)

## North Star metric

**Returning commanders**: The number of distinct human players who finish at least two eligible matches on different UTC dates within a rolling seven-day window. (assumed)

## Input metrics

| Key | Input | Lever | How it is measured |
|---|---|---|---|
| `new_players` | New players | Breadth | Distinct stable player IDs with their first `game_opened` on the UTC day; one daily count through `external_push`. (assumed) |
| `first_match_completion` | First match completion rate | Depth | Percentage of a mature first-open cohort who finish an eligible match within seven days; one daily 0–100 reading through `external_push`. (assumed) |
| `return_to_match` | Later-day match completion rate | Frequency | Percentage of a mature first-match-completer cohort who finish another eligible match on a different UTC date within seven days; one daily 0–100 reading through `external_push`. (assumed) |
| `match_completion` | Match completion rate | Efficiency | Percentage of eligible player-match starts on a UTC day that reach a terminal result within 24 hours; one daily 0–100 reading through `external_push` after that window closes. (assumed) |

## Lagging indicators

Player retention beyond seven days and revenue, if a revenue model is chosen, are lagging indicators to define after early playtests. (assumed)

## Sync payload

The metric and its inputs in the shape the Golden Frijoles engine takes; daily aggregation sends the values because raw event occurrence counts cannot represent unique-player counts or conversion rates. (assumed)

```json
{
  "metric": {
    "key": "returning_commanders",
    "name": "Returning commanders",
    "description": "The number of distinct human players who finish at least two eligible matches on different UTC dates within a rolling seven-day window."
  },
  "inputs": [
    { "key": "new_players", "name": "New players", "valueSource": "external_push" },
    { "key": "first_match_completion", "name": "First match completion rate", "valueSource": "external_push" },
    { "key": "return_to_match", "name": "Later-day match completion rate", "valueSource": "external_push" },
    { "key": "match_completion", "name": "Match completion rate", "valueSource": "external_push" }
  ]
}
```
