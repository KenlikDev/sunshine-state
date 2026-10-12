extends VehicleBody3D

signal driver_changed(has_driver: bool)

@export var engine_power: float = 2400.0
@export var brake_power: float = 65.0
@export var max_steering_angle: float = 0.42
@export var steering_speed: float = 2.2
@export var max_speed_kph: float = 95.0
@export var max_reverse_speed_kph: float = 35.0
@export var impact_speed_threshold: float = 2.8
@export var impact_feedback_cooldown_ms: int = 1200

const RECOVERY_ACTION: StringName = &"vehicle_recover"
@export var mouse_sensitivity: float = 0.0025

var _driver: Node3D
var _speed_before_last_step: float = 0.0
var _last_impact_feedback_msec: int = -1200
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _vehicle_camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D


func _ready() -> void:
	add_to_group("vehicles")
	_vehicle_camera.current = false
	_create_wheel_visuals()


func get_interaction_prompt_key() -> String:
	if is_instance_valid(_driver):
		return "INTERACT_VEHICLE_OCCUPIED"
	return "INTERACT_ENTER_VEHICLE"


func interact(actor: Node) -> String:
	if is_instance_valid(_driver):
		return "MESSAGE_VEHICLE_OCCUPIED"
	if not actor.has_method("enter_vehicle"):
		return "MESSAGE_VEHICLE_CANNOT_ENTER"

	var entered: bool = bool(actor.call("enter_vehicle", self))
	if entered:
		return "MESSAGE_VEHICLE_ENTERED"
	return "MESSAGE_VEHICLE_CANNOT_ENTER"


func take_driver(driver: Node3D) -> bool:
	if is_instance_valid(_driver) or not is_instance_valid(driver):
		return false

	_driver = driver
	_vehicle_camera.make_current()
	driver_changed.emit(true)
	return true


func has_driver() -> bool:
	return is_instance_valid(_driver)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_driver):
		engine_force = 0.0
		brake = 4.0
		steering = move_toward(steering, 0.0, steering_speed * delta)
		_speed_before_last_step = linear_velocity.length()
		return

	if Input.is_action_just_pressed(RECOVERY_ACTION):
		if not _attempt_recovery():
			_driver.call("notify_interaction_feedback", "MESSAGE_VEHICLE_RECOVERY_BLOCKED")
		_speed_before_last_step = linear_velocity.length()
		return

	if Input.is_action_just_pressed("interact"):
		_request_exit()
		return

	var throttle: float = (
		Input.get_action_strength("move_forward")
		- Input.get_action_strength("move_backward")
	)
	var steering_input: float = (
		Input.get_action_strength("move_left")
		- Input.get_action_strength("move_right")
	)
	var longitudinal_speed_kph: float = -linear_velocity.dot(global_transform.basis.z) * 3.6
	var at_forward_limit: bool = throttle > 0.0 and longitudinal_speed_kph >= max_speed_kph
	var at_reverse_limit: bool = throttle < 0.0 and longitudinal_speed_kph <= -max_reverse_speed_kph

	if at_forward_limit or at_reverse_limit:
		engine_force = 0.0
	else:
		# Positive input drives along local -Z; reverse input drives along local +Z.
		engine_force = -throttle * engine_power

	brake = Input.get_action_strength("jump") * brake_power
	if absf(throttle) < 0.01:
		engine_force = 0.0

	steering = move_toward(
		steering,
		steering_input * max_steering_angle,
		steering_speed * delta
	)
	_emit_collision_feedback_if_needed()
	_speed_before_last_step = linear_velocity.length()


func _emit_collision_feedback_if_needed() -> void:
	if not is_instance_valid(_driver):
		return
	if _speed_before_last_step < impact_speed_threshold:
		return
	if get_contact_count() <= 0:
		return

	var has_horizontal_impact: bool = false
	for contact_index: int in range(get_contact_count()):
		var normal: Vector3 = get_contact_local_normal(contact_index)
		if absf(normal.y) < 0.65:
			has_horizontal_impact = true
			break
	if not has_horizontal_impact:
		return

	var now_msec: int = Time.get_ticks_msec()
	if now_msec - _last_impact_feedback_msec < impact_feedback_cooldown_ms:
		return
	_last_impact_feedback_msec = now_msec
	_driver.call("notify_interaction_feedback", "MESSAGE_VEHICLE_IMPACT")


