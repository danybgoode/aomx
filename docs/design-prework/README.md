# Battle for La Roma — Design Bible

**Version:** 0.2 · **Date:** 2026-10-13 · **Status:** Living design, pre-production

The [v0.3 GDD](../design/GDD.md) now provides global design alignment. This v0.2 package is retained as historical working material; when its proposals conflict with GDD sections 1–10, the v0.3 GDD takes precedence. Delivery scope and implementation status live in the [roadmap](../../Roadmap/README.md) and source.

A satirical, mechanically serious, AoE2-inspired real-time strategy game in an alternate contemporary Mexico City where regional communities wage **literal battles**, destroy buildings, build economies, and fight for La Roma.

## Confirmed decisions
- **Fiction:** A + C: contemporary Mexico City with medieval-style factional warfare treated as normal. Combat is literal, not abstract.
- **Engine for MVP:** Godot (selected after technical spike). Engine decisions belong to development; design remains portable.
- **Ambition:** Full classic RTS experience; **do not interpret this package as an MVP cut**.
- **Player fantasy:** Arrive as foráneos, organize a community, build an empire, conquer La Roma.
- **Primary mode:** Classic skirmish; territory-based mode is a signature candidate, not a replacement.

## Reading order
1. `design/00-master-gdd.md`
2. `world/01-world-lore.md`
3. `systems/02-economy-progression.md`
4. `systems/03-combat-units.md`
5. `civilizations/04-factions.md`
6. `maps/05-maps-modes.md`
7. `art-audio/06-art-audio.md`
8. `ux/07-ux-accessibility.md`
9. `systems/08-balance.md`
10. `production/09-roadmap-risks.md`
11. `production/10-decisions-open-questions.md`
12. `production/11-design-spec-template.md`
13. `references/sources.md`

## How to use
These are **design references**, not instructions to implement everything immediately. `Confirmed`, `Proposed`, `Experimental`, and `Deferred` have different meanings. Preserve decisions; test proposals; don't silently convert jokes into mechanics. Codex can derive its own MVP slices and implementation plan. Never treat sample costs or bonuses as approved balance.
