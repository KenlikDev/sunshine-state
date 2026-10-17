extends Node3D
## Uses the rigged, animated CC0 Quaternius character as the default presentation.
## Procedural parts remain as an explicit fallback if model import ever fails.

const IMPORTED_CHARACTER_SCENE: PackedScene = preload("res://assets/characters/quaternius_animated_man.glb")

@export_enum("hero", "pedestrian", "police") var character_style: String = "pedestrian"
@export var skin_tone: Color = Color(0.62, 0.42, 0.30, 1.0)
@export var clothing_color: Color = Color(0.06, 0.35, 0.43, 1.0)

var _imported_visual: Node3D
var _motion_pivot: Node3D
var _smoothed_horizontal_speed: float = 0.0
var _animation_player: AnimationPlayer
var _idle_animation: StringName = &""
var _walk_animation: StringName = &""
var _run_animation: StringName = &""
var _current_animation: StringName = &""
var _shirt_material: StandardMaterial3D
var _pants_material: StandardMaterial3D
var _accent_material: StandardMaterial3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _walk_phase: float = 0.0


func _ready() -> void:
	# Gameplay controllers retain this Node3D as their visibility anchor.
	if _try_build_imported_character():
		return
	_build_character()


func _process(delta: float) -> void:
	if _imported_visual != null:
		_update_rig_animation(delta)
		return

	var actor := get_parent() as CharacterBody3D
	if actor == null:
		return

	var horizontal_speed := Vector2(actor.velocity.x, actor.velocity.z).length()
	var gait := clampf(horizontal_speed / 3.5, 0.0, 1.0)
	if gait > 0.02:
		_walk_phase += delta * (4.5 + horizontal_speed * 1.7)

	var stride := sin(_walk_phase) * 0.58 * gait
	if is_instance_valid(_left_leg):
		_left_leg.rotation.x = lerpf(_left_leg.rotation.x, stride, minf(delta * 10.0, 1.0))
	if is_instance_valid(_right_leg):
		_right_leg.rotation.x = lerpf(_right_leg.rotation.x, -stride, minf(delta * 10.0, 1.0))
	if is_instance_valid(_left_arm):
		_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -stride * 0.72, minf(delta * 10.0, 1.0))
	if is_instance_valid(_right_arm):
		_right_arm.rotation.x = lerpf(_right_arm.rotation.x, stride * 0.72, minf(delta * 10.0, 1.0))


func set_clothing_color(color: Color) -> void:
	clothing_color = color
	if _imported_visual != null:
		_apply_imported_materials()
		return
	if _shirt_material == null:
		return
	_shirt_material.albedo_color = color
	if _pants_material != null:
		_pants_material.albedo_color = color.darkened(0.34)
	if _accent_material != null:
		_accent_material.albedo_color = color.lightened(0.20)


