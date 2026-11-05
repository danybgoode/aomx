# Turning the owned concept boards into game art

The twelve JPEGs in `references/newArtWork/` are flattened design boards. They contain multiple objects, text, scenery, and proposed abilities in one image. Cropping a panel does not yield a clean sprite or an approved gameplay rule. The owner confirmed rights to these boards; they remain ignored local references.

## Current game coverage

The playable build already has a project-original Cibeles fountain sprite (`prop_cdmx_cibeles`), a jacaranda, flowers, a barricade, a gold cart, and a plaza medallion. Cibeles was generated with `roma-norte.jpg` as visual direction. None of the pictured landmarks in `landmarks.jpg` or the individual objects in `props.jpg` has been directly extracted into runtime art. The game treats Cibeles as the existing central objective; the other landmarks and their illustrated bonuses are concepts only.

## Reusable extraction path

1. Choose one object and its intended **visual** role. Check that it belongs on an authored map before placing it. No board caption changes faction balance, passability, victory conditions, or the map catalog.
2. Use the owned board as a visual reference to create an isolated, transparent source. Retain the prompt, source-board name, asset hash, and commercial-rights record. Review the alpha edge at full size.
3. Export with the existing deterministic art pipeline to a canvas appropriate for its role: small street props around 48–64 px wide; a 2×2 landmark around 96×80 px if its details remain legible. Record canvas, pivot, source/export SHA-256, view-only role, and decoded-memory cost in the game manifest.
4. Run the manifest validator, inspect a 100% Godot capture on the actual map, then check selection, pathing, sight, save/replay, and cross-platform rendering. Add a landmark only where the map geography supports it.

Two transparent **candidates** demonstrate the reference-to-source step: [street bench](candidates/bench-from-props.png) from `props.jpg` and [Kiosco Morisco](candidates/kiosco-from-landmarks.png) from `landmarks.jpg`. They are AI-assisted original illustrations, not crops of the flattened JPEGs. They are not exported or used in the game. The bench still needs small-scale and alpha-edge review; the kiosco needs a suitable authored location and map-role decision before integration. `menus.jpg` and `full-map.jpg` remain interface/world vision because they depict campaign and map screens beyond the current release. `regional-factions.jpg` informs the existing worker art direction, but its depicted abilities are not game rules.
