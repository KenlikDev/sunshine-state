extends Node

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var system: Node = get_node_or_null("/root/WantedSystem")
	_check(system != null, "WantedSystem autoload is available.")
	if system == null:
		get_tree().quit(1)
		return

	system.set("debug_logging", false)
	system.call("clear_wanted", &"TEST_SETUP")
	system.set("search_duration_seconds", 0.05)
	system.set("decay_interval_seconds", 0.05)

	var first_level: int = int(
		system.call("report_crime", &"PROPERTY_DAMAGE", 2, Vector3(5.0, 0.0, 9.0), true, &"UNIT_TEST")
	)
	_check(first_level == 2, "Crime severity raises the wanted level by the specified amount.")
	_check(String(system.call("get_state_name")) == "SEARCHING", "Witnessed crimes start a search state.")
	_check(
		(system.call("get_last_known_player_position") as Vector3).is_equal_approx(Vector3(5.0, 0.0, 9.0)),
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
	_check(String(system.call("get_state_name")) == "COOLING_DOWN", "Expired search time enters the cooling-down state.")
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

			wall.queue_free()
			await get_tree().physics_frame
			officer.global_position = player.global_position + Vector3(7.0, 0.0, 0.0)
			officer.global_rotation = Vector3(0.0, PI / 2.0, 0.0)
			for _frame: int in range(3):
				await get_tree().physics_frame
			_check(String(system.call("get_state_name")) == "PURSUIT", "Police can reacquire the player after line of sight is restored.")

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


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
