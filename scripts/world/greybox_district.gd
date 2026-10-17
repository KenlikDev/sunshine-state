extends Node3D

const INTERACTABLE_SCRIPT: Script = preload("res://scripts/gameplay/interactable.gd")
const VEHICLE_SCENE: PackedScene = preload("res://scenes/vehicles/sedan.tscn")
const COMPACT_SCENE: PackedScene = preload("res://scenes/vehicles/compact.tscn")
const PICKUP_SCENE: PackedScene = preload("res://scenes/vehicles/pickup.tscn")
const TRAFFIC_VISUAL_MODELS: Array[PackedScene] = [
	preload("res://assets/vehicles/kenney_sedan.glb"),
	preload("res://assets/vehicles/kenney_hatchback_sports.glb"),
	preload("res://assets/vehicles/kenney_utility_truck.glb")
]
const PEDESTRIAN_SCENE: PackedScene = preload("res://scenes/pedestrians/pedestrian.tscn")
const TRAFFIC_SCENE: PackedScene = preload("res://scenes/traffic/traffic_vehicle.tscn")
const POLICE_SCENE: PackedScene = preload("res://scenes/police/police_officer.tscn")
const CRIME_SCENE: PackedScene = preload("res://scenes/crime/graffiti_spot.tscn")
const SHOP_SCENE: PackedScene = preload("res://scenes/economy/shop_interactable.tscn")
const DAY_NIGHT_SCRIPT: Script = preload("res://scripts/world/day_night_cycle.gd")
const STYLIZED_CITY_ART_SCRIPT: Script = preload("res://scripts/world/stylized_city_art.gd")
const BUILDING_VISUAL_SCRIPT: Script = preload("res://scripts/world/building_glb_visual.gd")
const BUILDING_VISUAL_SCENES: Array[PackedScene] = [
	preload("res://assets/environment/kenney_building_a.glb"),
	preload("res://assets/environment/kenney_building_d.glb"),
	preload("res://assets/environment/kenney_building_f.glb"),
	preload("res://assets/environment/kenney_building_h.glb"),
	preload("res://assets/environment/kenney_building_skyscraper_a.glb")
]


func _ready() -> void:
	_create_environment()
	_create_ground_and_roads()
	_create_buildings()
	_create_coastline()
	_create_information_board()
	_create_crime_site()
	_create_shops()
	_create_police()
	_create_test_vehicle()
	_create_pedestrians()
	_create_traffic()
	_create_world_boundaries()
	var visual_pass := Node3D.new()
	visual_pass.name = "StylizedCityArt"
	visual_pass.set_script(STYLIZED_CITY_ART_SCRIPT)
	add_child(visual_pass)


func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	world_environment.name = "WorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.background_color = Color(0.49, 0.72, 0.86, 1.0)
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.11, 0.43, 0.70, 1.0)
	sky_material.sky_horizon_color = Color(0.71, 0.86, 0.90, 1.0)
	sky_material.ground_bottom_color = Color(0.18, 0.21, 0.22, 1.0)
	sky_material.ground_horizon_color = Color(0.59, 0.68, 0.67, 1.0)
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.69, 0.78, 0.82, 1.0)
	environment.ambient_light_energy = 0.82
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.tonemap_white = 5.0
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.58, 0.77, 0.82, 1.0)
	environment.fog_density = 0.0015
	environment.glow_enabled = true
	environment.glow_intensity = 0.18
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "Sunlight"
	sunlight.rotation_degrees = Vector3(-48.0, 32.0, 0.0)
	sunlight.light_energy = 1.15
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_max_distance = 100.0
	add_child(sunlight)

	var day_night_cycle := Node.new()
	day_night_cycle.name = "DayNightCycle"
	day_night_cycle.set_script(DAY_NIGHT_SCRIPT)
	add_child(day_night_cycle)


