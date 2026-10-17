# Battle for La Roma — Game Design Document

**Document:** `docs/design/GDD.md`
**Version:** 0.3 — consolidated creative north star
**Updated:** 2026-10-16
**Status:** Living design reference; not an implementation audit
**Audience:** Designers, artists, engineers, Codex agents, QA, production

> **Document authority:** This GDD defines the intended game. The current repository, tests, and release configuration define what is *actually implemented*. Do not interpret a feature described here as implemented. Existing roadmap milestones and architectural decision records remain authoritative for sequencing unless explicitly updated.

**Project integration, 2026-10-16:** This tracked copy is the global design reference; the original in the ignored `references/` folder remains local input. The [capability and architecture review](../architecture-review-2026-10-16.md) records implementation evidence and gaps, and the [full-game build path](../../Roadmap/full-game-build-path.md) orders delivery. The owner confirmed commercial game rights for `references/newArtWork`, `references/critters`, and `references/isometric tileset`, and chose Age of Empires II: Definitive Edition as the fidelity reference ([ADR 002](../architecture-decisions/002-aoe2-definitive-edition-reference.md)). A specific build/patch and exception policy remain open, so no numerical parity claim is approved. Images and labels in concept boards illustrate possibilities; they do not approve game rules, map scope, or production-ready assets.

## 1. Executive vision

**Elevator pitch.** *Age of Empires II's strategic depth collides with a deliriously literal battle for Mexico City's Roma neighborhood.* Regional Mexican communities arrive as foráneos, build neighborhoods, professionalize into godínez, and wage stylized RTS warfare for control of an alternate contemporary CDMX.

**Product intent (confirmed):** A **standalone, commercial-quality, independently installable game**. It is **not** a mod requiring Age of Empires II or its proprietary game data. The game uses original characters, factions, settings, art, audio, and interface expression while pursuing high **mechanical, behavioral, and experiential fidelity** to a specifically identified AoE2 reference ruleset. Fidelity is an engineering/design target, not a claim that compatibility is already achieved.

**Engine and platforms (confirmed direction):** Godot; native Windows/macOS/Linux, native Android/iOS, and browser-based desktop/mobile play. **itch.io** is the initial distribution channel for downloadable desktop and browser builds. Other distribution channels may follow. A shared simulation and game-content model powers all targets; presentation, graphics quality, and control schemes adapt to device capabilities.

**Player promise:** Begin with a few students in a shared room and grow into a sprawling urban civilization. Every minute presents consequential economic, tactical, and strategic choices, punctuated by recognizably Mexican satire.

### 1.1 Design pillars

1. **RTS first.** Scouting, build orders, economic tempo, unit counters, positioning, map control, and army micro matter even without the jokes.
2. **AoE2 fidelity is deliberate.** Reproduce core systems and behaviors against an identified reference edition; document and test deviations.
3. **Mexico in the mechanics.** Humor emerges through professions, buildings, geography, voices, and tactical roles—not detached joke labels.
4. **Literal absurdity, internally consistent.** Contemporary urban communities behave like competing medieval RTS civilizations; buildings can be demolished and armies defeated, with stylized, non-graphic presentation.
5. **Asymmetric but fair.** Factions have meaningful strengths, weaknesses, and viable strategic paths.
6. **Readable at a glance.** Strong silhouettes, terrain contrast, faction cues, informative HUD, and consistent feedback.
7. **One game, multiple interfaces.** Desktop, touch, and web share gameplay rules and content.

### 1.2 Core loops

| Horizon | Loop |
|---|---|
| Seconds | Inspect → select → command → feedback → adjust |
| Minutes | Gather → produce → construct → scout → research → expand → fight |
| Match | Establish foothold → develop economy → advance ages → seize territory → defeat opponents |
| Meta | Learn factions/maps → improve strategies → play scenarios/skirmishes → share or compete |

### 1.3 The four ages

| Age | Fiction | Gameplay function |
|---|---|---|
| **Edad Foránea** | Arrival, shared housing, survival | Workers, rudimentary economy, scouting |
| **Edad Universitaria** | Student networks and specialization | Early military, technology, expanding infrastructure |
| **Edad Godín** | Offices, organized economic power | Mature economy, fortifications, siege |
| **Edad de la Gentrificación** | Real estate, prestige, concentrated influence | Elite forces, monuments, endgame |

