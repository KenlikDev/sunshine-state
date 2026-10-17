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

	var pedestrian_visuals: int = 0
	for pedestrian: Node in get_tree().get_nodes_in_group("pedestrians"):
		var visual := pedestrian.get_node_or_null("MeshInstance3D") as Node3D
		if visual != null and _is_animated_rig(visual):
			pedestrian_visuals += 1
	_check(pedestrian_visuals == 4, "All four pedestrians use the skinned humanoid rig.")

	var police_visual := instance.get_node_or_null("World/PoliceOfficer01/BodyMesh") as Node3D
	_check(police_visual != null and police_visual.get_node_or_null("PoliceBadge") != null, "The police officer has role-specific uniform details.")
	_check(police_visual != null and _is_animated_rig(police_visual), "The police officer uses the same animated humanoid rig.")

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

	var world_environment := instance.get_node_or_null("World/WorldEnvironment") as WorldEnvironment
	_check(world_environment != null and world_environment.environment.background_mode == Environment.BG_SKY, "The world uses a procedural sky instead of a flat-color background.")

	instance.queue_free()
	await get_tree().process_frame
	_finish()


func _is_animated_rig(anchor: Node3D) -> bool:
	var character := anchor.get_node_or_null("QuaterniusCharacter") as Node3D
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
