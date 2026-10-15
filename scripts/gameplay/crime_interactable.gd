extends StaticBody3D

@export var crime_type: StringName = &"PROPERTY_DAMAGE"
@export_range(1, 5, 1) var severity: int = 1
@export var source_id: StringName = &"GRAFFITI_SITE"
@export var interaction_cooldown_ms: int = 2500

var _cooldown_until_msec: int = 0


func _ready() -> void:
	add_to_group("interactable")
	add_to_group("crime_interactables")


func get_interaction_prompt_key() -> String:
	return "INTERACT_DAMAGE_PROPERTY"


func interact(actor: Node) -> String:
	if not actor is Node3D:
		return "MESSAGE_CRIME_INVALID_ACTOR"

	var now_msec: int = Time.get_ticks_msec()
	if now_msec < _cooldown_until_msec:
		return "MESSAGE_CRIME_COOLDOWN"

	_cooldown_until_msec = now_msec + interaction_cooldown_ms
	WantedSystem.report_crime(
		crime_type,
		severity,
		(actor as Node3D).global_position,
		true,
		source_id
	)
	MissionService.record_event(&"CRIME_REPORTED", source_id)
	return "MESSAGE_CRIME_REPORTED"
