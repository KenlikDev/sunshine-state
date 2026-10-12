extends CharacterBody3D

signal ai_state_changed(state_name: String)

enum RouteAxis { NORTH_SOUTH, EAST_WEST }

@export var route_points: PackedVector3Array = PackedVector3Array()
@export var route_axis: RouteAxis = RouteAxis.NORTH_SOUTH
@export var start_at_end: bool = false
@export var cruise_speed: float = 5.0
@export var turn_speed: float = 3.8
@export var offscreen_distance: float = 55.0
@export var obstacle_recovery_delay: float = 3.0
@export var reverse_recovery_duration: float = 1.1
@export var body_color: Color = Color(0.23, 0.48, 0.72, 1.0)

var _route_index: int = 1
var _route_direction: int = 1
var _stalled_seconds: float = 0.0
var _reverse_remaining: float = 0.0
var _ai_state: String = "DRIVING"
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

@onready var _obstacle_ray: RayCast3D = $ObstacleRay
@onready var _body_mesh: MeshInstance3D = $BodyMesh


func _ready() -> void:
	add_to_group("traffic_vehicles")
	_obstacle_ray.add_exception(self)
	if start_at_end and route_points.size() >= 2:
		_route_index = route_points.size() - 2
		_route_direction = -1
	else:
		_route_index = 1
		_route_direction = 1
	_apply_body_color()
	_create_wheel_visuals()


func _physics_process(delta: float) -> void:
	if route_points.size() < 2:
		velocity = Vector3.ZERO
		return

	var direction: Vector3 = _get_route_direction()
	var yielding: bool = _should_yield_for_intersection()
	var near_camera: bool = _is_near_camera()
	var blocked: bool = false

	if near_camera:
		_obstacle_ray.force_raycast_update()
		if _obstacle_ray.is_colliding():
			var collider: Object = _obstacle_ray.get_collider()
			if collider is Node and collider != self:
				blocked = true

	if _reverse_remaining > 0.0:
		_reverse_remaining = maxf(0.0, _reverse_remaining - delta)
		_set_ai_state("RECOVERING")
		direction = -global_transform.basis.z
		direction.y = 0.0
		direction = direction.normalized()
		velocity.x = direction.x * 1.5
		velocity.z = direction.z * 1.5
	elif yielding:
		_stalled_seconds = 0.0
		_set_ai_state("YIELDING")
		velocity.x = 0.0
		velocity.z = 0.0
	elif blocked:
		_stalled_seconds += delta
		_set_ai_state("WAITING")
		velocity.x = 0.0
		velocity.z = 0.0
		if _stalled_seconds >= obstacle_recovery_delay:
			_stalled_seconds = 0.0
			_reverse_remaining = reverse_recovery_duration
	else:
		_stalled_seconds = 0.0
		_set_ai_state("DRIVING")
		var speed_scale: float = 1.0 if near_camera else 0.8
		velocity.x = direction.x * cruise_speed * speed_scale
		velocity.z = direction.z * cruise_speed * speed_scale
		_face_direction(direction, delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	move_and_slide()


func get_ai_state() -> String:
	return _ai_state


func get_route_index() -> int:
	return _route_index


func get_stalled_seconds() -> float:
	return _stalled_seconds


func _get_route_direction() -> Vector3:
	var parent_3d: Node3D = get_parent() as Node3D
	var target: Vector3 = parent_3d.to_global(route_points[_route_index])
	target.y = global_position.y
	var offset: Vector3 = target - global_position
	offset.y = 0.0

	if offset.length() < 2.2:
		_route_index += _route_direction
		if _route_index >= route_points.size():
			_route_direction = -1
			_route_index = route_points.size() - 2
		elif _route_index < 0:
			_route_direction = 1
			_route_index = 1

		target = parent_3d.to_global(route_points[_route_index])
		target.y = global_position.y
		offset = target - global_position
		offset.y = 0.0

	return offset.normalized() if offset.length_squared() > 0.001 else Vector3.ZERO


func _should_yield_for_intersection() -> bool:
	if route_axis != RouteAxis.EAST_WEST:
		return false
	if absf(global_position.x) > 10.0 or absf(global_position.z) > 7.0:
		return false

	for other: Node in get_tree().get_nodes_in_group("traffic_vehicles"):
		if other == self or not other is Node3D:
			continue
		if int(other.get("route_axis")) != RouteAxis.NORTH_SOUTH:
			continue
		if absf((other as Node3D).global_position.x) < 8.0 and absf((other as Node3D).global_position.z) < 20.0:
			return true
	return false


func _is_near_camera() -> bool:
	var camera: Camera3D = get_viewport().get_camera_3d()
	return (
		is_instance_valid(camera)
		and camera.global_position.distance_squared_to(global_position)
		<= offscreen_distance * offscreen_distance
	)


func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.01:
		return
	var desired_yaw: float = atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, desired_yaw, clampf(turn_speed * delta, 0.0, 1.0))


func _set_ai_state(next_state: String) -> void:
	if _ai_state == next_state:
		return
	_ai_state = next_state
	ai_state_changed.emit(_ai_state)


func _apply_body_color() -> void:
	var source: StandardMaterial3D = _body_mesh.material_override as StandardMaterial3D
	if source == null:
		source = StandardMaterial3D.new()
	var material: StandardMaterial3D = source.duplicate() as StandardMaterial3D
	material.albedo_color = body_color
	_body_mesh.material_override = material


func _create_wheel_visuals() -> void:
	var tire_material := StandardMaterial3D.new()
	tire_material.albedo_color = Color(0.055, 0.06, 0.065, 1.0)
	tire_material.roughness = 1.0

	for position: Vector3 in [
		Vector3(-0.77, -0.22, -1.1),
		Vector3(0.77, -0.22, -1.1),
		Vector3(-0.77, -0.22, 1.1),
		Vector3(0.77, -0.22, 1.1)
	]:
		var tire_mesh := CylinderMesh.new()
		tire_mesh.top_radius = 0.26
		tire_mesh.bottom_radius = 0.26
		tire_mesh.height = 0.18
		tire_mesh.radial_segments = 12
		var tire := MeshInstance3D.new()
		tire.name = "TrafficWheel"
		tire.position = position
		tire.rotation_degrees.z = 90.0
		tire.mesh = tire_mesh
		tire.material_override = tire_material
		add_child(tire)
