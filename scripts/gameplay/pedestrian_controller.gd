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
@export_range(0.8, 4.0, 0.1) var obstacle_look_ahead: float = 2.0
@export_range(0.6, 2.5, 0.1) var crowd_avoidance_radius: float = 1.45
@export_range(0.0, 2.0, 0.1) var crowd_avoidance_weight: float = 1.1
@export_range(2.0, 12.0, 0.5) var steering_turn_speed: float = 5.5
@export_range(2.0, 16.0, 0.5) var acceleration: float = 8.5
@export_range(2.0, 20.0, 0.5) var deceleration: float = 11.0
@export_flags_3d_physics var obstacle_collision_mask: int = 1
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

	var camera: Camera3D = get_viewport().get_camera_3d()
	var near_camera: bool = (
		is_instance_valid(camera)
		and camera.global_position.distance_squared_to(global_position)
		<= detailed_simulation_distance * detailed_simulation_distance
	)
	var near_player: bool = (
		is_instance_valid(player)
		and _flat_distance_to(player.global_position) <= detailed_simulation_distance
	)

	if direction.length_squared() > 0.001:
		direction = _avoid_obstacles(direction)
		if near_camera or near_player:
			direction = _apply_crowd_separation(direction)
		if direction.length_squared() > 0.001:
			direction = direction.normalized()
			_face_direction(direction, delta)
			velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
			velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
			velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

	# Keep physics/collision active at every distance. Skipping move_and_slide
	# off-screen allowed pedestrians to cross building and district boundaries.
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()


func get_ai_state() -> String:
	return "ALERT" if _ai_state == AIState.ALERT else "PATROL"


func get_route_index() -> int:
	return _route_index


func _get_patrol_direction() -> Vector3:
	if route_points.size() < 2:
		return Vector3.ZERO

	var parent_3d: Node3D = get_parent() as Node3D
	if parent_3d == null:
		return Vector3.ZERO
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


func _avoid_obstacles(desired_direction: Vector3) -> Vector3:
	var forward: Vector3 = desired_direction.normalized()
	if not _ray_has_obstacle(forward, obstacle_look_ahead):
		return forward

	# Test both shoulders before steering. The deterministic preference prevents
	# two agents repeatedly swapping sides while approaching the same obstacle.
	var left: Vector3 = forward.rotated(Vector3.UP, deg_to_rad(58.0)).normalized()
	var right: Vector3 = forward.rotated(Vector3.UP, deg_to_rad(-58.0)).normalized()
	var left_blocked: bool = _ray_has_obstacle(left, obstacle_look_ahead * 0.9)
	var right_blocked: bool = _ray_has_obstacle(right, obstacle_look_ahead * 0.9)
	if not left_blocked and not right_blocked:
		var prefer_left: bool = get_instance_id() % 2 == 0
		return (forward * 0.42 + (left if prefer_left else right) * 0.88).normalized()
	if not left_blocked:
		return (forward * 0.28 + left * 0.96).normalized()
	if not right_blocked:
		return (forward * 0.28 + right * 0.96).normalized()

	# A narrow blockage should cause a brief, safe wait instead of tunnelling.
	return Vector3.ZERO


func _ray_has_obstacle(direction: Vector3, distance: float) -> bool:
	if direction.length_squared() < 0.001:
		return false
	var ray_origin: Vector3 = global_position + Vector3.UP * 0.9
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + direction.normalized() * distance,
		obstacle_collision_mask
	)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	return not hit.is_empty()


func _apply_crowd_separation(desired_direction: Vector3) -> Vector3:
	var separation: Vector3 = Vector3.ZERO
	var neighbours: Array[Node] = get_tree().get_nodes_in_group("pedestrians")
	neighbours.append_array(get_tree().get_nodes_in_group("police"))
	for candidate: Node in neighbours:
		if candidate == self or not candidate is Node3D:
			continue
		var other: Node3D = candidate as Node3D
		var away: Vector3 = global_position - other.global_position
		away.y = 0.0
		var distance: float = away.length()
		if distance < 0.01 or distance >= crowd_avoidance_radius:
			continue
		# Ignore agents directly behind so crowd separation does not reverse
		# the route direction or create a stop-start oscillation.
		if desired_direction.dot(-away.normalized()) < -0.35:
			continue
		separation += away.normalized() * (1.0 - distance / crowd_avoidance_radius)

	if separation.length_squared() < 0.001:
		return desired_direction
	return (desired_direction + separation.normalized() * crowd_avoidance_weight).normalized()


func _flat_distance_to(target: Vector3) -> float:
	var offset: Vector3 = target - global_position
	offset.y = 0.0
	return offset.length()


func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.01:
		return
	var target_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, clampf(steering_turn_speed * delta, 0.0, 1.0))


func _set_state(next_state: AIState) -> void:
	if _ai_state == next_state:
		return
	_ai_state = next_state
	ai_state_changed.emit(get_ai_state())


func _apply_clothing_color() -> void:
	if _body_mesh.has_method("set_clothing_color"):
		_body_mesh.call("set_clothing_color", clothing_color)
