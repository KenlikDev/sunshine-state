extends Node3D
## Presentation-only details shared by the drivable prototypes and background traffic.

@export var traffic_vehicle: bool = false
@export var body_width: float = 1.9
@export var body_length: float = 3.8
@export var body_height: float = 0.7
@export var wheel_radius: float = 0.32
@export var wheel_width: float = 0.22

var _rim_material: StandardMaterial3D
var _rubber_material: StandardMaterial3D
var _trim_material: StandardMaterial3D
var _glass_material: StandardMaterial3D
var _headlight_material: StandardMaterial3D
var _tail_light_material: StandardMaterial3D
@export var imported_vehicle_model_active: bool = false


func _ready() -> void:
	if imported_vehicle_model_active:
		visible = false
		call_deferred("_hide_generated_tire_visuals")
		return
	_rim_material = _make_material(Color(0.58, 0.62, 0.63, 1.0), 0.28, 0.72)
	_rubber_material = _make_material(Color(0.035, 0.039, 0.043, 1.0), 0.98)
	_trim_material = _make_material(Color(0.14, 0.16, 0.17, 1.0), 0.45, 0.36)
	_glass_material = _make_material(Color(0.08, 0.20, 0.24, 1.0), 0.18, 0.18)
	_headlight_material = _make_emissive_material(Color(1.0, 0.84, 0.57, 1.0), 0.72)
	_tail_light_material = _make_emissive_material(Color(0.85, 0.065, 0.035, 1.0), 0.55)

	var actor := get_parent() as Node3D
	if actor == null:
		return
	if not traffic_vehicle:
		var configured_radius: Variant = actor.get("visual_wheel_radius")
		var configured_width: Variant = actor.get("visual_wheel_width")
		if configured_radius != null:
			wheel_radius = float(configured_radius)
		if configured_width != null:
			wheel_width = float(configured_width)

	var chassis := actor.get_node_or_null("ChassisMesh") as MeshInstance3D
	if chassis == null:
		chassis = actor.get_node_or_null("BodyMesh") as MeshInstance3D
	if chassis != null and chassis.mesh is BoxMesh:
		var chassis_box := chassis.mesh as BoxMesh
		body_width = chassis_box.size.x
		body_length = chassis_box.size.z
		body_height = chassis_box.size.y
		var chassis_y: float = chassis.position.y
		_add_body_lights_and_bumpers(chassis_y, chassis_box.size, chassis.position.z)
		_add_cabin_details(actor, chassis_y)
	call_deferred("_add_wheel_details")


func _hide_generated_tire_visuals() -> void:
	var vehicle := get_parent() as Node3D
	if vehicle == null:
		return
	for wheel: Node in vehicle.get_children():
		if not wheel is VehicleWheel3D:
			continue
		var tire_visual := wheel.get_node_or_null("TireVisual") as MeshInstance3D
		if tire_visual != null:
			tire_visual.visible = false


func _add_body_lights_and_bumpers(chassis_y: float, chassis_size: Vector3, chassis_z: float) -> void:
	var bumper_y: float = chassis_y - chassis_size.y * 0.5 + 0.15
	var front_z: float = chassis_z - body_length * 0.5 - 0.035
	var rear_z: float = chassis_z + body_length * 0.5 + 0.035
	_add_box("FrontBumper", Vector3(body_width * 0.94, 0.13, 0.17), Vector3(0.0, bumper_y, front_z), _trim_material)
	_add_box("RearBumper", Vector3(body_width * 0.94, 0.13, 0.17), Vector3(0.0, bumper_y, rear_z), _trim_material)
	_add_box("FrontGrille", Vector3(body_width * 0.25, 0.18, 0.055), Vector3(0.0, chassis_y - 0.02, front_z - 0.035), _make_material(Color(0.025, 0.035, 0.04, 1.0), 0.48, 0.25))
	_add_box("FrontGrilleBar", Vector3(body_width * 0.20, 0.025, 0.065), Vector3(0.0, chassis_y + 0.015, front_z - 0.07), _rim_material)

	for side: float in [-1.0, 1.0]:
		_add_box("Headlamp" + str(side), Vector3(body_width * 0.18, 0.13, 0.055), Vector3(side * body_width * 0.31, chassis_y + chassis_size.y * 0.05, front_z - 0.012), _headlight_material)
		_add_box("TailLamp" + str(side), Vector3(body_width * 0.15, 0.16, 0.055), Vector3(side * body_width * 0.34, chassis_y + chassis_size.y * 0.06, rear_z + 0.012), _tail_light_material)
		_add_box("FrontFogLamp" + str(side), Vector3(0.11, 0.055, 0.045), Vector3(side * body_width * 0.34, bumper_y + 0.015, front_z - 0.055), _headlight_material)

	_add_box("FrontLicensePlate", Vector3(body_width * 0.30, 0.105, 0.025), Vector3(0.0, bumper_y - 0.005, front_z - 0.095), _make_material(Color(0.83, 0.85, 0.79, 1.0), 0.6))
	_add_box("RearLicensePlate", Vector3(body_width * 0.30, 0.105, 0.025), Vector3(0.0, bumper_y - 0.005, rear_z + 0.095), _make_material(Color(0.83, 0.85, 0.79, 1.0), 0.6))


