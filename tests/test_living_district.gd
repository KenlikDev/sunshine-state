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

		if is_instance_valid(player) and is_instance_valid(first_pedestrian):
			player.global_position = first_pedestrian.global_position + Vector3(0.0, 0.0, 2.0)
			for _frame: int in range(3):
				await get_tree().physics_frame
			_check(
				String(first_pedestrian.call("get_ai_state")) == "ALERT",
				"Pedestrians react to a nearby player with the alert state."
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
