extends Node

signal health_changed(current_health: int, max_health: int)
signal died(instigator: Node)

@export_range(1, 1000, 1) var max_health: int = 100

var current_health: int = 100
var is_dead: bool = false


func _ready() -> void:
	max_health = maxi(1, max_health)
	current_health = max_health
	add_to_group("damageable")
	health_changed.emit(current_health, max_health)


func apply_damage(amount: int, instigator: Node = null) -> bool:
	if is_dead or amount <= 0:
		return false

	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health > 0:
		return true

	is_dead = true
	died.emit(instigator)
	var target: Node = get_parent()
	if not is_instance_valid(target):
		return true

	if target.has_method("on_damaged_actor_died"):
		target.call("on_damaged_actor_died", instigator)
	else:
		target.queue_free()
	return true


func apply_healing(amount: int) -> bool:
	if is_dead or amount <= 0 or current_health >= max_health:
		return false
	current_health = mini(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)
	return true


func restore_full_health() -> void:
	is_dead = false
	current_health = max_health
	health_changed.emit(current_health, max_health)
