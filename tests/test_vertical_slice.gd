extends Node

var _failures: Array[String] = []
var _feedback_messages: Array[String] = []


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var main_scene: PackedScene = load("res://scenes/bootstrap/main.tscn")
	_check(main_scene != null, "Main scene resource loads.")

	if main_scene != null:
		var instance: Node = main_scene.instantiate()
		add_child(instance)
		await get_tree().process_frame
		await get_tree().physics_frame

		_check(instance.get_node_or_null("World") != null, "Bootstrap creates the world.")
		_check(instance.get_node_or_null("Player") is CharacterBody3D, "Bootstrap creates a CharacterBody3D player.")
		_check(instance.get_node_or_null("HUD") is CanvasLayer, "Bootstrap creates the HUD.")
		_check(
			not get_tree().get_nodes_in_group("interactable").is_empty(),
			"District includes at least one interactable object."
		)

		var player: Node = instance.get_node_or_null("Player")
		if player != null:
			_check(player.has_method("get_current_interaction_prompt_key"), "Player exposes the interaction prompt contract.")
			_check(player.has_method("refresh_interaction_prompt"), "Player can refresh its prompt after a locale change.")
			player.connect("interaction_feedback", Callable(self, "_capture_feedback"))
			player.call("refresh_interaction_prompt")
			_check(
				String(player.call("get_current_interaction_prompt_key")) == "INTERACT_READ_BOARD",
				"Player raycast discovers the information board from the spawn position."
			)
			player.call("_try_interact")
			_check(
				_feedback_messages.has("MESSAGE_BOARD_READ"),
				"Interacting with the board emits the expected feedback event."
			)

			var initial_z: float = (player as Node3D).global_position.z
			Input.action_press("move_forward")
			for _frame: int in range(24):
				await get_tree().physics_frame
			Input.action_release("move_forward")
			_check(
				(player as Node3D).global_position.z < initial_z - 0.1,
				"Forward input moves the player through the physics controller."
			)

		var localization: Node = get_node_or_null("/root/Localization")
		_check(localization != null, "Localization autoload is available to game scenes.")
		if localization != null:
			localization.call("set_locale", "ru")
			var russian_objective: String = String(
				localization.call("translate_key", "HUD_OBJECTIVE")
			)
			_check(
				russian_objective.contains("исследуйте район"),
				"Russian UI localization is loaded from the CSV table."
			)
			localization.call("set_locale", "en")

		instance.queue_free()
		await get_tree().process_frame

	if _failures.is_empty():
		print("Vertical-slice checks passed.")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error(failure)
		get_tree().quit(1)


func _capture_feedback(message_key: String) -> void:
	_feedback_messages.append(message_key)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
