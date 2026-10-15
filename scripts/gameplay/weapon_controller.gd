extends Node

signal ammo_changed(current_ammo: int, reserve_ammo: int)
signal aim_state_changed(is_aiming: bool)
signal shot_fired(hit_target_name: String)

@export_range(1, 100, 1) var magazine_capacity: int = 12
@export_range(0, 500, 1) var initial_reserve_ammo: int = 48
@export_range(1, 1000, 1) var damage_per_shot: int = 35
@export_range(0.05, 3.0, 0.01) var fire_interval_seconds: float = 0.28
@export_range(0.05, 5.0, 0.01) var reload_duration_seconds: float = 1.0
@export_range(1.0, 200.0, 1.0) var weapon_range: float = 80.0
@export_range(30.0, 75.0, 1.0) var aim_fov: float = 55.0
@export_range(50.0, 100.0, 1.0) var default_fov: float = 75.0

var current_ammo: int = 12
var reserve_ammo: int = 48
var _cooldown_remaining: float = 0.0
var _reload_remaining: float = 0.0
var _is_reloading: bool = false
var _is_aiming: bool = false

@onready var _player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var _camera: Camera3D = _player.get_node("CameraPivot/SpringArm3D/Camera3D")


func _ready() -> void:
	current_ammo = magazine_capacity
	reserve_ammo = initial_reserve_ammo
	_camera.fov = default_fov
	ammo_changed.emit(current_ammo, reserve_ammo)


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)

	if _is_reloading:
		_reload_remaining = maxf(0.0, _reload_remaining - delta)
		if _reload_remaining <= 0.0:
			_complete_reload()
		if _is_reloading:
			return

	if _is_player_unavailable():
		_set_aiming(false)
		return

	_set_aiming(Input.is_action_pressed("aim_weapon"))
	if Input.is_action_just_pressed("reload_weapon"):
		request_reload()
	if Input.is_action_just_pressed("fire_weapon"):
		fire_weapon()


func fire_weapon() -> bool:
	if _is_player_unavailable() or _is_reloading:
		return false
	if _cooldown_remaining > 0.0 or current_ammo <= 0:
		return false

	current_ammo -= 1
	_cooldown_remaining = fire_interval_seconds
	ammo_changed.emit(current_ammo, reserve_ammo)
	AudioService.play_weapon_fire()

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var screen_center: Vector2 = viewport_size * 0.5
	var ray_origin: Vector3 = _camera.project_ray_origin(screen_center)
	var ray_direction: Vector3 = _camera.project_ray_normal(screen_center).normalized()
	var ray_end: Vector3 = ray_origin + ray_direction * weapon_range
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end, 1)
	query.exclude = [_player.get_rid()]
	query.collide_with_areas = false

	var hit_target_name: String = ""
	var result: Dictionary = _player.get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		var collider: Node = result.get("collider") as Node
		var damageable: Node = _find_damageable(collider)
		if is_instance_valid(damageable):
			var parent_node: Node = damageable.get_parent()
			hit_target_name = String(parent_node.name) if is_instance_valid(parent_node) else "Damageable"
			damageable.call("apply_damage", damage_per_shot, _player)

	shot_fired.emit(hit_target_name)
	return true


func request_reload() -> bool:
	if _is_player_unavailable() or _is_reloading:
		return false
	if reserve_ammo <= 0 or current_ammo >= magazine_capacity:
		return false

	_is_reloading = true
	_reload_remaining = reload_duration_seconds
	_set_aiming(false)
	return true


func get_current_ammo() -> int:
	return current_ammo


func get_reserve_ammo() -> int:
	return reserve_ammo


func get_is_aiming() -> bool:
	return _is_aiming


func is_reloading() -> bool:
	return _is_reloading


func _complete_reload() -> void:
	var needed: int = magazine_capacity - current_ammo
	var loaded: int = mini(needed, reserve_ammo)
	current_ammo += loaded
	reserve_ammo -= loaded
	_is_reloading = false
	_reload_remaining = 0.0
	ammo_changed.emit(current_ammo, reserve_ammo)


func _find_damageable(starting_node: Node) -> Node:
	var cursor: Node = starting_node
	while is_instance_valid(cursor):
		if cursor.has_method("apply_damage"):
			return cursor
		var component: Node = cursor.get_node_or_null("Damageable")
		if is_instance_valid(component) and component.has_method("apply_damage"):
			return component
		cursor = cursor.get_parent()
	return null


func _is_player_unavailable() -> bool:
	if not is_instance_valid(_player):
		return true
	if _player.has_method("is_incapacitated") and bool(_player.call("is_incapacitated")):
		return true
	if _player.has_method("is_in_vehicle") and bool(_player.call("is_in_vehicle")):
		return true
	return false


func _set_aiming(should_aim: bool) -> void:
	if _is_aiming == should_aim:
		return
	_is_aiming = should_aim
	_camera.fov = aim_fov if _is_aiming else default_fov
	aim_state_changed.emit(_is_aiming)