Ages represent the development of a *community*, not the personal life cycle of one character. Age names are creative targets; numerical costs, timing, and technology prerequisites require a ruleset mapping and balance validation.

### 1.4 Four resources

| Resource | AoE2 analogue | Fictional role |
|---|---|---|
| **Comida** | Food | Feeding population and recruiting units |
| **Materiales** | Wood | Construction and infrastructure |
| **Varos** | Gold | Specialized units and research |
| **Terrenos** | Stone | Fortification and major development |

Workers gather, carry, and deposit resources physically. **Terrenos** is a resource abstraction, not a literal real-estate ownership simulation; its exact gatherable representation and drop-off fiction remain to be finalized.

## 2. Design authority and fidelity rules

- **Reference edition:** Age of Empires II: Definitive Edition. Record a specific DE build/balance patch before making exact numerical parity claims. Until then, mechanics are *AoE2-inspired targets*, not certified parity.
- **Three fidelity axes:** mechanical (outcomes/timing), behavioral (command response/automation), experiential (pacing/readability/control feel).
- **Original expression:** No proprietary AoE2 sprites, music, dialogue, maps, branding, data files, or copied UI artwork in shipping builds. Mechanics can inform independently implemented systems; third-party code reuse needs license review.
- **Deviation protocol:** Any intentional difference from the reference ruleset must be described with rationale, player impact, and test expectations.
- **Traceability:** Each major gameplay feature should link to a specification, tests, implementation evidence, and roadmap milestone.
- **Full vision vs milestone:** This GDD describes the long-term product. A vertical slice or alpha is not the final scope.

## 3. Core simulation contract (target architecture, not asserted current state)

1. **Input adapters** translate mouse/keyboard, touch, and other controls into platform-neutral player commands.
2. **Command validation** checks ownership, target, prerequisites, resources, and game phase.
3. **Authoritative simulation** applies valid commands on a fixed logical clock, updates entities and systems, and emits events.
4. **Game state** contains units, buildings, owners, resources, technologies, fog, map, objectives, and timers.
5. **Presentation** reads state/events and draws sprites, animations, sound, HUD, and effects without determining gameplay outcomes.
6. **Persistence and networking** serialize commands/state in versioned formats; multiplayer synchronization model is a design decision requiring research and testing.

**Example:** Tap or right-click a taquería with a selected worker → issue `gather(unit_ids, target_id)` → validate → route and gather → carry to drop-off → update Comida → animate and update HUD. The same command must behave equivalently on native and web clients.

**Non-negotiable engineering safeguards:** no gameplay tied to rendering FPS; deterministic random source where needed; explicit update ordering; cross-platform determinism tests before promising lockstep; headless or otherwise automated simulation tests; profiling under representative unit counts. Godot scenes should not become the sole authority for rules.

## 4. Gameplay feature inventory and fidelity checklist

This is a **target inventory**, not a declaration of completion.

| Domain | Expected complete-game capabilities |
|---|---|
| Economy | Gathering rates, carry limits, drop-offs, depletion, farms/renewables, worker automation, trading, market-style exchanges, population limits |
| Construction | Placement constraints, multi-builder progress, repair, building states, queues, prerequisites, destruction, garrisoning |
| Units | Classes, upgrades, selection groups, patrol/guard/follow/stance, formations, rally points, queueing, transport/garrison behavior as applicable |
| Combat | Melee/ranged, projectile travel, attack timing, armor and bonus damage, elevation, counters, siege, healing/conversion equivalents, target acquisition |
| Technology | Age progression, tech tree, prerequisite graph, faction bonuses, unique tech and unit lines |
| World | Terrain and elevation, collision, line of sight, exploration/fog, resources, obstacles, random-map generation |
| AI | Economy, scouting, strategy, production, offense/defense, difficulty settings, team behavior |
| Modes | Skirmish, conquest, wonder, signature territorial scenario, campaigns, custom scenarios, editor |
| Multiplayer | Player slots, teams/diplomacy, deterministic or alternative sync, reconnect policy, desync detection, replay and version compatibility |
| UX | Minimap, selection, contextual commands, hotkeys, alerts, queues, stats, pause/speed as mode allows, tutorial, accessibility |

