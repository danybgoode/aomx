# 02 — Economy, Buildings & Progression

## Core rule — CONFIRMED
Four-resource RTS economy with workers, deposits, carrying capacity, drop-offs, depletion, buildings, queues, research, population and age advancement.

| Resource | Function | Candidate sources | Key uncertainty |
|---|---|---|---|
| Comida | workers/basic units | fondas, taquerías, mercados | gathering visuals |
| Materiales | structures | ferreterías, warehouses, salvage | renewable supply |
| Varos | elite units/research | commerce, jobs, deposits | physical vs generated economy |
| Terrenos | defenses/monuments | lots, deeds, development sites | believable gather/return loop |

**Rule:** Resource types are mechanically stable even if fictional representations evolve. No fifth resource without strong strategic justification.

## Worker lifecycle — PROPOSED
Idle → move to source → harvest until capacity → move to valid drop-off → deposit → repeat; interruptions include depletion, blocked path, attack, command override, destruction. Idle-worker indication and retasking are essential.

## Construction
Placement preview (valid/invalid), cost reservation/payment, foundation, worker construction progress, completion, production availability, cancellation/refund policy, repair. Buildings occupy navigable space and can be destroyed.

## Building families
- Housing: cuarto compartido → higher-capacity residential forms.
- Town center equivalent: community headquarters/centro de foráneos (name TBD).
- Economy: tiendita, mercado, commercial office, drop-offs.
- Military: recruitment centers, training organizations, advanced academies.
- Research: facultad, biblioteca, professional institutes.
- Defensive: barricades, watch structures, fortified developments.
- Monument: faction-specific megaproject.

Names are thematic candidates; final tech tree must identify precise functions, ages, prerequisites, cost, build time and footprint.

## Age transitions
| Transition | Candidate narrative | System effect |
|---|---|---|
| Foránea → Universitaria | establishment in city | early military and research |
| Universitaria → Godín | professional organization | advanced economy, siege |
| Godín → Gentrificación | capital accumulation | elite units and wonders |

Age-up consumes resources and time; player chooses tech versus army. Research prerequisites and timing are not yet approved.

## Technology concepts — PROPOSED
Tupper de Mamá (food efficiency), Servicio Social (worker/support upgrade), Home Office (production efficiency), Networking (economic aura), MBA (late economy), Especulación Inmobiliaria (territory/defense), Facturación (Regio economy). Avoid abilities whose effects cannot be expressed as measurable rules.

## System design checklist
For each building/tech: stable ID; age; cost; time; prerequisites; effects; UI copy; art/audio needs; cancellation behavior; AI usage; balancing variables; test scenarios.

## Edge cases
No drop-off available; exhausted node; insufficient resources during queue; blocked foundation; worker killed while carrying; demolished production building; pop cap reached; simultaneous research; canceled age-up.
