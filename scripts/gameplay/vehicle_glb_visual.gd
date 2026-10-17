extends Node3D
## Imports a licensed low-poly vehicle mesh while leaving driving physics in the
## existing VehicleBody3D and its authored collision/wheel nodes.

@export var model_scene: PackedScene
@export var target_dimensions: Vector3 = Vector3(1.8, 1.55, 3.55)
@export var target_bottom_y: float = -0.36
@export var yaw_degrees: float = 180.0
@export var wheel_radius: float = 0.32

var imported_model: Node3D
var model_mesh_count: int = 0
var rotating_wheel_count: int = 0
var _wheel_nodes: Array[MeshInstance3D] = []
var _wheel_base_rotations: Array[Vector3] = []
var _wheel_roll_angle: float = 0.0


func _ready() -> void:
	var vehicle := get_parent() as Node3D
	if vehicle == null or model_scene == null:
		push_warning("Vehicle visual model has no parent vehicle or imported scene.")
		return

	_hide_blockout_meshes(vehicle)
	var model_group := Node3D.new()
	model_group.name = "ModelPivot"
	model_group.rotation.y = deg_to_rad(yaw_degrees)
	add_child(model_group)

	imported_model = model_scene.instantiate() as Node3D
	if imported_model == null:
		push_error("Imported vehicle model root is not a Node3D.")
		model_group.queue_free()
		return
	imported_model.name = "ImportedVehicle"
	_ensure_fallback_surface_materials(imported_model)
	model_group.add_child(imported_model)
	imported_model.force_update_transform()

	var model_bounds: AABB = _calculate_bounds(imported_model)
	if model_bounds.size.x <= 0.001 or model_bounds.size.y <= 0.001 or model_bounds.size.z <= 0.001:
		push_error("Imported vehicle model has invalid geometry bounds.")
		imported_model.queue_free()
		return

	var x_scale: float = target_dimensions.x / model_bounds.size.x
	var y_scale: float = target_dimensions.y / model_bounds.size.y
	var z_scale: float = target_dimensions.z / model_bounds.size.z
	var uniform_scale: float = minf(x_scale, minf(y_scale, z_scale))
	imported_model.scale = Vector3.ONE * uniform_scale
	imported_model.position = Vector3(
		-model_bounds.get_center().x * uniform_scale,
		target_bottom_y - model_bounds.position.y * uniform_scale,
		-model_bounds.get_center().z * uniform_scale
	)
	imported_model.force_update_transform()

	model_mesh_count = _count_render_meshes(imported_model)
	if model_mesh_count == 0:
		push_error("Imported vehicle model contains no render meshes.")
		imported_model.queue_free()
		imported_model = null
		return

	_collect_wheel_nodes(imported_model)
	call_deferred("_disable_prototype_wheel_visuals")


func _physics_process(delta: float) -> void:
	if imported_model == null or _wheel_nodes.is_empty():
		return
	var vehicle := get_parent() as Node3D
	if vehicle == null:
		return
	var signed_speed: float = 0.0
	var steering_angle: float = 0.0
	if vehicle is VehicleBody3D:
		var rigid_vehicle := vehicle as VehicleBody3D
		signed_speed = rigid_vehicle.linear_velocity.dot(-rigid_vehicle.global_transform.basis.z)
		steering_angle = rigid_vehicle.steering
	elif vehicle is CharacterBody3D:
		var moving_vehicle := vehicle as CharacterBody3D
		signed_speed = moving_vehicle.velocity.dot(-moving_vehicle.global_transform.basis.z)
	_wheel_roll_angle = fposmod(_wheel_roll_angle + signed_speed / maxf(wheel_radius, 0.05) * delta, TAU)
	for index: int in range(_wheel_nodes.size()):
		var wheel_mesh := _wheel_nodes[index]
		if not is_instance_valid(wheel_mesh):
			continue
		var next_rotation: Vector3 = _wheel_base_rotations[index]
		next_rotation.x += _wheel_roll_angle
		if String(wheel_mesh.name).to_lower().contains("front"):
			next_rotation.y += steering_angle * 0.55
		wheel_mesh.rotation = next_rotation