func _build_character() -> void:
	var default_shirt: Color = clothing_color
	if character_style == "police":
		default_shirt = Color(0.035, 0.11, 0.23, 1.0)
	elif character_style == "pedestrian":
		default_shirt = clothing_color

	_shirt_material = _make_material(default_shirt)
	_pants_material = _make_material(default_shirt.darkened(0.34))
	_accent_material = _make_material(default_shirt.lightened(0.20))
	var skin_material := _make_material(skin_tone, 0.9)
	var hair_material := _make_material(Color(0.075, 0.048, 0.035, 1.0), 0.96)
	var shoe_material := _make_material(Color(0.045, 0.055, 0.065, 1.0), 0.72)
	var eye_material := _make_material(Color(0.025, 0.032, 0.035, 1.0), 0.5)
	var shirt_detail_material := _make_material(Color(0.84, 0.80, 0.69, 1.0), 0.75)
	var belt_material := _make_material(Color(0.08, 0.085, 0.075, 1.0), 0.58)
	var metal_material := _make_material(Color(0.68, 0.66, 0.52, 1.0), 0.32, 0.58)

	# Torso, collar, belt, and a small shirt/jacket panel create a clear
	# shoulder-to-waist silhouette rather than a capsule placeholder.
	_add_box("Torso", Vector3(0.54, 0.62, 0.31), _local_position(Vector3(0.0, 1.12, 0.0)), _shirt_material)
	_add_box("Collar", Vector3(0.22, 0.105, 0.335), _local_position(Vector3(0.0, 1.39, -0.004)), _accent_material)
	_add_box("FrontPanel", Vector3(0.19, 0.36, 0.025), _local_position(Vector3(0.0, 1.12, -0.166)), shirt_detail_material)
	_add_box("Belt", Vector3(0.48, 0.075, 0.325), _local_position(Vector3(0.0, 0.84, 0.0)), belt_material)
	_add_box("BeltBuckle", Vector3(0.075, 0.06, 0.025), _local_position(Vector3(0.0, 0.84, -0.171)), metal_material)

	# Neck and head are deliberately separated from the torso so the face
	# reads at normal third-person camera distance.
	_add_cylinder("Neck", 0.075, 0.075, 0.15, _local_position(Vector3(0.0, 1.435, 0.0)), skin_material)
	_add_sphere("Head", Vector3(0.17, 0.215, 0.155), _local_position(Vector3(0.0, 1.535, -0.005)), skin_material)
	_add_sphere("EarLeft", Vector3(0.045, 0.066, 0.034), _local_position(Vector3(-0.166, 1.535, -0.003)), skin_material)
	_add_sphere("EarRight", Vector3(0.045, 0.066, 0.034), _local_position(Vector3(0.166, 1.535, -0.003)), skin_material)
	_add_sphere("EyeLeft", Vector3(0.022, 0.03, 0.014), _local_position(Vector3(-0.061, 1.548, -0.151)), eye_material)
	_add_sphere("EyeRight", Vector3(0.022, 0.03, 0.014), _local_position(Vector3(0.061, 1.548, -0.151)), eye_material)
	_add_box("EyebrowLeft", Vector3(0.055, 0.018, 0.018), _local_position(Vector3(-0.06, 1.592, -0.151)), hair_material)
	_add_box("EyebrowRight", Vector3(0.055, 0.018, 0.018), _local_position(Vector3(0.06, 1.592, -0.151)), hair_material)
	_add_sphere("Nose", Vector3(0.027, 0.043, 0.033), _local_position(Vector3(0.0, 1.505, -0.174)), skin_material)
	_add_box("Mouth", Vector3(0.065, 0.012, 0.014), _local_position(Vector3(0.0, 1.458, -0.157)), hair_material)

	_add_sphere("HairCap", Vector3(0.178, 0.09, 0.166), _local_position(Vector3(0.0, 1.705, 0.0)), hair_material)
	_add_box("HairFringe", Vector3(0.24, 0.075, 0.07), _local_position(Vector3(0.0, 1.655, -0.126)), hair_material)
	_add_box("HairSideLeft", Vector3(0.045, 0.14, 0.12), _local_position(Vector3(-0.148, 1.635, 0.005)), hair_material)
	_add_box("HairSideRight", Vector3(0.045, 0.14, 0.12), _local_position(Vector3(0.148, 1.635, 0.005)), hair_material)

	_create_limb_pivots(_pants_material, shoe_material, skin_material)
	if character_style == "police":
		_create_police_equipment(metal_material, belt_material, hair_material)
	elif character_style == "hero":
		_create_hero_equipment(belt_material, shirt_detail_material)


