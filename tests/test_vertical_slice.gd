extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var main_scene: PackedScene = load("res://scenes/bootstrap/main.tscn")
	_check(main_scene != null, "Main scene resource loads.")

	if main_scene != null:
		var instance: Node = main_scene.instantiate()
		root.add_child(instance)
		await process_frame
		await physics_frame

		_check(instance.get_node_or_null("World") != null, "Bootstrap creates the world.")
		_check(instance.get_node_or_null("Player") is CharacterBody3D, "Bootstrap creates a CharacterBody3D player.")
		_check(instance.get_node_or_null("HUD") is CanvasLayer, "Bootstrap creates the HUD.")
		_check(
			not get_nodes_in_group("interactable").is_empty(),
			"District includes at least one interactable object."
		)

		var player: Node = instance.get_node_or_null("Player")
		if player != null:
			_check(player.has_method("get_current_interaction_prompt_key"), "Player exposes the interaction prompt contract.")
			_check(player.has_method("refresh_interaction_prompt"), "Player can refresh its prompt after a locale change.")

		TranslationServer.set_locale("ru")
		var russian_objective: String = TranslationServer.translate("HUD_OBJECTIVE")
		_check(
			russian_objective.contains("исследуйте район"),
			"Russian UI translation is available at runtime."
		)
		TranslationServer.set_locale("en")
		instance.queue_free()
		await process_frame

	if _failures.is_empty():
		print("Vertical-slice checks passed.")
		quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
