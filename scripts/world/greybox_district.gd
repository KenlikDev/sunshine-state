extends Node3D

const INTERACTABLE_SCRIPT: Script = preload("res://scripts/gameplay/interactable.gd")


func _ready() -> void:
	_create_environment()
	_create_ground_and_roads()
	_create_buildings()
	_create_coastline()
	_create_information_board()
	_create_world_boundaries()


func _create_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.49, 0.72, 0.86, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.77, 0.82, 1.0)
	environment.ambient_light_energy = 0.8
	world_environment.environment = environment
	add_child(world_environment)

	var sunlight := DirectionalLight3D.new()
	sunlight.name = "Sunlight"
	sunlight.rotation_degrees = Vector3(-48.0, 32.0, 0.0)
	sunlight.light_energy = 1.15
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_max_distance = 100.0
	add_child(sunlight)


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
		var material: StandardMaterial3D = _make_material(palette[index % palette.size()])
		_add_static_box(
			"Building%02d" % (index + 1),
			building["center"],
			building["size"],
			material
		)


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
	board.position = Vector3(0.0, 1.05, 7.4)
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
		Vector3(0.0, 0.35, 7.52),
		Vector3(0.16, 0.7, 0.16),
		post_material
	)


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