func _add_cabin_details(actor: Node3D, _chassis_y: float) -> void:
	var cabin := actor.get_node_or_null("CabinMesh") as MeshInstance3D
	if cabin == null or not cabin.mesh is BoxMesh:
		return
	var cabin_box := cabin.mesh as BoxMesh
	var cabin_center: Vector3 = cabin.position
	var cabin_size: Vector3 = cabin_box.size
	var roof_y: float = cabin_center.y + cabin_size.y * 0.5

	var source_paint: Material = null
	var chassis := actor.get_node_or_null("ChassisMesh") as MeshInstance3D
	if chassis != null:
		source_paint = chassis.material_override
	if source_paint == null:
		source_paint = _make_material(Color(0.75, 0.72, 0.62, 1.0), 0.38, 0.18)

	_add_box("PaintedRoof", Vector3(cabin_size.x * 0.94, 0.09, cabin_size.z * 0.42), Vector3(cabin_center.x, roof_y + 0.035, cabin_center.z + 0.02), source_paint)
	for side: float in [-1.0, 1.0]:
		var side_x: float = side * (cabin_size.x * 0.5 + 0.018)
		_add_box("SideWindow" + str(side), Vector3(0.035, cabin_size.y * 0.52, cabin_size.z * 0.66), Vector3(side_x, cabin_center.y + 0.015, cabin_center.z), _glass_material)
		_add_box("WindowPillarA" + str(side), Vector3(0.07, cabin_size.y * 0.90, 0.075), Vector3(side * cabin_size.x * 0.39, cabin_center.y, cabin_center.z - cabin_size.z * 0.37), source_paint)
		_add_box("WindowPillarB" + str(side), Vector3(0.07, cabin_size.y * 0.90, 0.075), Vector3(side * cabin_size.x * 0.39, cabin_center.y, cabin_center.z + cabin_size.z * 0.05), source_paint)
		_add_box("WindowPillarC" + str(side), Vector3(0.07, cabin_size.y * 0.90, 0.075), Vector3(side * cabin_size.x * 0.39, cabin_center.y, cabin_center.z + cabin_size.z * 0.37), source_paint)
		_add_box("SideMirrorArm" + str(side), Vector3(0.14, 0.035, 0.06), Vector3(side * (cabin_size.x * 0.5 + 0.06), cabin_center.y + 0.04, cabin_center.z - cabin_size.z * 0.25), _trim_material)
		_add_box("SideMirror" + str(side), Vector3(0.13, 0.11, 0.12), Vector3(side * (cabin_size.x * 0.5 + 0.11), cabin_center.y + 0.08, cabin_center.z - cabin_size.z * 0.25), _glass_material)

	_add_box("Windshield", Vector3(cabin_size.x * 0.75, cabin_size.y * 0.58, 0.028), Vector3(cabin_center.x, cabin_center.y + 0.025, cabin_center.z - cabin_size.z * 0.5 - 0.018), _glass_material)
	_add_box("RearWindow", Vector3(cabin_size.x * 0.70, cabin_size.y * 0.46, 0.028), Vector3(cabin_center.x, cabin_center.y + 0.025, cabin_center.z + cabin_size.z * 0.5 + 0.018), _glass_material)


