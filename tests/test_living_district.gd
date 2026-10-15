extends Node

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var main_scene: PackedScene = load("res://scenes/bootstrap/main.tscn")
	_check(main_scene != null, "Main scene resource loads.")

	if main_scene != null:
		var instance: Node = main_scene.instantiate()
		add_child(instance)
		for _frame: int in range(6):
			await get_tree().physics_frame

		var player: CharacterBody3D = instance.get_node_or_null("Player") as CharacterBody3D
		var day_night: Node = instance.get_node_or_null("World/DayNightCycle")
		var environment: WorldEnvironment = instance.get_node_or_null("World/WorldEnvironment") as WorldEnvironment
		var sunlight: DirectionalLight3D = instance.get_node_or_null("World/Sunlight") as DirectionalLight3D
		_check(day_night != null, "The world contains a real-time day-night controller.")
		_check(environment != null and sunlight != null, "Day-night control has environment and sunlight targets.")
		if day_night != null and environment != null and sunlight != null:
			day_night.call("set_time_of_day", 12.0)
			var midday_energy: float = sunlight.light_energy
			var midday_background: Color = environment.environment.background_color
			day_night.call("set_time_of_day", 0.0)
			var midnight_energy: float = sunlight.light_energy
			var midnight_background: Color = environment.environment.background_color
			_check(midday_energy > midnight_energy, "Midday sunlight is brighter than midnight.")
			_check(not midnight_background.is_equal_approx(midday_background), "Night changes the sky background color.")
			_check(
				float(day_night.call("get_time_of_day")) < 0.001,
				"Time-of-day can be set deterministically for tests."
			)
		var pedestrians: Array[Node] = get_tree().get_nodes_in_group("pedestrians")
		var traffic: Array[Node] = get_tree().get_nodes_in_group("traffic_vehicles")
		_check(player != null, "Main scene creates the player.")
		_check(player != null and player.is_in_group("player"), "Player is registered for nearby AI perception.")
		_check(pedestrians.size() == 4, "District starts with a bounded set of four pedestrians.")
		_check(traffic.size() == 4, "District starts with a bounded set of four traffic vehicles.")

		var first_pedestrian: Node3D
		var first_traffic: Node3D
		if not pedestrians.is_empty():
			first_pedestrian = pedestrians[0] as Node3D
		if not traffic.is_empty():
			first_traffic = traffic[0] as Node3D

		var pedestrian_start: Vector3 = first_pedestrian.global_position if is_instance_valid(first_pedestrian) else Vector3.ZERO
		var traffic_start: Vector3 = first_traffic.global_position if is_instance_valid(first_traffic) else Vector3.ZERO

		for _frame: int in range(180):
			await get_tree().physics_frame

		_check(
			get_tree().get_nodes_in_group("pedestrians").size() == 4,
			"Pedestrian population stays bounded during the route simulation."
		)
		_check(
			get_tree().get_nodes_in_group("traffic_vehicles").size() == 4,
			"Traffic population stays bounded during the route simulation."
		)
		if is_instance_valid(first_pedestrian):
			_check(
				first_pedestrian.global_position.distance_to(pedestrian_start) > 0.25,
				"Pedestrian agents advance along their authored routes."
			)
		if is_instance_valid(first_traffic):
			_check(
				first_traffic.global_position.distance_to(traffic_start) > 1.0,
				"Traffic agents advance along their authored road routes."
			)

		var north_south: Node3D = instance.get_node_or_null("World/TrafficNorthbound") as Node3D
		var east_west: Node3D = instance.get_node_or_null("World/TrafficEastbound") as Node3D
		if is_instance_valid(north_south) and is_instance_valid(east_west):
			north_south.global_position = Vector3(-2.0, 0.65, -8.0)
			east_west.global_position = Vector3(-8.0, 0.65, -2.0)
			for _frame: int in range(3):
				await get_tree().physics_frame
			_check(
				String(east_west.call("get_ai_state")) == "YIELDING",
				"East-west traffic yields to nearby north-south traffic at the junction."
			)

			# Keep a cross-traffic vehicle inside the conflict zone to ensure
			# the right-of-way policy cannot starve the east-west route forever.
			north_south.set_physics_process(false)
			north_south.global_position = Vector3(-2.0, 0.65, -2.0)
			east_west.global_position = Vector3(-8.0, 0.65, -2.0)
			east_west.global_rotation = Vector3(0.0, -PI / 2.0, 0.0)
			east_west.set("_route_index", 1)
			east_west.set("_route_direction", 1)
			east_west.set("_yielding_seconds", 0.0)
			east_west.set("_stalled_seconds", 0.0)
			var yield_test_start_x: float = east_west.global_position.x
			var observed_yield: bool = false
			for _frame: int in range(420):
				await get_tree().physics_frame
				observed_yield = observed_yield or String(east_west.call("get_ai_state")) == "YIELDING"
			_check(observed_yield, "The conflict timeout test begins in a yielding state.")
			_check(
				String(east_west.call("get_ai_state")) == "DRIVING"
				and east_west.global_position.x > yield_test_start_x + 1.0,
				"Traffic resumes after its bounded yield timeout when cross traffic remains stalled."
			)
			north_south.set_physics_process(true)

		if is_instance_valid(player) and is_instance_valid(first_pedestrian):
			player.global_position = first_pedestrian.global_position + Vector3(0.0, 0.0, 2.0)
			for _frame: int in range(3):
				await get_tree().physics_frame
			_check(
				String(first_pedestrian.call("get_ai_state")) == "ALERT",
				"Pedestrians react to a nearby player with the alert state."
			)

		var crossing_pedestrian: Node3D = instance.get_node_or_null("World/PedestrianEast02") as Node3D
		var crossing_traffic: Node3D = instance.get_node_or_null("World/TrafficEastbound") as Node3D
		if is_instance_valid(crossing_pedestrian) and is_instance_valid(crossing_traffic):
			player.global_position = Vector3(0.0, 0.0, 12.0)
			crossing_pedestrian.global_position = Vector3(9.1, 0.0, 4.4)
			crossing_pedestrian.set("_route_index", 3)
			crossing_traffic.global_position = Vector3(9.1, 0.65, 2.0)
			crossing_traffic.set_physics_process(false)
			var crossing_start_z: float = crossing_pedestrian.global_position.z
			_check(
				(crossing_pedestrian.collision_mask & 2) == 0 and (crossing_traffic.collision_layer & 2) != 0,
				"Pedestrians ignore the background-traffic collision layer."
			)
			for _frame: int in range(120):
				await get_tree().physics_frame
			_check(
				crossing_pedestrian.global_position.z < crossing_start_z - 1.0,
				"A stationary traffic car cannot permanently block an authored pedestrian route."
			)
			crossing_traffic.set_physics_process(true)

		var recovery_traffic: Node3D = instance.get_node_or_null("World/TrafficEastbound") as Node3D
		if is_instance_valid(player) and is_instance_valid(recovery_traffic):
			recovery_traffic.set("_route_index", 1)
			recovery_traffic.set("_route_direction", 1)
			recovery_traffic.set("_stalled_seconds", 0.0)
			recovery_traffic.set("_reverse_remaining", 0.0)
			recovery_traffic.global_position = Vector3(-50.0, 0.65, -2.0)
			recovery_traffic.global_rotation = Vector3(0.0, -PI / 2.0, 0.0)
			player.global_position = Vector3(-55.0, 0.0, -2.0)

			var obstacle := StaticBody3D.new()
			obstacle.name = "TrafficRecoveryRegressionObstacle"
			obstacle.position = recovery_traffic.global_position + Vector3(3.0, 0.35, 0.0)
			var obstacle_collision := CollisionShape3D.new()
			var obstacle_shape := BoxShape3D.new()
			obstacle_shape.size = Vector3(0.8, 2.0, 5.0)
			obstacle_collision.shape = obstacle_shape
			obstacle.add_child(obstacle_collision)
			instance.add_child(obstacle)

			var saw_waiting: bool = false
			var saw_recovering: bool = false
			var saw_reverse_motion: bool = false
			var in_recovery_phase: bool = false
			var recovery_phase_start_x: float = recovery_traffic.global_position.x
			for _frame: int in range(300):
				await get_tree().physics_frame
				var state_name: String = String(recovery_traffic.call("get_ai_state"))
				saw_waiting = saw_waiting or state_name == "WAITING"

				if state_name == "RECOVERING":
					saw_recovering = true
					if not in_recovery_phase:
						recovery_phase_start_x = recovery_traffic.global_position.x
						in_recovery_phase = true
					elif recovery_traffic.global_position.x < recovery_phase_start_x - 0.05:
						saw_reverse_motion = true
				else:
					in_recovery_phase = false

			_check(saw_waiting, "Traffic waits when a nearby obstacle blocks its forward route.")
			_check(saw_recovering, "Traffic uses a bounded reverse-and-retry recovery after a sustained blockage.")
			_check(
				saw_reverse_motion,
				"Traffic moves backwards during the recovery state instead of pushing into the obstacle."
			)
			obstacle.queue_free()
			for _frame: int in range(100):
				await get_tree().physics_frame
			_check(
				String(recovery_traffic.call("get_ai_state")) == "DRIVING",
				"Traffic resumes its route after the blocking obstacle is removed."
			)

			# Repeat the obstruction test outside the camera range, where ray-based
			# avoidance is intentionally disabled and physical progress must detect stalls.
			recovery_traffic.global_position = Vector3(-65.0, 0.65, -2.0)
			recovery_traffic.global_rotation = Vector3(0.0, -PI / 2.0, 0.0)
			recovery_traffic.set("_route_index", 1)
			recovery_traffic.set("_route_direction", 1)
			recovery_traffic.set("_stalled_seconds", 0.0)
			recovery_traffic.set("_reverse_remaining", 0.0)
			player.global_position = Vector3(0.0, 0.0, 12.0)
			var offscreen_obstacle := StaticBody3D.new()
			offscreen_obstacle.name = "OffscreenTrafficRecoveryObstacle"
			offscreen_obstacle.position = recovery_traffic.global_position + Vector3(3.0, 0.35, 0.0)
			var offscreen_collision := CollisionShape3D.new()
			var offscreen_shape := BoxShape3D.new()
			offscreen_shape.size = Vector3(0.8, 2.0, 5.0)
			offscreen_collision.shape = offscreen_shape
			offscreen_obstacle.add_child(offscreen_collision)
			instance.add_child(offscreen_obstacle)

			var saw_physical_stall: bool = false
			var saw_physical_recovery: bool = false
			var saw_physical_reverse: bool = false
			var physical_recovery_start_x: float = recovery_traffic.global_position.x
			var tracking_physical_reverse: bool = false
			for _frame: int in range(300):
				await get_tree().physics_frame
				var physical_state: String = String(recovery_traffic.call("get_ai_state"))
				saw_physical_stall = saw_physical_stall or physical_state == "WAITING"
				if physical_state == "RECOVERING":
					saw_physical_recovery = true
					if not tracking_physical_reverse:
						physical_recovery_start_x = recovery_traffic.global_position.x
						tracking_physical_reverse = true
					elif recovery_traffic.global_position.x < physical_recovery_start_x - 0.05:
						saw_physical_reverse = true
				else:
					tracking_physical_reverse = false

			_check(
				saw_physical_stall and saw_physical_recovery,
				"Off-screen traffic detects a physical stall without an obstacle ray and starts recovery."
			)
			_check(
				saw_physical_reverse,
				"Off-screen traffic reverses to escape a physical collision."
			)
			offscreen_obstacle.queue_free()

		if is_instance_valid(first_pedestrian):
			_check(
				String(first_pedestrian.call("get_ai_state")) == "PATROL",
				"Pedestrian returns to its patrol route after the player leaves the alert radius."
			)

		for traffic_node: Node in get_tree().get_nodes_in_group("traffic_vehicles"):
			var position: Vector3 = (traffic_node as Node3D).global_position
			_check(absf(position.x) < 88.0 and absf(position.z) < 78.0, "Traffic stays inside the district boundaries.")

		instance.queue_free()
		await get_tree().process_frame

	if _failures.is_empty():
		print("Living-district checks passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
