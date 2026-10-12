extends CharacterBody3D

signal interaction_prompt_changed(prompt_key: String)
signal interaction_feedback(message_key: String)

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var ground_acceleration: float = 22.0
@export var ground_deceleration: float = 28.0
@export var jump_velocity: float = 4.8
@export var mouse_sensitivity: float = 0.0025
@export var interaction_distance: float = 4.5

var _gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var _current_interactable: Node3D
var _current_prompt_key: String = ""

@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _interaction_ray: RayCast3D = $CameraPivot/InteractionRay


func _ready() -> void:
	_interaction_ray.add_exception(self)
	_interaction_ray.target_position = Vector3(0.0, 0.0, -interaction_distance)
	_interaction_ray.enabled = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		_camera_pivot.rotation.x = clampf(
			_camera_pivot.rotation.x,
			deg_to_rad(-55.0),
			deg_to_rad(35.0)
		)


func _physics_process(delta: float) -> void:
	var movement_input: Vector2 = Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)
	var desired_direction: Vector3 = (
		global_transform.basis * Vector3(movement_input.x, 0.0, movement_input.y)
	).normalized()
	var target_speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var acceleration: float = (
		ground_acceleration if movement_input.length_squared() > 0.01 else ground_deceleration
	)

	velocity.x = move_toward(velocity.x, desired_direction.x * target_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_direction.z * target_speed, acceleration * delta)

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		velocity.y -= _gravity * delta

	move_and_slide()
	_update_interactable()

	if Input.is_action_just_pressed("interact"):
		_try_interact()


func _update_interactable() -> void:
	_interaction_ray.force_raycast_update()
	var target: Node3D

	if _interaction_ray.is_colliding():
		var collider: Object = _interaction_ray.get_collider()
		if (
			collider is Node3D
			and collider.has_method("get_interaction_prompt_key")
			and collider.has_method("interact")
		):
			target = collider as Node3D

	if target == _current_interactable:
		return

	_current_interactable = target
	_current_prompt_key = ""
	if is_instance_valid(_current_interactable):
		_current_prompt_key = String(_current_interactable.call("get_interaction_prompt_key"))
	interaction_prompt_changed.emit(_current_prompt_key)


func _try_interact() -> void:
	if not is_instance_valid(_current_interactable):
		return
	if not _current_interactable.has_method("interact"):
		return

	var message_key: String = String(_current_interactable.call("interact", self))
	if not message_key.is_empty():
		interaction_feedback.emit(message_key)


func get_current_interaction_prompt_key() -> String:
	return _current_prompt_key


func refresh_interaction_prompt() -> void:
	_update_interactable()