func _collect_wheel_nodes(root: Node3D) -> void:
	for candidate: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh == null or not String(mesh_instance.name).to_lower().contains("wheel"):
			continue
		_wheel_nodes.append(mesh_instance)
		_wheel_base_rotations.append(mesh_instance.rotation)
	rotating_wheel_count = _wheel_nodes.size()


func _hide_blockout_meshes(vehicle: Node3D) -> void:
	for node_name: String in ["ChassisMesh", "BodyMesh", "CabinMesh", "BedMesh"]:
		var blockout_mesh := vehicle.get_node_or_null(node_name) as MeshInstance3D
		if blockout_mesh != null:
			blockout_mesh.visible = false


func _disable_prototype_wheel_visuals() -> void:
	var vehicle := get_parent() as Node3D
	if vehicle == null:
		return
	for wheel: Node in vehicle.get_children():
		if not wheel is VehicleWheel3D:
			continue
		var tire := wheel.get_node_or_null("TireVisual") as MeshInstance3D
		if tire != null:
			tire.visible = false
		for child: Node in wheel.get_children():
			if child is MeshInstance3D and String(child.name).begins_with("RimVisual"):
				(child as MeshInstance3D).visible = false


func _calculate_bounds(root: Node3D) -> AABB:
	var minimum: Vector3 = Vector3(1e20, 1e20, 1e20)
	var maximum: Vector3 = Vector3(-1e20, -1e20, -1e20)
	var found_mesh: bool = false

	for candidate: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		mesh_instance.force_update_transform()
		var local_bounds: AABB = mesh_instance.get_aabb()
		for corner_index: int in range(8):
			var corner := Vector3(
				local_bounds.position.x + (local_bounds.size.x if (corner_index & 1) != 0 else 0.0),
				local_bounds.position.y + (local_bounds.size.y if (corner_index & 2) != 0 else 0.0),
				local_bounds.position.z + (local_bounds.size.z if (corner_index & 4) != 0 else 0.0)
			)
			var point: Vector3 = root.to_local(mesh_instance.global_transform * corner)
			minimum = minimum.min(point)
			maximum = maximum.max(point)
			found_mesh = true

	if not found_mesh:
		return AABB()
	return AABB(minimum, maximum - minimum)


func _count_render_meshes(root: Node3D) -> int:
	var count: int = 0
	for candidate: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh != null:
			count += 1
	return count

func _ensure_fallback_surface_materials(root: Node3D) -> void:
	var fallback := StandardMaterial3D.new()
	fallback.resource_name = "FallbackMissingSurface"
	fallback.albedo_color = Color(0.72, 0.70, 0.64, 1.0)
	fallback.roughness = 0.88
	for candidate: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var surface_count: int = mesh_instance.mesh.get_surface_count()
		if mesh_instance.material_override != null:
			for surface_index: int in range(surface_count):
				if mesh_instance.get_surface_override_material(surface_index) != null:
					mesh_instance.set_surface_override_material(surface_index, null)
			continue
		var missing_surfaces: Array[int] = []
		for surface_index: int in range(surface_count):
			var surface_material: Material = mesh_instance.get_surface_override_material(surface_index)
			if surface_material == null:
				surface_material = mesh_instance.mesh.surface_get_material(surface_index)
			if surface_material == null:
				missing_surfaces.append(surface_index)
		if missing_surfaces.is_empty():
			continue
		var local_mesh := mesh_instance.mesh.duplicate(true) as Mesh
		if local_mesh == null:
			continue
		mesh_instance.mesh = local_mesh
		for surface_index: int in missing_surfaces:
			local_mesh.surface_set_material(surface_index, fallback)
