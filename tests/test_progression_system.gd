extends Node

var _failures: Array[String] = []


func _ready() -> void:
	var watchdog: SceneTreeTimer = get_tree().create_timer(35.0)
	watchdog.timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_tests")


func _run_tests() -> void:
	SaveService.delete_save_files()
	EconomyService.set("starting_balance", 400)
	EconomyService.reset_for_new_game()
	MissionService.reset_for_new_game()
	WantedSystem.reset_for_new_game()
	WantedSystem.set("debug_logging", false)

	_check(EconomyService.get_catalog_ids().size() >= 2, "Economy loads a data-driven catalog with multiple items.")
	_check(MissionService.get_mission_count() == 3, "Mission service loads all three connected mission definitions.")
	_check(MissionService.get_current_mission_id() == "district_orientation", "A new game activates the first mission.")
	_check(EconomyService.get_balance() == 300, "A new game starts with the configured currency balance.")

	_check(EconomyService.purchase_item("first_aid_kit", "test_purchase_1"), "A valid purchase succeeds.")
	_check(EconomyService.purchase_item("first_aid_kit", "test_purchase_2"), "The same item can be purchased in a distinct transaction.")
	_check(EconomyService.purchase_item("vehicle_repair", "test_purchase_3"), "A second catalog item can be purchased.")
	_check(EconomyService.get_balance() == 50, "Purchases debit the exact price.")
	_check(not EconomyService.purchase_item("first_aid_kit", "test_purchase_insufficient"), "Insufficient funds reject purchases.")
	_check(EconomyService.get_balance() == 50, "Rejected purchases cannot make the balance negative.")
	_check(EconomyService.get_item_count("first_aid_kit") == 2, "Repeated valid purchases increment inventory.")
	EconomyService.set("starting_balance", 300)
	EconomyService.reset_for_new_game()
	MissionService.reset_for_new_game()

	var main_scene: PackedScene = load("res://scenes/bootstrap/main.tscn")
	_check(main_scene != null, "Main scene resource loads for progression integration.")
	if main_scene == null:
		_finish(1)
		return
	var instance: Node = main_scene.instantiate()
	add_child(instance)
	for _frame: int in range(6):
		await get_tree().physics_frame

	var player: Node3D = instance.get_node_or_null("Player") as Node3D
	var world: Node = instance.get_node_or_null("World")
	_check(player != null, "Bootstrap creates the player for interaction missions.")
	_check(world != null, "Bootstrap creates the world and objective interactables.")
	if player == null or world == null:
		_finish(1, instance)
		return

	MissionService.record_event(&"PLAYER_DEATH", &"PLAYER")
	_check(MissionService.get_mission_state("district_orientation") == "FAILED", "Player death fails an active mission.")
	_check(MissionService.restart_current_mission(), "A failed mission can be restarted.")
	_check(MissionService.get_mission_state("district_orientation") == "ACTIVE", "Restart restores the active mission state.")

	var board: Node = world.get_node_or_null("DistrictInformationBoard")
	_check(board != null, "The district information board exists.")
	if board != null:
		board.call("interact", player)
	_check(MissionService.is_mission_completed("district_orientation"), "Reading the district board completes mission one.")
	_check(MissionService.get_current_mission_id() == "property_report", "Mission two activates after mission one.")
	_check(EconomyService.get_balance() == 400, "Mission one grants its reward exactly once.")
	EconomyService.grant_reward(100, "mission_reward:district_orientation")
	_check(EconomyService.get_balance() == 400, "A duplicate reward transaction cannot increase the balance.")

	var crime_site: Node = world.get_node_or_null("GraffitiSpot")
	_check(crime_site != null, "The property-damage crime interaction exists.")
	if crime_site != null:
		crime_site.call("interact", player)
	_check(MissionService.is_mission_completed("property_report"), "Reporting property damage completes mission two.")
	_check(MissionService.get_current_mission_id() == "supply_run", "Mission three activates after mission two.")
	_check(EconomyService.get_balance() == 600, "Mission two reward is credited through the economy service.")

	var vendor: Node = world.get_node_or_null("FirstAidVendor")
	_check(vendor != null, "The first-aid vendor exists in the district.")
	if vendor != null:
		vendor.call("interact", player)
	_check(MissionService.is_mission_completed("supply_run"), "Purchasing a first-aid kit completes mission three.")
	_check(MissionService.get_current_mission_id().is_empty(), "The mission chain reaches a stable completion state.")
	_check(EconomyService.get_balance() == 800, "Mission three reward and purchase debit are both applied.")
	_check(EconomyService.get_item_count("first_aid_kit") == 1, "Purchased supplies persist in inventory state.")

	_check(SaveService.save_game(false), "The completed progression state can be saved.")
	var expected_balance: int = EconomyService.get_balance()
	var expected_inventory: int = EconomyService.get_item_count("first_aid_kit")
	_check(EconomyService.purchase_item("vehicle_repair", "test_repair_before_backup"), "A repair-service purchase updates the save candidate.")
	await get_tree().create_timer(0.15).timeout
	var corrupt_file: FileAccess = FileAccess.open(SaveService.get_save_data_path(), FileAccess.WRITE)
	_check(corrupt_file != null, "Primary save file can be opened for corruption-recovery validation.")
	if corrupt_file != null:
		corrupt_file.store_string("{ invalid json")
		corrupt_file.close()

	_check(SaveService.load_game(false), "A corrupt primary save recovers from the valid backup.")
	_check(EconomyService.get_balance() == expected_balance, "Backup recovery restores the last known-good currency balance.")
	_check(EconomyService.get_item_count("first_aid_kit") == expected_inventory, "Backup recovery restores inventory.")
	_check(MissionService.is_mission_completed("district_orientation"), "Backup recovery preserves completed mission one.")
	_check(MissionService.is_mission_completed("property_report"), "Backup recovery preserves completed mission two.")
	_check(MissionService.is_mission_completed("supply_run"), "Backup recovery preserves completed mission three.")
	_check(int(WantedSystem.call("get_wanted_level")) >= 0, "Wanted save state remains valid through save/load.")
	_check(SaveService.get_schema_version() == 1, "The save service records a versioned schema.")

	SaveService.delete_save_files()
	_finish(0 if _failures.is_empty() else 1, instance)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)


func _finish(exit_code: int, instance: Node = null) -> void:
	if is_instance_valid(instance):
		instance.queue_free()
	if exit_code == 0 and _failures.is_empty():
		print("Progression-system checks passed.")
	else:
		for failure: String in _failures:
			push_error(failure)
	get_tree().quit(exit_code)


func _on_watchdog_timeout() -> void:
	push_error("Progression regression timed out before completing all checks.")
	get_tree().quit(1)
