extends StaticBody3D

@export var item_id: String = "first_aid_kit"


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
	var price: int = int(item.get("price", 0))
	if EconomyService.get_balance() < price:
		return "MESSAGE_INSUFFICIENT_FUNDS"
	if not EconomyService.purchase_item(item_id):
		return "MESSAGE_PURCHASE_FAILED"

	MissionService.record_event(&"PURCHASE_ITEM", StringName(item_id))
	return "MESSAGE_PURCHASED_ITEM"
