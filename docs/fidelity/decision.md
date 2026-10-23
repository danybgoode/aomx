# Gameplay fidelity decision — proposed for owner review

**Status:** Builder audit complete; reference and exception decisions owed to the owner. This document authorizes no mechanics change.

The [matrix](audit-2026-10-22.md) shows a repeatable four-resource/four-age solo simulation with construction, combat, fog, fair AI fixtures, versioned save/replay and two terminal routes. It also shows no observed DE reference build, no numerical parity evidence and gaps in the broader classic RTS command/world set. Headless project checks do not settle control feel or downloaded-build comprehension.

| Priority | Decision or follow-on | Why now | Home |
| --- | --- | --- | --- |
| 1 | Confirm DE build 185872 or substitute the owned installed build, then measure four controlled scenarios before any parity claim. | The reference contract is the dependency for numbers and exceptions. | Owner review of [reference contract](reference-contract.md); this spike remains open. |
| 2 | Fix HUD readability, selection and command feedback; test uncoached control feel at normal viewing distance. | The owner directly reports small controls, so this is the clearest current experiential gap. | [Complete game interfaces](../../Roadmap/02-civilizations-and-world/complete-game-interfaces/README.md), with the older HUD finding transferred or closed explicitly. |
| 3 | Finish existing downloaded full-match and human QA for strategic play, warfare, opponent, world and maps. | The deterministic samples are stronger than the real-build evidence; do not duplicate funded work. | Their existing epics and owner walkthroughs. |
| 4 | Shape a command-depth follow-on only after the reference and human control review: patrol/stances, formations, rally, garrison/transport as justified by scenarios. | These are not in the inspected command set and could expand scope without proven value. | New seed if owner chooses; do not append silently to current epics. |
| 5 | Decide whether generated maps/elevation belong in a later wave. | Three authored maps exist; broad world parity and device-scale pathing are unproven. | Map/world roadmap after #16 owner QA. |

## Exceptions for the owner

- **Terrenos:** approve the current finite survey-packet mechanic as an intentional original-resource exception, or request a new rules/fantasy proposal. Avoid claims about real regions or property behavior.
- **La Roma victory:** approve the central 75-second uncontested hold as the game’s signature exception; constrain any close-fidelity statement to the systems actually compared.
- **Faction and neighborhood modifiers:** keep current fictional play doctrines under existing balance/portrayal QA. No new geographic modifier is approved by concept art.
- **Claim language:** use “AoE2-inspired” until the fixed build, observed baselines and tolerances support a narrower explicit claim.

**Recommended decision:** adopt the proposed reference build as a fixed test target only after verifying it in an owned installation; approve La Roma hold as an intentional exception; defer any new mechanics until #18 human control/readability QA and the existing full-match checks. The owner may revise any of these without changing the audit evidence.
