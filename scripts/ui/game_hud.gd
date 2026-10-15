extends CanvasLayer

var _player: Node3D
var _title_label: Label
var _objective_label: Label
var _controls_label: Label
var _prompt_label: Label
var _status_label: Label
var _language_button: Button
var _wanted_label: Label
var _combat_label: Label
var _prompt_key: String = ""
var _status_key: String = "HUD_READY"


func _ready() -> void:
	var screen := Control.new()
	screen.name = "Screen"
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(screen)

	var panel := PanelContainer.new()
	panel.name = "ObjectivePanel"
	panel.position = Vector2(24.0, 24.0)
	panel.custom_minimum_size = Vector2(470.0, 0.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.055, 0.07, 0.88)
	panel_style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", panel_style)
	screen.add_child(panel)

	var margin := MarginContainer.new()
	for margin_name: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(margin_name, 16)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)

	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.97, 0.98))
	stack.add_child(_title_label)

	_objective_label = Label.new()
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.add_theme_font_size_override("font_size", 17)
	_objective_label.add_theme_color_override("font_color", Color(0.88, 0.91, 0.92))
	stack.add_child(_objective_label)

	_controls_label = Label.new()
	_controls_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_controls_label.add_theme_font_size_override("font_size", 13)
	_controls_label.add_theme_color_override("font_color", Color(0.70, 0.76, 0.79))
	stack.add_child(_controls_label)

	_combat_label = Label.new()
	_combat_label.name = "CombatStatus"
	_combat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_combat_label.add_theme_font_size_override("font_size", 14)
	_combat_label.add_theme_color_override("font_color", Color(0.96, 0.83, 0.34))
	stack.add_child(_combat_label)

	_language_button = Button.new()
	_language_button.name = "LanguageButton"
	_language_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_language_button.offset_left = -132.0
	_language_button.offset_top = 24.0
	_language_button.offset_right = -24.0
	_language_button.offset_bottom = 66.0
	_language_button.custom_minimum_size = Vector2(108.0, 42.0)
	_language_button.pressed.connect(_toggle_locale)
	screen.add_child(_language_button)

	_wanted_label = Label.new()
	_wanted_label.name = "WantedStatus"
	_wanted_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_wanted_label.offset_left = -330.0
	_wanted_label.offset_top = 76.0
	_wanted_label.offset_right = -24.0
	_wanted_label.offset_bottom = 108.0
	_wanted_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_wanted_label.add_theme_font_size_override("font_size", 16)
	_wanted_label.add_theme_color_override("font_color", Color(0.96, 0.83, 0.34))
	_wanted_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(_wanted_label)

	WantedSystem.wanted_level_changed.connect(_on_wanted_level_changed)
	WantedSystem.wanted_state_changed.connect(_on_wanted_state_changed)
	MissionService.mission_state_changed.connect(_on_mission_state_changed)
	MissionService.mission_completed.connect(_on_mission_completed)
	MissionService.mission_failed.connect(_on_mission_failed)
	MissionService.mission_restarted.connect(_on_mission_restarted)
	SaveService.save_status_changed.connect(_on_save_status_changed)
	SettingsService.locale_changed.connect(_on_settings_locale_changed)
	if not Input.joy_connection_changed.is_connected(_on_joy_connection_changed):
		Input.joy_connection_changed.connect(_on_joy_connection_changed)

	var crosshair := Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -8.0
	crosshair.offset_top = -18.0
	crosshair.offset_right = 8.0
	crosshair.offset_bottom = 18.0
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_font_size_override("font_size", 24)
	crosshair.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.85))
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(crosshair)

	_prompt_label = Label.new()
	_prompt_label.name = "InteractionPrompt"
	_prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.offset_left = -250.0
	_prompt_label.offset_top = -112.0
	_prompt_label.offset_right = 250.0
	_prompt_label.offset_bottom = -72.0
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 20)
	_prompt_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(_prompt_label)

	_status_label = Label.new()
	_status_label.name = "StatusMessage"
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_status_label.offset_left = -420.0
	_status_label.offset_top = -64.0
	_status_label.offset_right = 420.0
	_status_label.offset_bottom = -28.0
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(0.90, 0.94, 0.96))
	_status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(_status_label)

	_refresh_localized_texts()


func bind_player(player: Node3D) -> void:
	_player = player
	if _player.has_signal("interaction_prompt_changed"):
		_player.connect("interaction_prompt_changed", _on_interaction_prompt_changed)
	if _player.has_signal("interaction_feedback"):
		_player.connect("interaction_feedback", _on_interaction_feedback)
	var health_component: Node = _player.get_node_or_null("Damageable")
	if is_instance_valid(health_component):
		health_component.connect("health_changed", Callable(self, "_on_health_changed"))
	var weapon_component: Node = _player.get_node_or_null("WeaponController")
	if is_instance_valid(weapon_component):
		weapon_component.connect("ammo_changed", Callable(self, "_on_ammo_changed"))
	EconomyService.balance_changed.connect(_on_economy_balance_changed)
	EconomyService.inventory_changed.connect(_on_economy_inventory_changed)
	_prompt_key = String(_player.call("get_current_interaction_prompt_key"))
	_refresh_interaction_prompt()
	_refresh_combat_status()
	_refresh_wanted_status()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_language"):
		_toggle_locale()
		get_viewport().set_input_as_handled()


func _toggle_locale() -> void:
	var current_locale: String = Localization.get_locale()
	var next_locale: String = "ru" if current_locale.begins_with("en") else "en"
	SettingsService.set_locale(next_locale)
	_refresh_localized_texts()
	if is_instance_valid(_player):
		_player.call("refresh_interaction_prompt")


