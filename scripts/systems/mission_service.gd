extends Node

signal mission_state_changed(mission_id: String, state: String)
signal mission_completed(mission_id: String, reward: int)
signal mission_failed(mission_id: String, reason_key: String)
signal mission_restarted(mission_id: String)

const MISSION_DATA_PATH: String = "res://data/missions/missions.json"
const VALID_STATES: Array[String] = ["LOCKED", "AVAILABLE", "ACTIVE", "FAILED", "COMPLETED"]

var _definitions: Array[Dictionary] = []
var _states: Dictionary = {}
var _current_mission_id: String = ""


func _ready() -> void:
	_load_definitions()
	reset_for_new_game()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().get_first_node_in_group("gameplay_scene") == null:
		return
	if event.is_action_pressed("restart_mission"):
		restart_current_mission()
		get_viewport().set_input_as_handled()


func get_current_mission_id() -> String:
	return _current_mission_id


func get_mission_count() -> int:
	return _definitions.size()


func get_mission_state(mission_id: String) -> String:
	return String(_states.get(mission_id, "LOCKED"))


func is_mission_completed(mission_id: String) -> bool:
	return get_mission_state(mission_id) == "COMPLETED"


func get_active_mission() -> Dictionary:
	if _current_mission_id.is_empty():
		return {}
	var definition: Dictionary = _find_definition(_current_mission_id)
	if definition.is_empty():
		return {}
	var result: Dictionary = definition.duplicate(true)
	result["state"] = get_mission_state(_current_mission_id)
	return result


func get_active_target_node() -> Node3D:
	var mission: Dictionary = get_active_mission()
	if mission.is_empty():
		return null

	var target_name: String = String(mission.get("target_node_name", ""))
	if target_name.is_empty():
		return null
	var gameplay_scene: Node = get_tree().get_first_node_in_group("gameplay_scene")
	if not is_instance_valid(gameplay_scene):
		return null
	var world: Node = gameplay_scene.get_node_or_null("World")
	if not is_instance_valid(world):
		return null
	return world.get_node_or_null(target_name) as Node3D


func record_event(event_type: StringName, source_id: StringName) -> void:
	if _current_mission_id.is_empty() or get_mission_state(_current_mission_id) != "ACTIVE":
		return

	var definition: Dictionary = _find_definition(_current_mission_id)
	if definition.is_empty():
		return

	var failure_event: String = String(definition.get("failure_event", ""))
	if not failure_event.is_empty() and String(event_type) == failure_event:
		_fail_current_mission(String(definition.get("failure_message_key", "MESSAGE_MISSION_FAILED")))
		return

	if (
		String(definition.get("objective_event", "")) == String(event_type)
		and String(definition.get("objective_source", "")) == String(source_id)
	):
		_complete_current_mission(definition)


func restart_current_mission() -> bool:
	if _current_mission_id.is_empty():
		return false
	var state: String = get_mission_state(_current_mission_id)
	if state != "ACTIVE" and state != "FAILED":
		return false

	var mission_id: String = _current_mission_id
	_states[mission_id] = "ACTIVE"
	mission_state_changed.emit(mission_id, "ACTIVE")
	mission_restarted.emit(mission_id)
	return true


func get_save_data() -> Dictionary:
	return {
		"states": _states.duplicate(true),
		"current_mission_id": _current_mission_id
	}


func get_world_state() -> Dictionary:
	return {
		"district_board_inspected": is_mission_completed("district_orientation"),
		"crime_site_reported": is_mission_completed("property_report"),
		"supply_purchased": is_mission_completed("supply_run")
	}


func is_save_data_valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var payload: Dictionary = data
	var states_value: Variant = payload.get("states", null)
	if not states_value is Dictionary:
		return false

	var known_ids: Dictionary = {}
	for definition: Dictionary in _definitions:
		known_ids[String(definition["id"])] = true

	for mission_id: Variant in states_value.keys():
		if not known_ids.has(String(mission_id)):
			return false
		var state_value: Variant = states_value[mission_id]
		if typeof(state_value) != TYPE_STRING or not VALID_STATES.has(String(state_value)):
			return false

	var current_value: Variant = payload.get("current_mission_id", null)
	if typeof(current_value) != TYPE_STRING:
		return false
	var current_id: String = String(current_value)
	if not current_id.is_empty() and not known_ids.has(current_id):
		return false
	if not current_id.is_empty():
		var current_state: String = String(states_value.get(current_id, "LOCKED"))
		if current_state != "ACTIVE" and current_state != "FAILED":
			return false

	for definition: Dictionary in _definitions:
		var mission_id: String = String(definition["id"])
		if String(states_value.get(mission_id, "LOCKED")) == "COMPLETED":
			if not _prerequisites_completed_for_data(definition, states_value):
				return false
	return true


