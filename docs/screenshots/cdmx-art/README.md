# CDMX art builder captures — 2026-10-22

These are 1280×800 captures from Godot 4.7.2 on the Apple M2 Max using `game/tests/cdmx_render_capture.gd` and the current La Roma scene. The capture fixture starts Regios, disables the AI, then reveals the center with one fighter or adds a fixed 12-unit contested crowd. It does not change match rules.

| Capture | Zoom and view | Observed debug sample |
| --- | --- | --- |
| [center-100.png](center-100.png) | Cibeles at 100% | 120 displayed frames; p95 interval 24.01 ms, peak static 41.8 MiB |
| [center-125.png](center-125.png) | Cibeles at 125% | p95 23.74 ms, peak static 41.8 MiB |
| [fit-overview.png](fit-overview.png) | Initial fog and base at 110% fit | p95 24.10 ms, peak static 41.8 MiB |
| [dense-center-100.png](dense-center-100.png) | Contested center at 100% | p95 24.25 ms, peak static 42.0 MiB |
| [place-and-buildings.png](place-and-buildings.png) | Five building kinds, construction and low health | p95 24.07 ms, peak static 41.8 MiB |

The role fixture was captured separately at 125% for [Regios](roles-regios.png), [Poblanos](roles-poblanos.png), [Oaxaqueños](roles-oaxaquenos.png) and [Veracruzanos](roles-veracruzanos.png). Each shows the five existing unit kinds on both sides with the same Cibeles backdrop. These are builder inspection frames; the owner and uncoached readers still decide whether the symbols and silhouettes are understood.

Frame interval includes display waiting. Earlier published art probes used a 20×20 fixture and cannot serve as this pack's baseline. Review the dense crowd for badge and role comprehension in owner QA; the screenshot cannot establish it alone.

For a like-for-like local debug sample, the same capture script was copied into a detached `origin/master` archive before this art branch. [Before center](before-center-100.png) measured 26.84 ms p95 / 40.9 MiB peak static; after center measured 24.01 ms / 41.8 MiB. [Before dense center](before-dense-center-100.png) measured 25.85 ms / 41.0 MiB; after dense center measured 24.25 ms / 42.0 MiB. The source IDs and fixture match, but single short GUI runs vary with display scheduling. This supports only that no obvious debug regression appeared here; minimum-device and release-build performance remain unmeasured.
