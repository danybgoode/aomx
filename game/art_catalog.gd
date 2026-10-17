extends RefCounted

const MANIFEST_PATH := "res://assets/manifest.v0.1.json"

var records: Dictionary = {}
var textures: Dictionary = {}
var hit_images: Dictionary = {}

func load_manifest(include_pilot: bool = false) -> void:
	var source := FileAccess.get_file_as_string(MANIFEST_PATH)
	assert(not source.is_empty(), "Art manifest is missing.")
	var data: Variant = JSON.parse_string(source)
	assert(data is Dictionary and data.get("schema_version", 0) == 1, "Art manifest schema mismatch.")
	records.clear()
	textures.clear()
	hit_images.clear()
	for record in data.assets:
		if record.get("runtime_use", "match") == "pilot" and not include_pilot:
			continue
		var id: String = record.id
		assert(not records.has(id), "Duplicate art asset: " + id)
		records[id] = record
		var texture: Resource = ResourceLoader.load(record.path)
		assert(texture is Texture2D, "Missing art texture: " + record.path)
		textures[id] = texture
		hit_images[id] = (texture as Texture2D).get_image()

func texture(id: String) -> Texture2D:
	assert(textures.has(id), "Unknown art asset: " + id)
	return textures[id] as Texture2D

func pivot(id: String) -> Vector2:
	assert(records.has(id), "Unknown art asset: " + id)
	var value: Array = records[id].pivot
	return Vector2(float(value[0]), float(value[1]))

func hit_test(id: String, pixel: Vector2, padding: int = 4) -> bool:
	assert(hit_images.has(id), "Unknown art asset: " + id)
	var bitmap: Image = hit_images[id]
	var px := roundi(pixel.x)
	var py := roundi(pixel.y)
	for y in range(maxi(0, py - padding), mini(bitmap.get_height() - 1, py + padding) + 1):
		for x in range(maxi(0, px - padding), mini(bitmap.get_width() - 1, px + padding) + 1):
			if bitmap.get_pixel(x, y).a > 0.2:
				return true
	return false
