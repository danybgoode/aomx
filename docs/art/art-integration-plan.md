# Art integration plan v0.1

## Order

1. Lock the geometry and manifest against the present code. Export one grass tile, one blue command post and one blue worker and inspect them at 100%, 110% and 125% in the real scene.
2. Load a cached asset catalog from the manifest. Replace only terrain and these two entities first; keep existing selection, HP and order feedback visible. Confirm that tile picking and the two win routes are unchanged.
3. Add authored visual-map assignments for all 400 existing tiles. Draw walkable variants, hard-blocked cells, gold source markers and La Roma treatment, never using art to decide walkability or objective ownership.
4. Add blue/red command post and barracks skins, then worker/melee/ranged skins. Derive facing and brief animation cues in the view layer from existing position/job/cooldown. Sort tall visual sprites by ground depth, while hit tests remain simulation tile tests.
5. Run the deterministic Godot and Node contract gates. Play both factions and both win routes in a rendered local build. Inspect crowded center, placement, construction, damage, terminal, offline restart and sync status.
6. Record actual frame-time and memory observations on the same debug setup as the pre-art baseline. If a restricted preview is produced, follow the alpha runbook; merge does not create a public or deployed game build.

## Review boundaries

- Pilot: a full-size comparison of source references and exported sprites at gameplay zoom; approve or revise palette, silhouette, pivot and pixel scale before expansion.
- Sprint 2: verify all present entity kinds appear with no primitive fallback except explicitly procedural overlays. The JSON manifest paths and sizes match real PNG files.
- Sprint 3: two blind reviewers, one familiar and one unfamiliar with the cultural references, attempt both-win-route and friend/enemy identification checks. Record exact findings. The current private-alpha owner QA and participant invitation gates remain separate.

## Risks and follow-ons

Fractional board zoom can soften pixel edges. Tall assets can occlude units even with correct depth order. Static poses provide only view cues; true four-direction animation needs separately authored frame sets. The current map has no camera pan, no tested WebGL export and no mobile performance evidence. Full desktop HUD, mobile controls, sound effects/music and new gameplay objects are follow-on bets.

## Verification commands

From the repository root with GODOT_BIN pointing to Godot 4.7.2:

- GODOT_BIN --headless --path game --import
- GODOT_BIN --headless --path game --script res://tests/skirmish_test.gd
- GODOT_BIN --headless --path game --script res://tests/faction_test.gd
- GODOT_BIN --headless --path game --script res://tests/district_test.gd
- GODOT_BIN --headless --path game --script res://tests/skirmish_client_test.gd
- GODOT_BIN --headless --path game --script res://tests/outbox_test.gd
- GODOT_BIN=<path> npm run skirmish:contract

Use game/README.md for the full QA and controlled smoke scenarios. A green headless run does not replace rendered inspection.