func _create_ground_and_roads() -> void:
	var ground_material := _make_material(Color(0.25, 0.35, 0.27))
	var road_material := _make_material(Color(0.12, 0.14, 0.16))
	var sidewalk_material := _make_material(Color(0.58, 0.59, 0.56))
	var marking_material := _make_material(Color(0.88, 0.83, 0.63))

	_add_static_box("Ground", Vector3(0.0, -0.3, 0.0), Vector3(180.0, 0.6, 160.0), ground_material)
	_add_visual_box("MainRoadEastWest", Vector3(0.0, 0.012, 0.0), Vector3(176.0, 0.024, 12.0), road_material)
	_add_visual_box("MainRoadNorthSouth", Vector3(0.0, 0.014, 0.0), Vector3(12.0, 0.028, 156.0), road_material)

	for side: float in [-1.0, 1.0]:
		_add_visual_box(
			"EastWestSidewalk%s" % str(side),
			Vector3(0.0, 0.035, side * 7.7),
			Vector3(176.0, 0.07, 3.2),
			sidewalk_material
		)
		_add_visual_box(
			"NorthSouthSidewalk%s" % str(side),
			Vector3(side * 7.7, 0.035, 0.0),
			Vector3(3.2, 0.07, 156.0),
			sidewalk_material
		)

	for stripe_index: int in range(17):
		var stripe_x: float = -80.0 + float(stripe_index) * 10.0
		_add_visual_box(
			"RoadMarking%s" % stripe_index,
			Vector3(stripe_x, 0.028, 0.0),
			Vector3(3.6, 0.012, 0.18),
			marking_material
		)


func _create_buildings() -> void:
	var palette: Array[Color] = [
		Color(0.72, 0.68, 0.58),
		Color(0.68, 0.74, 0.74),
		Color(0.78, 0.72, 0.62),
		Color(0.57, 0.66, 0.70),
		Color(0.74, 0.76, 0.71)
	]
	var specifications: Array[Dictionary] = [
		{"center": Vector3(-29.0, 4.0, -23.0), "size": Vector3(16.0, 8.0, 14.0)},
		{"center": Vector3(29.0, 7.0, -23.0), "size": Vector3(16.0, 14.0, 14.0)},
		{"center": Vector3(-29.0, 5.0, 23.0), "size": Vector3(16.0, 10.0, 14.0)},
		{"center": Vector3(29.0, 6.0, 23.0), "size": Vector3(16.0, 12.0, 14.0)},
		{"center": Vector3(-59.0, 4.5, -25.0), "size": Vector3(12.0, 9.0, 18.0)},
		{"center": Vector3(59.0, 6.0, -25.0), "size": Vector3(12.0, 12.0, 18.0)},
		{"center": Vector3(-59.0, 3.5, 25.0), "size": Vector3(12.0, 7.0, 18.0)},
		{"center": Vector3(59.0, 5.0, 25.0), "size": Vector3(12.0, 10.0, 18.0)},
		{"center": Vector3(-20.0, 4.0, -49.0), "size": Vector3(14.0, 8.0, 12.0)},
		{"center": Vector3(20.0, 6.0, -49.0), "size": Vector3(14.0, 12.0, 12.0)},
		{"center": Vector3(-48.0, 5.0, -49.0), "size": Vector3(14.0, 10.0, 12.0)},
		{"center": Vector3(48.0, 4.0, -49.0), "size": Vector3(14.0, 8.0, 12.0)}
	]

	for index: int in range(specifications.size()):
		var building: Dictionary = specifications[index]
		var building_size: Vector3 = building["size"]
		var material: StandardMaterial3D = _make_material(palette[index % palette.size()])
		var building_body: StaticBody3D = _add_static_box(
			"Building%02d" % (index + 1),
			building["center"],
			building["size"],
			material
		)
		var blockout_mesh: MeshInstance3D
		for child: Node in building_body.get_children():
			if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
				blockout_mesh = child as MeshInstance3D
				break
		if blockout_mesh != null:
			blockout_mesh.name = "BlockoutMesh"
			blockout_mesh.visible = index >= 8
		# The eight buildings nearest the playable core use imported, textured
		# CC0 assets. Keep the remaining four facade blockouts as a lightweight
		# fallback so the procedural windows and trim still have coverage.
		if index < 8:
			var visual := Node3D.new()
			visual.name = "ImportedBuildingVisual"
			visual.set_script(BUILDING_VISUAL_SCRIPT)
			visual.set("model_scene", BUILDING_VISUAL_SCENES[index % BUILDING_VISUAL_SCENES.size()])
			visual.set("target_dimensions", building_size)
			visual.set("target_bottom_y", -building_size.y * 0.5)
			visual.set("yaw_degrees", float((index % 4) * 90))
			building_body.add_child(visual)


func _create_coastline() -> void:
	var sand_material := _make_material(Color(0.78, 0.69, 0.49))
	var water_material := _make_material(Color(0.10, 0.43, 0.62), 0.35)
	_add_visual_box("Beach", Vector3(0.0, 0.018, 60.5), Vector3(178.0, 0.036, 37.0), sand_material)
	_add_visual_box("Water", Vector3(0.0, -0.12, 106.0), Vector3(220.0, 0.08, 55.0), water_material)


