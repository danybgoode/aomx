# 08 — Balance, Metrics & Playtests

## Principles
Strategic fairness, not identical factions. Balance economy, timing windows, army compositions, map control and counterplay. Separate thematic flavor from quantitative power.

## Canonical data categories
Unit: cost vector, build time, HP, speed, armor, attack type, damage, range, cooldown, sight, pop, tags. Building: footprint, cost, HP, build time, queue, garrison. Tech: prerequisite, cost, duration, effect. Resource: gather rate, capacity, travel, depletion. Age: prerequisites, cost, duration.

## Design equations (illustrative, not game constants)
- Effective resource income ≈ workers × gather rate × uptime × travel efficiency.
- Unit replacement burden ≈ unit cost / sustainable resource income.
- Time-to-defeat ≈ target effective HP / sustained effective damage.
These guide tests; actual armor and attack formulas remain unspecified.

## Test matrix
Opening build-order viability; rush vs boom; defense vs siege; fast units vs anti-mobile; map spawn equity; unique-unit counters; wonder holdability; late-game resource starvation; large-army pathing.

## Telemetry candidates
Age-up timings, idle worker seconds, resource float, unit composition, units lost, map control, match length, win rates by faction/map/skill, APM proxy, command failures.

## Method
Hypothesis → controlled scenario → automated simulation → human playtest → evidence → balance decision. Record build/version and scenario seed. Do not present invented numeric bonuses as tuned values.
