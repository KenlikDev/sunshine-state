extends Node

signal balance_changed(balance: int)
signal inventory_changed(item_id: String, count: int)
signal transaction_committed(transaction_id: String, kind: String, balance: int, amount: int)
signal transaction_rejected(reason_key: String, item_id: String)

const ITEM_CATALOG_PATH: String = "res://data/items/items.json"
const MAX_BALANCE: int = 1000000000

@export_range(0, 1000000, 1) var starting_balance: int = 300

var _balance: int = 0
var _catalog: Dictionary = {}
var _inventory: Dictionary = {}
var _processed_transactions: Dictionary = {}
var _purchase_sequence: int = 0


func _ready() -> void:
	_load_catalog()
	reset_for_new_game()


func get_balance() -> int:
	return _balance


func get_item_count(item_id: String) -> int:
	return int(_inventory.get(item_id, 0))


func get_item_definition(item_id: String) -> Dictionary:
	var definition: Variant = _catalog.get(item_id, {})
	if not definition is Dictionary:
		return {}
	var item_definition: Dictionary = definition
	return item_definition.duplicate(true)


func get_catalog_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id: Variant in _catalog.keys():
		result.append(String(item_id))
	result.sort()
	return result


func purchase_item(item_id: String, idempotency_key: String = "") -> bool:
	var item: Dictionary = get_item_definition(item_id)
	if item.is_empty():
		transaction_rejected.emit("MESSAGE_ITEM_UNAVAILABLE", item_id)
		return false

	var price: int = int(item.get("price", -1))
	if price < 0:
		transaction_rejected.emit("MESSAGE_ITEM_UNAVAILABLE", item_id)
		return false

	var transaction_id: String = idempotency_key
	if transaction_id.is_empty():
		_purchase_sequence += 1
		transaction_id = "purchase:%s:%d" % [item_id, _purchase_sequence]

	if _processed_transactions.has(transaction_id):
		return false
	if _balance < price:
		transaction_rejected.emit("MESSAGE_INSUFFICIENT_FUNDS", item_id)
		return false

	_balance -= price
	_inventory[item_id] = get_item_count(item_id) + 1
	_processed_transactions[transaction_id] = true
	balance_changed.emit(_balance)
	inventory_changed.emit(item_id, get_item_count(item_id))
	transaction_committed.emit(transaction_id, "PURCHASE", _balance, -price)
	return true


func grant_reward(amount: int, idempotency_key: String) -> bool:
	if amount <= 0 or idempotency_key.strip_edges().is_empty():
		return false
	if _processed_transactions.has(idempotency_key):
		return false
	if _balance > MAX_BALANCE - amount:
		return false

	_balance += amount
	_processed_transactions[idempotency_key] = true
	balance_changed.emit(_balance)
	transaction_committed.emit(idempotency_key, "REWARD", _balance, amount)
	return true


func get_save_data() -> Dictionary:
	var transaction_ids: Array[String] = []
	for transaction_id: Variant in _processed_transactions.keys():
		transaction_ids.append(String(transaction_id))
	transaction_ids.sort()
	return {
		"balance": _balance,
		"inventory": _inventory.duplicate(true),
		"processed_transactions": transaction_ids,
		"purchase_sequence": _purchase_sequence
	}


func is_save_data_valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var payload: Dictionary = data
	var balance_value: Variant = payload.get("balance", null)
	if typeof(balance_value) != TYPE_INT and typeof(balance_value) != TYPE_FLOAT:
		return false
	var balance: int = int(balance_value)
	if balance < 0 or balance > MAX_BALANCE:
		return false

	var inventory: Variant = payload.get("inventory", null)
	if not inventory is Dictionary:
		return false
	for item_id: Variant in inventory.keys():
		if not _catalog.has(String(item_id)):
			return false
		var count_value: Variant = inventory[item_id]
		if typeof(count_value) != TYPE_INT or int(count_value) < 0 or int(count_value) > 100000:
			return false

	var transactions: Variant = payload.get("processed_transactions", null)
	if not transactions is Array:
		return false
	for transaction_id: Variant in transactions:
		if not transaction_id is String or String(transaction_id).is_empty():
			return false

	var sequence_value: Variant = payload.get("purchase_sequence", null)
	if typeof(sequence_value) != TYPE_INT or int(sequence_value) < 0:
		return false
	return true


func load_save_data(data: Dictionary) -> bool:
	if not is_save_data_valid(data):
		return false

	_balance = int(data["balance"])
	var inventory_data: Dictionary = data["inventory"]
	_inventory = inventory_data.duplicate(true)
	_processed_transactions.clear()
	for transaction_id: Variant in data["processed_transactions"]:
		_processed_transactions[String(transaction_id)] = true
	_purchase_sequence = int(data["purchase_sequence"])
	balance_changed.emit(_balance)
	for item_id: String in _catalog.keys():
		inventory_changed.emit(item_id, get_item_count(item_id))
	return true


func reset_for_new_game() -> void:
	_balance = clampi(starting_balance, 0, MAX_BALANCE)
	_inventory.clear()
	_processed_transactions.clear()
	_purchase_sequence = 0
	balance_changed.emit(_balance)
	for item_id: String in _catalog.keys():
		inventory_changed.emit(item_id, 0)


func _load_catalog() -> void:
	_catalog.clear()
	var file: FileAccess = FileAccess.open(ITEM_CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open item catalog: %s" % ITEM_CATALOG_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Item catalog must be a JSON object.")
		return
	var catalog_data: Dictionary = parsed
	var item_list: Variant = catalog_data.get("items", null)
	if not item_list is Array:
		push_error("Item catalog must contain an items array.")
		return

	for raw_item: Variant in item_list:
		if not raw_item is Dictionary:
			continue
		var item: Dictionary = raw_item
		var item_id: String = String(item.get("id", ""))
		var price: int = int(item.get("price", -1))
		if item_id.is_empty() or price < 0 or _catalog.has(item_id):
			push_warning("Skipping invalid or duplicate item catalog entry.")
			continue
		_catalog[item_id] = item.duplicate(true)
