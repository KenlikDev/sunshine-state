extends Node

@export var duration_seconds: float = 900.0
@export var sample_interval_seconds: float = 5.0
@export var pedestrian_stall_limit_seconds: float = 35.0
@export var traffic_stall_limit_seconds: float = 60.0
@export var yielding_stall_limit_seconds: float = 90.0

var _failures: Array[String] = []
var _elapsed_seconds: float = 0.0
var _last_positions: Dictionary = {}
var _stationary_seconds: Dictionary = {}


func _ready() -> void:
	call_deferred("_run_soak_test")


func _run_soak_test() -> void:
	var main_scene: PackedScene = load("res://scenes/bootstrap/main.tscn")
	if main_scene == null:
		quit(1)
		return

	var instance: Node = main_scene.instantiate()
	add_child(instance)
	for _frame: int in range(8):
		await get_tree().physics_frame

	if not _validate_population():
		_finish(instance)
		return

	print(
		"Living-district soak started: duration=", duration_seconds,
		"s sample_interval=", sample_interval_seconds, "s"
	)

	while _elapsed_seconds < duration_seconds and _failures.is_empty():
		var step_seconds: float = minf(
			sample_interval_seconds,
			duration_seconds - _elapsed_seconds
		)
		await get_tree().create_timer(step_seconds).timeout
		_elapsed_seconds += step_seconds
		_sample_group("pedestrians", 4, pedestrian_stall_limit_seconds, false, step_seconds)
		_sample_group("traffic_vehicles", 4, traffic_stall_limit_seconds, true, step_seconds)

		if int(_elapsed_seconds) % 60 < int(step_seconds):
			print(
				"Living-district soak progress: ",
				int(_elapsed_seconds), "/", int(duration_seconds),
				"s pedestrians=", get_tree().get_nodes_in_group("pedestrians").size(),
				" traffic=", get_tree().get_nodes_in_group("traffic_vehicles").size()
			)

	if _failures.is_empty():
		print("Living-district soak passed: no population growth, boundary escape, or prolonged route stall observed.")
		_finish(instance)
	else:
		for failure: String in _failures:
			push_error(failure)
		_finish(instance, 1)


func _validate_population() -> bool:
	var pedestrians: Array[Node] = get_tree().get_nodes_in_group("pedestrians")
	var traffic: Array[Node] = get_tree().get_nodes_in_group("traffic_vehicles")
	if pedestrians.size() != 4:
		_failures.append("Expected exactly four pedestrians at soak start; found %s." % pedestrians.size())
	if traffic.size() != 4:
		_failures.append("Expected exactly four traffic agents at soak start; found %s." % traffic.size())
	return _failures.is_empty()


func _sample_group(
	group_name: String,
	expected_count: int,
	stall_limit: float,
	is_traffic: bool,
	step_seconds: float
) -> void:
	var agents: Array[Node] = get_tree().get_nodes_in_group(group_name)
	if agents.size() != expected_count:
		_failures.append(
			"Population changed in group '%s': expected %s, found %s at %.1f seconds."
			% [group_name, expected_count, agents.size(), _elapsed_seconds]
		)
		return

	for agent: Node in agents:
		if not agent is Node3D:
			_failures.append("Non-3D agent found in group '%s'." % group_name)
			continue

		var agent_3d: Node3D = agent as Node3D
		var agent_id: int = agent.get_instance_id()
		var position: Vector3 = agent_3d.global_position
		var previous: Vector3 = _last_positions.get(agent_id, position)
		var stationary: float = float(_stationary_seconds.get(agent_id, 0.0))

		if position.distance_to(previous) > 0.45:
			stationary = 0.0
		else:
			stationary += step_seconds

		_last_positions[agent_id] = position
		_stationary_seconds[agent_id] = stationary

		if absf(position.x) >= 88.0 or absf(position.z) >= 78.0:
			_failures.append(
				"Agent '%s' left the authored district bounds at %.1f seconds."
				% [agent.name, _elapsed_seconds]
			)

		var state_name: String = String(agent.call("get_ai_state"))
		var allowed_stall: float = yielding_stall_limit_seconds if is_traffic and state_name == "YIELDING" else stall_limit
		if stationary > allowed_stall:
			_failures.append(
				"Agent '%s' remained stationary for %.1f seconds (state=%s)."
				% [agent.name, stationary, state_name]
			)


func _finish(instance: Node, exit_code: int = 0) -> void:
	instance.queue_free()
	await get_tree().process_frame
	get_tree().quit(exit_code)