### 4.1 Signature victory ideas

- **Conquest (primary):** defeat rival players according to explicit elimination criteria.
- **Wonder:** erect and protect a monumental project through a countdown.
- **Battle for La Roma (signature candidate):** contest and hold central district landmarks under clearly defined scoring/control rules.
- **Scenario-specific:** authored narrative and mission goals.

Current alpha labels such as **HQ**, **POST**, and **LA ROMA 3×3** are prototype terminology; they do not, by themselves, finalize full-game victory logic.

## 5. Current visual target and art production principles

**Approved direction:** Detailed, warm, crisp, retro-isometric pixel-art / pre-rendered-sprite sensibility, closer to the richness of classic late-1990s RTS than minimalist 8-bit art. Mexico City streets, Roma architecture, jacarandas, sidewalk vendors, rooftops, water tanks, signage, and urban plazas. Blue Poblanos vs red Regios are the currently illustrated opposing teams; color must not be the only distinguishing cue.

**Reference concept art:** A richly detailed La Roma battlefield and an annotated desktop RTS HUD/mobile touch concept have been approved creatively. **They are visual references, not game-ready sprites**. Do not flatten a concept illustration into the playable map.

**Production rules:**
- Match the project's actual tile projection, anchors, world scale, and depth sorting; Codex must inspect the repo before finalizing pixel dimensions.
- Terrain must tile or transition correctly; buildings/props need transparent sprites and logical footprint metadata.
- Units need readable silhouettes, consistent facing conventions, and animation frame anchors; plan for directional animation even if the first art slice uses fewer directions.
- UI should be built from reusable Godot controls, not one static image.
- Preserve selection, collision, and simulation geometry while replacing primitive rendering.
- Record sources and commercial licensing for all external art/audio; original assets must have source and export metadata.

**First visual slice:** grass/pavement/asphalt/plaza tiles; jacaranda and street props; Poblano and Regio ranged units; faction HQs, command post, central La Roma landmark; selection/health indicators; desktop command HUD. Touch HUD follows shared command semantics.

## 6. Platform, controls, and distribution

| Target | UX | Distribution |
|---|---|---|
| Desktop native | Traditional RTS mouse/keyboard HUD and shortcuts | itch.io downloadable builds initially |
| Desktop browser | Same desktop command model in Godot web export | itch.io HTML5 and potentially own website |
| Android/iOS native | Landscape-first touch-oriented RTS interface | Android distribution initially as appropriate; store routes later |
| Mobile browser | Touch UI, same rules; performance/compatibility subject to validation | itch.io HTML5 / independent hosting where supported |

**Web engineering constraints:** Godot 4 web export targets WebAssembly/WebGL 2 through the Compatibility renderer; single-threaded export is the baseline for broad hosting/browser compatibility. Test Safari and mobile browsers explicitly; no blanket performance promises. Validate input, audio activation, storage eviction, save export/import, loading time, memory, and long sessions.

**Save/release versioning:** track application, simulation, content, and multiplayer protocol versions separately. Browser-local storage alone is not a sufficient long-term progress guarantee. Build artifacts should be traceable to a source commit and published through tested release channels.

## 7. Experience and onboarding

- **Desktop:** drag-select, right-click contextual orders, hotkeys/control groups, minimap navigation, visible queues, unit portrait/stats, build/research grids, readable alerts.
- **Touch:** tap-select, contextual tap, clear command mode, drag/pan and pinch/zoom with gesture conflict resolution, large enough targets, collapsible panels, reachable controls, accessible selection feedback.
- **Onboarding:** tutorial introduces movement → gathering → building → recruitment → attack → age advancement → map control, with humor supporting rather than obstructing clarity.
- **Accessibility:** scalable text/UI, remappable controls where feasible, color-blind-safe cues, reduced motion/effects, audio sliders/subtitles, readable selection outlines.

## 8. Quality bar and acceptance tests

