extends StaticBody3D

@export var interaction_prompt_key: String = "INTERACT_READ_BOARD"
@export var interaction_message_key: String = "MESSAGE_BOARD_READ"


func get_interaction_prompt_key() -> String:
	return interaction_prompt_key


func interact(_actor: Node) -> String:
	return interaction_message_key
