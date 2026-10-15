extends Control

const ACTION_LABEL_KEYS: Dictionary = {
	&"move_forward": "BINDING_MOVE_FORWARD",
	&"move_backward": "BINDING_MOVE_BACKWARD",
	&"move_left": "BINDING_MOVE_LEFT",
	&"move_right": "BINDING_MOVE_RIGHT",
	&"sprint": "BINDING_SPRINT",
	&"jump": "BINDING_JUMP",
	&"interact": "BINDING_INTERACT",
	&"vehicle_recover": "BINDING_VEHICLE_RECOVER",
	&"fire_weapon": "BINDING_FIRE",
	&"aim_weapon": "BINDING_AIM",
	&"reload_weapon": "BINDING_RELOAD",
	&"use_first_aid_kit": "BINDING_FIRST_AID",
	&"save_game": "BINDING_SAVE",
	&"load_game": "BINDING_LOAD",
	&"restart_mission": "BINDING_RESTART_MISSION",
	&"toggle_language": "BINDING_TOGGLE_LANGUAGE"
}

var _title_label: Label
var _instruction_label: Label
var _status_label: Label
var _rows: Dictionary = {}
var _key_labels: Dictionary = {}
var _change_buttons: Dictionary = {}
var _close_button: Button
var _reset_button: Button
var _listening_action: StringName = &""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 100
	_build_ui()
	SettingsService.binding_change_started.connect(_on_binding_change_started)
	SettingsService.binding_change_completed.connect(_on_binding_change_completed)
	SettingsService.binding_change_cancelled.connect(_on_binding_change_cancelled)
	SettingsService.binding_change_rejected.connect(_on_binding_change_rejected)
	SettingsService.locale_changed.connect(_on_locale_changed)
	_refresh_texts()
	visible = false


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.01, 0.025, 0.035, 0.93)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var center := CenterContainer.new()
	center.name = "BindingsCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.name = "BindingsPanel"
	panel.custom_minimum_size = Vector2(760.0, 0.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.045, 0.06, 0.99)
	panel_style.border_color = Color(0.21, 0.42, 0.44, 0.95)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.name = "BindingsMargin"
	for margin_name: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(margin_name, 24)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "BindingsStack"
	stack.add_theme_constant_override("separation", 10)
	margin.add_child(stack)

	_title_label = Label.new()
	_title_label.name = "BindingsTitle"
	_title_label.add_theme_font_size_override("font_size", 25)
	stack.add_child(_title_label)

	_instruction_label = Label.new()
	_instruction_label.name = "BindingsInstruction"
	_instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_instruction_label)

	var scroll := ScrollContainer.new()
	scroll.name = "BindingsScroll"
	scroll.custom_minimum_size = Vector2(700.0, 430.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)

	var rows_stack := VBoxContainer.new()
	rows_stack.name = "BindingsRows"
	rows_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows_stack.add_theme_constant_override("separation", 5)
	scroll.add_child(rows_stack)

	for action: StringName in SettingsService.REMAPPABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.name = "BindingRow_%s" % String(action)
		row.custom_minimum_size = Vector2(0.0, 34.0)
		row.add_theme_constant_override("separation", 12)
		rows_stack.add_child(row)

		var action_label := Label.new()
		action_label.name = "ActionLabel"
		action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(action_label)

		var key_label := Label.new()
		key_label.name = "KeyLabel"
		key_label.custom_minimum_size = Vector2(115.0, 0.0)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		key_label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.78))
		row.add_child(key_label)

		var change_button := Button.new()
		change_button.name = "ChangeButton"
		change_button.custom_minimum_size = Vector2(120.0, 32.0)
		change_button.pressed.connect(_start_rebind.bind(action))
		row.add_child(change_button)

		_rows[action] = action_label
		_key_labels[action] = key_label
		_change_buttons[action] = change_button

	var footer := HBoxContainer.new()
	footer.name = "BindingsFooter"
	footer.add_theme_constant_override("separation", 10)
	stack.add_child(footer)

	_status_label = Label.new()
	_status_label.name = "BindingStatus"
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(_status_label)

	_reset_button = Button.new()
	_reset_button.name = "ResetDefaultsButton"
	_reset_button.custom_minimum_size = Vector2(145.0, 40.0)
	_reset_button.pressed.connect(_reset_defaults)
	footer.add_child(_reset_button)

	_close_button = Button.new()
	_close_button.name = "CloseBindingsButton"
	_close_button.custom_minimum_size = Vector2(100.0, 40.0)
	_close_button.pressed.connect(_close_panel)
	footer.add_child(_close_button)


func _input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	if SettingsService.get_binding_keycode(&"move_forward") > 0 and _listening_action == &"":
		_close_panel()
		get_viewport().set_input_as_handled()


func _refresh_texts() -> void:
	if not is_instance_valid(_title_label):
		return
	_title_label.text = Localization.translate_key("SETTINGS_KEYBOARD_CONTROLS")
	_instruction_label.text = Localization.translate_key("SETTINGS_BINDINGS_INSTRUCTION")
	_reset_button.text = Localization.translate_key("SETTINGS_RESET_BINDINGS")
	_close_button.text = Localization.translate_key("SETTINGS_BACK")
	for action: StringName in SettingsService.REMAPPABLE_ACTIONS:
		var action_label: Label = _rows[action]
		var key_label: Label = _key_labels[action]
		var change_button: Button = _change_buttons[action]
		action_label.text = Localization.translate_key(String(ACTION_LABEL_KEYS.get(action, String(action))))
		if _listening_action == action:
			key_label.text = Localization.translate_key("SETTINGS_PRESS_KEY")
		else:
			key_label.text = SettingsService.get_binding_label(action)
		change_button.text = Localization.translate_key("SETTINGS_CHANGE_BINDING")
	_status_label.text = Localization.translate_key("SETTINGS_BINDING_STATUS") if _listening_action == &"" else Localization.translate_key("SETTINGS_PRESS_KEY")


func _start_rebind(action: StringName) -> void:
	if SettingsService.begin_rebind(action):
		_listening_action = action
		_refresh_texts()


func _on_binding_change_started(action: StringName) -> void:
	_listening_action = action
	_refresh_texts()


func _on_binding_change_completed(action: StringName, _physical_keycode: int) -> void:
	if _listening_action == action:
		_listening_action = &""
	_refresh_texts()
	_status_label.text = Localization.translate_key("SETTINGS_BINDING_SAVED")


func _on_binding_change_cancelled(action: StringName) -> void:
	if _listening_action == action:
		_listening_action = &""
	_refresh_texts()


func _on_binding_change_rejected(action: StringName, message_key: String) -> void:
	if _listening_action == action:
		_listening_action = &""
	_refresh_texts()
	_status_label.text = Localization.translate_key(message_key)


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()


func _reset_defaults() -> void:
	SettingsService.reset_all_bindings()
	_listening_action = &""
	_refresh_texts()
	_status_label.text = Localization.translate_key("SETTINGS_BINDINGS_RESET")


func _close_panel() -> void:
	SettingsService.cancel_rebind()
	visible = false
