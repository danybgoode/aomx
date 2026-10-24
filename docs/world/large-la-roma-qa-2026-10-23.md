# La Roma Large pilot — builder QA and owner read

**State, 2026-10-23:** The 96×96 solo pilot and related #11 movement repair are in verification. Code integration and local game checks do not close the owner downloaded-build walkthrough, map-feel decision or uncoached read. There is no public game release or eligible cohort.

## What the build contains

- The three original 28×28 maps remain selectable alongside one 96×96 La Roma Large pilot. Both large-map starts have a worker and a faster, farther-sighted, noncombat bicitaxi. The camera opens on home at a readable unit scale; the minimap can navigate to the far quadrant.
- Each side has four nearby starter sources and four independent distant expansion sources. The authored layout mirrors route length for both starts. AI scouts with ordinary vision and only assigns workers to expansion sites after they are explored.
- The selected-unit panel exposes a blocked route. Crowded move/gather/delivery jobs retry without overlapping units; destroyed drop-offs and exhausted sources leave recoverable worker state. The interface uses the former readable 200% presentation as fresh-install 100% and reduces routine full-health battlefield marks.
- The rules and cross-platform fixture are pinned to `godot-4.7.2-skirmish-7` and `la-roma-world-5`. Older incompatible save/replay files remain on disk with an explicit version error. The existing three maps retained their 12 pinned match hashes; four large-map faction hashes were added.

## Local checks

| Check | Result | Limit |
| --- | --- | --- |
| Godot large-map layout/client, warfare, persistence, replay, content, world-expansion and 16 hash cases | Passed on Godot 4.7.2/macOS. | Linux CI still supplies the independent platform check. |
| Independent high-risk review | Initial AI expansion, stale blocked-job and mixed-order measurement gaps were fixed and re-reviewed. Reviewer verified routes of 66 tiles to district and 143 tiles to enemy post from each home, and restored side-1 network state with altered expansion stock. | Private matches remain pinned to the original La Roma map; this pilot is solo. |
| Large-map victory rules | Deterministic conquest and uncontested district hold pass. Reviewer observed a legal home-to-district move and hold win at tick 944 and a standard-AI conquest win at tick 2748 in a separate idle-human match. | Four player-driven faction/outcome combinations and match pacing need downloaded-app observation. |
| 6000-tick, AI-enabled, mixed 96×96 owner-Mac probe | Up to 78 live entities; 689 timed route-bearing orders including scout/gather/build/combat; two actual combat casualties; route p95 4.802 ms ≤ 12, tick p95 1.378 ms ≤ 8, static memory 31.22 MiB ≤ 768. | A synthetic ten-logical-minute scenario, not a human playthrough. Rare tick outliers reached 35.97 ms. |
| 128×128 candidate | Synthetic route/tick/memory stress fit the declared budgets in the earlier map-size comparison. | 128×128 has more outliers and is not an authored/shipped pilot. |
| Release render, 1280×800 and 1024×700 | An isolated macOS release export with 80 actors rendered 600 frames at each size. At 1280×800 p95 was 25.589 and 26.141 ms on two runs; at 1024×700 it was 25.720 ms. All are below 33.3 ms. Peak process RSS was 237,551,616 bytes and 251,166,720 bytes respectively, below 768 MiB. [1280 opening](screenshots/large-la-roma/opening-1280.png) · [1024 opening](screenshots/large-la-roma/opening-1024.png). | This is a local exported app, not the later independently downloaded Restricted archive. The 600-frame sample does not cover all ten minutes of play. |

The AI-enabled probe reports logical simulation time, not wall-clock match time. Its route sample includes the non-fighter orders and build-site attempts. Its frame companion samples 600 rendered frames with 80 actors, separately from the 6000-tick simulation. Earlier debug and release samples sat just above 33.3 ms; the final optimized release export passed at both target sizes. Godot's release `Performance.MEMORY_STATIC` monitor returned zero, so process RSS from `/usr/bin/time -l` supplies the release memory evidence.

## Downloaded Restricted preview walkthrough

Use the exact signed build ID and fresh authenticated download, then record the window size, interface setting, route, observed result and any failure for each step. The [epic sprints](../../Roadmap/01-core-play/build-large-la-roma-battlefield/README.md) hold the complete numbered scripts.

1. Open La Roma Large at 1280×800 and 1024×700. Confirm that text fits, the base and bicitaxi read at normal scale, ordinary healthy units are not covered in bars, and selection/damage still stand out.
2. Scout two different expansions, gather from one, and build a forward support structure. Confirm fog, panning, save/resume and replay.
3. Move a mixed group through a crowded crossing, change an obstacle, then retry. Confirm progress or a visible blocked state and no permanent cargo trap.
4. Complete conquest and district hold with both factions, including one saved match. Check test-tagged event sync only after a compatible Restricted ingest/host is available.
5. Give one unfamiliar player the start screen without CDMX explanation. Ask what the bicitaxi does, where to expand and how both victory routes work. Record exact answers and confusion.

**Decision required:** owner accepts or revises map size, resource spacing, bicitaxi readability and pacing after the downloaded build. No public invitation follows this preview.
