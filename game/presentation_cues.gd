extends RefCounted

# View-only cue policy. Tick numbers are for throttling, never simulation authority.
const RULES := {
	"order-confirm": {"priority": 2, "cooldown": 0},
	"order-reject": {"priority": 3, "cooldown": 0},
	"economy": {"priority": 1, "cooldown": 35},
	"construction": {"priority": 2, "cooldown": 12},
	"threat": {"priority": 4, "cooldown": 18},
	"destruction": {"priority": 4, "cooldown": 8},
	"objective": {"priority": 5, "cooldown": 8},
	"result-win": {"priority": 6, "cooldown": 0},
	"result-loss": {"priority": 6, "cooldown": 0},
	"result-draw": {"priority": 6, "cooldown": 0},
}

var seen_keys: Dictionary = {}
var last_kind_tick: Dictionary = {}

func reset() -> void:
	seen_keys.clear()
	last_kind_tick.clear()

func priority(kind: String) -> int:
	if not RULES.has(kind):
		return -1
	return int(RULES[kind].priority)

func claim(kind: String, key: String, tick: int) -> bool:
	if not RULES.has(kind) or key.is_empty() or seen_keys.has(key):
		return false
	var cooldown: int = int(RULES[kind].cooldown)
	if last_kind_tick.has(kind) and tick - int(last_kind_tick[kind]) < cooldown:
		return false
	seen_keys[key] = tick
	last_kind_tick[kind] = tick
	if seen_keys.size() > 512:
		for old_key in seen_keys.keys():
			if tick - int(seen_keys[old_key]) > 300:
				seen_keys.erase(old_key)
	return true