A feature is not 'AoE2-faithful' because it looks similar. Define measurable reference scenarios: worker gathering over fixed time, construction with multiple builders, unit attack intervals/armor, pathfinding around obstacles, production queues, and age advancement prerequisites. Record target version, setup, expected observations, and tolerances. Automated regression tests should verify deterministic outcomes on supported platforms where required.

**Art acceptance:** assets align with tile anchors, sort correctly behind/in front of actors, retain legibility at gameplay zoom, avoid halos/seams, and fit memory/performance budgets.

**Release acceptance:** representative skirmishes function on desktop and web; save/load and crash recovery are verified; mobile and browser claims reflect actual device testing; licensing and attribution register is complete.

## 9. Production governance

- Existing Codex roadmap remains the delivery plan; reconcile against this GDD rather than replacing it without approval.
- Keep **design decisions**, **implemented state**, and **proposed changes** visibly distinct.
- Prefer vertical slices that exercise the real command/simulation/rendering pipeline.
- Before adopting algorithms/code from openage, freeaoe, or OpenRA, document applicability, version, maintenance, license, and integration cost. Reference study does not authorize copying.
- Document technical risks early: pathfinding scalability, deterministic multiplayer, web single-thread performance, save compatibility, UI density, animation production costs, asset licensing.

## 10. Open decisions requiring owner approval

1. DE reference build/patch and interpretation of fidelity exceptions (the edition is settled in [ADR 002](../architecture-decisions/002-aoe2-definitive-edition-reference.md)).
2. Final unit/building/tech naming and faction roster at release.
3. Detailed Terrenos gathering fiction and economy balance.
4. Exact win/defeat conditions for signature La Roma control mode.
5. Map generation system, scenario scripting format, and editor scope.
6. Multiplayer architecture, matchmaking/cross-play policy, and replay format.
7. Exact sprite scale, tile dimensions, camera conventions, and art export formats (must come from repo inspection).
8. Minimum mobile/browser device performance targets and battle-size acceptance budgets.
9. Monetization/pricing, content packs, localization priorities, and release staging.
10. Music/voice direction and final commercial licensing approvals.

---

## Appendix A — Consolidated legacy design notes (v0.2)

The following sections preserve the earlier design bible as **historical design material**. Where any note conflicts with the confirmed product decisions above (standalone commercial release, Godot, web/mobile, itch.io, AoE2 fidelity), **sections 1–10 take precedence**. Older tentative mechanics and numerical values remain proposals until adopted by the current roadmap.


### World & lore — legacy notes

# 01 — World & Lore Bible

## Canonical premise — CONFIRMED
In an alternate contemporary CDMX, foráneo communities organize as civilizations. University groups grow into guilds, companies, militias, and real-estate powers. Their rivalries become **literal warfare**: they train troops, besiege offices, tear down buildings, occupy neighborhoods and erect monuments. Nobody in-world questions the basic premise.

## Tone rules
- Play the military situation straight; the absurdity comes from everyday Mexican institutions acting like medieval powers.
- Satirize aspirations, institutions, bureaucracy, class performance, rent and urban change; avoid reducing an entire state to a slur.
- Keep factions multidimensional: strengths, flaws, internal variety, and affectionate local specificity.
- Dialogue in natural Mexican Spanish; optional localization must preserve gameplay meaning.
- Cultural references should be comprehensible through animation and role even if the player misses the meme.

## Social geography
- **CU/Copilco:** symbolic arrival, student economies and humble infrastructure.
- **Narvarte:** transitional residential and commercial expansion.
- **Condesa:** valuable parks and dense high-tier commercial territory.
- **Roma Norte/Sur:** symbolic prize and site of final territorial contests.
These are **map themes**, not mandatory campaign chronology.

## What warfare looks like — PROPOSED
A student collective raises barricades around a facultad; a regiment of godínez advances with office-themed gear; brokers and developers field heavy siege crews; cafés and coworking spaces are defensible assets. Units have clear melee/ranged/siege roles; their props and animations supply satire. Violence is stylized, non-graphic, and deliberately game-like.

## Faction narrative template
Origin and migration story; ambitions in CDMX; architectural motifs; colloquialisms; internal contradictions; signature institution; why it wages war; strengths and vulnerabilities; comedic boundaries.

