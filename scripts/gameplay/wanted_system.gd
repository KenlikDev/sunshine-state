extends Node

signal crime_reported(crime_type: StringName, severity: int, wanted_level: int, source_id: StringName)
signal wanted_level_changed(level: int)
signal wanted_state_changed(state_name: String)
signal wanted_cleared(reason: StringName)

enum WantedState { CLEAR, PURSUIT, SEARCHING, COOLING_DOWN }

const MAX_WANTED_LEVEL: int = 5

@export_range(0.1, 60.0, 0.1) var search_duration_seconds: float = 8.0
@export_range(0.1, 120.0, 0.1) var decay_interval_seconds: float = 12.0
@export var debug_logging: bool = true

var _wanted_level: int = 0
var _state: WantedState = WantedState.CLEAR
var _last_known_player_position: Vector3 = Vector3.ZERO
var _search_remaining: float = 0.0
var _decay_remaining: float = 0.0
var _visible_police: Dictionary = {}


func _process(delta: float) -> void:
	if _wanted_level <= 0:
		return

	if _has_visible_police():
		_set_state(WantedState.PURSUIT, "police have line of sight")
		return

	if _state == WantedState.PURSUIT:
		_search_remaining = search_duration_seconds
		_set_state(WantedState.SEARCHING, "line of sight lost")

	match _state:
		WantedState.SEARCHING:
			_search_remaining = maxf(0.0, _search_remaining - delta)
			if _search_remaining <= 0.0:
				_decay_remaining = decay_interval_seconds
				_set_state(WantedState.COOLING_DOWN, "search window expired")
		WantedState.COOLING_DOWN:
			_decay_remaining -= delta
			if _decay_remaining <= 0.0:
				_decay_one_level()
		_:
			pass


func report_crime(
	crime_type: StringName,
	severity: int,
	player_position: Vector3,
	witnessed: bool = true,
	source_id: StringName = &""
) -> int:
	if crime_type.is_empty() or severity < 1:
		push_warning("Rejected crime event with an empty type or non-positive severity.")
		return _wanted_level

	var previous_level: int = _wanted_level
	_wanted_level = clampi(_wanted_level + severity, 1, MAX_WANTED_LEVEL)
	_last_known_player_position = player_position
	_search_remaining = search_duration_seconds
	_decay_remaining = decay_interval_seconds

	if _wanted_level != previous_level:
		wanted_level_changed.emit(_wanted_level)

	crime_reported.emit(crime_type, severity, _wanted_level, source_id)
	_log_event(
		"Crime %s (severity=%d, source=%s) -> wanted %d/%d"
		% [String(crime_type), severity, String(source_id), _wanted_level, MAX_WANTED_LEVEL]
	)

	if _has_visible_police():
		_set_state(WantedState.PURSUIT, "crime reported while police are watching")
	elif witnessed:
		_set_state(WantedState.SEARCHING, "witnessed crime reported")
	else:
		_set_state(WantedState.COOLING_DOWN, "unwitnessed crime reported")

	return _wanted_level


func register_police_detection(
	detector_id: int,
	sees_player: bool,
	player_position: Vector3
) -> void:
	if _wanted_level <= 0:
		_visible_police.erase(detector_id)
		return

	if sees_player:
		_visible_police[detector_id] = true
		_last_known_player_position = player_position
		_search_remaining = search_duration_seconds
		_set_state(WantedState.PURSUIT, "police detector %d acquired target" % detector_id)
	else:
		_visible_police.erase(detector_id)
		if not _has_visible_police() and _state == WantedState.PURSUIT:
			_search_remaining = search_duration_seconds
			_set_state(WantedState.SEARCHING, "all police lost line of sight")


func clear_wanted(reason: StringName = &"CLEARED") -> void:
	var previous_level: int = _wanted_level
	_wanted_level = 0
	_visible_police.clear()
	_search_remaining = 0.0
	_decay_remaining = 0.0
	_last_known_player_position = Vector3.ZERO

	if previous_level > 0:
		wanted_level_changed.emit(0)
	_log_event("Wanted state cleared: %s" % String(reason))
	_set_state(WantedState.CLEAR, "wanted level cleared")
	wanted_cleared.emit(reason)


