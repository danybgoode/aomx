# Small-map starter resource spacing

La Roma, Narvarte and Copilco each have four visibly separate starter sites per side. Their authored Comida, Materiales, Varos and Terrenos tiles are at least four Manhattan tiles apart. The small maps remain fixed, readable teaching maps; Medium and Large retain seeded neutral sites for exploration and replay variety.

The La Roma opening was checked for both accessibility and fairness. From each starting worker, paths to Comida, Materiales, Varos and Terrenos are respectively 1, 7, 3 and 7 steps on **both** sides. The source tiles and nearby building approaches stay passable. `small_resource_spacing_test.gd` checks all three maps for spacing and access; `geography_test.gd` pins the balanced La Roma routes. The AI now checks a prospective building footprint and its worker routes before issuing a build order, so a speculative site search does not interrupt workers or count as a rejected order. All twelve pinned opponent scenarios finish without AI order rejections.

This is authored world content `la-roma-world-6` and game version `godot-4.7.2-skirmish-12`. The state structure remains schema 8. Existing version 11 saves and replays remain on disk but cannot load into this rule/content version. Matching game exports and private-match host images must be built before the new layout reaches testers.
