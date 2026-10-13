extends Node

signal locale_changed(locale: String)
signal mouse_sensitivity_changed(value: float)
signal master_volume_changed(value: float)
signal display_settings_changed(fullscreen: bool, resolution_index: int)

const SETTINGS_PATH: String = "user://sunshine_state_settings.cfg"
const DEFAULT_LOCALE: String = "en"
const DEFAULT_MOUSE_SENSITIVITY: float = 0.0025
const MIN_MOUSE_SENSITIVITY: float = 0.001
const MAX_MOUSE_SENSITIVITY: float = 0.01
const DEFAULT_MASTER_VOLUME: float = 0.8
const RESOLUTION_PRESETS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]

var _mouse_sensitivity: float = DEFAULT_MOUSE_SENSITIVITY
var _master_volume: float = DEFAULT_MASTER_VOLUME
var _is_fullscreen: bool = false
var _resolution_index: int = 0


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
		_master_volume = clampf(float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 1.0)
		_is_fullscreen = bool(config.get_value("display", "fullscreen", false))
		_resolution_index = clampi(int(config.get_value("display", "resolution_index", 0)), 0, RESOLUTION_PRESETS.size() - 1)
	if not Localization.SUPPORTED_LOCALES.has(saved_locale):
		saved_locale = DEFAULT_LOCALE
	Localization.set_locale(saved_locale)
	_apply_mouse_sensitivity()
	_apply_master_volume()
	_apply_display_settings()


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
	config.set_value("display", "fullscreen", _is_fullscreen)
	config.set_value("display", "resolution_index", _resolution_index)
	config.set_value("controls", "mouse_sensitivity", _mouse_sensitivity)
	config.set_value("audio", "master_volume", _master_volume)
	var save_error: Error = config.save(SETTINGS_PATH)
	if save_error != OK:
		push_warning("Could not save user settings (error %d)." % save_error)



func get_master_volume() -> float:
	return _master_volume


func set_master_volume(value: float) -> void:
	var next_value: float = clampf(value, 0.0, 1.0)
	if is_equal_approx(_master_volume, next_value):
		return
	_master_volume = next_value
	_apply_master_volume()
	_save_settings()
	master_volume_changed.emit(_master_volume)


func get_is_fullscreen() -> bool:
	return _is_fullscreen


func set_is_fullscreen(enabled: bool) -> void:
	if _is_fullscreen == enabled:
		return
	_is_fullscreen = enabled
	_apply_display_settings()
	_save_settings()
	display_settings_changed.emit(_is_fullscreen, _resolution_index)


func get_resolution_index() -> int:
	return _resolution_index


func get_resolution_presets() -> Array[Vector2i]:
	return RESOLUTION_PRESETS.duplicate()


func set_resolution_index(index: int) -> void:
	var next_index: int = clampi(index, 0, RESOLUTION_PRESETS.size() - 1)
	if _resolution_index == next_index:
		return
	_resolution_index = next_index
	_apply_display_settings()
	_save_settings()
	display_settings_changed.emit(_is_fullscreen, _resolution_index)


func _apply_master_volume() -> void:
	var master_bus: int = AudioServer.get_bus_index("Master")
	if master_bus < 0:
		return
	AudioServer.set_bus_volume_db(master_bus, -80.0 if _master_volume <= 0.001 else linear_to_db(_master_volume))


func _apply_display_settings() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if _is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(RESOLUTION_PRESETS[_resolution_index])
