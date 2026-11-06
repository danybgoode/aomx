extends SceneTree
## Proves the game reads in Spanish and English: catalogs load, names translate, the language
## choice persists, and no English source text leaks into the Spanish setup screen or HUD.

const Scene = preload("res://skirmish_main.tscn")
const Skirmish = preload("res://skirmish.gd")
var failed := false
## English source strings whose Spanish translation is different, longest first.
var leak_markers: Array[String] = []
var scanned := 0
var ENGLISH_WORDS := RegEx.create_from_string("(?i)\\b(the|your|with|you|click|select|choose|enemy|units?|workers?|match|room|faction|here|build|gather|resources?)\\b")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_load_leak_markers()
	check(leak_markers.size() > 150, "enough English phrases to detect leaks (%d)" % leak_markers.size())
	GameText.apply("es")
	check(tr("Worker") == "Obrero", "Spanish catalog loads")
	check(GameText.name("depot") == "Bodega" and GameText.name("melee") == "Peleador", "ids translate to Spanish names")
	check(tr("%d workers assigned to %s.") % [2, GameText.name("varos")] == "2 obreros a juntar Varos.", "formatted Spanish keeps placeholder order")
	GameText.apply("en")
	check(tr("PARTIDA RÁPIDA") == "QUICK MATCH" and GameText.name("comida") == "Food", "English catalog translates Spanish source text")
	check(GameText.initial_locale("es") == "es" and GameText.initial_locale("fr") in GameText.SUPPORTED, "saved choice wins and unsupported values fall back")

	var client = Scene.instantiate()
	root.add_child(client)
	await process_frame
	var previous: String = client.chosen_locale
	client._set_locale("es")
	await process_frame
	check(GameText.current() == "es" and client.setup_language.selected == GameText.SUPPORTED.find("es"), "setup language picker switches to Spanish")
	check(client.chosen_locale == "es", "explicit language choice is remembered")
	_expect_no_leaks(client, "setup screen")
	check(scanned > 40, "setup scan covered the visible controls (%d texts)" % scanned)
	# The detector must catch a real leak, or a passing scan proves nothing.
	var probe := Label.new()
	probe.text = "Choose a faction"
	probe.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	client.setup_panel.add_child(probe)
	var caught: Array[String] = []
	_find_leaks(probe, caught)
	check(caught == ["Choose a faction"], "leak detector flags untranslated English")
	probe.text = "Any faction can fight here."
	caught.clear()
	_find_leaks(probe, caught)
	check(caught.size() == 1, "leak detector flags English missing from the catalog")
	probe.queue_free()
	check(client.setup_map.get_item_text(4).contains("Grande"), "composed map names rebuild in Spanish")

	client._choose_faction(Skirmish.POBLANOS)
	client.sim.ai_enabled = false
	for i in 30:
		client.sim.tick()
	client.selected_id = client.sim._find(Skirmish.HUMAN, "worker")
	client.selected_ids.clear()
	client.selected_ids.append(client.selected_id)
	client._update_hud()
	await process_frame
	check(client.hud_ui.age_label.text.begins_with("EDAD"), "HUD age reads in Spanish")
	check(client.hud_ui.faction_label.text == "TÚ · POBLANOS", "HUD faction badge reads in Spanish")
	_expect_no_leaks(client, "match HUD")
	client.hud_ui.diagnostics.show()
	await process_frame
	_expect_no_leaks(client.hud_ui.diagnostics, "settings panel")
	check(client.hud_ui.language_choice.selected == GameText.SUPPORTED.find("es"), "in-match language picker shows Spanish")
	client.hud_ui.diagnostics.hide()

	client._set_locale("en")
	await process_frame
	client._update_hud()
	check(client.hud_ui.age_label.text.begins_with("AGE · OUT-OF-TOWNER"), "switching back to English updates the HUD live")
	client.chosen_locale = previous
	client._save_ui_settings()
	GameText.apply(GameText.initial_locale(previous))
	root.remove_child(client)
	client.queue_free()
	await process_frame
	if not failed:
		print("Localization checks passed")
	quit(1 if failed else 0)

func _load_leak_markers() -> void:
	var text := FileAccess.get_file_as_string("res://i18n/es.po")
	var regex := RegEx.create_from_string('msgid "((?:[^"\\\\]|\\\\.)*)"\\nmsgstr "((?:[^"\\\\]|\\\\.)*)"')
	for m in regex.search_all(text):
		var id := m.get_string(1).c_unescape()
		var es := m.get_string(2).c_unescape()
		# Only whole English phrases make reliable leak markers; short words and pure formats don't.
		var words := id.replace("%s", "").replace("%d", "").strip_edges()
		if id != es and words.length() >= 12 and words.contains(" ") and not id.contains("%"):
			leak_markers.append(id)
	leak_markers.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())

func _expect_no_leaks(node: Node, where: String) -> void:
	var leaks: Array[String] = []
	_find_leaks(node, leaks)
	check(leaks.is_empty(), "%s shows no untranslated English %s" % [where, leaks])

## Walks visible controls, collecting English phrases that should have read in Spanish.
func _find_leaks(node: Node, leaks: Array[String]) -> void:
	if node is CanvasItem and not node.is_visible_in_tree():
		return
	for text in _displayed_texts(node):
		var found := false
		for marker in leak_markers:
			if text.contains(marker):
				leaks.append(marker)
				found = true
				break
		# Second net for English that never reached the catalog (content files, new code).
		if not found and ENGLISH_WORDS.search(text) != null:
			leaks.append(text)
	for child in node.get_children():
		_find_leaks(child, leaks)

func _displayed_texts(node: Node) -> Array[String]:
	var texts: Array[String] = []
	var raw: Array = []
	if node is Label or node is Button or node is LineEdit:
		raw.append(node.text)
	if node is LineEdit:
		raw.append(node.placeholder_text)
	if node is OptionButton:
		for i in node.item_count:
			raw.append(node.get_item_text(i))
	if node is Control:
		raw.append(node.tooltip_text)
	for value in raw:
		var shown := String(value)
		if shown.is_empty():
			continue
		scanned += 1
		texts.append(node.atr(shown) if node.can_auto_translate() else shown)
	return texts

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
