# 00 — Master Game Design Document

**Status:** Foundational vision (confirmed except where labeled)

## Pitch
*Age of Empires II meets a deliriously literal battle for Mexico City's Roma neighborhood.* Regional Mexican communities arrive as university foráneos, survive student life, professionalize into godínez, and command absurd modern armies to conquer neighborhoods and destroy rival infrastructure.

## Player promise
From a few students in a shared room to a sprawling urban civilization: every minute offers meaningful economic, tactical, or strategic decisions, punctuated by unmistakably Mexican satire.

## Design pillars
1. **RTS first:** Economic tempo, counterplay, scouting, expansion and army control matter without the jokes.
2. **Mexico in the mechanics:** Humor emerges from recognizable professions, buildings, sound, geography, and their strategic roles.
3. **Literal absurdity, consistent rules:** The fictional society accepts open warfare between students, professionals, and regional factions.
4. **Asymmetric, fair factions:** Each civilization offers distinctive advantages, vulnerabilities, and viable strategies.
5. **Readable at a glance:** Silhouettes, feedback and UI communicate the game state during chaos.

## Core loops
- **Seconds:** inspect → select → command → observe feedback → adjust.
- **Minutes:** gather → produce → build → scout → research → expand → fight.
- **Match:** survive arrival → develop student community → professionalize → dominate high-value urban territory → win.

## Four ages
| Age | Social metaphor | Strategic function |
|---|---|---|
| Edad Foránea | Arrival, shared rooms, survival | Workers, basic economy, scouting |
| Edad Universitaria | Networks, education, student organizations | Specialization, early aggression |
| Edad Godín | Offices, startups, organized power | Mature economy, fortification, siege |
| Edad de la Gentrificación | Wealth, development, influence | Elite units, monuments, endgame |

Ages represent **collective community development**, not a single person's biography.

## Economy
Four functional resources: **Comida** (food), **Materiales** (wood-equivalent), **Varos** (gold-equivalent), **Terrenos** (stone-equivalent). Workers physically gather and deliver; exact fiction for Terrenos is an open design problem. Preserve opportunity costs and resource scarcity.

## Core systems
- Isometric or angled 2D battlefield; fog of war, exploration, camera, minimap.
- Workers, gathering, drop-offs, construction, repair, production queues, population cap.
- Tech trees, four ages, faction bonuses, unit upgrades.
- Melee, ranged, siege, defenses, counter system, formations/control groups.
- AI skirmish, diplomacy/team play, victory modes; multiplayer long-term.
- Maps inspired by CDMX rather than 1:1 GIS reconstructions.

## Combat premise
**Confirmed:** Units literally attack, are defeated, and demolish buildings. The world is an alternate contemporary city where rival regional communities act like medieval powers. Absurdity is presented straight-faced. Mechanics must not become metaphorical social-influence battles.

## Victory modes
- **Conquest (primary):** Eliminate opponents according to explicit defeat conditions (to be specified).
- **Wonder:** Build and defend a monumental development for a countdown.
- **Battle for La Roma (signature candidate):** Contest strategic neighborhoods and hold the central district.
- **Scenario:** Narrative-specific objectives.

## Target experience
Desktop first; mouse and keyboard. Skirmish should be understandable without knowing the jokes. **Proposed** match-length hypothesis: 25–50 minutes; validate by playtest.

## Scope principle
The **full design is the north star**. Development milestones and MVP cuts are separate planning artifacts; no features here are silently discarded because they are difficult.

## Creative non-goals
- Not a 1:1 street-map simulator.
- Not a life-sim or abstract economic influence game.
- Not a parody using original AoE2 artwork, audio, trademarks, or proprietary data.
- Not a requirement to copy AoE2's exact numeric values or interface.
