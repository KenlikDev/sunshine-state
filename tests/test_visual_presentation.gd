extends Node

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var main_scene: PackedScene = load("res://scenes/bootstrap/main.tscn")
	_check(main_scene != null, "The gameplay bootstrap scene can be loaded.")
	if main_scene == null:
		_finish()
		return

	var instance: Node3D = main_scene.instantiate() as Node3D
	add_child(instance)
	for _frame: int in range(8):
		await get_tree().process_frame

	var player_visual := instance.get_node_or_null("Player/MeshInstance3D") as Node3D
	_check(player_visual != null, "The player has a dedicated visual root.")
	if player_visual != null:
		_check(_is_animated_rig(player_visual), "The player uses the bundled skinned humanoid with an animation library.")
		_check(
			bool(player_visual.call("is_initial_pose_synchronized")),
			"The player's idle pose is evaluated synchronously before the first rendered frame."
		)

	var pedestrian_visuals: int = 0
	for pedestrian: Node in get_tree().get_nodes_in_group("pedestrians"):
		var visual := pedestrian.get_node_or_null("MeshInstance3D") as Node3D
		if visual != null and _is_animated_rig(visual):
			pedestrian_visuals += 1
			_check(
				bool(visual.call("is_initial_pose_synchronized")),
				"Each pedestrian evaluates its initial skinned pose before rendering."
			)
	_check(pedestrian_visuals == 4, "All four pedestrians use the skinned humanoid rig.")

	# Alert-state movement must select the run clip at the pedestrian's actual
	# flee speed (3.3 m/s), rather than waiting for the player's sprint threshold.
	var pedestrian_agents: Array[Node] = get_tree().get_nodes_in_group("pedestrians")
	if not pedestrian_agents.is_empty():
		var animation_test_actor := pedestrian_agents[0] as CharacterBody3D
		var animation_test_visual := animation_test_actor.get_node_or_null("MeshInstance3D") as Node3D
		if animation_test_visual != null and _is_animated_rig(animation_test_visual):
			animation_test_actor.set("_ai_state", 1)
			animation_test_actor.velocity = Vector3(0.0, 0.0, 3.3)
			for _frame: int in range(6):
				animation_test_visual.call("_update_rig_animation", 0.1)
			_check(
					String(animation_test_visual.call("get_locomotion_state")) == "RUN",
					"Alerted pedestrians use a blended running animation at their flee speed."
			)
			animation_test_actor.set("_ai_state", 0)
			animation_test_actor.velocity = Vector3.ZERO

	var police_visual := instance.get_node_or_null("World/PoliceOfficer01/BodyMesh") as Node3D
	_check(police_visual != null and police_visual.get_node_or_null("PoliceBadge") != null, "The police officer has role-specific uniform details.")
	_check(police_visual != null and _is_animated_rig(police_visual), "The police officer uses the same animated humanoid rig.")
	if police_visual != null:
		_check(
			bool(police_visual.call("is_initial_pose_synchronized")),
			"The police officer evaluates its initial skinned pose before rendering."
		)

	var imported_building_count: int = 0
	for building: Node in instance.get_node("World").get_children():
		if not building is StaticBody3D or not String(building.name).begins_with("Building"):
			continue
		var building_body := building as StaticBody3D
		var visual := building_body.get_node_or_null("ImportedBuildingVisual") as Node3D
		if visual == null:
			continue
		var blockout_mesh: MeshInstance3D
		for child: Node in building_body.get_children():
			if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
				blockout_mesh = child as MeshInstance3D
				break
		_check(blockout_mesh != null, "Imported buildings retain their blockout render node for collision alignment.")
		if blockout_mesh != null:
			_check(not blockout_mesh.visible, "Imported buildings hide the box render mesh.")
		var collision_shape: CollisionShape3D
		for child: Node in building_body.get_children():
			if child is CollisionShape3D:
				collision_shape = child as CollisionShape3D
				break
		_check(collision_shape != null and collision_shape.shape != null, "Imported buildings retain their authored collision shape.")
		var imported_model := visual.get_node_or_null("ModelPivot/ImportedBuilding") as Node3D
		_check(imported_model != null, "Imported city buildings instantiate a Kenney GLB model.")
		_check(int(visual.get("model_mesh_count")) >= 1, "Each imported city building has renderable mesh geometry.")
		imported_building_count += 1
	_check(imported_building_count == 8, "The eight buildings nearest the playable core use imported city models.")

	# Review the first-run composition as well as the asset inventory: the
	# objective board must be reachable without directly covering the player,
	# and the crime scene must not regress to a single blank colored slab.
	var start_player := instance.get_node_or_null("Player") as Node3D
	var information_board := instance.get_node_or_null("World/DistrictInformationBoard") as StaticBody3D
	_check(start_player != null and information_board != null, "The start scene contains both the player and the information board.")
	if start_player != null and information_board != null:
		_check(
			absf(information_board.global_position.x - start_player.global_position.x) >= 0.5,
			"The information board is offset from the player's center line."
		)
		_check(
			start_player.global_position.distance_to(information_board.global_position) <= float(start_player.get("interaction_distance")),
			"The information board remains within initial interaction reach."
		)
		_check(
			information_board.get_node_or_null("InformationPanel1.0") != null
			and information_board.get_node_or_null("InformationHeader1.0") != null
			and information_board.get_node_or_null("InformationTextLine1.0_0") != null,
			"The information board has a designed inset, header, and readable line details."
		)
		var board_collision := information_board.get_node_or_null("CollisionShape3D") as CollisionShape3D
		_check(
			board_collision != null and board_collision.shape != null,
			"The information board retains a single simple interaction collider."
		)

	var graffiti_site := instance.get_node_or_null("World/GraffitiSpot") as StaticBody3D
	_check(graffiti_site != null, "The authored crime interaction remains in the district.")
	if graffiti_site != null:
		_check(
			graffiti_site.get_node_or_null("GraffitiAquaSlash1.0") != null
			and graffiti_site.get_node_or_null("GraffitiGoldTag1.0") != null
			and graffiti_site.get_node_or_null("GraffitiFrameSide1.0_-1.0") != null,
			"The crime scene has a framed, multi-colour mural instead of a blank block."
		)
		var graffiti_collision := graffiti_site.get_node_or_null("CollisionShape3D") as CollisionShape3D
		_check(
			graffiti_collision != null and graffiti_collision.shape != null,
			"The crime interaction retains its authored collision shape."
		)

	var city_art := instance.get_node_or_null("World/StylizedCityArt") as Node3D
	_check(city_art != null, "The city art pass is attached to the world.")
	if city_art != null:
		var glass := city_art.get_node_or_null("WindowGlass") as MultiMeshInstance3D
		var warm_glass := city_art.get_node_or_null("WarmWindowGlass") as MultiMeshInstance3D
		_check(glass != null and glass.multimesh != null and glass.multimesh.instance_count > 100, "Building facades contain instanced window geometry.")
		_check(warm_glass != null and warm_glass.multimesh != null and warm_glass.multimesh.instance_count > 10, "Some windows have a warm emissive night palette.")
		_check(_count_named_children(city_art, "PalmTrunk") == 12, "The coastal promenade contains twelve palm trees.")
		_check(_count_named_children(city_art, "LampLight") >= 20, "The road network contains working street-light fixtures.")
		_check(_count_named_children(city_art, "Crosswalk") >= 28, "The intersection has painted pedestrian crossings.")
		_check(_count_named_children(city_art, "BeachUmbrellaCanopy") == 8, "The beach contains a set of colorful umbrellas.")
		_check(_count_named_children(city_art, "PromenadeBenchSeat") == 5, "The promenade has a consistent set of benches.")
		_check(
			int(city_art.call("get_animated_palm_frond_count")) == 96,
			"All palm fronds have a lightweight, phase-offset wind animation."
		)

	var drivable_vehicle_count: int = 0
	for vehicle: Node in get_tree().get_nodes_in_group("vehicles"):
		var details := vehicle.get_node_or_null("VehicleVisualDetails") as Node3D
		_check(details != null and not details.visible, "Imported vehicle models replace generated blockout detail meshes.")
		var model_wrapper := vehicle.get_node_or_null("VehicleVisualModel") as Node3D
		_check(model_wrapper != null, "Each drivable vehicle has an imported visual model wrapper.")
		if model_wrapper != null:
			var imported_model := model_wrapper.get_node_or_null("ModelPivot/ImportedVehicle") as Node3D
			_check(imported_model != null, "Each drivable vehicle instantiates a CC0 glTF model.")
			_check(int(model_wrapper.get("model_mesh_count")) >= 1, "Each imported vehicle has renderable model geometry.")
			_check(int(model_wrapper.get("rotating_wheel_count")) >= 4, "Imported vehicle wheel meshes are identified for motion.");

		var chassis_mesh := vehicle.get_node_or_null("ChassisMesh") as MeshInstance3D
		_check(chassis_mesh != null and not chassis_mesh.visible, "The cuboid chassis placeholder is hidden while keeping its collider.")
		var front_left_wheel: Node = vehicle.get_node_or_null("FrontLeftWheel")
		if front_left_wheel != null:
			var tire_visual := front_left_wheel.get_node_or_null("TireVisual") as MeshInstance3D
			_check(tire_visual != null and not tire_visual.visible, "Prototype wheels are hidden behind the imported vehicle's wheels.")
		drivable_vehicle_count += 1
	_check(drivable_vehicle_count == 3, "The visual pass preserves all three drivable vehicle variants.")

	var traffic_details_count: int = 0
	for traffic: Node in get_tree().get_nodes_in_group("traffic_vehicles"):
		var details := traffic.get_node_or_null("VehicleVisualDetails") as Node3D
		_check(details != null and not details.visible, "Background traffic blockout details are hidden for imported vehicle models.")
		var model_wrapper := traffic.get_node_or_null("VehicleVisualModel") as Node3D
		_check(model_wrapper != null, "Background traffic has an imported vehicle model wrapper.")
		if model_wrapper != null:
			_check(int(model_wrapper.get("model_mesh_count")) >= 1, "Background traffic has renderable imported geometry.")
			_check(int(model_wrapper.get("rotating_wheel_count")) >= 4, "Background traffic wheel meshes are identified for motion.")
		var body_mesh := traffic.get_node_or_null("BodyMesh") as MeshInstance3D
		_check(body_mesh != null and not body_mesh.visible, "Traffic cuboid body render mesh is hidden.")
		traffic_details_count += 1
	_check(traffic_details_count == 4, "All background traffic agents remain present after visual enhancement.")

	var water := instance.get_node_or_null("World/Water") as MeshInstance3D
	_check(water != null and water.mesh is PlaneMesh, "The ocean is a tessellated surface suitable for vertex-displaced waves.")
	if water != null:
		var water_mesh := water.mesh as PlaneMesh
		_check(water_mesh.subdivide_width >= 32 and water_mesh.subdivide_depth >= 16, "The water has enough vertices for smooth, low-amplitude waves.")
		var water_material := water.material_override as ShaderMaterial
		_check(water_material != null and water_material.shader != null, "The ocean uses its dedicated stylized water shader.")
		if water_material != null and water_material.shader != null:
			_check(water_material.shader.code.contains("TIME") and water_material.shader.code.contains("VERTEX.y"), "Water highlights and surface displacement animate over time.")
			var day_night := instance.get_node_or_null("World/DayNightCycle")
			if day_night != null:
				day_night.call("set_time_of_day", 12.0)
				var day_water_factor: float = float(water_material.get_shader_parameter("night_factor"))
				day_night.call("set_time_of_day", 0.0)
				var night_water_factor: float = float(water_material.get_shader_parameter("night_factor"))
				_check(night_water_factor > day_water_factor, "The water palette responds to the day-night cycle.")

	# Background traffic lamp geometry should react to the shared clock and
	# make braking/yielding visually legible, without spawning per-car light nodes.
	var traffic_agents: Array[Node] = get_tree().get_nodes_in_group("traffic_vehicles")
	_check(traffic_agents.size() == 4, "The district has four vehicles with signal-light presentation.")
	if not traffic_agents.is_empty():
		var traffic_sample := traffic_agents[0] as Node3D
		_check(
			traffic_sample.get_node_or_null("HeadlightLeft") is MeshInstance3D
			and traffic_sample.get_node_or_null("HeadlightRight") is MeshInstance3D
			and traffic_sample.get_node_or_null("TaillightLeft") is MeshInstance3D
			and traffic_sample.get_node_or_null("TaillightRight") is MeshInstance3D,
			"Background vehicles have visible headlight and taillight geometry."
		)
		var day_night_for_lights := instance.get_node_or_null("World/DayNightCycle")
		if day_night_for_lights != null:
			day_night_for_lights.call("set_time_of_day", 12.0)
			var day_lights: Dictionary = traffic_sample.call("get_signal_light_state")
			day_night_for_lights.call("set_time_of_day", 0.0)
			var night_lights: Dictionary = traffic_sample.call("get_signal_light_state")
			_check(
				not bool(day_lights.get("headlights_visible", true))
				and bool(night_lights.get("headlights_visible", false)),
				"Background headlights switch on at night and remain off at midday."
			)
			traffic_sample.call("_set_ai_state", "DRIVING")
			var steady_taillight_energy: float = float(traffic_sample.call("get_signal_light_state").get("taillight_energy", 0.0))
			traffic_sample.call("_set_ai_state", "YIELDING")
			var braking_lights: Dictionary = traffic_sample.call("get_signal_light_state")
			_check(
				bool(braking_lights.get("braking", false))
				and float(braking_lights.get("taillight_energy", 0.0)) > steady_taillight_energy,
				"Traffic taillights brighten during yielding and obstruction-recovery states."
			)
			traffic_sample.call("_set_ai_state", "DRIVING")
			day_night_for_lights.call("set_time_of_day", 12.0)

	var world_environment := instance.get_node_or_null("World/WorldEnvironment") as WorldEnvironment
	_check(world_environment != null and world_environment.environment.background_mode == Environment.BG_SKY, "The world uses a procedural sky instead of a flat-color background.")
	if world_environment != null:
		_check(world_environment.environment.adjustment_enabled, "The environment applies a restrained contrast and saturation grade.")

	instance.queue_free()
	await get_tree().process_frame
	_finish()


func _is_animated_rig(anchor: Node3D) -> bool:
	# The imported rig is parented beneath CharacterMotionPivot so visual lean
	# stays outside animation tracks; discover it recursively instead of by path.
	var character := anchor.find_child("QuaterniusCharacter", true, false) as Node3D
	if character == null:
		return false
	var skeletons := character.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return false
	var skinned_mesh_count: int = 0
	for candidate: Node in character.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh != null and mesh_instance.skin != null:
			skinned_mesh_count += 1
	if skinned_mesh_count == 0:
		return false
	var animation_players := character.find_children("*", "AnimationPlayer", true, false)
	if animation_players.is_empty():
		return false
	var animation_player := animation_players[0] as AnimationPlayer
	return animation_player.get_animation_list().size() >= 3


func _count_named_children(parent: Node, prefix: String) -> int:
	var count: int = 0
	for child: Node in parent.get_children():
		if String(child.name).begins_with(prefix):
			count += 1
	return count


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)


func _finish() -> void:
	if _failures.is_empty():
		print("Visual-presentation checks passed.")
		get_tree().quit(0)
		return

	for failure: String in _failures:
		push_error(failure)
	get_tree().quit(1)
