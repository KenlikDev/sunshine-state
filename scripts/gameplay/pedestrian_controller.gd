extends CharacterBody3D

signal ai_state_changed(state_name: String)

enum AIState { PATROL, ALERT }

@export var route_points: PackedVector3Array = PackedVector3Array()
@export_range(0, 31) var initial_waypoint_index: int = 0
@export var patrol_speed: float = 1.45
@export var alert_speed: float = 3.3
@export var alert_radius: float = 4.2
@export var alert_duration: float = 2.25
@export var detailed_simulation_distance: float = 45.0
@export var clothing_color: Color = Color(0.77, 0.48, 0.24, 1.0)

var _ai_state: AIState = AIState.PATROL
var _route_index: int = 0
var _alert_time_remaining: float = 0.0
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

@onready var _body_mesh: Node3D = $MeshInstance3D


func _ready() -> void:
	add_to_group("pedestrians")
	_route_index = wrapi(initial_waypoint_index + 1, 0, maxi(route_points.size(), 1))
	_apply_clothing_color()


func _physics_process(delta: float) -> void:
	var player_node: Node = get_tree().get_first_node_in_group("player")
	var player: Node3D = player_node as Node3D
	var close_to_player: bool = (
		is_instance_valid(player)
		and _flat_distance_to(player.global_position) <= alert_radius
	)

	if close_to_player:
		_set_state(AIState.ALERT)
		_alert_time_remaining = alert_duration
	elif _ai_state == AIState.ALERT:
		_alert_time_remaining = maxf(0.0, _alert_time_remaining - delta)
		if _alert_time_remaining <= 0.0:
			_set_state(AIState.PATROL)

	var direction: Vector3 = Vector3.ZERO
	var move_speed: float = patrol_speed

	if _ai_state == AIState.ALERT and is_instance_valid(player):
		direction = global_position - player.global_position
		direction.y = 0.0
		if direction.length_squared() < 0.01:
			direction = Vector3.RIGHT
		direction = direction.normalized()
		move_speed = alert_speed
	else:
		direction = _get_patrol_direction()

	if direction.length_squared() < 0.001:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var camera: Camera3D = get_viewport().get_camera_3d()
	var near_camera: bool = (
		is_instance_valid(camera)
		and camera.global_position.distance_squared_to(global_position)
		<= detailed_simulation_distance * detailed_simulation_distance
	)
	var near_player: bool = is_instance_valid(player) and _flat_distance_to(player.global_position) < alert_radius + 6.0

	if not near_camera and not near_player:
		global_position += direction * move_speed * delta
		return

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	move_and_slide()
	_face_direction(direction)


func get_ai_state() -> String:
	return "ALERT" if _ai_state == AIState.ALERT else "PATROL"


func get_route_index() -> int:
	return _route_index


func _get_patrol_direction() -> Vector3:
	if route_points.size() < 2:
		return Vector3.ZERO

	var parent_3d: Node3D = get_parent() as Node3D
	var target: Vector3 = parent_3d.to_global(route_points[_route_index])
	target.y = global_position.y
	var offset: Vector3 = target - global_position
	offset.y = 0.0

	if offset.length() < 0.8:
		_route_index = (_route_index + 1) % route_points.size()
		target = parent_3d.to_global(route_points[_route_index])
		target.y = global_position.y
		offset = target - global_position
		offset.y = 0.0

	return offset.normalized() if offset.length_squared() > 0.001 else Vector3.ZERO


func _flat_distance_to(target: Vector3) -> float:
	var offset: Vector3 = target - global_position
	offset.y = 0.0
	return offset.length()


func _face_direction(direction: Vector3) -> void:
	if direction.length_squared() < 0.01:
		return
	look_at(global_position + direction, Vector3.UP)


func _set_state(next_state: AIState) -> void:
	if _ai_state == next_state:
		return
	_ai_state = next_state
	ai_state_changed.emit(get_ai_state())


func _apply_clothing_color() -> void:
	if _body_mesh.has_method("set_clothing_color"):
		_body_mesh.call("set_clothing_color", clothing_color)
