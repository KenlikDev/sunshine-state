extends Node3D
## Presentation-only building mesh. The parent StaticBody3D keeps the original
## authored collision box; only the visible blockout mesh is replaced.

@export var model_scene: PackedScene
@export var target_dimensions: Vector3 = Vector3(12.0, 9.0, 12.0)
@export var target_bottom_y: float = -4.5
@export var yaw_degrees: float = 0.0

var imported_model: Node3D
var model_mesh_count: int = 0


func _ready() -> void:
	var building := get_parent() as StaticBody3D
	if building == null or model_scene == null:
		push_warning("Building visual model has no parent StaticBody3D or imported scene.")
		return

	var blockout_mesh: MeshInstance3D
	for child: Node in building.get_children():
		if child is MeshInstance3D and (child as MeshInstance3D).mesh is BoxMesh:
			blockout_mesh = child as MeshInstance3D
			break
	if blockout_mesh != null:
		blockout_mesh.visible = false

	var model_group := Node3D.new()
	model_group.name = "ModelPivot"
	model_group.rotation.y = deg_to_rad(yaw_degrees)
	add_child(model_group)

	imported_model = model_scene.instantiate() as Node3D
	if imported_model == null:
		push_error("Imported building model root is not a Node3D.")
		return
	imported_model.name = "ImportedBuilding"
	_ensure_fallback_surface_materials(imported_model)
	model_group.add_child(imported_model)
	imported_model.force_update_transform()

	var model_bounds: AABB = _calculate_bounds(imported_model)
	if model_bounds.size.x <= 0.001 or model_bounds.size.y <= 0.001 or model_bounds.size.z <= 0.001:
		push_error("Imported building model has invalid geometry bounds.")
		imported_model.queue_free()
		imported_model = null
		return

	var uniform_scale: float = minf(
		target_dimensions.x / model_bounds.size.x,
		minf(
			target_dimensions.y / model_bounds.size.y,
			target_dimensions.z / model_bounds.size.z
		)
	)
	imported_model.scale = Vector3.ONE * uniform_scale
	imported_model.position = Vector3(
		-model_bounds.get_center().x * uniform_scale,
		target_bottom_y - model_bounds.position.y * uniform_scale,
		-model_bounds.get_center().z * uniform_scale
	)
	imported_model.force_update_transform()
	model_mesh_count = _count_render_meshes(imported_model)
	if model_mesh_count == 0:
		push_error("Imported building model contains no render meshes.")
		imported_model.queue_free()
		imported_model = null


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
