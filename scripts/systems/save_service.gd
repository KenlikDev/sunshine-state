extends Node

signal save_status_changed(message_key: String)

const SAVE_PATH: String = "user://sunshine_state_save.json"
const BACKUP_PATH: String = "user://sunshine_state_save.bak"
const TEMP_PATH: String = "user://sunshine_state_save.tmp"
const SCHEMA_VERSION: int = 1

var _autosave_queued: bool = false
var _is_loading: bool = false


func _ready() -> void:
	EconomyService.transaction_committed.connect(_on_progress_changed)
	MissionService.mission_state_changed.connect(_on_mission_state_changed)
	WantedSystem.crime_reported.connect(_on_crime_reported)
	WantedSystem.wanted_level_changed.connect(_on_wanted_level_changed)


func _unhandled_input(event: InputEvent) -> void:
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


func get_schema_version() -> int:
	return SCHEMA_VERSION


func _build_payload() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"timestamp_utc": Time.get_datetime_string_from_system(true),
		"economy": EconomyService.get_save_data(),
		"missions": MissionService.get_save_data(),
		"wanted": WantedSystem.get_save_data(),
		"world": MissionService.get_world_state()
	}


func _read_valid_payload(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
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
		return false
	if not MissionService.is_save_data_valid(payload.get("missions", null)):
		return false
	if not WantedSystem.is_save_data_valid(payload.get("wanted", null)):
		return false
	if not payload.get("world", null) is Dictionary:
		return false
	return true


func _apply_payload(payload: Dictionary) -> bool:
	_is_loading = true
	var economy_ok: bool = EconomyService.load_save_data(payload["economy"])
	var missions_ok: bool = MissionService.load_save_data(payload["missions"])
	var wanted_ok: bool = WantedSystem.load_save_data(payload["wanted"])
	_is_loading = false
	return economy_ok and missions_ok and wanted_ok


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
