extends Node3D

const WORLD_SCENE: PackedScene = preload("res://scenes/world/greybox_district.tscn")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/ui/game_hud.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://scenes/ui/pause_menu.tscn")


func _ready() -> void:
	add_to_group("gameplay_scene")

	var world: Node3D = WORLD_SCENE.instantiate()
	world.name = "World"
	add_child(world)
	var day_night_cycle: Node = world.get_node_or_null("DayNightCycle")
	if is_instance_valid(day_night_cycle):
		SaveService.restore_pending_world_time(day_night_cycle)
	SaveService.restore_pending_vehicle_health()

	var player: CharacterBody3D = PLAYER_SCENE.instantiate()
	player.name = "Player"
	player.position = Vector3(0.0, 0.0, 12.0)
	player.add_to_group("player")
	add_child(player)

	var hud: CanvasLayer = HUD_SCENE.instantiate()
	hud.name = "HUD"
	add_child(hud)
	hud.call("bind_player", player)

	var pause_menu: CanvasLayer = PAUSE_MENU_SCENE.instantiate() as CanvasLayer
	pause_menu.name = "PauseMenu"
	add_child(pause_menu)

	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
