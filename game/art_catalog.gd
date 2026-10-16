extends RefCounted

const MANIFEST_PATH := "res://assets/manifest.v0.1.json"

var records: Dictionary = {}
var textures: Dictionary = {}

func load_manifest() -> void:
	var source := FileAccess.get_file_as_string(MANIFEST_PATH)
	assert(not source.is_empty(), "Art manifest is missing.")
	var data: Variant = JSON.parse_string(source)
	assert(data is Dictionary and data.get("schema_version", 0) == 1, "Art manifest schema mismatch.")
	for record in data.assets:
		var id: String = record.id
		assert(not records.has(id), "Duplicate art asset: " + id)
		records[id] = record
		var texture: Resource = ResourceLoader.load(record.path)
		assert(texture is Texture2D, "Missing art texture: " + record.path)
		textures[id] = texture

func texture(id: String) -> Texture2D:
	assert(textures.has(id), "Unknown art asset: " + id)
	return textures[id] as Texture2D

func pivot(id: String) -> Vector2:
	assert(records.has(id), "Unknown art asset: " + id)
	var value: Array = records[id].pivot
	return Vector2(float(value[0]), float(value[1]))
