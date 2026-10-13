extends Node

signal locale_changed(locale: String)
signal mouse_sensitivity_changed(value: float)

const SETTINGS_PATH: String = "user://sunshine_state_settings.cfg"
const DEFAULT_LOCALE: String = "en"
const DEFAULT_MOUSE_SENSITIVITY: float = 0.0025
const MIN_MOUSE_SENSITIVITY: float = 0.001
const MAX_MOUSE_SENSITIVITY: float = 0.01

var _mouse_sensitivity: float = DEFAULT_MOUSE_SENSITIVITY


func _ready() -> void:
	var config := ConfigFile.new()
	var load_error: Error = config.load(SETTINGS_PATH)
	var saved_locale: String = DEFAULT_LOCALE
	if load_error == OK:
		saved_locale = String(config.get_value("display", "locale", DEFAULT_LOCALE))
		_mouse_sensitivity = clampf(
			float(config.get_value("controls", "mouse_sensitivity", DEFAULT_MOUSE_SENSITIVITY)),
			MIN_MOUSE_SENSITIVITY,
			MAX_MOUSE_SENSITIVITY
		)
	if not Localization.SUPPORTED_LOCALES.has(saved_locale):
		saved_locale = DEFAULT_LOCALE
	Localization.set_locale(saved_locale)
	_apply_mouse_sensitivity()


func get_locale() -> String:
	return Localization.get_locale()


func set_locale(locale: String) -> void:
	if not Localization.SUPPORTED_LOCALES.has(locale):
		return
	if Localization.get_locale() == locale:
		return
	Localization.set_locale(locale)
	_save_settings()
	locale_changed.emit(locale)


func get_mouse_sensitivity() -> float:
	return _mouse_sensitivity


func set_mouse_sensitivity(value: float) -> void:
	var next_value: float = clampf(value, MIN_MOUSE_SENSITIVITY, MAX_MOUSE_SENSITIVITY)
	if is_equal_approx(_mouse_sensitivity, next_value):
		return
	_mouse_sensitivity = next_value
	_apply_mouse_sensitivity()
	_save_settings()
	mouse_sensitivity_changed.emit(_mouse_sensitivity)


func _apply_mouse_sensitivity() -> void:
	for player: Node in get_tree().get_nodes_in_group("player"):
		player.set("mouse_sensitivity", _mouse_sensitivity)
	for vehicle: Node in get_tree().get_nodes_in_group("vehicles"):
		vehicle.set("mouse_sensitivity", _mouse_sensitivity)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "locale", Localization.get_locale())
	config.set_value("controls", "mouse_sensitivity", _mouse_sensitivity)
	var save_error: Error = config.save(SETTINGS_PATH)
	if save_error != OK:
		push_warning("Could not save user settings (error %d)." % save_error)
