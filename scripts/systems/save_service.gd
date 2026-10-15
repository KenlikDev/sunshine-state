extends Node

signal save_status_changed(message_key: String)

const SAVE_PATH: String = "user://sunshine_state_save.json"
const BACKUP_PATH: String = "user://sunshine_state_save.bak"
const TEMP_PATH: String = "user://sunshine_state_save.tmp"
const SCHEMA_VERSION: int = 1

var _autosave_queued: bool = false
var _is_loading: bool = false
var _pending_world_time_hours: float = -1.0


func _ready() -> void:
	EconomyService.transaction_committed.connect(_on_progress_changed)
	MissionService.mission_state_changed.connect(_on_mission_state_changed)
	WantedSystem.crime_reported.connect(_on_crime_reported)
	WantedSystem.wanted_level_changed.connect(_on_wanted_level_changed)


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().get_first_node_in_group("gameplay_scene") == null:
		return
	if event.is_action_pressed("save_game"):
		save_game(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("load_game"):
		load_game(true)
		get_viewport().set_input_as_handled()


func save_game(show_feedback: bool = true) -> bool:
	var payload: Dictionary = _build_payload()
	var file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		_set_status("MESSAGE_SAVE_FAILED", show_feedback)
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()

	var primary_absolute: String = ProjectSettings.globalize_path(SAVE_PATH)
	var backup_absolute: String = ProjectSettings.globalize_path(BACKUP_PATH)
	var temporary_absolute: String = ProjectSettings.globalize_path(TEMP_PATH)

	if FileAccess.file_exists(SAVE_PATH):
		var existing_payload: Dictionary = _read_valid_payload(SAVE_PATH)
		if not existing_payload.is_empty():
			if FileAccess.file_exists(BACKUP_PATH):
				DirAccess.remove_absolute(backup_absolute)
			var backup_error: Error = DirAccess.copy_absolute(primary_absolute, backup_absolute)
			if backup_error != OK:
				DirAccess.remove_absolute(temporary_absolute)
				_set_status("MESSAGE_SAVE_FAILED", show_feedback)
				return false

	if FileAccess.file_exists(SAVE_PATH):
		var remove_error: Error = DirAccess.remove_absolute(primary_absolute)
		if remove_error != OK:
			DirAccess.remove_absolute(temporary_absolute)
			_set_status("MESSAGE_SAVE_FAILED", show_feedback)
			return false

	var rename_error: Error = DirAccess.rename_absolute(temporary_absolute, primary_absolute)
	if rename_error != OK:
		if FileAccess.file_exists(BACKUP_PATH) and not FileAccess.file_exists(SAVE_PATH):
			DirAccess.copy_absolute(backup_absolute, primary_absolute)
		_set_status("MESSAGE_SAVE_FAILED", show_feedback)
		return false

	_set_status("MESSAGE_SAVE_SUCCESS", show_feedback)
	return true


func load_game(show_feedback: bool = true) -> bool:
	var primary_exists: bool = FileAccess.file_exists(SAVE_PATH)
	var backup_exists: bool = FileAccess.file_exists(BACKUP_PATH)
	var payload: Dictionary = _read_valid_payload(SAVE_PATH)

	if not payload.is_empty():
		var loaded: bool = _apply_payload(payload)
		_set_status("MESSAGE_LOAD_SUCCESS" if loaded else "MESSAGE_SAVE_FAILED", show_feedback)
		return loaded

	if backup_exists:
		var backup_payload: Dictionary = _read_valid_payload(BACKUP_PATH)
		if not backup_payload.is_empty():
			var recovered: bool = _apply_payload(backup_payload)
			_set_status("MESSAGE_SAVE_RECOVERED" if recovered else "MESSAGE_SAVE_FAILED", show_feedback)
			return recovered

	if show_feedback and (primary_exists or backup_exists):
		save_status_changed.emit("MESSAGE_SAVE_FAILED")
	return false


func delete_save_files() -> void:
	for path: String in [SAVE_PATH, BACKUP_PATH, TEMP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func get_save_data_path() -> String:
	return SAVE_PATH


func has_valid_save() -> bool:
	if not _read_valid_payload(SAVE_PATH).is_empty():
		return true
	return not _read_valid_payload(BACKUP_PATH).is_empty()


func get_schema_version() -> int:
	return SCHEMA_VERSION


func get_backup_data_path() -> String:
	return BACKUP_PATH


func validate_save_file(path: String) -> bool:
	return not _read_valid_payload(path).is_empty()


func _build_payload() -> Dictionary:
	var world_state: Dictionary = MissionService.get_world_state()
	var day_night_cycle: Node = _get_day_night_cycle()
	if is_instance_valid(day_night_cycle) and day_night_cycle.has_method("get_time_of_day"):
		world_state["time_of_day_hours"] = float(day_night_cycle.call("get_time_of_day"))
	return {
		"schema_version": SCHEMA_VERSION,
		"timestamp_utc": Time.get_datetime_string_from_system(true),
		"economy": EconomyService.get_save_data(),
		"missions": MissionService.get_save_data(),
		"wanted": WantedSystem.get_save_data(),
		"world": world_state
	}


func _read_valid_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {}
	var payload: Dictionary = parsed
	if not _is_valid_payload(payload):
		return {}
	return payload


func _is_valid_payload(payload: Dictionary) -> bool:
	if int(payload.get("schema_version", -1)) != SCHEMA_VERSION:
		return false
	if typeof(payload.get("timestamp_utc", null)) != TYPE_STRING:
		return false
	if not EconomyService.is_save_data_valid(payload.get("economy", null)):
		push_warning("Save validation failed: economy payload is invalid.")
		return false
	if not MissionService.is_save_data_valid(payload.get("missions", null)):
		push_warning("Save validation failed: mission payload is invalid.")
		return false
	if not WantedSystem.is_save_data_valid(payload.get("wanted", null)):
		push_warning("Save validation failed: wanted payload is invalid.")
		return false
	if not payload.get("world", null) is Dictionary:
		push_warning("Save validation failed: world payload is invalid.")
		return false
	var world_state: Dictionary = payload["world"]
	if world_state.has("time_of_day_hours"):
		var time_value: Variant = world_state["time_of_day_hours"]
		if typeof(time_value) != TYPE_INT and typeof(time_value) != TYPE_FLOAT:
			push_warning("Save validation failed: world time is not numeric.")
			return false
		var time_hours: float = float(time_value)
		if time_hours < 0.0 or time_hours >= 24.0 or time_hours != time_hours:
			push_warning("Save validation failed: world time is outside the valid day range.")
			return false
	return true


func _apply_payload(payload: Dictionary) -> bool:
	_is_loading = true
	var economy_ok: bool = EconomyService.load_save_data(payload["economy"])
	var missions_ok: bool = MissionService.load_save_data(payload["missions"])
	var wanted_ok: bool = WantedSystem.load_save_data(payload["wanted"])
	_is_loading = false
	if not economy_ok or not missions_ok or not wanted_ok:
		return false
	_pending_world_time_hours = -1.0
	var world_state: Dictionary = payload["world"]
	if world_state.has("time_of_day_hours"):
		_pending_world_time_hours = float(world_state["time_of_day_hours"])
	var day_night_cycle: Node = _get_day_night_cycle()
	if is_instance_valid(day_night_cycle):
		restore_pending_world_time(day_night_cycle)
	return true


func restore_pending_world_time(day_night_cycle: Node) -> bool:
	if _pending_world_time_hours < 0.0 or not is_instance_valid(day_night_cycle):
		return false
	if not day_night_cycle.has_method("set_time_of_day"):
		return false
	day_night_cycle.call("set_time_of_day", _pending_world_time_hours)
	_pending_world_time_hours = -1.0
	return true


func _get_day_night_cycle() -> Node:
	return get_tree().get_first_node_in_group("day_night_cycle")


func _queue_autosave() -> void:
	if _is_loading or _autosave_queued:
		return
	_autosave_queued = true
	call_deferred("_run_autosave")


func _run_autosave() -> void:
	_autosave_queued = false
	save_game(false)


func _on_progress_changed(
	_transaction_id: String,
	_kind: String,
	_balance: int,
	_amount: int
) -> void:
	_queue_autosave()


func _on_mission_state_changed(_mission_id: String, _state: String) -> void:
	_queue_autosave()


func _on_crime_reported(
	_crime_type: StringName,
	_severity: int,
	_wanted_level: int,
	_source_id: StringName
) -> void:
	_queue_autosave()


func _on_wanted_level_changed(_level: int) -> void:
	_queue_autosave()


func _set_status(message_key: String, show_feedback: bool) -> void:
	if show_feedback:
		save_status_changed.emit(message_key)
