extends Node3D

const WORLD_SCENE: PackedScene = preload("res://scenes/world/greybox_district.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")


func _ready() -> void:
	SaveService.load_game(false)
	Localization.set_locale("en")

	var world: Node3D = WORLD_SCENE.instantiate()
	world.name = "World"
	add_child(world)

	var player: CharacterBody3D = PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.position = Vector3(0.0, 0.0, 12.0)
	player.add_to_group("player")
	add_child(player)

	var hud: CanvasLayer = HUD_SCENE.instantiate()
	hud.name = "HUD"
	add_child(hud)
	hud.call("bind_player", player)

	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
