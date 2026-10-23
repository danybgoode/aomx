# Gameplay fidelity reference contract

**Audit date:** 2026-10-22  
**Project code baseline:** `1415812` on master; audit branch begins at `9f531c0` with no gameplay changes.  
**Project runtime observed:** Godot 4.7.2.stable.official.ed1daf0bf on macOS, headless scenario tests.  
**Reference edition:** Age of Empires II: Definitive Edition, per [ADR 002](../architecture-decisions/002-aoe2-definitive-edition-reference.md).

## Reference build

**Proposed fixed comparison build: DE update 185872**, documented in the [official 2026-09-22 release notes](https://www.ageofempires.com/news/age-of-empires-ii-definitive-edition-update-185872/). Those notes describe an AI and pathfinding rework, making the build material to this audit. This is a **documented candidate, not an observed DE installation**. No DE binary or licensed reference data was available in this macOS workspace. The owner must confirm the displayed build and platform before a numerical baseline is accepted. If the owner has a different build, record it here and re-run the scenarios against that build. Do not silently substitute a later live patch.

## Scenario protocol

For each reference observation record: displayed build, platform, game mode, map and seed, civilization, unit/technology state, starting resources, speed, visibility, game-time start/end, action sequence, result or frame capture, observer and date. Repeat a scenario at least three times if timing or path choice can vary. Write the raw observations before choosing tolerances.

| Sample | DE setup to record on the pinned build | La Roma setup | Comparison axis |
| --- | --- | --- | --- |
| Worker economy | One worker, one finite source and one drop-off; note carry capacity, route, gather and deposit timestamps. | Seeded worker at a physical source in `strategic_economy_test.gd`; four project resources remain distinct. | Mechanical income and behavioral rerouting; no equivalence of resource fiction assumed. |
| Construction | One and two workers on the same legal foundation; note placement rejection, progress, repair cost and finish time. | Seeded housing site and assist/repair cases in `strategic_economy_test.gd`. | Mechanical progress and behavioral command response. |
| Combat | Two known units and a building in controlled range; note armor, attack interval, target loss and siege effect. | Seeded armor/counter/siege cases in `warfare_test.gd`. | Mechanical damage and behavioral retargeting. |
| Movement and sight | The same obstacle, crowd, fog and lost-target setup; record route, collision and information available to player/AI. | `warfare_test.gd`, `strategic_opponent_test.gd` and scale benchmark fixtures. | Behavioral and experiential; never infer numerical parity from similar screenshots. |

No common map, resource names, faction modifiers or unit stat table has been approved between these games. Exact timing and balance tolerances are **unset** until the reference is observed. A project test passing means its own rule is repeatable; it does not certify DE parity.

## Exceptions awaiting owner decision

1. **Terrenos:** keep it as the current physical, finite survey-packet resource with timed replenishment, revise its fiction/rules, or align a different economy behavior. The game must explain the choice without making real estate stereotypes into facts.
2. **La Roma hold:** keep the 75-second uncontested central district as a distinct victory route, revise it, or limit close-fidelity claims to conquest and classic systems.
3. **Neighborhood modifiers and regional faction bonuses:** retain only explicitly approved fictional play doctrines with readable counterplay. Any new location modifier requires a separate rules decision and test.
4. **Fidelity claim:** until the owner confirms the reference build and scenario/tolerance policy, describe the game as AoE2-inspired and the current findings as project behavior only.

No proprietary DE code, assets or data enter the project.