func _refresh_localized_texts() -> void:
	if not is_instance_valid(_title_label):
		return
	_title_label.text = Localization.translate_key("HUD_TITLE")
	_objective_label.text = Localization.translate_key("HUD_OBJECTIVE")
	_controls_label.text = Localization.translate_key("HUD_CONTROLS")
	if not Input.get_connected_joypads().is_empty():
		_controls_label.text += "\n" + Localization.translate_key("HUD_CONTROLLER_CONTROLS")
	_language_button.text = "%s: %s" % [
		Localization.translate_key("HUD_LANGUAGE_LABEL"),
		"RU" if Localization.get_locale().begins_with("ru") else "EN"
	]
	_language_button.tooltip_text = Localization.translate_key("HUD_LANGUAGE_HINT")
	_status_label.text = Localization.translate_key(_status_key)
	_refresh_interaction_prompt()
	_refresh_wanted_status()
	_refresh_mission_status()


func _refresh_interaction_prompt() -> void:
	if not is_instance_valid(_prompt_label):
		return
	if _prompt_key.is_empty():
		_prompt_label.text = ""
	else:
		_prompt_label.text = Localization.format_key("HUD_INTERACT_PROMPT", [Localization.translate_key(_prompt_key)])


func _on_interaction_prompt_changed(prompt_key: String) -> void:
	_prompt_key = prompt_key
	_refresh_interaction_prompt()


func _on_interaction_feedback(message_key: String) -> void:
	_status_key = message_key
	if is_instance_valid(_status_label):
		_status_label.text = Localization.translate_key(_status_key)


func _refresh_wanted_status() -> void:
	if not is_instance_valid(_wanted_label):
		return

	var wanted_level: int = int(WantedSystem.call("get_wanted_level"))
	if wanted_level <= 0:
		_wanted_label.text = ""
		_wanted_label.visible = false
		return

	var state_name: String = String(WantedSystem.call("get_state_name"))
	var state_key: String = "WANTED_STATE_" + state_name
	_wanted_label.text = "%s %d/5 · %s" % [
		Localization.translate_key("HUD_WANTED_LABEL"),
		wanted_level,
		Localization.translate_key(state_key)
	]
	_wanted_label.visible = true


func _on_wanted_level_changed(_level: int) -> void:
	_refresh_wanted_status()


func _on_wanted_state_changed(_state_name: String) -> void:
	_refresh_wanted_status()



func _refresh_combat_status() -> void:
	if not is_instance_valid(_combat_label) or not is_instance_valid(_player):
		return
	var health_component: Node = _player.get_node_or_null("Damageable")
	var weapon_component: Node = _player.get_node_or_null("WeaponController")
	if not is_instance_valid(health_component) or not is_instance_valid(weapon_component):
		_combat_label.text = ""
		return
	_combat_label.text = "%s %d/%d  ·  %s %d/%d  ·  %s $%d  ·  %s %d" % [
		Localization.translate_key("HUD_HEALTH_LABEL"),
		int(health_component.get("current_health")),
		int(health_component.get("max_health")),
		Localization.translate_key("HUD_AMMO_LABEL"),
		int(weapon_component.call("get_current_ammo")),
		int(weapon_component.call("get_reserve_ammo")),
		Localization.translate_key("HUD_MONEY_LABEL"),
		EconomyService.get_balance(),
		Localization.translate_key("HUD_FIRST_AID_LABEL"),
		EconomyService.get_item_count("first_aid_kit")
	]


func _on_health_changed(_current_health: int, _max_health: int) -> void:
	_refresh_combat_status()


func _on_ammo_changed(_current_ammo: int, _reserve_ammo: int) -> void:
	_refresh_combat_status()



func _refresh_mission_status() -> void:
	if not is_instance_valid(_objective_label):
		return
	var mission: Dictionary = MissionService.get_active_mission()
	if mission.is_empty():
		_objective_label.text = Localization.translate_key("HUD_ALL_MISSIONS_COMPLETE")
		return

	var title: String = Localization.translate_key(String(mission.get("title_key", "HUD_OBJECTIVE")))
	var objective: String = Localization.translate_key(String(mission.get("objective_key", "HUD_OBJECTIVE")))
	var state: String = String(mission.get("state", "ACTIVE"))
	_objective_label.text = "%s\n%s" % [title, objective]
	if state == "FAILED":
		_objective_label.text += "\n" + Localization.translate_key("HUD_MISSION_FAILED_HINT")


func _on_mission_state_changed(_mission_id: String, _state: String) -> void:
	_refresh_mission_status()


func _on_mission_completed(_mission_id: String, _reward: int) -> void:
	_status_key = "MESSAGE_MISSION_COMPLETED"
	if is_instance_valid(_status_label):
		_status_label.text = Localization.translate_key(_status_key)
	_refresh_mission_status()


func _on_mission_failed(_mission_id: String, reason_key: String) -> void:
	_status_key = reason_key
	if is_instance_valid(_status_label):
		_status_label.text = Localization.translate_key(_status_key)
	_refresh_mission_status()


func _on_mission_restarted(_mission_id: String) -> void:
	_status_key = "MESSAGE_MISSION_RESTARTED"
	if is_instance_valid(_status_label):
		_status_label.text = Localization.translate_key(_status_key)
	_refresh_mission_status()


func _on_save_status_changed(message_key: String) -> void:
	_status_key = message_key
	if is_instance_valid(_status_label):
		_status_label.text = Localization.translate_key(_status_key)


func _on_economy_balance_changed(_balance: int) -> void:
	_refresh_combat_status()


func _on_economy_inventory_changed(_item_id: String, _count: int) -> void:
	_refresh_combat_status()


func _on_settings_locale_changed(_locale: String) -> void:
	_refresh_localized_texts()


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	_refresh_localized_texts()
