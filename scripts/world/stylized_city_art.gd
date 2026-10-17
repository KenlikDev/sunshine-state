extends Node3D
## Runtime-built art dressing for the coastal district.
## The pass adds presentation meshes only; it deliberately adds no colliders.

const SKY_BLUE: Color = Color(0.26, 0.72, 0.82, 1.0)
const CREAM: Color = Color(0.91, 0.83, 0.68, 1.0)
const SUNSET_CORAL: Color = Color(0.94, 0.40, 0.32, 1.0)
const AQUA: Color = Color(0.10, 0.61, 0.62, 1.0)
const DEEP_GLASS: Color = Color(0.045, 0.13, 0.18, 1.0)
const LIT_GLASS: Color = Color(0.94, 0.66, 0.34, 1.0)
const PALM_GREEN: Color = Color(0.14, 0.38, 0.23, 1.0)
const _SIGN_COLORS: Array[Color] = [
	Color(0.95, 0.48, 0.32, 1.0),
	Color(0.16, 0.63, 0.66, 1.0),
	Color(0.94, 0.77, 0.35, 1.0),
	Color(0.35, 0.50, 0.78, 1.0)
]

var _street_lamps: Array[OmniLight3D] = []
var _palm_fronds: Array[Dictionary] = []
var _animation_time: float = 0.0


func _process(delta: float) -> void:
	_animation_time += delta
	for frond_data: Dictionary in _palm_fronds:
		var frond: Node3D = frond_data.get("node") as Node3D
		if not is_instance_valid(frond):
			continue
		var rest_rotation: Vector3 = frond_data["rest_rotation"]
		var phase: float = float(frond_data["phase"])
		frond.rotation.x = rest_rotation.x + sin(_animation_time * 0.57 + phase) * 0.045
		frond.rotation.z = rest_rotation.z + sin(_animation_time * 0.73 + phase * 1.31) * 0.055


func get_animated_palm_frond_count() -> int:
	return _palm_fronds.size()


func _ready() -> void:
	_decorate_buildings()
	_add_crosswalks_and_road_details()
	_add_street_furniture()
	_add_palms()
	_add_beach_objects()

	var world := get_parent()
	var day_night: Node = world.get_node_or_null("DayNightCycle") if world != null else null
	if day_night != null and day_night.has_signal("time_of_day_changed"):
		day_night.time_of_day_changed.connect(_update_lamp_state)
		_update_lamp_state(float(day_night.call("get_time_of_day")))


func _decorate_buildings() -> void:
	var frame_transforms: Array[Transform3D] = []
	var glass_transforms: Array[Transform3D] = []
	var warm_glass_transforms: Array[Transform3D] = []
	var building_index: int = 0

	for candidate: Node in get_parent().get_children():
		if not candidate is StaticBody3D or not String(candidate.name).begins_with("Building"):
			continue
		var building := candidate as StaticBody3D
		if building.get_node_or_null("ImportedBuildingVisual") != null:
			continue
		var facade: MeshInstance3D
		for building_child: Node in building.get_children():
			if building_child is MeshInstance3D and (building_child as MeshInstance3D).mesh is BoxMesh:
				facade = building_child as MeshInstance3D
				break
		if facade == null or not facade.mesh is BoxMesh:
			continue
		var dimensions: Vector3 = (facade.mesh as BoxMesh).size
		var center: Vector3 = building.position
		_add_building_trims(String(building.name), center, dimensions, _SIGN_COLORS[building_index % _SIGN_COLORS.size()])
		_collect_windows(center, dimensions, building_index, frame_transforms, glass_transforms, warm_glass_transforms)
		_add_facade_mural(String(building.name), center, dimensions, building_index)
		building_index += 1

	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(1.28, 1.48, 0.10)
	_add_multimesh("WindowFrames", frame_mesh, frame_transforms, _make_material(CREAM, 0.72))
	var glass_mesh := BoxMesh.new()
	glass_mesh.size = Vector3(1.09, 1.27, 0.115)
	_add_multimesh("WindowGlass", glass_mesh, glass_transforms, _make_glass_material(DEEP_GLASS))
	var warm_mesh := BoxMesh.new()
	warm_mesh.size = Vector3(1.09, 1.27, 0.118)
	_add_multimesh("WarmWindowGlass", warm_mesh, warm_glass_transforms, _make_emissive_material(LIT_GLASS, 0.35))