func _create_limb_pivots(pants: StandardMaterial3D, shoes: StandardMaterial3D, skin: StandardMaterial3D) -> void:
	_left_arm = _create_pivot("LeftArmPivot", Vector3(-0.305, _local_y(1.29), 0.0))
	_right_arm = _create_pivot("RightArmPivot", Vector3(0.305, _local_y(1.29), 0.0))
	for arm: Node3D in [_left_arm, _right_arm]:
		_add_capsule_to(arm, "UpperArm", 0.09, 0.52, Vector3(0.0, -0.235, 0.0), _shirt_material)
		_add_sphere_to(arm, "Hand", Vector3(0.072, 0.08, 0.065), Vector3(0.0, -0.49, -0.005), skin)

	_left_leg = _create_pivot("LeftLegPivot", Vector3(-0.145, _local_y(0.88), 0.0))
	_right_leg = _create_pivot("RightLegPivot", Vector3(0.145, _local_y(0.88), 0.0))
	for leg: Node3D in [_left_leg, _right_leg]:
		_add_capsule_to(leg, "TrouserLeg", 0.105, 0.72, Vector3(0.0, -0.33, 0.0), pants)
		_add_box_to(leg, "Shoe", Vector3(0.17, 0.10, 0.28), Vector3(0.0, -0.80, -0.045), shoes)


func _create_police_equipment(metal: StandardMaterial3D, belt: StandardMaterial3D, hair: StandardMaterial3D) -> void:
	var badge_material := _make_material(Color(0.87, 0.68, 0.22, 1.0), 0.28, 0.55)
	_add_box("PoliceBadge", Vector3(0.10, 0.14, 0.03), _local_position(Vector3(-0.14, 1.245, -0.173)), badge_material)
	_add_box("Radio", Vector3(0.085, 0.15, 0.08), _local_position(Vector3(0.22, 0.93, 0.13)), belt)
	_add_box("ShoulderPatch", Vector3(0.09, 0.12, 0.035), _local_position(Vector3(0.255, 1.30, -0.03)), badge_material)
	_add_box("PoliceCap", Vector3(0.34, 0.10, 0.31), _local_position(Vector3(0.0, 1.77, -0.005)), hair)
	_add_box("CapBrim", Vector3(0.36, 0.035, 0.22), _local_position(Vector3(0.0, 1.728, -0.095)), hair)
	_add_box("ChestStripe", Vector3(0.06, 0.26, 0.025), _local_position(Vector3(0.055, 1.13, -0.17)), metal)


func _create_hero_equipment(belt: StandardMaterial3D, panel: StandardMaterial3D) -> void:
	var pack_material := _make_material(Color(0.12, 0.19, 0.20, 1.0), 0.92)
	_add_box("Backpack", Vector3(0.34, 0.40, 0.14), _local_position(Vector3(0.0, 1.12, 0.205)), pack_material)
	_add_box("BackpackFlap", Vector3(0.28, 0.10, 0.025), _local_position(Vector3(0.0, 1.28, 0.284)), belt)
	_add_box("ShoulderSeamLeft", Vector3(0.07, 0.25, 0.025), _local_position(Vector3(-0.205, 1.20, -0.166)), panel)
	_add_box("ShoulderSeamRight", Vector3(0.07, 0.25, 0.025), _local_position(Vector3(0.205, 1.20, -0.166)), panel)


func set_skin_tone(color: Color) -> void:
	skin_tone = color
	if _imported_visual != null:
		_apply_imported_materials()
		return
	if is_inside_tree():
		var head := get_node_or_null("Head") as MeshInstance3D
		if head != null:
			head.material_override = _make_material(skin_tone, 0.9)


