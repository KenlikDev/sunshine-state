extends CharacterBody3D

signal ai_state_changed(state_name: String)

@export var route_points: PackedVector3Array = PackedVector3Array()
@export var initial_waypoint_index: int = 0
@export var patrol_speed: float = 2.2
@export var pursuit_speed: float = 5.4
@export var search_speed: float = 2.8
@export var vision_range: float = 30.0
@export var stop_distance: float = 1.6
@export var turn_speed: float = 4.0

var _ai_state: String = "PATROL"
var _route_index: int = 0
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

@onready var _wanted_system: Node = get_node("/root/WantedSystem")
@onready var _body_mesh: MeshInstance3D = $BodyMesh


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

	if wanted_level <= 0 or not is_instance_valid(player):
		_set_ai_state("PATROL")
		direction = _get_patrol_direction()
		movement_speed = patrol_speed
	else:
		var wanted_state: String = String(_wanted_system.call("get_state_name"))
		if sees_player:
			_set_ai_state("PURSUIT")
			direction = player.global_position - global_position
			direction.y = 0.0
			movement_speed = pursuit_speed
		elif wanted_state == "SEARCHING" or wanted_state == "PURSUIT":
			_set_ai_state("SEARCHING")
			direction = Vector3(
				(_wanted_system.call("get_last_known_player_position") as Vector3)
				- global_position
			)
			direction.y = 0.0
			movement_speed = search_speed
		else:
			_set_ai_state("PATROL")
			direction = _get_patrol_direction()
			movement_speed = patrol_speed

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


func _apply_motion(direction: Vector3, movement_speed: float, delta: float) -> void:
	if direction.length_squared() > 0.01:
		direction = direction.normalized()
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
		var target_yaw: float = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, patrol_speed * delta * 3.0)
		velocity.z = move_toward(velocity.z, 0.0, patrol_speed * delta * 3.0)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()


func _set_ai_state(next_state: String) -> void:
	if _ai_state == next_state:
		return
	_ai_state = next_state
	ai_state_changed.emit(_ai_state)


func _apply_police_material() -> void:
	var source: StandardMaterial3D = _body_mesh.material_override as StandardMaterial3D
	if source == null:
		source = StandardMaterial3D.new()
	var material: StandardMaterial3D = source.duplicate() as StandardMaterial3D
	material.albedo_color = Color(0.08, 0.17, 0.36, 1.0)
	_body_mesh.material_override = material