func _create_information_board() -> void:
	var board_material := _make_material(Color(0.12, 0.38, 0.43))
	var post_material := _make_material(Color(0.27, 0.25, 0.21))

	var board := StaticBody3D.new()
	board.name = "DistrictInformationBoard"
	board.position = Vector3(0.0, 1.05, 7.7)
	board.set_script(INTERACTABLE_SCRIPT)
	board.set("interaction_prompt_key", "INTERACT_READ_BOARD")
	board.set("interaction_message_key", "MESSAGE_BOARD_READ")
	board.add_to_group("interactable")

	var board_mesh := MeshInstance3D.new()
	var board_box := BoxMesh.new()
	board_box.size = Vector3(2.1, 1.7, 0.18)
	board_mesh.mesh = board_box
	board_mesh.material_override = board_material
	board.add_child(board_mesh)

	var board_collision := CollisionShape3D.new()
	var board_shape := BoxShape3D.new()
	board_shape.size = board_box.size
	board_collision.shape = board_shape
	board.add_child(board_collision)
	add_child(board)

	_add_static_box(
		"InformationBoardPost",
		Vector3(0.0, 0.35, 7.82),
		Vector3(0.16, 0.7, 0.16),
		post_material
	)


func _create_crime_site() -> void:
	var crime_site: StaticBody3D = CRIME_SCENE.instantiate() as StaticBody3D
	crime_site.name = "GraffitiSpot"
	crime_site.position = Vector3(-4.0, 1.0, 8.0)
	add_child(crime_site)


func _create_shops() -> void:
	_spawn_shop("FirstAidVendor", Vector3(-15.0, 0.9, 12.0), "first_aid_kit")
	_spawn_shop("VehicleServiceDesk", Vector3(15.0, 0.9, 12.0), "vehicle_repair")


func _spawn_shop(node_name: String, shop_position: Vector3, item_id: String) -> void:
	var shop: StaticBody3D = SHOP_SCENE.instantiate() as StaticBody3D
	shop.name = node_name
	shop.position = shop_position
	shop.set("item_id", item_id)
	shop.add_to_group("interactable")
	add_child(shop)


func _create_police() -> void:
	var patrol_route := PackedVector3Array([
		Vector3(14.0, 0.0, 18.0),
		Vector3(14.0, 0.0, -18.0),
		Vector3(20.0, 0.0, -18.0),
		Vector3(20.0, 0.0, 18.0)
	])
	var officer: CharacterBody3D = POLICE_SCENE.instantiate() as CharacterBody3D
	officer.name = "PoliceOfficer01"
	officer.set("route_points", patrol_route)
	officer.set("initial_waypoint_index", 0)
	officer.position = patrol_route[0]
	add_child(officer)


func _create_test_vehicle() -> void:
	var sedan: VehicleBody3D = VEHICLE_SCENE.instantiate() as VehicleBody3D
	sedan.name = "PrototypeSedan"
	sedan.position = Vector3(3.5, 0.6, -5.0)
	add_child(sedan)

	var compact: VehicleBody3D = COMPACT_SCENE.instantiate() as VehicleBody3D
	compact.name = "CompactCoupe"
	compact.position = Vector3(-3.5, 0.6, -5.0)
	add_child(compact)

	var pickup: VehicleBody3D = PICKUP_SCENE.instantiate() as VehicleBody3D
	pickup.name = "UtilityPickup"
	pickup.position = Vector3(0.0, 0.65, -18.0)
	add_child(pickup)


func _create_pedestrians() -> void:
	var east_route := PackedVector3Array([
		Vector3(7.9, 0.0, -64.0),
		Vector3(7.9, 0.0, 64.0),
		Vector3(9.1, 0.0, 64.0),
		Vector3(9.1, 0.0, -64.0)
	])
	var west_route := PackedVector3Array([
		Vector3(-7.9, 0.0, 64.0),
		Vector3(-7.9, 0.0, -64.0),
		Vector3(-9.1, 0.0, -64.0),
		Vector3(-9.1, 0.0, 64.0)
	])

	_spawn_pedestrian("PedestrianEast01", east_route, 0, Color(0.75, 0.28, 0.18, 1.0), Color(0.55, 0.33, 0.22, 1.0))
	_spawn_pedestrian("PedestrianEast02", east_route, 2, Color(0.18, 0.38, 0.72, 1.0), Color(0.79, 0.60, 0.43, 1.0))
	_spawn_pedestrian("PedestrianWest01", west_route, 0, Color(0.83, 0.68, 0.24, 1.0), Color(0.37, 0.23, 0.17, 1.0))
	_spawn_pedestrian("PedestrianWest02", west_route, 2, Color(0.3, 0.58, 0.38, 1.0), Color(0.85, 0.69, 0.54, 1.0))