func load_save_data(data: Dictionary) -> bool:
	if not is_save_data_valid(data):
		return false

	_states.clear()
	for definition: Dictionary in _definitions:
		_states[String(definition["id"])] = "LOCKED"

	var saved_states: Dictionary = data["states"]
	for mission_id: Variant in saved_states.keys():
		_states[String(mission_id)] = String(saved_states[mission_id])
	_current_mission_id = String(data["current_mission_id"])

	if _current_mission_id.is_empty():
		_activate_next_available()
	elif get_mission_state(_current_mission_id) == "ACTIVE":
		mission_state_changed.emit(_current_mission_id, "ACTIVE")
	else:
		mission_state_changed.emit(_current_mission_id, "FAILED")

	for definition: Dictionary in _definitions:
		var mission_id: String = String(definition["id"])
		mission_state_changed.emit(mission_id, get_mission_state(mission_id))
	return true


func reset_for_new_game() -> void:
	_states.clear()
	for definition: Dictionary in _definitions:
		_states[String(definition["id"])] = "LOCKED"
	_current_mission_id = ""
	_activate_next_available()


func _complete_current_mission(definition: Dictionary) -> void:
	var completed_id: String = String(definition["id"])
	var reward: int = maxi(0, int(definition.get("reward", 0)))
	if reward > 0:
		EconomyService.grant_reward(reward, "mission_reward:%s" % completed_id)

	_states[completed_id] = "COMPLETED"
	var next_id: String = String(definition.get("next_mission", ""))
	_current_mission_id = ""
	if not next_id.is_empty():
		var next_definition: Dictionary = _find_definition(next_id)
		if not next_definition.is_empty() and _prerequisites_completed(next_definition):
			_states[next_id] = "ACTIVE"
			_current_mission_id = next_id

	mission_completed.emit(completed_id, reward)
	mission_state_changed.emit(completed_id, "COMPLETED")
	if not _current_mission_id.is_empty():
		mission_state_changed.emit(_current_mission_id, "ACTIVE")


func _fail_current_mission(reason_key: String) -> void:
	var failed_id: String = _current_mission_id
	_states[failed_id] = "FAILED"
	mission_failed.emit(failed_id, reason_key)
	mission_state_changed.emit(failed_id, "FAILED")


func _activate_next_available() -> void:
	for definition: Dictionary in _definitions:
		var mission_id: String = String(definition["id"])
		if get_mission_state(mission_id) == "COMPLETED" or get_mission_state(mission_id) == "FAILED":
			continue
		if not _prerequisites_completed(definition):
			_states[mission_id] = "LOCKED"
			continue
		_states[mission_id] = "ACTIVE"
		_current_mission_id = mission_id
		mission_state_changed.emit(mission_id, "ACTIVE")
		return


func _prerequisites_completed(definition: Dictionary) -> bool:
	var prerequisites: Variant = definition.get("prerequisites", [])
	if not prerequisites is Array:
		return false
	for prerequisite: Variant in prerequisites:
		if not is_mission_completed(String(prerequisite)):
			return false
	return true


func _prerequisites_completed_for_data(definition: Dictionary, states: Dictionary) -> bool:
	var prerequisites: Variant = definition.get("prerequisites", [])
	if not prerequisites is Array:
		return false
	for prerequisite: Variant in prerequisites:
		if String(states.get(String(prerequisite), "LOCKED")) != "COMPLETED":
			return false
	return true


func _find_definition(mission_id: String) -> Dictionary:
	for definition: Dictionary in _definitions:
		if String(definition.get("id", "")) == mission_id:
			return definition
	return {}


func _load_definitions() -> void:
	_definitions.clear()
	var file: FileAccess = FileAccess.open(MISSION_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open mission definitions: %s" % MISSION_DATA_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Array:
		push_error("Mission definitions must be a JSON array.")
		return

	var seen_ids: Dictionary = {}
	for raw_definition: Variant in parsed:
		if not raw_definition is Dictionary:
			push_warning("Skipping invalid mission definition.")
			continue
		var definition: Dictionary = raw_definition
		var mission_id: String = String(definition.get("id", ""))
		var event_type: String = String(definition.get("objective_event", ""))
		var source_id: String = String(definition.get("objective_source", ""))
		var target_node_name: String = String(definition.get("target_node_name", ""))
		if mission_id.is_empty() or event_type.is_empty() or source_id.is_empty() or target_node_name.is_empty() or seen_ids.has(mission_id):
			push_error("Invalid or duplicate mission definition: %s" % mission_id)
			continue
		if int(definition.get("reward", -1)) < 0:
			push_error("Mission reward cannot be negative: %s" % mission_id)
			continue
		seen_ids[mission_id] = true
		_definitions.append(definition.duplicate(true))

	for definition: Dictionary in _definitions:
		var next_id: String = String(definition.get("next_mission", ""))
		if not next_id.is_empty() and not seen_ids.has(next_id):
			push_error("Mission '%s' references missing next mission '%s'." % [definition["id"], next_id])
