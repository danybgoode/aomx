# 03 — Combat & Units

## Canon — CONFIRMED
Combat is literal: units fight, damage other units and buildings, and can destroy structures. Battles are stylized, non-graphic, and strategically legible.

## Unit roles (mechanics before names)
| Role | Tactical job | Counters / vulnerabilities |
|---|---|---|
| Worker | economy and building | vulnerable to raids |
| Light melee | cheap early pressure | weak versus armored defense |
| Heavy melee | frontline durability | kiteable / expensive |
| Ranged | distance damage | vulnerable when caught |
| Fast/mobile | scouting, raids, flanks | countered by anti-mobile |
| Anti-mobile | defend against fast units | situational |
| Siege | destroy structures | weak unsupported |
| Support | heal/buff/logistics | low direct combat |
| Unique | faction expression | explicit counters required |

## Combat loop
Acquire target → move into range → attack wind-up → apply damage → cooldown → retarget or follow orders. Include line-of-sight/range rules, armor, damage types, projectiles, minimum range where appropriate, friendly fire policy and building attack classes.

## Commands
Move, attack, attack-move, patrol, stop, hold position, guard/follow, gather, build, repair, garrison, ungarrison; group selection, control groups, queue orders. Some are full-vision features rather than initial commitments.

## Candidate thematic archetypes — NOT finalized
Foráneo (worker); Godín (organized professional combatant); Mirrey (elite/expensive archetype); Repartidor (fast unit); Activista (support or crowd-control); Consultor (support/elite); Broker (siege/territory); Influencer (morale/support). **Do not assign mechanics purely from stereotypes.**

## Building combat
Defensive structures acquire targets; buildings have hit points, armor and destruction states. Siege must be a meaningful investment. Buildings cannot become trivial to destroy with generic light units.

## Death and destruction feedback
Clear hit feedback, health bars, selection feedback, audio cues, rubble and pathing updates. Non-graphic comic presentation. Unit defeat should not be confused with retreat.

## AI and multiplayer implications
Simulation needs reproducible orders, explicit target rules and consistent update timing; Godot engine choice does not automatically guarantee cross-device determinism. Network model remains a separate architecture decision.

## Edge cases to specify
Target dies mid-attack; unreachable target; collision congestion; target inside building; command interrupted by combat; projectile after shooter death; fog-of-war target lost; destroyed obstacle opens route; allied fire; unit stuck between buildings.

## Acceptance scenarios
Two units with known stats produce predictable outcome; siege beats undefended structures; anti-mobile composition beats fast raiders under controlled conditions; right-click context remains unambiguous; units reroute after construction/destruction.
