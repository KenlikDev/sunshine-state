extends Node

signal locale_changed(locale: String)
signal mouse_sensitivity_changed(value: float)
signal master_volume_changed(value: float)
signal display_settings_changed(fullscreen: bool, resolution_index: int)
signal binding_change_started(action: StringName)
signal binding_change_completed(action: StringName, physical_keycode: int)
signal binding_change_cancelled(action: StringName)
signal binding_change_rejected(action: StringName, message_key: String)

const SETTINGS_PATH: String = "user://sunshine_state_settings.cfg"
const DEFAULT_LOCALE: String = "en"
const DEFAULT_MOUSE_SENSITIVITY: float = 0.0025
const MIN_MOUSE_SENSITIVITY: float = 0.001
const MAX_MOUSE_SENSITIVITY: float = 0.01
const DEFAULT_MASTER_VOLUME: float = 0.8
const RESOLUTION_PRESETS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
const REMAPPABLE_ACTIONS: Array[StringName] = [
	&"move_forward", &"move_backward", &"move_left", &"move_right",
	&"sprint", &"jump", &"interact", &"vehicle_recover", &"fire_weapon",
	&"aim_weapon", &"reload_weapon", &"use_first_aid_kit", &"save_game",
	&"load_game", &"restart_mission", &"toggle_language"
]

var _mouse_sensitivity: float = DEFAULT_MOUSE_SENSITIVITY
var _master_volume: float = DEFAULT_MASTER_VOLUME
var _is_fullscreen: bool = false
var _resolution_index: int = 0
var _default_key_bindings: Dictionary = {}
var _custom_key_bindings: Dictionary = {}
var _listening_action: StringName = &""


func _ready() -> void:
	_cache_default_key_bindings()
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
		_load_saved_key_bindings(config)
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
	for action: StringName in _custom_key_bindings.keys():
		config.set_value("input", String(action), int(_custom_key_bindings[action]))
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


func get_binding_keycode(action: StringName) -> int:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode > 0:
			return int((event as InputEventKey).physical_keycode)
	return 0


func get_binding_label(action: StringName) -> String:
	var physical_keycode: int = get_binding_keycode(action)
	if physical_keycode <= 0:
		if action == &"fire_weapon":
			return Localization.translate_key("BINDING_MOUSE_LEFT")
		if action == &"aim_weapon":
			return Localization.translate_key("BINDING_MOUSE_RIGHT")
		return Localization.translate_key("SETTINGS_BINDING_UNASSIGNED")
	return OS.get_keycode_string(physical_keycode)


func get_default_binding_keycode(action: StringName) -> int:
	return int(_default_key_bindings.get(action, 0))


func set_binding_keycode(action: StringName, physical_keycode: int) -> bool:
	if not REMAPPABLE_ACTIONS.has(action) or not _default_key_bindings.has(action):
		return false
	if physical_keycode <= 0 or _has_binding_conflict(action, physical_keycode):
		return false
	_replace_keyboard_binding(action, physical_keycode)
	if physical_keycode == int(_default_key_bindings[action]):
		_custom_key_bindings.erase(action)
	else:
		_custom_key_bindings[action] = physical_keycode
	_save_settings()
	binding_change_completed.emit(action, physical_keycode)
	return true


func begin_rebind(action: StringName) -> bool:
	if not REMAPPABLE_ACTIONS.has(action) or not InputMap.has_action(action):
		return false
	if _listening_action != &"":
		cancel_rebind()
	_listening_action = action
	binding_change_started.emit(action)
	return true


func cancel_rebind() -> void:
	if _listening_action == &"":
		return
	var previous_action: StringName = _listening_action
	_listening_action = &""
	binding_change_cancelled.emit(previous_action)


func reset_binding(action: StringName) -> bool:
	if not _default_key_bindings.has(action):
		return false
	var default_keycode: int = int(_default_key_bindings[action])
	_replace_keyboard_binding(action, default_keycode)
	_custom_key_bindings.erase(action)
	_save_settings()
	binding_change_completed.emit(action, default_keycode)
	return true


func reset_all_bindings() -> void:
	cancel_rebind()
	for action: StringName in REMAPPABLE_ACTIONS:
		if _default_key_bindings.has(action):
			_replace_keyboard_binding(action, int(_default_key_bindings[action]))
	_custom_key_bindings.clear()
	_save_settings()
	for action: StringName in REMAPPABLE_ACTIONS:
		binding_change_completed.emit(action, get_binding_keycode(action))


func _input(event: InputEvent) -> void:
	if _listening_action == &"" or not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE:
		cancel_rebind()
		get_viewport().set_input_as_handled()
		return

	var action: StringName = _listening_action
	var physical_keycode: int = int(key_event.physical_keycode)
	if physical_keycode <= 0:
		binding_change_rejected.emit(action, "MESSAGE_KEY_BINDING_INVALID")
		cancel_rebind()
		get_viewport().set_input_as_handled()
		return
	if _has_binding_conflict(action, physical_keycode):
		_listening_action = &""
		binding_change_rejected.emit(action, "MESSAGE_KEY_BINDING_CONFLICT")
		get_viewport().set_input_as_handled()
		return

	_replace_keyboard_binding(action, physical_keycode)
	_custom_key_bindings[action] = physical_keycode
	_listening_action = &""
	_save_settings()
	binding_change_completed.emit(action, physical_keycode)
	get_viewport().set_input_as_handled()


func _cache_default_key_bindings() -> void:
	for action: StringName in REMAPPABLE_ACTIONS:
		if not InputMap.has_action(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey and (event as InputEventKey).physical_keycode > 0:
				_default_key_bindings[action] = int((event as InputEventKey).physical_keycode)
				break
		if not _default_key_bindings.has(action):
			_default_key_bindings[action] = 0


func _load_saved_key_bindings(config: ConfigFile) -> void:
	for action: StringName in REMAPPABLE_ACTIONS:
		if not _default_key_bindings.has(action):
			continue
		var saved_keycode: int = int(config.get_value("input", String(action), -1))
		if saved_keycode <= 0 or _has_binding_conflict(action, saved_keycode):
			continue
		_replace_keyboard_binding(action, saved_keycode)
		_custom_key_bindings[action] = saved_keycode


func _has_binding_conflict(action: StringName, physical_keycode: int) -> bool:
	for other_action: StringName in REMAPPABLE_ACTIONS:
		if other_action == action or not InputMap.has_action(other_action):
			continue
		for event: InputEvent in InputMap.action_get_events(other_action):
			if event is InputEventKey and int((event as InputEventKey).physical_keycode) == physical_keycode:
				return true
	return false


func _replace_keyboard_binding(action: StringName, physical_keycode: int) -> void:
	if not InputMap.has_action(action):
		return
	for event: InputEvent in InputMap.action_get_events(action).duplicate():
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	if physical_keycode > 0:
		var new_event := InputEventKey.new()
		new_event.physical_keycode = physical_keycode
		InputMap.action_add_event(action, new_event)


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