func _add_building_trims(node_name: String, center: Vector3, dimensions: Vector3, accent: Color) -> void:
	var half_x: float = dimensions.x * 0.5
	var half_z: float = dimensions.z * 0.5
	var bottom: float = center.y - dimensions.y * 0.5
	var top: float = center.y + dimensions.y * 0.5
	var wall_accent := _make_material(accent, 0.78)
	var trim := _make_material(CREAM, 0.74)
	# The four distant procedural buildings sit directly behind the taller
	# imported core block. Their thin roof coping projected as detached wire-like
	# rectangles above the skyline because the foreground facade hid the roof
	# mass. Keep the roof edge on nearer facades only; the rear skyline reads
	# cleaner with the authored building silhouette unobstructed.
	if center.z > -40.0:
		var roof := BoxMesh.new()
		roof.size = Vector3(dimensions.x + 0.34, 0.18, dimensions.z + 0.34)
		_add_mesh(
			StringName(node_name + "RoofCoping"),
			roof,
			center + Vector3.UP * (dimensions.y * 0.5 + 0.02),
			trim
		)

	_add_box(StringName(node_name + "BaseFront"), Vector3(dimensions.x + 0.08, 0.16, 0.14), center + Vector3(0.0, bottom + 0.56, half_z + 0.06), wall_accent)
	_add_box(StringName(node_name + "BaseBack"), Vector3(dimensions.x + 0.08, 0.16, 0.14), center + Vector3(0.0, bottom + 0.56, -half_z - 0.06), wall_accent)
	_add_box(StringName(node_name + "BaseLeft"), Vector3(0.14, 0.16, dimensions.z + 0.08), center + Vector3(-half_x - 0.06, bottom + 0.56, 0.0), wall_accent)
	_add_box(StringName(node_name + "BaseRight"), Vector3(0.14, 0.16, dimensions.z + 0.08), center + Vector3(half_x + 0.06, bottom + 0.56, 0.0), wall_accent)

	_add_box(StringName(node_name + "TopFront"), Vector3(dimensions.x + 0.18, 0.14, 0.15), center + Vector3(0.0, top - 0.42, half_z + 0.05), trim)
	_add_box(StringName(node_name + "TopBack"), Vector3(dimensions.x + 0.18, 0.14, 0.15), center + Vector3(0.0, top - 0.42, -half_z - 0.05), trim)
	_add_box(StringName(node_name + "TopLeft"), Vector3(0.15, 0.14, dimensions.z + 0.18), center + Vector3(-half_x - 0.05, top - 0.42, 0.0), trim)
	_add_box(StringName(node_name + "TopRight"), Vector3(0.15, 0.14, dimensions.z + 0.18), center + Vector3(half_x + 0.05, top - 0.42, 0.0), trim)

	for x_side: float in [-1.0, 1.0]:
		_add_box(
			StringName(node_name + "PilasterZ" + str(x_side)),
			Vector3(0.16, dimensions.y - 0.50, 0.14),
			center + Vector3(x_side * (half_x - 0.16), 0.0, half_z + 0.055),
			trim
		)
		_add_box(
			StringName(node_name + "PilasterBack" + str(x_side)),
			Vector3(0.16, dimensions.y - 0.50, 0.14),
			center + Vector3(x_side * (half_x - 0.16), 0.0, -half_z - 0.055),
			trim
		)