func _attempt_recovery() -> bool:
	if not is_instance_valid(_driver):
		return false

	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var flat_basis: Basis = Basis(Vector3.UP, global_rotation.y)
	var chassis_shape := BoxShape3D.new()
	chassis_shape.size = Vector3(1.9, 0.95, 3.8)

	var overlap_query := PhysicsShapeQueryParameters3D.new()
	overlap_query.shape = chassis_shape
	overlap_query.collision_mask = collision_mask
	overlap_query.collide_with_areas = false
	overlap_query.exclude = [get_rid()]

	var planar_right: Vector3 = flat_basis.x
	var planar_forward: Vector3 = -flat_basis.z
	var offsets: Array[Vector3] = [
		Vector3.ZERO,
		planar_right * 3.3,
		-planar_right * 3.3,
		planar_forward * 4.2,
		-planar_forward * 4.2,
		(planar_right + planar_forward).normalized() * 3.4,
		(planar_right - planar_forward).normalized() * 3.4,
		(-planar_right + planar_forward).normalized() * 3.4,
		(-planar_right - planar_forward).normalized() * 3.4
	]

	for offset: Vector3 in offsets:
		var candidate_xz: Vector3 = global_position + offset
		candidate_xz.y = 0.0

		var ray_query := PhysicsRayQueryParameters3D.create(
			candidate_xz + Vector3.UP * 12.0,
			candidate_xz - Vector3.UP * 20.0,
			collision_mask
		)
		ray_query.exclude = [get_rid()]
		var ground_hit: Dictionary = space_state.intersect_ray(ray_query)
		if ground_hit.is_empty():
			continue

		var ground_position: Vector3 = ground_hit["position"]
		var recovery_position: Vector3 = Vector3(
			candidate_xz.x,
			ground_position.y + 0.65,
			candidate_xz.z
		)
		overlap_query.transform = Transform3D(flat_basis, recovery_position)
		if not space_state.intersect_shape(overlap_query, 1).is_empty():
			continue

		global_transform = Transform3D(flat_basis, recovery_position)
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO
		sleeping = false
		_speed_before_last_step = 0.0
		_last_impact_feedback_msec = Time.get_ticks_msec()
		_driver.call("notify_interaction_feedback", "MESSAGE_VEHICLE_RECOVERED")
		return true

	return false


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_driver):
		return

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		_camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		_camera_pivot.rotation.x = clampf(
			_camera_pivot.rotation.x,
			deg_to_rad(-12.0),
			deg_to_rad(28.0)
		)


func _request_exit() -> void:
	if not is_instance_valid(_driver):
		return

	var exit_position: Variant = _find_safe_exit_position()
	if exit_position == null:
		_driver.call("notify_interaction_feedback", "MESSAGE_VEHICLE_EXIT_BLOCKED")
		return

	var previous_driver: Node3D = _driver
	_driver = null
	_vehicle_camera.current = false
	driver_changed.emit(false)
	previous_driver.call("exit_vehicle", self, exit_position)


func _find_safe_exit_position() -> Variant:
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8

	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	query.collide_with_areas = false
	query.exclude = [get_rid()]

	var offsets: Array[Vector3] = [
		global_transform.basis.x * -2.2,
		global_transform.basis.x * 2.2,
		global_transform.basis.z * 2.6,
		global_transform.basis.z * -2.6
	]
	for offset: Vector3 in offsets:
		var candidate: Vector3 = global_position + offset
		candidate.y = 0.0
		query.transform = Transform3D(Basis(), candidate + Vector3.UP * 0.95)
		if space_state.intersect_shape(query, 1).is_empty():
			return candidate

	return null


func _create_wheel_visuals() -> void:
	var tire_material := StandardMaterial3D.new()
	tire_material.albedo_color = Color(0.055, 0.06, 0.065, 1.0)
	tire_material.roughness = 1.0

	for child: Node in get_children():
		if not child is VehicleWheel3D:
			continue

		var tire_mesh := CylinderMesh.new()
		tire_mesh.top_radius = 0.32
		tire_mesh.bottom_radius = 0.32
		tire_mesh.height = 0.22
		tire_mesh.radial_segments = 16

		var tire := MeshInstance3D.new()
		tire.name = "TireVisual"
		tire.mesh = tire_mesh
		tire.material_override = tire_material
		tire.rotation_degrees.z = 90.0
		child.add_child(tire)