func _spawn_pedestrian(
	node_name: String,
	route: PackedVector3Array,
	start_waypoint: int,
	clothing_color: Color,
	skin_tone: Color
) -> void:
	var pedestrian: CharacterBody3D = PEDESTRIAN_SCENE.instantiate() as CharacterBody3D
	pedestrian.name = node_name
	pedestrian.set("route_points", route)
	pedestrian.set("initial_waypoint_index", start_waypoint)
	pedestrian.set("clothing_color", clothing_color)
	var character_visual: Node = pedestrian.get_node("MeshInstance3D")
	character_visual.set("skin_tone", skin_tone)
	pedestrian.position = route[start_waypoint]
	add_child(pedestrian)


func _create_traffic() -> void:
	var north_south_west := PackedVector3Array([
		Vector3(-2.0, 0.65, -68.0),
		Vector3(-2.0, 0.65, 68.0)
	])
	var north_south_east := PackedVector3Array([
		Vector3(2.0, 0.65, -68.0),
		Vector3(2.0, 0.65, 68.0)
	])
	var east_west_north := PackedVector3Array([
		Vector3(-78.0, 0.65, -2.0),
		Vector3(78.0, 0.65, -2.0)
	])
	var east_west_south := PackedVector3Array([
		Vector3(-78.0, 0.65, 2.0),
		Vector3(78.0, 0.65, 2.0)
	])

	_spawn_traffic(
		"TrafficNorthbound",
		north_south_west,
		0,
		false,
		Color(0.19, 0.46, 0.68, 1.0),
		0
	)
	_spawn_traffic(
		"TrafficSouthbound",
		north_south_east,
		0,
		true,
		Color(0.68, 0.23, 0.16, 1.0),
		1
	)
	_spawn_traffic(
		"TrafficEastbound",
		east_west_north,
		1,
		false,
		Color(0.23, 0.56, 0.38, 1.0),
		2
	)
	_spawn_traffic(
		"TrafficWestbound",
		east_west_south,
		1,
		true,
		Color(0.72, 0.52, 0.15, 1.0),
		0
	)


func _spawn_traffic(
	node_name: String,
	route: PackedVector3Array,
	route_axis: int,
	start_at_end: bool,
	body_color: Color,
	model_index: int
) -> void:
	var traffic: CharacterBody3D = TRAFFIC_SCENE.instantiate() as CharacterBody3D
	traffic.name = node_name
	traffic.set("route_points", route)
	traffic.set("route_axis", route_axis)
	traffic.set("start_at_end", start_at_end)
	traffic.set("body_color", body_color)
	var visual_model: Node3D = traffic.get_node("VehicleVisualModel") as Node3D
	visual_model.set("model_scene", TRAFFIC_VISUAL_MODELS[model_index % TRAFFIC_VISUAL_MODELS.size()])
	var vehicle_dimensions: Vector3 = Vector3(1.8, 1.35, 3.6)
	if model_index == 2:
		vehicle_dimensions = Vector3(1.8, 1.7, 3.8)
	visual_model.set("target_dimensions", vehicle_dimensions)
	var start_index: int = route.size() - 1 if start_at_end else 0
	traffic.position = route[start_index]
	add_child(traffic)


func _create_world_boundaries() -> void:
	var boundary_material := _make_material(Color(0.31, 0.39, 0.38))
	_add_static_box("BoundaryWest", Vector3(-89.0, 4.0, 0.0), Vector3(2.0, 8.0, 160.0), boundary_material)
	_add_static_box("BoundaryEast", Vector3(89.0, 4.0, 0.0), Vector3(2.0, 8.0, 160.0), boundary_material)
	_add_static_box("BoundaryNorth", Vector3(0.0, 4.0, -79.0), Vector3(180.0, 8.0, 2.0), boundary_material)
	_add_static_box("BoundarySouth", Vector3(0.0, 4.0, 79.0), Vector3(180.0, 8.0, 2.0), boundary_material)


func _make_material(color: Color, roughness: float = 0.92) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	return material


func _add_visual_box(
	node_name: String,
	center: Vector3,
	size: Vector3,
	material: StandardMaterial3D
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.material_override = material
	instance.position = center
	add_child(instance)
	return instance


func _add_static_box(
	node_name: String,
	center: Vector3,
	size: Vector3,
	material: StandardMaterial3D
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = center

	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

	body.add_to_group("world_geometry")
	add_child(body)
	return body
