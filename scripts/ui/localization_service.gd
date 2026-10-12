extends Node

const TRANSLATION_CSV: String = "res://localization/ui.csv"
const SUPPORTED_LOCALES: Array[String] = ["en", "ru"]

var _locale: String = "en"
var _tables: Dictionary = {
	"en": {},
	"ru": {}
}


func _ready() -> void:
	_load_translation_table()


func get_locale() -> String:
	return _locale


func set_locale(locale: String) -> void:
	if not SUPPORTED_LOCALES.has(locale):
		push_warning("Unsupported locale requested: %s" % locale)
		return

	_locale = locale
	TranslationServer.set_locale(locale)


func translate_key(key: String) -> String:
	var table: Dictionary = _tables.get(_locale, {})
	return String(table.get(key, key))


func format_key(key: String, arguments: Array = []) -> String:
	var template: String = translate_key(key)
	if arguments.is_empty():
		return template
	return template % arguments


func _load_translation_table() -> void:
	var file: FileAccess = FileAccess.open(TRANSLATION_CSV, FileAccess.READ)
	if file == null:
		push_error("Cannot open localization table: %s" % TRANSLATION_CSV)
		return

	var headers: PackedStringArray = file.get_csv_line()
	var key_column: int = headers.find("keys")
	if key_column < 0:
		push_error("Localization CSV must contain a 'keys' column.")
		return

	var locale_columns: Dictionary = {}
	for locale: String in SUPPORTED_LOCALES:
		var column: int = headers.find(locale)
		if column >= 0:
			locale_columns[locale] = column

	if locale_columns.size() != SUPPORTED_LOCALES.size():
		push_error("Localization CSV must contain columns for en and ru.")
		return

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.is_empty() or key_column >= row.size():
			continue

		var key: String = row[key_column].strip_edges()
		if key.is_empty():
			continue

		for locale: String in SUPPORTED_LOCALES:
			var column: int = int(locale_columns[locale])
			if column >= row.size():
				push_warning("Skipping incomplete localization row for key: %s" % key)
				continue

			var locale_table: Dictionary = _tables[locale]
			locale_table[key] = row[column]