func _collect_windows(
	center: Vector3,
	dimensions: Vector3,
	seed_index: int,
	frame_transforms: Array[Transform3D],
	glass_transforms: Array[Transform3D],
	warm_transforms: Array[Transform3D]
) -> void:
	var columns_x: int = maxi(2, int(floor(dimensions.x / 2.6)))
	var columns_z: int = maxi(2, int(floor(dimensions.z / 2.6)))
	var rows: int = clampi(int(floor((dimensions.y - 1.25) / 2.15)), 2, 6)
	var bottom: float = center.y - dimensions.y * 0.5

	for side: int in range(4):
		var is_z_face: bool = side < 2
		var columns: int = columns_x if is_z_face else columns_z
		for row: int in range(rows):
			var window_y: float = bottom + 1.55 + float(row) * 2.15
			if window_y > center.y + dimensions.y * 0.5 - 0.72:
				continue
			for column: int in range(columns):
				var along: float
				if is_z_face:
					along = center.x - dimensions.x * 0.5 + (float(column) + 0.5) * dimensions.x / float(columns)
				else:
					along = center.z - dimensions.z * 0.5 + (float(column) + 0.5) * dimensions.z / float(columns)

				var face_position: Vector3
				var outward: Vector3
				var orientation: Basis
				if side == 0:
					face_position = Vector3(along, window_y, center.z + dimensions.z * 0.5 + 0.035)
					outward = Vector3.BACK
					orientation = Basis.IDENTITY
				elif side == 1:
					face_position = Vector3(along, window_y, center.z - dimensions.z * 0.5 - 0.035)
					outward = Vector3.FORWARD
					orientation = Basis(Vector3.UP, PI)
				elif side == 2:
					face_position = Vector3(center.x + dimensions.x * 0.5 + 0.035, window_y, along)
					outward = Vector3.RIGHT
					orientation = Basis(Vector3.UP, PI * 0.5)
				else:
					face_position = Vector3(center.x - dimensions.x * 0.5 - 0.035, window_y, along)
					outward = Vector3.LEFT
					orientation = Basis(Vector3.UP, -PI * 0.5)

				frame_transforms.append(Transform3D(orientation, to_local(face_position)))
				var glass_position: Vector3 = face_position + outward * 0.065
				var glass_transform := Transform3D(orientation, to_local(glass_position))
				if (column + row * 2 + seed_index) % 5 == 0:
					warm_transforms.append(glass_transform)
				else:
					glass_transforms.append(glass_transform)


func _add_facade_mural(node_name: String, center: Vector3, dimensions: Vector3, index: int) -> void:
	if index % 3 != 0:
		return
	var mural_colors: Array[Color] = [SUNSET_CORAL, AQUA, Color(0.95, 0.75, 0.34, 1.0)]
	var mural_color: Color = mural_colors[index % mural_colors.size()]
	var sign_width: float = minf(2.3, dimensions.x * 0.22)
	var center_y: float = center.y - dimensions.y * 0.5 + 0.82
	var front_sign: float = 1.0 if center.z < 0.0 else -1.0
	var front_z: float = center.z + front_sign * (dimensions.z * 0.5 + 0.16)
	_add_box(StringName(node_name + "FeatureSign"), Vector3(sign_width, 0.42, 0.12), Vector3(center.x, center_y, front_z), _make_material(Color(0.06, 0.16, 0.20, 1.0), 0.5))
	_add_box(StringName(node_name + "FeatureStripe"), Vector3(sign_width * 0.72, 0.075, 0.04), Vector3(center.x, center_y, front_z + front_sign * 0.085), _make_material(mural_color, 0.55))
	_add_box(StringName(node_name + "FeatureDot"), Vector3(0.16, 0.16, 0.05), Vector3(center.x - sign_width * 0.34, center_y, front_z + front_sign * 0.11), _make_emissive_material(mural_color, 0.25))