func reset_for_new_game() -> void:
	clear_wanted(&"NEW_GAME")


func get_wanted_level() -> int:
	return _wanted_level


func get_state_name() -> String:
	match _state:
		WantedState.PURSUIT:
			return "PURSUIT"
		WantedState.SEARCHING:
			return "SEARCHING"
		WantedState.COOLING_DOWN:
			return "COOLING_DOWN"
		_:
			return "CLEAR"


func get_last_known_player_position() -> Vector3:
	return _last_known_player_position


func get_visible_police_count() -> int:
	return _visible_police.size()


func _has_visible_police() -> bool:
	return not _visible_police.is_empty()


func _decay_one_level() -> void:
	_wanted_level = maxi(0, _wanted_level - 1)
	wanted_level_changed.emit(_wanted_level)
	_log_event("Wanted level decayed to %d/%d" % [_wanted_level, MAX_WANTED_LEVEL])

	if _wanted_level == 0:
		clear_wanted(&"DECAYED")
	else:
		_search_remaining = search_duration_seconds
		_decay_remaining = decay_interval_seconds
		_set_state(WantedState.SEARCHING, "wanted level decayed; another search cycle begins")


func _set_state(next_state: WantedState, reason: String) -> void:
	if _state == next_state:
		return
	_state = next_state
	var state_name: String = get_state_name()
	_log_event("State -> %s (%s)" % [state_name, reason])
	wanted_state_changed.emit(state_name)


func get_save_data() -> Dictionary:
	return {
		"wanted_level": _wanted_level,
		"last_known_position": {
			"x": _last_known_player_position.x,
			"y": _last_known_player_position.y,
			"z": _last_known_player_position.z
		},
		"state": get_state_name()
	}


func is_save_data_valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var payload: Dictionary = data
	var level_value: Variant = payload.get("wanted_level", null)
	if not _is_integral_number(level_value, MAX_WANTED_LEVEL):
		return false
	var position_value: Variant = payload.get("last_known_position", null)
	if not position_value is Dictionary:
		return false
	for axis: String in ["x", "y", "z"]:
		var axis_value: Variant = position_value.get(axis, null)
		if typeof(axis_value) != TYPE_INT and typeof(axis_value) != TYPE_FLOAT:
			return false
	if typeof(payload.get("state", null)) != TYPE_STRING:
		return false
	if not ["CLEAR", "PURSUIT", "SEARCHING", "COOLING_DOWN"].has(String(payload["state"])):
		return false
	return true


func _is_integral_number(value: Variant, maximum: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	var numeric_value: float = float(value)
	if numeric_value < 0.0 or numeric_value > float(maximum):
		return false
	return is_equal_approx(numeric_value, roundf(numeric_value))


func load_save_data(data: Dictionary) -> bool:
	if not is_save_data_valid(data):
		return false

	var previous_level: int = _wanted_level
	_wanted_level = clampi(int(data["wanted_level"]), 0, MAX_WANTED_LEVEL)
	var saved_position: Dictionary = data["last_known_position"]
	_last_known_player_position = Vector3(
		float(saved_position["x"]),
		float(saved_position["y"]),
		float(saved_position["z"])
	)
	_visible_police.clear()
	if previous_level != _wanted_level:
		wanted_level_changed.emit(_wanted_level)

	if _wanted_level <= 0:
		_last_known_player_position = Vector3.ZERO
		_search_remaining = 0.0
		_decay_remaining = 0.0
		_set_state(WantedState.CLEAR, "wanted state loaded from save")
	else:
		_search_remaining = search_duration_seconds
		_decay_remaining = decay_interval_seconds
		_set_state(WantedState.SEARCHING, "loaded save requires police to reacquire the player")
	return true


func _log_event(message: String) -> void:
	if debug_logging:
		print("[WantedSystem] ", message)
