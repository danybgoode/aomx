# RTS core prototype

This is the approved E1 worker/resource/structure proof on an original 20×20 isometric map. It uses Godot **4.7.2.stable.official.ed1daf0bf**. It is not a finishable match and emits no launch-funnel event; all replay command metadata are test tagged.

From the repository root, set `GODOT_BIN` to the downloaded Godot executable (on this Mac it is `/Users/cosmo/Downloads/Godot.app/Contents/MacOS/Godot`), then run:

```sh
"$GODOT_BIN" --headless --path game --import
"$GODOT_BIN" --headless --path game --script res://tests/simulation_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/benchmark.gd
"$GODOT_BIN" --path game
```

In the window, left-click the blue worker, right-click a reachable tile to move, and right-click the gold resource to gather. The worker carries four, returns to the tan drop-off, and increases stockpile once per delivery. Press **B** to preview a 2×2 structure; click clear ground when stockpile is at least six. The worker constructs it, after which its footprint blocks movement. Press **R** to reset. The four dark tiles around a small pocket at the lower half of the map make an unreachable-order fixture; a right-click inside the pocket produces visible feedback.

The simulation owns integer tile positions, costs, source and carry accounting, pathing and construction. The scene draws it and accepts input. A fixed 0.1-second tick drives rules; rendered frame delta only schedules ticks. The test script checks rejection, resource conservation, interruption/resume, placement, footprint blocking and replay equality. No proprietary assets or external services are required.

Performance evidence on Apple M2 Max, Godot 4.7.2, one worker and a 20×20 map: 1,000 route orders averaged **1.497 ms** each; 10,000 fixed ticks averaged **0.00110 ms** each. The debug window showed a process-frame monitor between roughly 18 and 35 ms during automated capture, which is not a representative game benchmark. More workers, larger maps and a release export remain unmeasured. The builder recommends continuing with Godot for the next small slice while measuring the first multi-unit skirmish before treating performance as settled.
