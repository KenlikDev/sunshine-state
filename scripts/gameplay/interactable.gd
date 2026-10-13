extends StaticBody3D

@export var interaction_prompt_key: String = "INTERACT_READ_BOARD"
@export var interaction_message_key: String = "MESSAGE_BOARD_READ"
@export var progression_event_type: StringName = &"INTERACT"
@export var progression_source_id: StringName = &"DISTRICT_BOARD"


func get_interaction_prompt_key() -> String:
	return interaction_prompt_key


func interact(_actor: Node) -> String:
	MissionService.record_event(progression_event_type, progression_source_id)
	return interaction_message_key
