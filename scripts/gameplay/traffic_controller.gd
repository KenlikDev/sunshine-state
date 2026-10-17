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
@export_range(1.0, 15.0, 0.5) var intersection_yield_timeout_seconds: float = 4.5
@export var body_color: Color = Color(0.23, 0.48, 0.72, 1.0)

var _route_index: int = 1
var _route_direction: int = 1
var _stalled_seconds: float = 0.0
var _reverse_remaining: float = 0.0
var _yielding_seconds: float = 0.0
var _ai_state: String = "DRIVING"
var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _headlight_nodes: Array[MeshInstance3D] = []
var _taillight_nodes: Array[MeshInstance3D] = []
var _headlight_material: StandardMaterial3D
var _taillight_material: StandardMaterial3D
var _night_factor: float = 0.0

@onready var _obstacle_ray: RayCast3D = $ObstacleRay
@onready var _body_mesh: MeshInstance3D = $BodyMesh


func _ready() -> void:
	# Traffic is its own layer: players and drivable cars collide with it, but it cannot block patrol pedestrians.
	collision_layer = 2
	collision_mask = 1
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
	_create_signal_lights()
	_connect_day_night_cycle()


func _physics_process(delta: float) -> void:
	if route_points.size() < 2:
		velocity = Vector3.ZERO
		return

	var frame_start_position: Vector3 = global_position
	var was_recovering: bool = _reverse_remaining > 0.0
	var direction: Vector3 = _get_route_direction()
	var conflict_requires_yield: bool = _should_yield_for_intersection()
	if conflict_requires_yield:
		_yielding_seconds = minf(_yielding_seconds + delta, intersection_yield_timeout_seconds)
	else:
		_yielding_seconds = 0.0
	var yielding: bool = conflict_requires_yield and _yielding_seconds < intersection_yield_timeout_seconds
	var near_camera: bool = _is_near_camera()
	var blocked: bool = false

	var yield_timeout_elapsed: bool = (
		conflict_requires_yield
		and _yielding_seconds >= intersection_yield_timeout_seconds
	)
	if near_camera:
		_obstacle_ray.force_raycast_update()
		if _obstacle_ray.is_colliding():
			var collider: Object = _obstacle_ray.get_collider()
			if collider is Node and collider != self:
				blocked = not (
					yield_timeout_elapsed
					and _is_timed_out_cross_traffic(collider as Node)
				)

	if _reverse_remaining > 0.0:
		_reverse_remaining = maxf(0.0, _reverse_remaining - delta)
		_set_ai_state("RECOVERING")
		direction = global_transform.basis.z
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

	# Off-screen traffic skips ray-based avoidance, so physical collision stalls
	# need their own bounded recovery path instead of remaining in DRIVING forever.
	if not was_recovering and not yielding and not blocked:
		var horizontal_step: float = Vector2(
			global_position.x - frame_start_position.x,
			global_position.z - frame_start_position.z
		).length()
		if direction.length_squared() > 0.1 and horizontal_step < maxf(0.025, cruise_speed * delta * 0.15):
			_stalled_seconds += delta
			if _stalled_seconds >= obstacle_recovery_delay:
				_stalled_seconds = 0.0
				_reverse_remaining = reverse_recovery_duration
				_set_ai_state("WAITING")
		else:
			_stalled_seconds = 0.0


func get_ai_state() -> String:
	return _ai_state


func get_route_index() -> int:
	return _route_index


func get_stalled_seconds() -> float:
	return _stalled_seconds


func get_yielding_seconds() -> float:
	return _yielding_seconds


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


func _is_timed_out_cross_traffic(candidate: Node) -> bool:
	if not candidate.is_in_group("traffic_vehicles"):
		return false
	if int(candidate.get("route_axis")) != RouteAxis.NORTH_SOUTH:
		return false
	if not candidate is Node3D:
		return false
	var candidate_position: Vector3 = (candidate as Node3D).global_position
	return absf(candidate_position.x) < 8.0 and absf(candidate_position.z) < 20.0


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
	_update_brake_lights()
	ai_state_changed.emit(_ai_state)