func _try_build_imported_character() -> bool:
	if IMPORTED_CHARACTER_SCENE == null:
		return false

	_imported_visual = IMPORTED_CHARACTER_SCENE.instantiate() as Node3D
	if _imported_visual == null:
		return false
	_imported_visual.name = "QuaterniusCharacter"
	_imported_visual.position = Vector3.ZERO
	_imported_visual.rotation = Vector3.ZERO
	_imported_visual.scale = Vector3.ONE
	_ensure_fallback_surface_materials(_imported_visual)
	add_child(_imported_visual)

	var skeletons := _imported_visual.find_children("*", "Skeleton3D", true, false)
	var skinned_meshes: int = 0
	for candidate: Node in _imported_visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh != null and mesh_instance.skin != null:
			skinned_meshes += 1
	if skeletons.is_empty() or skinned_meshes == 0:
		push_warning(
			"Rigged character asset did not expose a Skeleton3D and skinned mesh (skeletons=%d, skinned_meshes=%d); using the procedural fallback."
			% [skeletons.size(), skinned_meshes]
		)
		_imported_visual.queue_free()
		_imported_visual = null
		return false

	var bounds: AABB = _calculate_imported_bounds(_imported_visual)
	if bounds.size.y <= 0.01:
		_imported_visual.queue_free()
		_imported_visual = null
		return false

	var normalization_scale: float = 1.78 / bounds.size.y
	_imported_visual.scale = Vector3.ONE * normalization_scale
	_imported_visual.position = Vector3(
		-bounds.get_center().x * normalization_scale,
		-position.y - bounds.position.y * normalization_scale,
		-bounds.get_center().z * normalization_scale
	)
	# Keep procedural movement lean outside the imported rig's animation paths.
	var normalized_transform: Transform3D = _imported_visual.transform
	remove_child(_imported_visual)
	_motion_pivot = Node3D.new()
	_motion_pivot.name = "CharacterMotionPivot"
	add_child(_motion_pivot)
	_motion_pivot.add_child(_imported_visual)
	_imported_visual.transform = normalized_transform
	# Godot uses -Z as forward; the source rig is oriented +Z.
	_imported_visual.rotation.y = PI

	var animators := _imported_visual.find_children("*", "AnimationPlayer", true, false)
	if not animators.is_empty():
		_animation_player = animators[0] as AnimationPlayer
		_find_locomotion_animations()
	else:
		push_warning("Rigged character asset has no AnimationPlayer; keeping the rig static until valid animation resources are available.")

	_apply_imported_materials()
	print(
		"Imported Quaternius character (style=%s, skeletons=%d, skinned_meshes=%d, animations=%d)."
		% [character_style, skeletons.size(), skinned_meshes, _animation_player.get_animation_list().size() if _animation_player != null else 0]
	)
	if character_style == "police":
		_add_imported_police_accessories()
	if not _idle_animation.is_empty():
		_animation_player.play(_idle_animation)
		_current_animation = _idle_animation
	return true


func _calculate_imported_bounds(root: Node3D) -> AABB:
	var minimum: Vector3 = Vector3(1e20, 1e20, 1e20)
	var maximum: Vector3 = Vector3(-1e20, -1e20, -1e20)
	var found_mesh: bool = false
	for candidate: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var local_bounds: AABB = mesh_instance.get_aabb()
		for corner_index: int in range(8):
			var corner := Vector3(
				local_bounds.position.x + (local_bounds.size.x if (corner_index & 1) != 0 else 0.0),
				local_bounds.position.y + (local_bounds.size.y if (corner_index & 2) != 0 else 0.0),
				local_bounds.position.z + (local_bounds.size.z if (corner_index & 4) != 0 else 0.0)
			)
			var point: Vector3 = to_local(mesh_instance.global_transform * corner)
			minimum = minimum.min(point)
			maximum = maximum.max(point)
			found_mesh = true
	if not found_mesh:
		return AABB()
	return AABB(minimum, maximum - minimum)


func _find_locomotion_animations() -> void:
	if _animation_player == null:
		return
	for animation_name: StringName in _animation_player.get_animation_list():
		var normalized: String = String(animation_name).to_lower()
		if _idle_animation.is_empty() and (normalized.contains("idle") or normalized.contains("stand")):
			_idle_animation = animation_name
		elif _walk_animation.is_empty() and (normalized.contains("walk") or normalized.contains("jog")):
			_walk_animation = animation_name
		elif _run_animation.is_empty() and (normalized.contains("run") or normalized.contains("sprint")):
			_run_animation = animation_name


func get_locomotion_state() -> String:
	if not _run_animation.is_empty() and _current_animation == _run_animation:
		return "RUN"
	if not _walk_animation.is_empty() and _current_animation == _walk_animation:
		return "WALK"
	return "IDLE"