## Campaign concept — PROPOSED
A sequence of escalating urban conflicts: arrival at CU, survival in Copilco, factional expansion through Narvarte, confrontation in Condesa, final Battle for La Roma. Campaign is not required for skirmish and may bend standard rules.

## Editorial guardrails
Use fictional characters and generic institutions where possible; avoid presenting satire as factual claims about real people or businesses. Research references with local collaborators. Avoid directly reproducing third-party logos, songs, and game assets.

## Open questions
What is the in-world authority behind war? What happens to defeated units (cartoon collapse, retreat, respawn)? Are landmarks parodies or fictionalized equivalents? How explicit is the class satire? Decide before voice/script production.



### Economy and progression — legacy notes

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



### Combat and units — legacy notes

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



### Civilizations — legacy notes

# 04 — Civilization Bible

## Representation — PROPOSED
Regional cultural identities, rather than literal government entities. Factions may be associated with states/cities; candidate launch roster is not locked.

## Faction design contract
Every faction needs: fantasy; origin; economic bonus; strategic military identity; unique unit and counter; unique techs; architectural motifs; voice palette; strengths/weaknesses; matchups; monument; accessibility-readable color/silhouette; test cases.

## Regios — PROPOSED
Monterrey/Nuevo León inspiration. Economic booming and costly advanced units. Emprendedor Regio (unique candidate); Facturación and Networking en San Pedro (tech candidates); Torre Corporativa (wonder). Weakness candidate: expensive military and vulnerable timing windows. Never assume actual cultural groups behave this way.

## Poblanos — PROPOSED
Puebla inspiration. Fortification and defensive resilience. Mirrey Poblano (candidate unit, **role TBD**); Herencia Familiar (tech candidate); Complejo Residencial (wonder). Weakness candidate: slower map control.

## Oaxaqueños — PROPOSED
Oaxaca inspiration. Resource efficiency, flexible support and resilience. Maestro Mezcalero (candidate support unit); Producción Artesanal (tech); Centro Cultural (wonder). Weakness candidate: less explosive late-game army.

## Veracruzanos — PROPOSED
Veracruz inspiration. Mobility, trade and aggressive map control. Jarocho (unique candidate, role TBD); Comercio del Puerto (tech); Gran Malecón (wonder). Weakness candidate: weaker static defenses.

## Additional faction pool — EXPLORATORY
Tapatíos, Yucatecos, Chihuahuenses, Sinaloenses, Queretanos, Michoacanos, Chilangos (as a potential special faction). No final roster commitment.

## Balance heuristic
A bonus should change decisions, not just add flavor. Give each faction counterplay, viable early/mid/late plans and at least one clearly exploitable weakness. Test mirror and cross-faction matches. **No numeric bonus in earlier brainstorming is approved.**

## Content specification template
```
id: faction_slug
status: proposed
identity: ...
strategy: ...
economic_bonuses: []
unit_roster_changes: []
unique_units: []
unique_technologies: []
architecture_set: ...
voice_style: ...
monument: ...
strengths: []
weaknesses: []
counterplay: []
playtest_questions: []
```



### Maps and modes — legacy notes

# 05 — Maps, Geography & Game Modes

## Map philosophy
Stylized CDMX, not a geographic simulation. Recognizable streets, parks, transit, university grounds and architecture must serve fair RTS movement, expansion and readable battlefields.

## Map candidates
| Map | Gameplay identity | Visual anchors |
|---|---|---|
| Ciudad Universitaria | open, scouting-focused | campus, broad plazas |
| Copilco | dense, chokepoint-heavy | student housing, eateries |
| Narvarte | balanced grid | residential streets, commerce |
| Roma–Condesa | contested center | parks, cafés, mixed-use blocks |

## Map design specification
Size; players/teams; spawn symmetry; terrain passability; resource distribution; expansion sites; chokepoints; line of sight; landmark objectives; decorative layers; pathing test; performance budget; AI navigation test.

## Modes
**Conquest (core):** eliminate rival ability to continue; formal defeat condition TBD.
**Wonder (planned):** erect and defend monumental development for timer; interruption rules TBD.
**Battle for La Roma (signature proposal):** capture/hold a valuable center with counterplay, comeback paths and clear progress feedback; not a replacement for conquest.
**Campaign/scenarios (future):** scripted narrative missions.
**Multiplayer/team play (long-term):** classic RTS configurations; synchronization architecture TBD.