func _add_crosswalks_and_road_details() -> void:
	var stripe_material := _make_material(Color(0.91, 0.90, 0.82, 1.0), 0.95)
	var curb_material := _make_material(Color(0.76, 0.73, 0.64, 1.0), 0.94)
	for crossing_z: float in [-8.1, 8.1]:
		for index: int in range(7):
			var x: float = -5.0 + float(index) * 1.65
			_add_box(StringName("CrosswalkZ%s_%s" % [crossing_z, index]), Vector3(1.22, 0.018, 0.34), Vector3(x, 0.045, crossing_z), stripe_material)
	for crossing_x: float in [-8.1, 8.1]:
		for index: int in range(7):
			var z: float = -5.0 + float(index) * 1.65
			_add_box(StringName("CrosswalkX%s_%s" % [crossing_x, index]), Vector3(0.34, 0.018, 1.22), Vector3(crossing_x, 0.047, z), stripe_material)

	# A painted stop line and lane-edge paint give the intersection a readable scale.
	for stop_x: float in [-5.4, 5.4]:
		_add_box(StringName("StopLineWestEast" + str(stop_x)), Vector3(0.18, 0.018, 5.2), Vector3(stop_x, 0.046, -8.0), stripe_material)
	for stop_z: float in [-5.4, 5.4]:
		_add_box(StringName("StopLineNorthSouth" + str(stop_z)), Vector3(5.2, 0.018, 0.18), Vector3(-8.0, 0.046, stop_z), stripe_material)

	for lane_edge: float in [-5.85, 5.85]:
		_add_box(StringName("RoadEdgeLineX" + str(lane_edge)), Vector3(176.0, 0.012, 0.10), Vector3(0.0, 0.036, lane_edge), curb_material)
		_add_box(StringName("RoadEdgeLineZ" + str(lane_edge)), Vector3(0.10, 0.012, 156.0), Vector3(lane_edge, 0.038, 0.0), curb_material)


func _add_street_furniture() -> void:
	var pole_material := _make_material(Color(0.19, 0.23, 0.25, 1.0), 0.42, 0.42)
	var fixture_material := _make_emissive_material(Color(1.0, 0.75, 0.42, 1.0), 0.4)
	var seat_material := _make_material(Color(0.58, 0.28, 0.18, 1.0), 0.78)
	var concrete_material := _make_material(Color(0.77, 0.75, 0.67, 1.0), 0.92)

	var lamp_positions: Array[Vector3] = []
	for lane_position: float in [-10.4, 10.4]:
		for along: float in [-60.0, -40.0, -20.0, 20.0, 40.0, 60.0]:
			lamp_positions.append(Vector3(along, 0.0, lane_position))
			lamp_positions.append(Vector3(lane_position, 0.0, along))

	var lamp_index: int = 0
	for lamp_position: Vector3 in lamp_positions:
		_add_street_lamp(lamp_index, lamp_position, pole_material, fixture_material)
		lamp_index += 1

	for bench_index: int in range(5):
		var bench_x: float = -36.0 + float(bench_index) * 18.0
		var bench_z: float = 43.0
		_add_box(StringName("PromenadeBenchSeat" + str(bench_index)), Vector3(1.55, 0.12, 0.42), Vector3(bench_x, 0.52, bench_z), seat_material)
		_add_box(StringName("PromenadeBenchBack" + str(bench_index)), Vector3(1.55, 0.48, 0.12), Vector3(bench_x, 0.81, bench_z + 0.16), seat_material)
		for leg_x: float in [-0.58, 0.58]:
			_add_box(StringName("PromenadeBenchLeg" + str(bench_index) + str(leg_x)), Vector3(0.10, 0.50, 0.12), Vector3(bench_x + leg_x, 0.26, bench_z), pole_material)

	for planter_index: int in range(8):
		var planter_x: float = -63.0 + float(planter_index) * 18.0
		_add_box(StringName("PromenadePlanter" + str(planter_index)), Vector3(1.8, 0.42, 0.72), Vector3(planter_x, 0.23, 33.0), concrete_material)
		_add_box(StringName("PlanterGreenery" + str(planter_index)), Vector3(1.45, 0.32, 0.48), Vector3(planter_x, 0.55, 33.0), _make_material(PALM_GREEN, 0.95))


func _add_street_lamp(index: int, base: Vector3, pole_material: Material, fixture_material: Material) -> void:
	_add_cylinder(StringName("LampPole" + str(index)), 0.055, 0.08, 4.8, base + Vector3.UP * 2.4, pole_material)
	_add_box(StringName("LampArm" + str(index)), Vector3(0.62, 0.075, 0.10), base + Vector3(0.25, 4.65, 0.0), pole_material)
	_add_box(StringName("LampFixture" + str(index)), Vector3(0.42, 0.12, 0.28), base + Vector3(0.50, 4.58, 0.0), fixture_material)
	var lamp := OmniLight3D.new()
	lamp.name = "LampLight" + str(index)
	lamp.position = to_local(base + Vector3(0.50, 4.42, 0.0))
	lamp.light_color = Color(1.0, 0.72, 0.42, 1.0)
	lamp.light_energy = 0.0
	lamp.omni_range = 8.0
	lamp.shadow_enabled = false
	add_child(lamp)
	_street_lamps.append(lamp)


