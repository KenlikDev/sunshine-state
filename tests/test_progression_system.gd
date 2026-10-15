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
	_check(EconomyService.get_balance() == 400, "A new game starts with the configured test currency balance.")

	_check(EconomyService.purchase_item("first_aid_kit", "test_purchase_1"), "A valid purchase succeeds.")
	_check(EconomyService.purchase_item("first_aid_kit", "test_purchase_2"), "The same item can be purchased in a distinct transaction.")
	_check(EconomyService.purchase_item("vehicle_repair", "test_purchase_3"), "A second catalog item can be purchased.")
	_check(EconomyService.get_balance() == 50, "Purchases debit the exact price.")
	_check(not EconomyService.purchase_item("first_aid_kit", "test_purchase_insufficient"), "Insufficient funds reject purchases.")
	_check(EconomyService.get_balance() == 50, "Rejected purchases cannot make the balance negative.")
	_check(EconomyService.get_item_count("first_aid_kit") == 2, "Repeated valid purchases increment inventory.")
	_check(
		not EconomyService.purchase_item("first_aid_kit", "test_purchase_1"),
		"Reusing a purchase idempotency key cannot charge the player twice."
	)
	_check(EconomyService.get_balance() == 50, "A duplicate purchase transaction cannot alter the balance.")
	_check(EconomyService.get_item_count("first_aid_kit") == 2, "A duplicate purchase transaction cannot increment inventory.")
	var fractional_sequence_data: Dictionary = EconomyService.get_save_data()
	fractional_sequence_data["purchase_sequence"] = 1.5
	_check(
		not EconomyService.is_save_data_valid(fractional_sequence_data),
		"Fractional transaction counters are rejected by save validation."
	)
	var fractional_inventory_data: Dictionary = EconomyService.get_save_data()
	var fractional_inventory: Dictionary = fractional_inventory_data["inventory"]
	fractional_inventory["first_aid_kit"] = 2.5
	fractional_inventory_data["inventory"] = fractional_inventory
	_check(
		not EconomyService.is_save_data_valid(fractional_inventory_data),
		"Fractional inventory counts are rejected by save validation."
	)
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
	var day_night: Node = world.get_node_or_null("DayNightCycle") if world != null else null
	_check(player != null, "Bootstrap creates the player for interaction missions.")
	_check(world != null, "Bootstrap creates the world and objective interactables.")
	_check(day_night != null, "The active world exposes its day-night clock.")
	var first_target: Node3D = MissionService.get_active_target_node()
	_check(
		is_instance_valid(first_target) and first_target.name == "DistrictInformationBoard",
		"The active orientation mission points at the district information board."
	)
	var hud: Node = instance.get_node_or_null("HUD")
	var waypoint_label: Label = hud.find_child("MissionWaypoint", true, false) as Label if hud != null else null
	_check(waypoint_label != null, "HUD exposes an active mission waypoint label.")
	if waypoint_label != null:
		_check(not waypoint_label.text.is_empty(), "HUD shows a direction and distance for the active target.")
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
	var property_target: Node3D = MissionService.get_active_target_node()
	_check(
		is_instance_valid(property_target) and property_target.name == "GraffitiSpot",
		"Completing mission one redirects the waypoint to the property-damage site."
	)
	_check(EconomyService.get_balance() == 400, "Mission one grants its reward exactly once.")
	EconomyService.grant_reward(100, "mission_reward:district_orientation")
	_check(EconomyService.get_balance() == 400, "A duplicate reward transaction cannot increase the balance.")

	var crime_site: Node = world.get_node_or_null("GraffitiSpot")
	_check(crime_site != null, "The property-damage crime interaction exists.")
	if crime_site != null:
		crime_site.call("interact", player)
	_check(MissionService.is_mission_completed("property_report"), "Reporting property damage completes mission two.")
	_check(MissionService.get_current_mission_id() == "supply_run", "Mission three activates after mission two.")
	var supply_target: Node3D = MissionService.get_active_target_node()
	_check(
		is_instance_valid(supply_target) and supply_target.name == "FirstAidVendor",
		"Completing mission two redirects the waypoint to the first-aid vendor."
	)
	_check(EconomyService.get_balance() == 600, "Mission two reward is credited through the economy service.")

	var vendor: Node = world.get_node_or_null("FirstAidVendor")
	_check(vendor != null, "The first-aid vendor exists in the district.")
	if vendor != null:
		vendor.call("interact", player)
	_check(MissionService.is_mission_completed("supply_run"), "Purchasing a first-aid kit completes mission three.")
	_check(MissionService.get_current_mission_id().is_empty(), "The mission chain reaches a stable completion state.")
	_check(
		MissionService.get_active_target_node() == null,
		"Finishing the mission chain removes the active waypoint target."
	)
	_check(EconomyService.get_balance() == 800, "Mission three reward and purchase debit are both applied.")
	_check(EconomyService.get_item_count("first_aid_kit") == 1, "Purchased supplies persist in inventory state.")
	MissionService.record_event(&"PURCHASE_ITEM", &"first_aid_kit")
	_check(EconomyService.get_balance() == 800, "Replaying a completed objective cannot grant another mission reward.")

	var player_health: Node = player.get_node_or_null("Damageable")
	_check(player_health != null, "Player health is available to the first-aid interaction.")
	if player_health != null:
		player_health.call("apply_damage", 60, player)
		_check(int(player_health.get("current_health")) == 40, "The first-aid scenario starts with damaged health.")
		_check(
			String(player.call("use_first_aid_kit")) == "MESSAGE_FIRST_AID_USED",
			"An owned first-aid kit can be consumed successfully."
		)
		_check(int(player_health.get("current_health")) == 90, "A first-aid kit restores the configured amount of health.")
		_check(EconomyService.get_item_count("first_aid_kit") == 0, "Using a first-aid kit consumes one inventory item.")
		_check(
			String(player.call("use_first_aid_kit")) == "MESSAGE_NO_FIRST_AID",
			"A player cannot use another kit after inventory reaches zero."
		)
		_check(int(player_health.get("current_health")) == 90, "Using an unavailable kit does not change health.")

	var repair_shop: Node = world.get_node_or_null("VehicleServiceDesk")
	var repair_vehicle: Node3D = world.get_node_or_null("PrototypeSedan") as Node3D
	_check(repair_shop != null, "The vehicle repair desk exists in the district.")
	_check(repair_vehicle != null, "The test sedan exists in the district.")
	if repair_shop != null and repair_vehicle != null:
		repair_vehicle.global_position = (repair_shop as Node3D).global_position + Vector3(0.0, -0.3, -4.0)
		_check(
			bool(repair_vehicle.call("apply_vehicle_damage", 45)),
			"The vehicle accepts collision damage."
		)
		_check(int(repair_vehicle.call("get_vehicle_health")) == 55, "Collision damage reduces vehicle health.")
		var balance_before_repair: int = EconomyService.get_balance()
		_check(
			String(repair_shop.call("interact", player)) == "MESSAGE_VEHICLE_REPAIRED",
			"A paid repair service repairs a damaged nearby vehicle."
		)
		_check(int(repair_vehicle.call("get_vehicle_health")) == 100, "Repair restores vehicle health to maximum.")
		_check(EconomyService.get_balance() == balance_before_repair - 150, "Repair service charges its catalog price exactly once.")
		_check(
			String(repair_shop.call("interact", player)) == "MESSAGE_NO_DAMAGED_VEHICLE",
			"A fully repaired vehicle is not charged for a redundant repair."
		)
		_check(EconomyService.get_balance() == balance_before_repair - 150, "Rejected redundant repairs do not charge the player.")
		_check(EconomyService.get_item_count("vehicle_repair") == 0, "A repair service is not stored as an inventory token.")

	var expected_saved_vehicle_health: int = -1
	var compact_vehicle: Node = world.get_node_or_null("CompactCoupe")
	var pickup_vehicle: Node = world.get_node_or_null("UtilityPickup")
	_check(compact_vehicle != null and pickup_vehicle != null, "Compact and pickup vehicles are present for persistence coverage.")
	if repair_vehicle != null and compact_vehicle != null and pickup_vehicle != null:
		_check(String(repair_vehicle.get("save_id")) == "sedan", "The sedan has a stable save identifier.")
		_check(String(compact_vehicle.get("save_id")) == "compact_coupe", "The compact coupe has a stable save identifier.")
		_check(String(pickup_vehicle.get("save_id")) == "utility_pickup", "The utility pickup has a stable save identifier.")
		_check(
			bool(repair_vehicle.call("apply_vehicle_damage", 35)),
			"Additional vehicle damage is accepted for persistence validation."
		)
		expected_saved_vehicle_health = int(repair_vehicle.call("get_vehicle_health"))
		_check(expected_saved_vehicle_health == 65, "Vehicle damage establishes a known health value for save tests.")
		await get_tree().create_timer(0.15).timeout
		var autosaved_payload: Dictionary = SaveService.call("_read_valid_payload", SaveService.get_save_data_path())
		var autosaved_world: Dictionary = autosaved_payload.get("world", {})
		var autosaved_vehicle_health: Dictionary = autosaved_world.get("vehicle_health", {})
		_check(
			int(autosaved_vehicle_health.get("sedan", -1)) == expected_saved_vehicle_health,
			"Vehicle damage automatically updates the valid save."
		)
		_check(
			autosaved_vehicle_health.has("compact_coupe") and autosaved_vehicle_health.has("utility_pickup"),
			"Autosaves record all three vehicles by stable ID."
		)
		repair_vehicle.set("current_vehicle_health", 100)
		instance.remove_from_group("gameplay_scene")
		_check(SaveService.load_game(false), "Loading a save without an active gameplay scene succeeds.")
		_check(
			int(repair_vehicle.call("get_vehicle_health")) == 100,
			"Vehicle health restoration waits until a gameplay scene is available."
		)
		instance.add_to_group("gameplay_scene")
		_check(
			SaveService.restore_pending_vehicle_health(),
			"Deferred vehicle health is applied when gameplay becomes available."
		)
		_check(
			int(repair_vehicle.call("get_vehicle_health")) == expected_saved_vehicle_health,
			"Deferred restoration returns the vehicle to its last saved health."
		)
		_check(
			int(compact_vehicle.call("get_vehicle_health")) == 100 and int(pickup_vehicle.call("get_vehicle_health")) == 100,
			"Loading the save restores health for the other vehicle prototypes too."
		)

	var expected_time_of_day: float = -1.0
	if day_night != null:
		day_night.call("set_time_of_day", 21.5)
		expected_time_of_day = float(day_night.call("get_time_of_day"))
	var candidate_payload: Dictionary = SaveService.call("_build_payload")
	var candidate_world: Dictionary = candidate_payload["world"]
	_check(
		absf(float(candidate_world.get("time_of_day_hours", -1.0)) - expected_time_of_day) < 0.001,
		"Save payload captures the current world clock."
	)
	var candidate_vehicle_health: Dictionary = candidate_world.get("vehicle_health", {})
	_check(
		int(candidate_vehicle_health.get("sedan", -1)) == expected_saved_vehicle_health,
		"Save payload serializes the damaged vehicle's current health."
	)
	_check(
		candidate_vehicle_health.has("compact_coupe") and candidate_vehicle_health.has("utility_pickup"),
		"Save payload includes the three stable vehicle identities."
	)
	var legacy_payload: Dictionary = candidate_payload.duplicate(true)
	var legacy_world: Dictionary = legacy_payload["world"]
	legacy_world.erase("vehicle_health")
	legacy_payload["world"] = legacy_world
	_check(
		bool(SaveService.call("_is_valid_payload", legacy_payload)),
		"Existing schema-version-1 saves without vehicle health remain compatible."
	)
	var invalid_vehicle_payload: Dictionary = candidate_payload.duplicate(true)
	var invalid_vehicle_world: Dictionary = invalid_vehicle_payload["world"]
	var invalid_vehicle_health: Dictionary = invalid_vehicle_world["vehicle_health"]
	invalid_vehicle_health["sedan"] = -1
	invalid_vehicle_world["vehicle_health"] = invalid_vehicle_health
	invalid_vehicle_payload["world"] = invalid_vehicle_world
	_check(
		not bool(SaveService.call("_is_valid_payload", invalid_vehicle_payload)),
		"Save validation rejects out-of-range vehicle health."
	)
	var fractional_vehicle_payload: Dictionary = candidate_payload.duplicate(true)
	var fractional_vehicle_world: Dictionary = fractional_vehicle_payload["world"]
	var fractional_vehicle_health: Dictionary = fractional_vehicle_world["vehicle_health"]
	fractional_vehicle_health["sedan"] = 65.5
	fractional_vehicle_world["vehicle_health"] = fractional_vehicle_health
	fractional_vehicle_payload["world"] = fractional_vehicle_world
	_check(
		not bool(SaveService.call("_is_valid_payload", fractional_vehicle_payload)),
		"Save validation rejects fractional vehicle health while accepting whole-number JSON values."
	)
	var invalid_time_payload: Dictionary = candidate_payload.duplicate(true)
	var invalid_time_world: Dictionary = invalid_time_payload["world"]
	invalid_time_world["time_of_day_hours"] = 24.0
	invalid_time_payload["world"] = invalid_time_world
	_check(
		not bool(SaveService.call("_is_valid_payload", invalid_time_payload)),
		"Save validation rejects day times outside the 0-to-24 hour range."
	)
	_check(SaveService.save_game(false), "The completed progression state can be saved.")
	var expected_balance: int = EconomyService.get_balance()
	var expected_inventory: int = EconomyService.get_item_count("first_aid_kit")
	_check(
		int(repair_vehicle.call("get_vehicle_health")) == expected_saved_vehicle_health,
		"The vehicle health is intact at the save/backup checkpoint."
	)
	_check(EconomyService.grant_reward(75, "test_reward_before_backup"), "A committed currency transaction updates the save candidate.")
	await get_tree().create_timer(0.15).timeout
	_check(
		FileAccess.file_exists(SaveService.get_backup_data_path()),
		"A prior valid save is rotated to a backup before replacing the primary."
	)
	_check(
		SaveService.validate_save_file(SaveService.get_backup_data_path()),
		"The backup save validates against all service schemas before corruption recovery."
	)
	if day_night != null:
		day_night.call("set_time_of_day", 7.25)
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
	_check(
		int(repair_vehicle.call("get_vehicle_health")) == expected_saved_vehicle_health,
		"Backup recovery restores the saved vehicle health."
	)
	if day_night != null:
		_check(
			absf(float(day_night.call("get_time_of_day")) - expected_time_of_day) < 0.01,
			"Backup recovery restores the previously saved world time."
		)
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
