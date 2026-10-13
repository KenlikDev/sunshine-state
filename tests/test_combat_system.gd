extends Node

const DAMAGEABLE_SCRIPT: Script = preload("res://scripts/gameplay/damageable.gd")
var _failures: Array[String] = []
var _shot_targets: Array[String] = []


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var wanted: Node = get_node_or_null("/root/WantedSystem")
	if is_instance_valid(wanted):
		wanted.set("debug_logging", false)
		wanted.call("reset_for_new_game")

	var main_scene: PackedScene = load("res://scenes/bootstrap/main.tscn")
	_check(main_scene != null, "Main scene resource loads.")
	if main_scene == null:
		_finish(1)
		return

	var instance: Node = main_scene.instantiate()
	add_child(instance)
	for _frame: int in range(8):
		await get_tree().physics_frame

	var player: CharacterBody3D = instance.get_node_or_null("Player") as CharacterBody3D
	if not is_instance_valid(player):
		_check(false, "Main scene creates the player.")
		_finish(1, instance)
		return

	var weapon: Node = player.get_node_or_null("WeaponController")
	var camera: Camera3D = player.get_node_or_null("CameraPivot/SpringArm3D/Camera3D") as Camera3D
	var health: Node = player.get_node_or_null("Damageable")
	_check(is_instance_valid(weapon), "Player owns a weapon controller.")
	_check(is_instance_valid(camera), "Weapon controller has an aiming camera.")
	_check(is_instance_valid(health), "Player has a damageable health component.")
	if not is_instance_valid(weapon) or not is_instance_valid(camera) or not is_instance_valid(health):
		_finish(1, instance)
		return

	weapon.connect("shot_fired", Callable(self, "_capture_shot"))
	weapon.set("fire_interval_seconds", 0.18)
	weapon.set("damage_per_shot", 35)
	weapon.set("weapon_range", 80.0)
	weapon.set("current_ammo", 3)
	weapon.set("reserve_ammo", 6)

	player.global_position = Vector3(75.0, 0.0, 40.0)
	player.global_rotation = Vector3.ZERO
	player.get_node("CameraPivot").rotation = Vector3.ZERO
	for _frame: int in range(3):
		await get_tree().physics_frame

	var camera_forward: Vector3 = -camera.global_transform.basis.z
	var target := StaticBody3D.new()
	target.name = "CombatRegressionTarget"
	target.position = camera.global_position + camera_forward * 7.0
	var target_shape := BoxShape3D.new()
	target_shape.size = Vector3(2.0, 2.0, 1.0)
	var target_collision := CollisionShape3D.new()
	target_collision.shape = target_shape
	target.add_child(target_collision)
	var target_health: Node = Node.new()
	target_health.name = "Damageable"
	target_health.set_script(DAMAGEABLE_SCRIPT)
	target_health.set("max_health", 70)
	target.add_child(target_health)
	instance.add_child(target)
	for _frame: int in range(2):
		await get_tree().physics_frame

	_check(bool(weapon.call("fire_weapon")), "A valid fire request fires a shot.")
	_check(int(weapon.call("get_current_ammo")) == 2, "A shot consumes one round.")
	_check(int(target_health.get("current_health")) == 35, "Raycast damage is deterministic.")
	_check(_shot_targets.has("CombatRegressionTarget"), "Shot telemetry identifies the hit target.")
	_check(not bool(weapon.call("fire_weapon")), "Fire cooldown rejects an immediate repeat.")
	_check(int(target_health.get("current_health")) == 35, "A rejected shot cannot apply damage twice.")

	await get_tree().create_timer(0.2).timeout
	_check(bool(weapon.call("fire_weapon")), "A new shot is accepted after the cooldown.")
	_check(int(target_health.get("current_health")) == 0, "Lethal damage reduces target health to zero.")
	await get_tree().process_frame
	_check(not is_instance_valid(target), "A generic damageable target is removed on death.")

	var distant_target := StaticBody3D.new()
	distant_target.name = "OutOfRangeTarget"
	distant_target.position = camera.global_position + camera_forward * 17.0
	var distant_shape := BoxShape3D.new()
	distant_shape.size = Vector3(2.0, 2.0, 1.0)
	var distant_collision := CollisionShape3D.new()
	distant_collision.shape = distant_shape
	distant_target.add_child(distant_collision)
	var distant_health: Node = Node.new()
	distant_health.name = "Damageable"
	distant_health.set_script(DAMAGEABLE_SCRIPT)
	distant_health.set("max_health", 50)
	distant_target.add_child(distant_health)
	instance.add_child(distant_target)
	weapon.set("weapon_range", 10.0)
	await get_tree.create_timer(0.2).timeout
	_check(bool(weapon.call("fire_weapon")), "Firing is allowed even when no target is in range.")
	_check(int(distant_health.get("current_health")) == 50, "Targets beyond weapon range take no damage.")
	weapon.set("weapon_range", 80.0)
	distant_target.queue_free()

	weapon.set("magazine_capacity", 12)
	weapon.set("current_ammo", 0)
	weapon.set("reserve_ammo", 6)
	weapon.set("reload_duration_seconds", 0.06)
	_check(bool(weapon.call("request_reload")), "Reload starts when reserve ammo is available.")
	await get_tree().create_timer(0.12).timeout
	_check(int(weapon.call("get_current_ammo")) == 6, "Reload transfers only available reserve rounds.")
	_check(int(weapon.call("get_reserve_ammo")) == 0, "Reload subtracts transferred reserve ammo.")
	_check(not bool(weapon.call("request_reload")), "Reload is rejected with no reserve ammo.")

	Input.action_press("aim_weapon")
	await get_tree().process_frame
	_check(bool(weapon.call("get_is_aiming")), "Aim input enters aim mode.")
	_check(is_equal_approx(camera.fov, float(weapon.get("aim_fov"))), "Aim mode narrows the field of view.")
	Input.action_release("aim_weapon")
	await get_tree().process_frame
	_check(not bool(weapon.call("get_is_aiming")), "Releasing aim exits aim mode.")
	_check(is_equal_approx(camera.fov, float(weapon.get("default_fov"))), "Aim exit restores default field of view.")

	if is_instance_valid(wanted):
		wanted.call("report_crime", &"COMBAT_TEST", 1, player.global_position, true, &"COMBAT_REGRESSION")
		var officers: Array[Node] = get_tree().get_nodes_in_group("police")
		if not officers.is_empty():
			var officer: Node3D = officers[0] as Node3D
			officer.global_position = player.global_position + Vector3(1.2, 0.0, 0.0)
			officer.global_rotation = Vector3(0.0, PI / 2.0, 0.0)
			var health_before_attack: int = int(health.get("current_health"))
			_check(
				bool(officer.call("try_attack_player", player)),
				"Police can attack only while wanted, close, and in line of sight."
			)
			_check(
				int(health.get("current_health")) < health_before_attack,
				"Police damage reduces player health."
			)

		player.set("respawn_delay_seconds", 0.1)
		health.call("apply_damage", 1000, null)
		_check(bool(player.call("is_incapacitated")), "Lethal damage incapacitates the player.")
		_check(int(wanted.call("get_wanted_level")) == 0, "Player death clears wanted level.")
		for _frame: int in range(2):
			await get_tree().physics_frame
		await get_tree().create_timer(0.15).timeout
		for _frame: int in range(2):
			await get_tree().physics_frame
		_check(not bool(player.call("is_incapacitated")), "Player respawns after the configured delay.")
		_check(
			int(health.get("current_health")) == int(health.get("max_health")),
			"Respawn restores full health."
		)
		_check(
			(player.get_node("MeshInstance3D") as MeshInstance3D).visible,
			"Player presentation is restored after respawn."
		)

	_finish(0 if _failures.is_empty() else 1, instance)


func _capture_shot(target_name: String) -> void:
	_shot_targets.append(target_name)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)


func _finish(exit_code: int, instance: Node = null) -> void:
	if is_instance_valid(instance):
		instance.queue_free()
	if exit_code == 0 and _failures.is_empty():
		print("Combat-system checks passed.")
	else:
		for failure: String in _failures:
			push_error(failure)
	get_tree().quit(exit_code)