func _add_palms() -> void:
	var trunk_material := _make_material(Color(0.40, 0.27, 0.16, 1.0), 0.96)
	var leaf_materials: Array[StandardMaterial3D] = [
		_make_material(Color(0.12, 0.35, 0.20, 1.0), 0.95),
		_make_material(Color(0.18, 0.46, 0.25, 1.0), 0.95),
		_make_material(Color(0.24, 0.52, 0.28, 1.0), 0.95)
	]
	var palm_index: int = 0
	for x_position: float in [-78.0, -61.0, 61.0, 78.0]:
		for z_position: float in [38.0, 54.0, 70.0]:
			_add_palm(palm_index, Vector3(x_position, 0.0, z_position), trunk_material, leaf_materials)
			palm_index += 1


func _add_palm(index: int, base: Vector3, trunk_material: Material, leaf_materials: Array[StandardMaterial3D]) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.12
	trunk.bottom_radius = 0.22
	trunk.height = 4.4
	trunk.radial_segments = 7
	var trunk_node := MeshInstance3D.new()
	trunk_node.name = "PalmTrunk" + str(index)
	trunk_node.mesh = trunk
	trunk_node.material_override = trunk_material
	trunk_node.position = to_local(base + Vector3.UP * 2.2)
	trunk_node.rotation_degrees.z = -2.0 if index % 2 == 0 else 2.5
	add_child(trunk_node)

	var crown: Vector3 = base + Vector3.UP * 4.25
	for frond: int in range(8):
		var leaf := MeshInstance3D.new()
		leaf.name = "PalmFrond" + str(index) + "_" + str(frond)
		var leaf_mesh := SphereMesh.new()
		leaf_mesh.radial_segments = 10
		leaf_mesh.rings = 5
		leaf.mesh = leaf_mesh
		leaf.material_override = leaf_materials[(index + frond) % leaf_materials.size()]
		leaf.scale = Vector3(0.18, 0.07, 1.48)
		leaf.position = to_local(crown + Vector3(0.0, -0.05, 0.0))
		leaf.rotation = Vector3(deg_to_rad(20.0 + float(frond % 3) * 7.0), TAU * float(frond) / 8.0, deg_to_rad(-23.0))
		add_child(leaf)
		_palm_fronds.append({
			"node": leaf,
			"rest_rotation": leaf.rotation,
			"phase": float(index) * 0.71 + float(frond) * 1.07
		})

	var fruit_material := _make_material(Color(0.31, 0.19, 0.09, 1.0), 0.82)
	for fruit: int in range(3):
		_add_sphere(StringName("PalmFruit" + str(index) + "_" + str(fruit)), Vector3(0.085, 0.085, 0.085), crown + Vector3(cos(float(fruit) * TAU / 3.0) * 0.13, -0.16, sin(float(fruit) * TAU / 3.0) * 0.13), fruit_material)


