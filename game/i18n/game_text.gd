class_name GameText
extends RefCounted
## Language selection and display names for Battle for La Roma.
##
## Plain literals assigned to Control text are translated automatically by Godot. Text built
## at runtime must call tr() on its format string, and ids shown to players must go through
## name() so they appear in the player's language. Message files live in res://i18n/*.po;
## run `node scripts/i18n-extract.mjs` after changing player-facing text.

const SUPPORTED := ["es", "en"]
const LABELS := {"es": "Español", "en": "English"}
const TRANSLATIONS := ["res://i18n/es.po", "res://i18n/en.po"]

## Source text for every id that reaches the screen. The values are message ids; es.po and
## en.po give the words players read (for example "Comida" reads as "Food" in English).
const NAMES := {
	# Resources
	"comida": "Comida", "materiales": "Materiales", "varos": "Varos", "terrenos": "Terrenos",
	# Factions
	"regios": "Regios", "poblanos": "Poblanos", "oaxaquenos": "Oaxaqueños", "veracruzanos": "Veracruzanos",
	# Ages
	"foranea": "Foránea", "universitaria": "Universitaria", "godin": "Godín", "gentrificacion": "Gentrificación",
	# Buildings
	"command_post": "Command post", "barracks": "Recruitment post", "depot": "Depot", "housing": "Housing",
	"registry": "Registry", "wonder": "Wonder",
	# Units
	"worker": "Worker", "melee": "Melee fighter", "ranged": "Ranged fighter", "armored": "Armored fighter",
	"siege": "Siege unit", "bicitaxi": "Bicitaxi scout", "scout": "Scout",
	# Technologies
	"carry_capacity_i": "Carry capacity", "construction_rate_i": "Construction rate",
	"combat_training_i": "Combat training", "cooperative_build_i": "Cooperative build",
	"street_exchange_i": "Street exchange",
	# Unit activity
	"idle": "Idle", "move": "Moving", "gather": "Gathering", "deliver": "Delivering", "build": "Building",
	"repair": "Repairing", "assist": "Assisting", "attack": "Attacking", "attack_move": "Advancing",
	"hold": "Holding", "plant": "Planting", "train": "Training",
	# Attack classes
	"blunt": "Blunt", "piercing": "Piercing", "none": "None",
	# Center states
	"human_hold": "Your hold", "computer_hold": "Enemy hold", "contested": "Contested", "reset": "Reset",
	"terminal": "Finished", "neutral": "Neutral", "empty": "Empty",
	# Opponent levels
	"learner": "Learner", "standard": "Standard", "challenger": "Challenger",
	# Results
	"victory": "Victory", "defeat": "Defeat", "draw": "Draw", "win": "Victory", "loss": "Defeat",
}

## Untranslated source text for an id. Assign this to a Control's text so Godot's
## auto-translate re-renders it when the language changes.
static func source(id: String) -> String:
	return NAMES.get(id, id.replace("_", " ").capitalize())

## Translated display name for an id, for text composed at runtime.
static func name(id: String) -> String:
	return String(TranslationServer.translate(source(id)))

## Chooses the starting language: an explicit override for QA, then the saved choice, then
## the device or browser language. Spanish speakers get Spanish; everyone else English.
static func initial_locale(saved: String) -> String:
	var forced := OS.get_environment("AOMX_LOCALE").substr(0, 2)
	if forced in SUPPORTED:
		return forced
	if saved in SUPPORTED:
		return saved
	return "es" if OS.get_locale_language() == "es" else "en"

static func apply(locale: String) -> void:
	TranslationServer.set_locale(locale if locale in SUPPORTED else "en")

static func current() -> String:
	var locale := TranslationServer.get_locale().substr(0, 2)
	return locale if locale in SUPPORTED else "en"