func _add_wheel_details() -> void:
	var actor := get_parent() as Node3D
	if actor == null:
		return

	var found_vehicle_wheels: bool = false
	for child: Node in actor.get_children():
		if not child is VehicleWheel3D:
			continue
		found_vehicle_wheels = true
		var wheel := child as VehicleWheel3D
		var tire_visual := wheel.get_node_or_null("TireVisual") as MeshInstance3D
		if tire_visual == null:
			continue
		var rim := MeshInstance3D.new()
		rim.name = "RimVisual"
		var rim_mesh := CylinderMesh.new()
		rim_mesh.top_radius = wheel_radius * 0.62
		rim_mesh.bottom_radius = wheel_radius * 0.62
		rim_mesh.height = wheel_width * 1.06
		rim_mesh.radial_segments = 20
		rim.mesh = rim_mesh
		rim.material_override = _rim_material
		rim.rotation_degrees.z = 90.0
		wheel.add_child(rim)

		var hub := MeshInstance3D.new()
		hub.name = "HubCap"
		var hub_mesh := CylinderMesh.new()
		hub_mesh.top_radius = wheel_radius * 0.27
		hub_mesh.bottom_radius = wheel_radius * 0.27
		hub_mesh.height = wheel_width * 1.16
		hub_mesh.radial_segments = 16
		hub.mesh = hub_mesh
		hub.material_override = _trim_material
		hub.rotation_degrees.z = 90.0
		wheel.add_child(hub)

		var outward_sign: float = signf(wheel.position.x)
		for bolt_index: int in range(5):
			var angle: float = TAU * float(bolt_index) / 5.0
			_add_sphere_to(
				wheel,
				"WheelBolt" + str(bolt_index),
				Vector3(0.022, 0.022, 0.022),
				Vector3(outward_sign * wheel_width * 0.60, cos(angle) * wheel_radius * 0.39, sin(angle) * wheel_radius * 0.39),
				_rim_material
			)

	if not found_vehicle_wheels:
		_add_traffic_wheels(actor)


func _add_traffic_wheels(actor: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		for axle: float in [-1.0, 1.0]:
			var tire := MeshInstance3D.new()
			tire.name = "TrafficTire" + str(side) + "_" + str(axle)
			var tire_mesh := CylinderMesh.new()
			tire_mesh.top_radius = wheel_radius
			tire_mesh.bottom_radius = wheel_radius
			tire_mesh.height = wheel_width
			tire_mesh.radial_segments = 16
			tire.mesh = tire_mesh
			tire.material_override = _rubber_material
			tire.rotation_degrees.z = 90.0
			tire.position = Vector3(side * body_width * 0.43, -body_height * 0.5 - 0.01, axle * body_length * 0.31)
			actor.add_child(tire)

			var rim := MeshInstance3D.new()
			rim.name = "TrafficRim" + str(side) + "_" + str(axle)
			var rim_mesh := CylinderMesh.new()
			rim_mesh.top_radius = wheel_radius * 0.58
			rim_mesh.bottom_radius = wheel_radius * 0.58
			rim_mesh.height = wheel_width * 1.06
			rim_mesh.radial_segments = 16
			rim.mesh = rim_mesh
			rim.material_override = _rim_material
			rim.rotation_degrees.z = 90.0
			rim.position = tire.position
			actor.add_child(rim)


func _add_box(part_name: String, dimensions: Vector3, local_position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	instance.mesh = mesh
	instance.material_override = material
	instance.position = local_position
	add_child(instance)
	return instance


func _add_sphere_to(parent: Node3D, part_name: String, scale: Vector3, local_position: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	var mesh := SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 4
	instance.mesh = mesh
	instance.scale = scale
	instance.material_override = material
	instance.position = local_position
	parent.add_child(instance)
	return instance


func _make_material(color: Color, roughness: float = 0.72, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _make_emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := _make_material(color, 0.38, 0.12)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