func _apply_body_color() -> void:
	var source: StandardMaterial3D = _body_mesh.material_override as StandardMaterial3D
	if source == null:
		source = StandardMaterial3D.new()
	var material: StandardMaterial3D = source.duplicate() as StandardMaterial3D
	material.albedo_color = body_color
	_body_mesh.material_override = material


func _create_signal_lights() -> void:
	_headlight_material = StandardMaterial3D.new()
	_headlight_material.albedo_color = Color(1.0, 0.91, 0.69, 1.0)
	_headlight_material.roughness = 0.3
	_headlight_material.emission_enabled = true
	_headlight_material.emission = Color(1.0, 0.82, 0.48, 1.0)
	_headlight_material.emission_energy_multiplier = 1.6

	_taillight_material = StandardMaterial3D.new()
	_taillight_material.albedo_color = Color(0.55, 0.025, 0.018, 1.0)
	_taillight_material.roughness = 0.36
	_taillight_material.emission_enabled = true
	_taillight_material.emission = Color(0.95, 0.025, 0.012, 1.0)
	_taillight_material.emission_energy_multiplier = 0.55

	for side: float in [-1.0, 1.0]:
		_headlight_nodes.append(
			_add_signal_lamp(
				"Headlight" + ("Left" if side < 0.0 else "Right"),
				Vector3(side * 0.53, 0.15, -1.79),
				Vector3(0.25, 0.13, 0.045),
				_headlight_material
			)
		)
		_taillight_nodes.append(
			_add_signal_lamp(
				"Taillight" + ("Left" if side < 0.0 else "Right"),
				Vector3(side * 0.57, 0.13, 1.79),
				Vector3(0.22, 0.15, 0.045),
				_taillight_material
			)
		)


func _add_signal_lamp(
	node_name: String,
	local_position: Vector3,
	dimensions: Vector3,
	material: StandardMaterial3D
) -> MeshInstance3D:
	var lamp_mesh := BoxMesh.new()
	lamp_mesh.size = dimensions
	var lamp := MeshInstance3D.new()
	lamp.name = node_name
	lamp.mesh = lamp_mesh
	lamp.position = local_position
	lamp.material_override = material
	lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lamp)
	return lamp


func _connect_day_night_cycle() -> void:
	var world: Node = get_parent()
	if world == null:
		return
	var cycle: Node = world.get_node_or_null("DayNightCycle")
	if cycle == null or not cycle.has_signal("time_of_day_changed"):
		return
	cycle.time_of_day_changed.connect(_apply_day_night_lights)
	if cycle.has_method("get_time_of_day"):
		_apply_day_night_lights(float(cycle.call("get_time_of_day")))


func _apply_day_night_lights(hour: float) -> void:
	var solar_angle: float = TAU * (hour - 6.0) / 24.0
	var daylight: float = clampf((sin(solar_angle) + 0.15) / 0.78, 0.0, 1.0)
	_night_factor = 1.0 - smoothstep(0.08, 0.34, daylight)
	var headlights_on: bool = _night_factor > 0.28
	for lamp: MeshInstance3D in _headlight_nodes:
		lamp.visible = headlights_on
	_headlight_material.emission_energy_multiplier = lerpf(0.0, 1.6, _night_factor)
	_update_brake_lights()


func _update_brake_lights() -> void:
	if _taillight_material == null:
		return
	var braking: bool = _ai_state in ["WAITING", "YIELDING", "RECOVERING"]
	var brake_energy: float = lerpf(0.55, 1.9, 1.0 if braking else 0.0)
	_taillight_material.emission_energy_multiplier = brake_energy * maxf(_night_factor, 0.36)


func get_signal_light_state() -> Dictionary:
	return {
		"night_factor": _night_factor,
		"headlights_visible": not _headlight_nodes.is_empty() and _headlight_nodes[0].visible,
		"braking": _ai_state in ["WAITING", "YIELDING", "RECOVERING"],
		"taillight_energy": _taillight_material.emission_energy_multiplier if _taillight_material != null else 0.0
	}


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