func _update_rig_animation(delta: float) -> void:
	var actor := get_parent() as CharacterBody3D
	if actor == null:
		return

	var actual_speed: float = Vector2(actor.velocity.x, actor.velocity.z).length()
	var speed_response: float = 15.0 if actual_speed < _smoothed_horizontal_speed else 10.0
	_smoothed_horizontal_speed = move_toward(
		_smoothed_horizontal_speed,
		actual_speed,
		speed_response * delta
	)

	# Fleeing pedestrians and pursuing officers should run even though their
	# designed AI speeds are lower than the player's sprint speed.
	var urgent_locomotion: bool = false
	if actor.has_method("get_ai_state"):
		var actor_state: String = String(actor.call("get_ai_state"))
		urgent_locomotion = actor_state == "ALERT" or actor_state == "PURSUIT"
	var run_threshold: float = 2.75 if urgent_locomotion else 5.4
	var target_animation: StringName = _idle_animation
	if not _run_animation.is_empty() and _smoothed_horizontal_speed >= run_threshold:
		target_animation = _run_animation
	elif not _walk_animation.is_empty() and _smoothed_horizontal_speed >= 0.18:
		target_animation = _walk_animation

	# A small hysteresis band prevents speed changes at turns/collisions from
	# rapidly flipping between walk and run clips.
	if _current_animation == _run_animation and not _run_animation.is_empty():
		if _smoothed_horizontal_speed >= run_threshold - 0.42:
			target_animation = _run_animation
	elif _current_animation == _walk_animation and not _walk_animation.is_empty():
		if _smoothed_horizontal_speed >= 0.12 and target_animation == _idle_animation:
			target_animation = _walk_animation

	if not target_animation.is_empty():
		if target_animation != _current_animation:
			_animation_player.play(target_animation, 0.24)
			_current_animation = target_animation
		if target_animation == _run_animation:
			_animation_player.speed_scale = clampf(_smoothed_horizontal_speed / 4.1, 0.82, 1.35)
		elif target_animation == _walk_animation:
			_animation_player.speed_scale = clampf(_smoothed_horizontal_speed / 1.8, 0.72, 1.22)
		else:
			_animation_player.speed_scale = 1.0

	if _motion_pivot != null:
		var local_velocity: Vector3 = actor.global_transform.basis.inverse() * Vector3(
			actor.velocity.x,
			0.0,
			actor.velocity.z
		)
		var movement_amount: float = clampf(_smoothed_horizontal_speed / 4.5, 0.0, 1.0)
		var target_lean: float = clampf(-local_velocity.x * 0.012, -0.045, 0.045) * movement_amount
		_motion_pivot.rotation.z = lerpf(
			_motion_pivot.rotation.z,
			target_lean,
			clampf(delta * 5.5, 0.0, 1.0)
		)


func _apply_imported_materials() -> void:
	if _imported_visual == null:
		return
	var shirt_color: Color = clothing_color
	if character_style == "police":
		shirt_color = Color(0.025, 0.075, 0.17, 1.0)
	for candidate: Node in _imported_visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := candidate as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		# A node-wide override masks every surface and can conflict with surface overrides
		# in imported glTF scenes. Keep that material setup intact.
		if mesh_instance.material_override != null:
			continue
		var source_mesh: Mesh = mesh_instance.mesh
		var replacements: Array[Dictionary] = []
		for surface_index: int in range(source_mesh.get_surface_count()):
			var source_material: Material = mesh_instance.get_surface_override_material(surface_index)
			if source_material == null:
				source_material = source_mesh.surface_get_material(surface_index)
			if source_material == null:
				continue
			var material_name: String = String(source_material.resource_name).to_lower()
			var replacement: StandardMaterial3D
			if material_name.contains("shirt"):
				replacement = _make_material(shirt_color if not material_name.ends_with("2") else shirt_color.darkened(0.16), 0.84)
			elif material_name.contains("pants"):
				replacement = _make_material(shirt_color.darkened(0.46), 0.9)
			elif material_name.contains("socks"):
				replacement = _make_material(shirt_color.darkened(0.32), 0.88)
			elif material_name.contains("shoe"):
				replacement = _make_material(Color(0.035, 0.039, 0.043, 1.0), 0.48, 0.14)
			elif material_name.contains("skin"):
				replacement = _make_material(skin_tone, 0.83)
			else:
				continue
			replacement.resource_name = source_material.resource_name
			replacements.append({"surface_index": surface_index, "material": replacement})
		if replacements.is_empty():
			continue
		# Edit a scene-local mesh instead of adding per-instance surface overrides.
		var local_mesh := source_mesh.duplicate(true) as Mesh
		if local_mesh == null:
			continue
		mesh_instance.mesh = local_mesh
		for surface_index: int in range(local_mesh.get_surface_count()):
			var existing_override: Material = mesh_instance.get_surface_override_material(surface_index)
			if existing_override != null:
				local_mesh.surface_set_material(surface_index, existing_override)
				mesh_instance.set_surface_override_material(surface_index, null)
		for replacement_record: Dictionary in replacements:
			local_mesh.surface_set_material(
				int(replacement_record["surface_index"]),
				replacement_record["material"] as Material
			)


