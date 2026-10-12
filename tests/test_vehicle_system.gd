extends Node

var _failures: Array[String] = []
var _feedback_messages: Array[String] = []


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var main_scene: PackedScene = load("res://scenes/bootstrap/main.tscn")
	_check(main_scene != null, "Main scene resource loads.")

	if main_scene != null:
		var instance: Node = main_scene.instantiate()
		add_child(instance)
		await get_tree().process_frame
		for _frame: int in range(4):
			await get_tree().physics_frame

		var player: CharacterBody3D = instance.get_node_or_null("Player") as CharacterBody3D
		var vehicles: Array[Node] = get_tree().get_nodes_in_group("vehicles")
		_check(player != null, "Main scene creates the player.")
		_check(not vehicles.is_empty(), "District contains a vehicle.")

		if player != null and not vehicles.is_empty():
			var vehicle: VehicleBody3D = vehicles[0] as VehicleBody3D
			_check(vehicle != null, "Prototype vehicle uses VehicleBody3D.")
			_check(vehicle.has_method("interact"), "Vehicle implements the shared interaction contract.")
			_check(vehicle.has_method("take_driver"), "Vehicle exposes explicit driver ownership.")
			_check(vehicle.has_method("has_driver"), "Vehicle exposes a driver-state query.")

			player.global_position = vehicle.global_position + Vector3(0.0, -0.6, 5.0)
			player.global_position.y = 0.0
			player.velocity = Vector3.ZERO
			player.rotation = Vector3.ZERO
			player.connect("interaction_feedback", Callable(self, "_capture_feedback"))
			player.call("refresh_interaction_prompt")
			_check(
				String(player.call("get_current_interaction_prompt_key")) == "INTERACT_ENTER_VEHICLE",
				"Player raycast finds the vehicle interaction area."
			)

			player.call("_try_interact")
			_check(bool(player.call("is_in_vehicle")), "Interaction transfers control to the vehicle.")
			_check(bool(vehicle.call("has_driver")), "Driver ownership is assigned after entry.")
			_check(
				not (player.get_node("MeshInstance3D") as MeshInstance3D).visible,
				"Player presentation is hidden while driving."
			)

			var initial_z: float = vehicle.global_position.z
			Input.action_press("move_forward")
			for _frame: int in range(60):
				await get_tree().physics_frame
			Input.action_release("move_forward")
			print(
				"Vehicle diagnostic: start_z=", initial_z,
				" end_z=", vehicle.global_position.z,
				" y=", vehicle.global_position.y,
				" velocity=", vehicle.linear_velocity,
				" engine_force=", vehicle.engine_force,
				" front_contact=",
				(vehicle.get_node("FrontLeftWheel") as VehicleWheel3D).is_in_contact(),
				" rear_contact=",
				(vehicle.get_node("RearLeftWheel") as VehicleWheel3D).is_in_contact()
			)
			_check(
				vehicle.global_position.z < initial_z - 0.1,
				"Throttle input moves the vehicle forward through physics."
			)

			Input.action_press("interact")
			for _frame: int in range(2):
				await get_tree().physics_frame
			Input.action_release("interact")
			await get_tree().physics_frame
			_check(not bool(player.call("is_in_vehicle")), "E transfers control back to the player.")
			_check(not bool(vehicle.call("has_driver")), "Vehicle releases driver ownership on exit.")
			_check(
				(player.get_node("MeshInstance3D") as MeshInstance3D).visible,
				"Player presentation is restored after exit."
			)
			_check(
				_feedback_messages.has("MESSAGE_VEHICLE_ENTERED"),
				"Vehicle entry emits the expected HUD feedback."
			)
			_check(
				_feedback_messages.has("MESSAGE_VEHICLE_EXITED"),
				"Vehicle exit emits the expected HUD feedback."
			)

		instance.queue_free()
		await get_tree().process_frame

	if _failures.is_empty():
		print("Vehicle system checks passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _capture_feedback(message_key: String) -> void:
	_feedback_messages.append(message_key)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