## Dynamic city events — DEFERRED
Lluvias, marchas, rent hikes, festivals and roadworks. Only add if they produce fair, readable, strategically meaningful decisions. Avoid random punishment with no counterplay.

## Map playtest questions
Can every start access comparable opening resources? Are attack routes legible? Do choke points favor defense excessively? Can units navigate around city props? Can players contest center without unavoidable snowballing?



### Art and audio — legacy notes

# 06 — Art & Audio Bible

## Visual north star
Classic readable isometric RTS meets warm, exaggerated contemporary CDMX. The aesthetic is an **original** world, not copied AoE2 assets.

## Art principles
Readable silhouettes at gameplay zoom; architecture evolves visibly with ages; faction-specific motifs do not obscure building function; streets and landmarks signal place; comedy through expressive animation rather than UI clutter.

## Visual progression
Foránea: rented rooms, tienditas, makeshift facilities. Universitaria: campus and organized student institutions. Godín: offices, startups, fortified commercial buildings. Gentrificación: luxury developments, galleries, monumental mixed-use towers.

## Sprite/asset spec (to finalize)
Camera angle; pixels-per-world-unit; animation directions; frame rate; idle/walk/attack/gather/build/death states; unit anchor; collision footprint; shadows; color masks; selection ring; LOD/readability; licensing metadata. Don't set arbitrary dimensions before engine prototype tests.

## UI identity
Clean strategic overlays over lively city; accessible faction differentiation beyond color; visually distinct economy/military/research icons; avoid real brand logos by default.

## Music
Original score inspired by varied Mexican regional musical traditions, reinterpreted for economic calm, buildup, combat and victory. No unlicensed recordings or direct melody copies.

## Voice
Mexican Spanish primary. Regional expression as flavor, never at the cost of comprehensible commands. Define short lines for select, move, gather, construct, attack, complete, warning, defeat; avoid repetitive jokes and caricature accents.

## Sound design
Distinct cues for command accepted, attack, damage, research, age-up, idle workers, queue completion and danger. Audio must complement visual cues, not replace them.

## Content review
Check satire, cultural specificity, legal rights, readability and tonal consistency before integrating assets.



### UX and accessibility — legacy notes

# 07 — UX, Controls & Accessibility

## Interaction model
Mouse/keyboard desktop RTS. Left-click selection; drag selection box; right-click contextual action; camera pan/zoom; hotkeys; control groups; minimap navigation; queueing; build placement; rally points.

## Core HUD
Four resources; population and cap; age; selected entity panel; command grid; production/research queues; minimap; notifications; objectives; pause/settings.

## Feedback principles
Every command communicates accepted/rejected state. Hover reveals contextual action. Placement preview shows footprint, blocked tiles and resource affordability. Selection states and team ownership are clear under combat clutter.

## Onboarding
First tutorial sequence: select foráneo → gather comida → deliver → construct cuarto → produce worker → research/age up → scout → defend. Teach mechanics before satirical vocabulary; tooltips can pair playful label with plain function.

## Accessibility
Remappable keys; scalable UI/text; non-color-only ownership cues; readable contrast; subtitle and caption options; audio sliders; reduced camera shake/flashes; pause in solo play; input latency feedback.

## Usability tests
Can new players distinguish resource types? Can they identify a selected unit and target? Can they tell why a build command failed? Can they issue attack-move without accidental gather? Can they recover from an idle-worker bottleneck?



### Balance — legacy notes

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



### Production and risks — legacy notes

# 09 — Full Vision, Roadmap & Risks

## Full scope (not an MVP cut)
Four ages; multiple civilizations; worker economy; construction; research; combat and siege; AI; fog; maps; victory conditions; multiplayer; campaigns; custom scenarios/editor; audio/visual identity; mod-friendly data.