func _add_beach_objects() -> void:
	var umbrella_colors: Array[Color] = [
		Color(0.94, 0.39, 0.29, 1.0),
		Color(0.13, 0.61, 0.70, 1.0),
		Color(0.94, 0.75, 0.37, 1.0),
		Color(0.91, 0.86, 0.72, 1.0)
	]
	var pole_material := _make_material(Color(0.86, 0.81, 0.70, 1.0), 0.86)
	var sand_detail := _make_material(Color(0.67, 0.57, 0.39, 1.0), 0.96)
	for umbrella_index: int in range(8):
		var x_position: float = -48.0 + float(umbrella_index) * 13.5
		var z_position: float = 59.0 + float(umbrella_index % 2) * 8.0
		_add_cylinder(StringName("BeachUmbrellaPole" + str(umbrella_index)), 0.018, 0.03, 2.0, Vector3(x_position, 1.0, z_position), pole_material)
		var canopy := CylinderMesh.new()
		canopy.top_radius = 0.06
		canopy.bottom_radius = 0.95
		canopy.height = 0.28
		canopy.radial_segments = 12
		var canopy_node := MeshInstance3D.new()
		canopy_node.name = "BeachUmbrellaCanopy" + str(umbrella_index)
		canopy_node.mesh = canopy
		canopy_node.material_override = _make_material(umbrella_colors[umbrella_index % umbrella_colors.size()], 0.9)
		canopy_node.position = to_local(Vector3(x_position, 2.12, z_position))
		add_child(canopy_node)

	for rock_index: int in range(12):
		var x_position: float = -86.0 + float(rock_index) * 15.5
		var z_position: float = 81.0 + float(rock_index % 3) * 2.0
		var rock := MeshInstance3D.new()
		rock.name = "CoastRock" + str(rock_index)
		var rock_mesh := SphereMesh.new()
		rock_mesh.radial_segments = 7
		rock_mesh.rings = 4
		rock.mesh = rock_mesh
		rock.scale = Vector3(1.2 + float(rock_index % 3) * 0.3, 0.48 + float(rock_index % 2) * 0.2, 0.8 + float(rock_index % 4) * 0.17)
		rock.material_override = sand_detail
		rock.position = to_local(Vector3(x_position, 0.28, z_position))
		rock.rotation_degrees.y = float(rock_index * 29)
		add_child(rock)


func _update_lamp_state(hour: float) -> void:
	var solar_angle: float = TAU * (hour - 6.0) / 24.0
	var daylight: float = clampf((sin(solar_angle) + 0.15) / 0.78, 0.0, 1.0)
	var night_factor: float = 1.0 - smoothstep(0.05, 0.32, daylight)
	var intensity: float = 1.15 * night_factor
	for lamp: OmniLight3D in _street_lamps:
		lamp.light_energy = intensity

	# Let the coast and building windows respond continuously to the same clock.
	var world: Node = get_parent()
	if world != null:
		var water := world.get_node_or_null("Water") as MeshInstance3D
		if water != null and water.material_override is ShaderMaterial:
			(water.material_override as ShaderMaterial).set_shader_parameter("night_factor", night_factor)
		var warm_windows := get_node_or_null("WarmWindowGlass") as MultiMeshInstance3D
		if warm_windows != null and warm_windows.material_override is StandardMaterial3D:
			var window_material := warm_windows.material_override as StandardMaterial3D
			window_material.emission_energy_multiplier = lerpf(0.04, 0.6, night_factor)


func _add_multimesh(node_name: String, mesh: Mesh, transforms: Array[Transform3D], material: Material) -> void:
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = transforms.size()
	for index: int in range(transforms.size()):
		multimesh.set_instance_transform(index, transforms[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material
	add_child(instance)


func _add_box(node_name: StringName, dimensions: Vector3, world_position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	return _add_mesh(node_name, mesh, world_position, material)


func _add_mesh(node_name: StringName, mesh: Mesh, world_position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = String(node_name)
	instance.mesh = mesh
	instance.material_override = material
	instance.position = to_local(world_position)
	add_child(instance)
	return instance


func _add_cylinder(node_name: StringName, top_radius: float, bottom_radius: float, height: float, world_position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 10
	return _add_mesh(node_name, mesh, world_position, material)


func _add_sphere(node_name: StringName, scale: Vector3, world_position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 10
	mesh.rings = 5
	var item := _add_mesh(node_name, mesh, world_position, material)
	item.scale = scale
	return item


func _make_material(color: Color, roughness: float = 0.84, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _make_glass_material(color: Color) -> StandardMaterial3D:
	var material := _make_material(color, 0.20, 0.16)
	material.emission_enabled = true
	material.emission = Color(0.03, 0.08, 0.10, 1.0)
	material.emission_energy_multiplier = 0.12
	return material


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _make_material(color, 0.42, 0.12)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
