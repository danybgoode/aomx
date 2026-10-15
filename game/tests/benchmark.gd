extends SceneTree

const Sim = preload("res://simulation.gd")

func _initialize() -> void:
	var sim = Sim.new()
	var began := Time.get_ticks_usec()
	for i in range(1000):
		sim.issue("move", Vector2i(18, 18) if i % 2 == 0 else Vector2i(1, 1))
	var path_ms := float(Time.get_ticks_usec() - began) / 1000.0
	began = Time.get_ticks_usec()
	for i in range(10000):
		sim.tick()
	var tick_ms := float(Time.get_ticks_usec() - began) / 1000.0
	print("scale=one worker, 20x20 map; 1000 path orders total_ms=%.3f mean_ms=%.4f; 10000 ticks total_ms=%.3f mean_ms=%.5f" % [path_ms, path_ms / 1000.0, tick_ms, tick_ms / 10000.0])
	quit(0)