## Capability progression (nonbinding)
1. **Technical foundation:** Godot prototype and engine-specific architecture, simulation/visual separation.
2. **Core interaction:** selection, movement, camera, map, workers, gathering.
3. **Economy:** four resources, construction, queues, population, tech, age-ups.
4. **War:** melee/ranged/siege, destruction, pathfinding, fog, defenses.
5. **Skirmish:** full match, one coherent faction, AI and victory.
6. **Identity:** expanded civilizations, unique units, maps, art/audio.
7. **Depth:** balance, improved AI, wonder and territory modes, campaigns.
8. **Long-term:** multiplayer, editor, modding, polish and accessibility.

**Codex owns MVP slicing and development planning separately.** This list is conceptual dependencies, not a mandated sprint schedule.

## Godot-specific considerations (nonbinding)
- Selected engine for MVP: Godot. Use version-pinned docs and project conventions.
- `TileMapLayer` is useful for layered 2D maps; Godot docs warn built-in TileMap navigation has limitations and recommend optimized navigation meshes for more demanding use cases.
- Large unit counts, crowd movement, reproducibility and multiplayer synchronization require explicit benchmarks/architecture; don't assume engine navigation or physics is deterministic across clients.
- Keep simulation rules and content data separate from visual nodes where practical.

## Risk register
| Risk | Consequence | Mitigation |
|---|---|---|
| Scope explosion | unfinished game | vertical playable milestones |
| Weak RTS fundamentals | joke wears off | combat/economy tests |
| Pathing at scale | frustrating battles | crowd benchmarks early |
| Inconsistent generated art | visual incoherence | art bible and review |
| Flat stereotypes | shallow satire | layered faction writing |
| Balance complexity | dominant builds | simulation + playtesting |
| Multiplayer determinism | desyncs | explicit technical spike |
| Copyright/IP confusion | distribution risk | original assets, legal review |
| Design drift | incoherent implementation | decision log + design status |



### Open decisions — legacy notes

# 10 — Decisions & Open Questions

## Confirmed decisions
| ID | Decision | Basis |
|---|---|---|
| D-001 | Working title Battle for La Roma | user direction |
| D-002 | AoE2-inspired full RTS ambition | user direction |
| D-003 | Alternate modern CDMX + medieval-faction logic | user chose combination A + C |
| D-004 | Combat is literal, buildings can be destroyed | explicit user decision |
| D-005 | Godot selected for MVP | user-reported technical spike |
| D-006 | Full design package, not pre-sliced MVP | explicit user decision |
| D-007 | User handles Codex/engineering separately | explicit user decision |

## Proposed, not approved
| ID | Proposal |
|---|---|
| P-001 | Four ages: Foránea, Universitaria, Godín, Gentrificación |
| P-002 | Four resources: Comida, Materiales, Varos, Terrenos |
| P-003 | Initial roster: Regios, Poblanos, Oaxaqueños, Veracruzanos |
| P-004 | Conquest primary, wonder and territory additional |
| P-005 | Regional cultural identities rather than state governments |
| P-006 | 25–50 minute match-length hypothesis |

## Highest-leverage open questions
1. How exactly do factions wage war in-world, and what weapons/vehicles fit the tone?
2. What are the primary unit counter triangles and how are they culturally expressed?
3. How are Terrenos physically gathered and delivered?
4. What is the full tech tree by age, with prerequisites?
5. What is the precise conquest elimination rule?
6. What is the exact Battle for La Roma capture/hold victory design?
7. Which four factions merit launch priority and local cultural review?
8. What art production format is most scalable in Godot?
9. How does the simulation support eventual multiplayer without a rewrite?
10. What content is timeless satire versus a meme likely to age quickly?

## Decision procedure
For each change record: context; alternatives; decision; status; gameplay implications; affected docs; validation; date. A developer implementation choice does not silently rewrite design canon.



## Appendix B — Technical and distribution references

- Godot web export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- itch.io HTML5 distribution: https://itch.io/docs/creators/html5
- openage reference engine: https://github.com/SFTtech/openage
- freeaoe reference engine: https://github.com/sandsmark/freeaoe
- OpenRA reference engine: https://github.com/OpenRA/OpenRA

**Maintenance instruction for Codex:** When updating this document, retain the north-star vision, label changes as proposed or approved, avoid asserting repo implementation status without code/tests, and keep technical specifications in separate dedicated documents linked from this GDD.
