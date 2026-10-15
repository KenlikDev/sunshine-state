extends StaticBody3D

@export var item_id: String = "first_aid_kit"
@export_range(1.0, 20.0, 0.5) var repair_service_radius: float = 9.0


func get_interaction_prompt_key() -> String:
	if item_id == "vehicle_repair":
		return "INTERACT_BUY_REPAIR"
	return "INTERACT_BUY_FIRST_AID"


func interact(actor: Node) -> String:
	if not actor is Node3D:
		return "MESSAGE_CRIME_INVALID_ACTOR"
	if actor.has_method("is_in_vehicle") and bool(actor.call("is_in_vehicle")):
		return "MESSAGE_SHOP_ON_FOOT_ONLY"

	var item: Dictionary = EconomyService.get_item_definition(item_id)
	if item.is_empty():
		return "MESSAGE_ITEM_UNAVAILABLE"

	var target_vehicle: Node3D
	if item_id == "vehicle_repair":
		target_vehicle = _find_damaged_vehicle()
		if not is_instance_valid(target_vehicle):
			return "MESSAGE_NO_DAMAGED_VEHICLE"

	var price: int = int(item.get("price", 0))
	if EconomyService.get_balance() < price:
		return "MESSAGE_INSUFFICIENT_FUNDS"
	var purchase_succeeded: bool = (
		EconomyService.purchase_service(item_id)
		if item_id == "vehicle_repair"
		else EconomyService.purchase_item(item_id)
	)
	if not purchase_succeeded:
		return "MESSAGE_PURCHASE_FAILED"

	if item_id == "vehicle_repair":
		var repaired: bool = bool(target_vehicle.call("repair_vehicle"))
		if not repaired:
			return "MESSAGE_REPAIR_FAILED"
		return "MESSAGE_VEHICLE_REPAIRED"

	MissionService.record_event(&"PURCHASE_ITEM", StringName(item_id))
	return "MESSAGE_PURCHASED_ITEM"


func _find_damaged_vehicle() -> Node3D:
	var nearest_vehicle: Node3D
	var nearest_distance: float = repair_service_radius
	for candidate: Node in get_tree().get_nodes_in_group("vehicles"):
		if not candidate is Node3D or not candidate.has_method("repair_vehicle"):
			continue
		var vehicle: Node3D = candidate as Node3D
		var distance: float = global_position.distance_to(vehicle.global_position)
		if distance > nearest_distance:
			continue
		var current_health: int = int(vehicle.call("get_vehicle_health"))
		var max_health: int = int(vehicle.get("max_vehicle_health"))
		if current_health >= max_health:
			continue
		nearest_vehicle = vehicle
		nearest_distance = distance
	return nearest_vehicle
