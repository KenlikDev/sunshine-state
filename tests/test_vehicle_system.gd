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
		_check(vehicles.size() == 3, "District contains three distinct vehicle configurations.")

		var sedan: VehicleBody3D = instance.get_node_or_null("World/PrototypeSedan") as VehicleBody3D
		var compact: VehicleBody3D = instance.get_node_or_null("World/CompactCoupe") as VehicleBody3D
		var pickup: VehicleBody3D = instance.get_node_or_null("World/UtilityPickup") as VehicleBody3D
		_check(sedan != null, "District includes the sedan configuration.")
		_check(compact != null, "District includes the compact configuration.")
		_check(pickup != null, "District includes the utility pickup configuration.")
		if sedan != null and compact != null and pickup != null:
			_check(
				not is_equal_approx(float(sedan.get("engine_power")), float(compact.get("engine_power")))
				and not is_equal_approx(float(sedan.get("engine_power")), float(pickup.get("engine_power")))
				and not is_equal_approx(float(compact.get("engine_power")), float(pickup.get("engine_power"))),
				"Each vehicle configuration has distinct power tuning."
			)

		if player != null and sedan != null:
			var vehicle: VehicleBody3D = sedan
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
			var hud: Node = instance.get_node_or_null("HUD")
			_check(hud != null, "Gameplay creates the HUD for mission navigation.")
			if hud != null:
				_check(
					hud.call("_get_guidance_origin") == player,
					"Mission waypoint guidance follows the player while on foot."
				)

			player.call("_try_interact")
			_check(bool(player.call("is_in_vehicle")), "Interaction transfers control to the vehicle.")
			_check(bool(vehicle.call("has_driver")), "Driver ownership is assigned after entry.")
			if hud != null:
				_check(
					hud.call("_get_guidance_origin") == vehicle,
					"Mission waypoint guidance follows the driven vehicle while seated."
				)
				hud.call("_refresh_waypoint_status")
			_check(
				not (player.get_node("MeshInstance3D") as MeshInstance3D).visible,
				"Player presentation is hidden while driving."
			)

			var initial_z: float = vehicle.global_position.z
			Input.action_press("move_forward")
			for _frame: int in range(60):
				await get_tree().physics_frame
			Input.action_release("move_forward")
			_check(
				vehicle.global_position.z < initial_z - 0.1,
				"Throttle input moves the vehicle forward through physics."
			)

			var speed_before_braking: float = vehicle.linear_velocity.length()
			Input.action_press("jump")
			for _frame: int in range(20):
				await get_tree().physics_frame
			Input.action_release("jump")
			_check(
				vehicle.linear_velocity.length() < speed_before_braking - 0.5,
				"Brake input reduces the vehicle's physical velocity."
			)

			var x_before_steering: float = vehicle.global_position.x
			Input.action_press("move_forward")
			Input.action_press("move_left")
			for _frame: int in range(60):
				await get_tree().physics_frame
			Input.action_release("move_forward")
			Input.action_release("move_left")
			_check(
				absf(vehicle.global_position.x - x_before_steering) > 0.1,
				"Steering input changes the vehicle's path."
			)
			_check(
				absf(vehicle.steering) > 0.05,
				"Steering input reaches the front-wheel steering control."
			)

			var barrier := StaticBody3D.new()
			barrier.name = "VehicleRegressionBarrier"
			var forward_direction: Vector3 = -vehicle.global_transform.basis.z
			forward_direction.y = 0.0
			forward_direction = forward_direction.normalized()
			barrier.position = vehicle.global_position + forward_direction * 3.0
			barrier.position.y = 1.0
			barrier.rotation.y = vehicle.global_rotation.y
			var barrier_collision := CollisionShape3D.new()
			var barrier_shape := BoxShape3D.new()
			barrier_shape.size = Vector3(5.0, 2.0, 1.0)
			barrier_collision.shape = barrier_shape
			barrier.add_child(barrier_collision)
			instance.add_child(barrier)
			await get_tree().physics_frame

			var health_before_impact: int = int(vehicle.call("get_vehicle_health"))
			Input.action_press("move_forward")
			for _frame: int in range(90):
				await get_tree().physics_frame
			Input.action_release("move_forward")
			var barrier_clearance: float = (barrier.global_position - vehicle.global_position).dot(forward_direction)
			_check(
				barrier_clearance > 1.0,
				"Vehicle chassis collides with a static barrier instead of passing through it."
			)
			_check(
				_feedback_messages.has("MESSAGE_VEHICLE_IMPACT"),
				"Horizontal vehicle impacts send throttled feedback."
			)
			_check(
				int(vehicle.call("get_vehicle_health")) < health_before_impact,
				"Vehicle impacts reduce persistent in-session vehicle health."
			)

			vehicle.global_position = barrier.global_position - forward_direction * 1.8
			vehicle.global_position.y = 0.65
			vehicle.global_rotation = Vector3(1.1, vehicle.global_rotation.y, 1.0)
			vehicle.linear_velocity = Vector3(7.0, 2.0, -3.0)
			vehicle.angular_velocity = Vector3(1.2, 0.8, -0.4)
			var position_before_recovery: Vector3 = vehicle.global_position
			var recovered: bool = bool(vehicle.call("_attempt_recovery"))
			_check(recovered, "Recovery finds a clear spot when the current vehicle footprint is blocked.")
			if recovered:
				_check(
					vehicle.global_position.distance_to(position_before_recovery) > 2.0,
					"Blocked recovery relocates the vehicle to a clear nearby position."
				)
				_check(
					absf(vehicle.global_rotation.x) < 0.05 and absf(vehicle.global_rotation.z) < 0.05,
					"Recovery returns a rolled vehicle to an upright orientation."
				)
				_check(
					vehicle.linear_velocity.length() < 0.1 and vehicle.angular_velocity.length() < 0.1,
					"Recovery clears linear and angular velocity."
				)
				_check(bool(vehicle.call("has_driver")), "Recovery preserves vehicle driver ownership.")
				_check(
					_feedback_messages.has("MESSAGE_VEHICLE_RECOVERED"),
					"Successful recovery emits localized HUD feedback."
				)

			Input.action_press("interact")
			for _frame: int in range(2):
				await get_tree().physics_frame
			Input.action_release("interact")
			await get_tree().physics_frame
			_check(not bool(player.call("is_in_vehicle")), "E transfers control back to the player.")
			_check(not bool(vehicle.call("has_driver")), "Vehicle releases driver ownership on exit.")
			if hud != null:
				_check(
					hud.call("_get_guidance_origin") == player,
					"Mission waypoint guidance returns to the player after exiting."
				)
				hud.call("_refresh_waypoint_status")
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
