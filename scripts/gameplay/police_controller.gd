extends CharacterBody3D

signal ai_state_changed(state_name: String)

@export var route_points: PackedVector3Array = PackedVector3Array()
@export var initial_waypoint_index: int = 0
@export var patrol_speed: float = 2.2
@export var pursuit_speed: float = 5.4
@export var search_speed: float = 2.8
@export var vision_range: float = 30.0
@export_range(0.5, 4.0, 0.1) var stop_distance: float = 1.6
@export_range(0.5, 4.0, 0.1) var investigation_arrival_radius: float = 1.15
@export_range(0.5, 5.0, 0.1) var investigation_scan_speed: float = 1.8
@export_range(0.1, 1.5, 0.05) var investigation_scan_angle: float = 0.58
@export_range(0.5, 4.0, 0.1) var obstacle_look_ahead: float = 2.2
@export_flags_3d_physics var obstacle_collision_mask: int = 1
@export_range(2.0, 14.0, 0.5) var acceleration: float = 8.5
@export_range(2.0, 18.0, 0.5) var deceleration: float = 10.5
@export var turn_speed: float = 4.0
@export var attack_range: float = 2.0
@export var attack_damage: int = 12
@export var attack_cooldown_ms: int = 1500

var _ai_state: String = "PATROL"
var _route_index: int = 0
var _last_attack_msec: int = -1500
var _search_arrived_at_target: bool = false
var _search_scan_elapsed: float = 0.0
var _search_scan_origin_yaw: float = 0.0
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

@onready var _wanted_system: Node = get_node("/root/WantedSystem")
@onready var _body_mesh: Node3D = $BodyMesh


func _ready() -> void:
	add_to_group("police")
	_route_index = wrapi(initial_waypoint_index, 0, maxi(route_points.size(), 1))
	_apply_police_material()


func _physics_process(delta: float) -> void:
	var player_node: Node = get_tree().get_first_node_in_group("player")
	var player: Node3D = player_node as Node3D
	var wanted_level: int = int(_wanted_system.call("get_wanted_level"))
	var sees_player: bool = (
		wanted_level > 0
		and is_instance_valid(player)
		and _has_line_of_sight(player)
	)

	var reported_position: Vector3 = (
		player.global_position if is_instance_valid(player)
		else Vector3.ZERO
	)
	_wanted_system.call(
		"register_police_detection",
		get_instance_id(),
		sees_player,
		reported_position
	)

	var direction: Vector3 = Vector3.ZERO
	var movement_speed: float = 0.0
	var target_to_ignore: Node3D

	if wanted_level <= 0 or not is_instance_valid(player):
		_set_ai_state("PATROL")
		direction = _get_patrol_direction()
		movement_speed = patrol_speed
		_search_arrived_at_target = false
	elif sees_player:
		_set_ai_state("PURSUIT")
		_search_arrived_at_target = false
		_search_scan_elapsed = 0.0
		target_to_ignore = player
		var to_player: Vector3 = player.global_position - global_position
		to_player.y = 0.0
		var player_in_vehicle: bool = (
			player.has_method("is_in_vehicle")
			and bool(player.call("is_in_vehicle"))
		)
		# Do not run directly into the player when the melee attack is available.
		# Still approach occupied vehicles because on-foot attacks are disabled there.
		if to_player.length() > stop_distance or player_in_vehicle:
			direction = to_player
			movement_speed = pursuit_speed
	else:
		var wanted_state: String = String(_wanted_system.call("get_state_name"))
		if wanted_state == "SEARCHING" or wanted_state == "PURSUIT":
			_set_ai_state("SEARCHING")
			var last_known_position: Vector3 = _wanted_system.call("get_last_known_player_position")
			var to_last_known: Vector3 = last_known_position - global_position
			to_last_known.y = 0.0
			if to_last_known.length() > investigation_arrival_radius:
				direction = to_last_known
				movement_speed = search_speed
				_search_arrived_at_target = false
				_search_scan_elapsed = 0.0
			else:
				# Reaching the last-known position starts a bounded-looking scan
				# instead of keeping a permanent velocity pointed at a zero-length vector.
				if not _search_arrived_at_target:
					_search_arrived_at_target = true
					_search_scan_elapsed = 0.0
					_search_scan_origin_yaw = rotation.y
				else:
					_search_scan_elapsed += delta
				var scan_yaw: float = _search_scan_origin_yaw + sin(
					_search_scan_elapsed * investigation_scan_speed
				) * investigation_scan_angle
				rotation.y = lerp_angle(
					rotation.y,
				scan_yaw,
				clampf(turn_speed * delta, 0.0, 1.0)
			)
		else:
			_set_ai_state("PATROL")
			direction = _get_patrol_direction()
			movement_speed = patrol_speed
			_search_arrived_at_target = false

	if direction.length_squared() > 0.01:
		direction = _steer_around_obstacles(direction, target_to_ignore)

	if sees_player:
		try_attack_player(player)

	_apply_motion(direction, movement_speed, delta)


