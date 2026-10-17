extends Node

var _failures: Array[String] = []
var _observed_states: Array[String] = []


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var system: Node = get_node_or_null("/root/WantedSystem")
	_check(system != null, "WantedSystem autoload is available.")
	if system == null:
		get_tree().quit(1)
		return

	system.set("debug_logging", false)
	system.connect("wanted_state_changed", Callable(self, "_capture_state"))
	system.call("clear_wanted", &"TEST_SETUP")
	system.set("search_duration_seconds", 0.05)
	system.set("decay_interval_seconds", 0.05)

	var first_level: int = int(
		system.call("report_crime", &"PROPERTY_DAMAGE", 2, Vector3(5.0, 0.0, 9.0), true, &"UNIT_TEST")
	)
	_check(first_level == 2, "Crime severity raises the wanted level by the specified amount.")
	_check(String(system.call("get_state_name")) == "SEARCHING", "Witnessed crimes start a search state.")
	var last_known_position: Vector3 = system.call("get_last_known_player_position")
	_check(
		last_known_position.is_equal_approx(Vector3(5.0, 0.0, 9.0)),
		"Crime registration stores the last-known player position."
	)

	var unchanged_level: int = int(
		system.call("report_crime", &"INVALID", 0, Vector3.ZERO, true, &"INVALID_TEST")
	)
	_check(unchanged_level == 2, "Invalid zero-severity crime events cannot raise or corrupt wanted state.")

	system.call("register_police_detection", 1001, true, Vector3(8.0, 0.0, 9.0))
	_check(String(system.call("get_state_name")) == "PURSUIT", "Police line of sight transitions the wanted system into pursuit.")
	_check(int(system.call("get_visible_police_count")) == 1, "Visible police detectors are tracked centrally.")
	system.call("register_police_detection", 1001, false, Vector3(8.0, 0.0, 9.0))
	_check(String(system.call("get_state_name")) == "SEARCHING", "Losing all police line of sight transitions to searching.")
	_check(int(system.call("get_visible_police_count")) == 0, "Lost police detections are removed from the detector registry.")

	await get_tree().create_timer(0.12).timeout
	_check(
		_observed_states.has("COOLING_DOWN"),
		"Expired search time enters the cooling-down state."
	)
	await get_tree().create_timer(0.24).timeout
	_check(int(system.call("get_wanted_level")) == 0, "Wanted level decays one step at a time until cleared.")
	_check(String(system.call("get_state_name")) == "CLEAR", "A fully decayed wanted level returns to CLEAR.")

	system.set("search_duration_seconds", 8.0)
	system.set("decay_interval_seconds", 12.0)
	system.call("clear_wanted", &"TEST_SETUP")

	var main_scene: PackedScene = load("res://scenes/bootstrap/main.tscn")
	_check(main_scene != null, "Main scene resource loads for police integration checks.")
	if main_scene != null:
		var instance: Node = main_scene.instantiate()
		add_child(instance)
		for _frame: int in range(6):
			await get_tree().physics_frame

		var player: Node3D = instance.get_node_or_null("Player") as Node3D
		var officers: Array[Node] = get_tree().get_nodes_in_group("police")
		var crime_sites: Array[Node] = get_tree().get_nodes_in_group("crime_interactables")
		_check(player != null, "Bootstrap creates the player.")
		_check(officers.size() == 1, "District creates one police officer.")
		_check(crime_sites.size() == 1, "District includes an original crime-trigger interaction.")

		if player != null and not officers.is_empty() and not crime_sites.is_empty():
			var officer: CharacterBody3D = officers[0] as CharacterBody3D
			var crime_site: Node = crime_sites[0]
			officer.global_position = player.global_position + Vector3(7.0, 0.0, 0.0)
			officer.global_rotation = Vector3(0.0, PI / 2.0, 0.0)

			var initial_message: String = String(crime_site.call("interact", player))
			_check(initial_message == "MESSAGE_CRIME_REPORTED", "The crime interaction reports a crime through the shared wanted service.")
			_check(int(system.call("get_wanted_level")) == 1, "The crime interaction increases wanted level.")

			for _frame: int in range(3):
				await get_tree().physics_frame
			_check(String(system.call("get_state_name")) == "PURSUIT", "Police establish pursuit after seeing the player.")
			_check(String(officer.call("get_ai_state")) == "PURSUIT", "Police agent switches to its pursuit state.")

			var wall := StaticBody3D.new()
			wall.name = "PoliceLineOfSightOccluder"
			wall.position = player.global_position + Vector3(3.5, 1.0, 0.0)
			var wall_collision := CollisionShape3D.new()
			var wall_shape := BoxShape3D.new()
			wall_shape.size = Vector3(0.8, 2.2, 4.0)
			wall_collision.shape = wall_shape
			wall.add_child(wall_collision)
			instance.add_child(wall)
			officer.global_position = player.global_position + Vector3(7.0, 0.0, 0.0)
			officer.global_rotation = Vector3(0.0, PI / 2.0, 0.0)
			for _frame: int in range(3):
				await get_tree().physics_frame
			_check(
				String(system.call("get_state_name")) == "SEARCHING",
				"An occluding wall makes police lose line of sight and begin searching."
			)
			_check(
				String(officer.call("get_ai_state")) == "SEARCHING",
				"Police switch from pursuit to their search behaviour after occlusion."
			)

			# Simulate the officer reaching the last-known position while the player
			# remains out of sight beyond the same occluding wall.
			var last_known: Vector3 = system.call("get_last_known_player_position")
			player.global_position = last_known + Vector3(12.0, 0.0, 0.0)
			officer.global_position = last_known + Vector3(0.65, 0.0, 0.0)
			officer.velocity = Vector3.ZERO
			officer.global_rotation = Vector3.ZERO
			var scan_start_yaw: float = officer.rotation.y
			for _frame: int in range(45):
				await get_tree().physics_frame
			var horizontal_search_speed: float = Vector2(officer.velocity.x, officer.velocity.z).length()
			var scan_yaw_delta: float = absf(wrapf(officer.rotation.y - scan_start_yaw, -PI, PI))
			_check(
				String(officer.call("get_ai_state")) == "SEARCHING",
				"Police retain the search state after reaching the last-known position."
			)
			_check(
				horizontal_search_speed < 0.75,
				"Police decelerate and stop near the last-known position instead of orbiting it."
			)
			_check(
				scan_yaw_delta > 0.08,
				"Police look around after reaching a last-known position."
			)

			# Restore the original test location before removing the occluder so
			# unrelated moving pedestrians cannot make reacquisition nondeterministic.
			player.global_position = last_known
			wall.queue_free()
			await get_tree().physics_frame
			officer.global_position = player.global_position + Vector3(7.0, 0.0, 0.0)
			officer.global_rotation = Vector3(0.0, PI / 2.0, 0.0)
			officer.velocity = Vector3.ZERO
			for _frame: int in range(3):
				await get_tree().physics_frame
			_check(String(system.call("get_state_name")) == "PURSUIT", "Police can reacquire the player after line of sight is restored.")

			# Police stop at the configured on-foot standoff instead of pushing
			# into the player, while remaining close enough for melee attacks.
			officer.global_position = player.global_position + Vector3(1.0, 0.0, 0.0)
			officer.velocity = Vector3.ZERO
			for _frame: int in range(8):
				await get_tree().physics_frame
			_check(
				Vector2(officer.velocity.x, officer.velocity.z).length() < 0.75,
				"Police decelerate at the player standoff distance."
			)

			# Probe local police obstacle steering against a real, narrow collider.
			var steering_obstacle := StaticBody3D.new()
			steering_obstacle.name = "PoliceSteeringRegressionObstacle"
			steering_obstacle.position = officer.global_position + Vector3(0.0, 1.0, -1.1)
			var steering_collision := CollisionShape3D.new()
			var steering_shape := BoxShape3D.new()
			steering_shape.size = Vector3(0.8, 2.2, 0.6)
			steering_collision.shape = steering_shape
			steering_obstacle.add_child(steering_collision)
			instance.add_child(steering_obstacle)
			await get_tree().physics_frame
			var steered_direction: Vector3 = officer.call(
				"_steer_around_obstacles",
				Vector3.FORWARD,
				null
			)
			_check(
				steered_direction.length_squared() > 0.5 and absf(steered_direction.x) > 0.25,
				"Police select a clear shoulder when a world obstacle blocks their route."
			)
			steering_obstacle.queue_free()
			await get_tree().physics_frame

			system.call("clear_wanted", &"PLAYER_DEATH")
			_check(int(system.call("get_wanted_level")) == 0, "Explicit player-death clearing resets wanted level.")
			_check(String(system.call("get_state_name")) == "CLEAR", "Player-death clearing resets the wanted state.")
			_check(
				String(crime_site.call("interact", player)) == "MESSAGE_CRIME_COOLDOWN",
				"Repeating the same crime interaction inside its cooldown is rejected."
			)

		instance.queue_free()
		await get_tree().process_frame

	if _failures.is_empty():
		print("Wanted-system checks passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _capture_state(state_name: String) -> void:
	_observed_states.append(state_name)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