func _add_imported_police_accessories() -> void:
	var cap_material := _make_material(Color(0.025, 0.06, 0.13, 1.0), 0.78)
	var badge_material := _make_material(Color(0.92, 0.70, 0.19, 1.0), 0.3, 0.5)
	_add_box("PoliceCap", Vector3(0.32, 0.075, 0.29), Vector3(0.0, 0.81, 0.0), cap_material)
	_add_box("PoliceCapBrim", Vector3(0.34, 0.025, 0.16), Vector3(0.0, 0.775, -0.075), cap_material)
	_add_box("PoliceBadge", Vector3(0.085, 0.12, 0.025), Vector3(-0.13, 0.35, -0.175), badge_material)
	_add_box("PoliceShoulderPatch", Vector3(0.075, 0.09, 0.025), Vector3(0.20, 0.38, -0.08), badge_material)


func _create_pivot(part_name: String, local_position: Vector3) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	pivot.position = local_position
	add_child(pivot)
	return pivot


func _add_box(part_name: String, dimensions: Vector3, local_position: Vector3, material: Material) -> MeshInstance3D:
	return _add_box_to(self, part_name, dimensions, local_position, material)


func _add_box_to(parent: Node3D, part_name: String, dimensions: Vector3, local_position: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = part_name
	var shape := BoxMesh.new()
	shape.size = dimensions
	item.mesh = shape
	item.material_override = material
	item.position = local_position
	parent.add_child(item)
	return item


func _add_sphere(part_name: String, radii: Vector3, local_position: Vector3, material: Material) -> MeshInstance3D:
	return _add_sphere_to(self, part_name, radii, local_position, material)


func _add_sphere_to(parent: Node3D, part_name: String, radii: Vector3, local_position: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = part_name
	var shape := SphereMesh.new()
	shape.radial_segments = 16
	shape.rings = 8
	item.mesh = shape
	item.scale = radii
	item.material_override = material
	item.position = local_position
	parent.add_child(item)
	return item


func _add_capsule_to(parent: Node3D, part_name: String, radius: float, height: float, local_position: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = part_name
	var shape := CapsuleMesh.new()
	shape.radius = radius
	shape.height = height
	shape.radial_segments = 12
	shape.rings = 6
	item.mesh = shape
	item.material_override = material
	item.position = local_position
	parent.add_child(item)
	return item


func _add_cylinder(part_name: String, top_radius: float, bottom_radius: float, height: float, local_position: Vector3, material: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.name = part_name
	var shape := CylinderMesh.new()
	shape.top_radius = top_radius
	shape.bottom_radius = bottom_radius
	shape.height = height
	item.mesh = shape
	item.position = local_position
	item.material_override = material
	add_child(item)
	return item


func _local_y(world_y: float) -> float:
	return world_y - position.y


func _local_position(world_position: Vector3) -> Vector3:
	var local := world_position
	local.y -= position.y
	return local


func _make_material(color: Color, roughness: float = 0.82, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

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
		# glTF may combine a node-wide override with per-surface overrides.
		# The node-wide override already wins; drop the redundant surface overrides
		# so Godot does not retain conflicting material bindings.
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
