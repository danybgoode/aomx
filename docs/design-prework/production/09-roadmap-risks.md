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