func get_ai_state() -> String:
	return _ai_state


func get_route_index() -> int:
	return _route_index


func _has_line_of_sight(player: Node3D) -> bool:
	var target_distance: float = global_position.distance_to(player.global_position)
	if target_distance > vision_range:
		return false

	var origin: Vector3 = global_position + Vector3.UP * 1.15
	var target: Vector3 = player.global_position + Vector3.UP * 1.05
	var query := PhysicsRayQueryParameters3D.create(origin, target, 1)
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return true

	var hit_node: Node = result.get("collider") as Node
	while is_instance_valid(hit_node):
		if hit_node == player:
			return true
		hit_node = hit_node.get_parent()

	return false


func try_attack_player(player: Node3D) -> bool:
	if not is_instance_valid(player) or not player.has_method("is_incapacitated"):
		return false
	if bool(player.call("is_incapacitated")) or bool(player.call("is_in_vehicle")):
		return false
	if int(_wanted_system.call("get_wanted_level")) <= 0:
		return false
	if global_position.distance_to(player.global_position) > attack_range:
		return false
	if not _has_line_of_sight(player):
		return false

	var now_msec: int = Time.get_ticks_msec()
	if now_msec - _last_attack_msec < attack_cooldown_ms:
		return false

	var damageable: Node = player.get_node_or_null("Damageable")
	if not is_instance_valid(damageable):
		return false

	_last_attack_msec = now_msec
	damageable.call("apply_damage", attack_damage, self)
	return true


func _get_patrol_direction() -> Vector3:
	if route_points.size() < 2:
		return Vector3.ZERO

	var parent_3d: Node3D = get_parent() as Node3D
	var target: Vector3 = parent_3d.to_global(route_points[_route_index])
	target.y = global_position.y
	var offset: Vector3 = target - global_position
	offset.y = 0.0

	if offset.length() < 1.6:
		_route_index = (_route_index + 1) % route_points.size()
		target = parent_3d.to_global(route_points[_route_index])
		target.y = global_position.y
		offset = target - global_position
		offset.y = 0.0

	return offset.normalized() if offset.length_squared() > 0.001 else Vector3.ZERO


func _steer_around_obstacles(desired_direction: Vector3, target_to_ignore: Node3D = null) -> Vector3:
	var forward: Vector3 = desired_direction.normalized()
	if not _ray_has_obstacle(forward, obstacle_look_ahead, target_to_ignore):
		return forward

	var left: Vector3 = forward.rotated(Vector3.UP, deg_to_rad(55.0)).normalized()
	var right: Vector3 = forward.rotated(Vector3.UP, deg_to_rad(-55.0)).normalized()
	var left_blocked: bool = _ray_has_obstacle(left, obstacle_look_ahead * 0.9, target_to_ignore)
	var right_blocked: bool = _ray_has_obstacle(right, obstacle_look_ahead * 0.9, target_to_ignore)
	if not left_blocked and not right_blocked:
		var prefer_left: bool = get_instance_id() % 2 == 0
		return (forward * 0.4 + (left if prefer_left else right) * 0.9).normalized()
	if not left_blocked:
		return (forward * 0.28 + left * 0.96).normalized()
	if not right_blocked:
		return (forward * 0.28 + right * 0.96).normalized()
	return Vector3.ZERO


func _ray_has_obstacle(direction: Vector3, distance: float, target_to_ignore: Node3D = null) -> bool:
	if direction.length_squared() < 0.001:
		return false
	var ray_origin: Vector3 = global_position + Vector3.UP * 0.9
	var exclusions: Array[RID] = [get_rid()]
	if is_instance_valid(target_to_ignore) and target_to_ignore is CollisionObject3D:
		exclusions.append((target_to_ignore as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + direction.normalized() * distance,
		obstacle_collision_mask
	)
	query.exclude = exclusions
	query.collide_with_areas = false
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _apply_motion(direction: Vector3, movement_speed: float, delta: float) -> void:
	if direction.length_squared() > 0.01 and movement_speed > 0.01:
		direction = direction.normalized()
		velocity.x = move_toward(velocity.x, direction.x * movement_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * movement_speed, acceleration * delta)
		var target_yaw: float = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()


func _set_ai_state(next_state: String) -> void:
	if _ai_state == next_state:
		return
	if next_state == "SEARCHING":
		_search_arrived_at_target = false
		_search_scan_elapsed = 0.0
	_ai_state = next_state
	ai_state_changed.emit(_ai_state)


func _apply_police_material() -> void:
	if _body_mesh.has_method("set_clothing_color"):
		_body_mesh.call("set_clothing_color", Color(0.035, 0.11, 0.23, 1.0))
