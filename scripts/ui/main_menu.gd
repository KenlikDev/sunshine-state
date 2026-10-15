extends Control

const GAME_SCENE: String = "res://scenes/bootstrap/main.tscn"
const INPUT_BINDINGS_SCENE: PackedScene = preload("res://scenes/ui/input_bindings_panel.tscn")

var _title_label: Label
var _subtitle_label: Label
var _new_game_button: Button
var _continue_button: Button
var _settings_button: Button
var _quit_button: Button
var _new_game_confirmation: ConfirmationDialog
var _settings_center: CenterContainer
var _settings_title: Label
var _language_label: Label
var _language_button: Button
var _keyboard_controls_button: Button
var _input_bindings_panel: Control
var _resolution_label: Label
var _resolution_option: OptionButton
var _fullscreen_checkbox: CheckBox
var _master_volume_label: Label
var _master_volume_slider: HSlider
var _music_volume_label: Label
var _music_volume_slider: HSlider
var _effects_volume_label: Label
var _effects_volume_slider: HSlider
var _sensitivity_label: Label
var _sensitivity_slider: HSlider
var _controller_sensitivity_label: Label
var _controller_sensitivity_slider: HSlider
var _invert_controller_y_checkbox: CheckBox
var _settings_back_button: Button
var _status_label: Label
var _status_key: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	_input_bindings_panel = INPUT_BINDINGS_SCENE.instantiate() as Control
	_input_bindings_panel.name = "InputBindingsPanel"
	add_child(_input_bindings_panel)
	SettingsService.locale_changed.connect(_on_locale_changed)
	_refresh_texts()
	if DisplayServer.get_name() != "headless":
		_new_game_button.grab_focus()
	if OS.get_environment("SUNSHINE_STATE_SMOKE_TEST") == "1":
		call_deferred("_start_new_game")


func _build_ui() -> void:
	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.035, 0.075, 0.105, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var horizon := ColorRect.new()
	horizon.name = "CoastalHorizon"
	horizon.color = Color(0.06, 0.20, 0.25, 0.55)
	horizon.anchor_top = 0.56
	horizon.anchor_bottom = 1.0
	horizon.anchor_right = 1.0
	horizon.offset_bottom = 0.0
	background.add_child(horizon)

	var menu_center := CenterContainer.new()
	menu_center.name = "MenuCenter"
	menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_center)

	var menu_panel := PanelContainer.new()
	menu_panel.name = "MenuPanel"
	menu_panel.custom_minimum_size = Vector2(480.0, 0.0)
	_style_panel(menu_panel, Color(0.025, 0.045, 0.06, 0.96))
	menu_center.add_child(menu_panel)

	var menu_margin := MarginContainer.new()
	menu_margin.name = "MenuMargin"
	for margin_name: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		menu_margin.add_theme_constant_override(margin_name, 30)
	menu_panel.add_child(menu_margin)

	var menu_stack := VBoxContainer.new()
	menu_stack.name = "MenuStack"
	menu_stack.add_theme_constant_override("separation", 12)
	menu_margin.add_child(menu_stack)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 36)
	_title_label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.92))
	menu_stack.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.name = "Subtitle"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_label.add_theme_font_size_override("font_size", 15)
	_subtitle_label.add_theme_color_override("font_color", Color(0.61, 0.76, 0.79))
	menu_stack.add_child(_subtitle_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 8.0)
	menu_stack.add_child(spacer)

	var menu_actions := VBoxContainer.new()
	menu_actions.name = "MenuActions"
	menu_actions.add_theme_constant_override("separation", 9)
	menu_stack.add_child(menu_actions)
	_new_game_button = _make_button("NewGameButton", Callable(self, "_request_new_game"))
	_continue_button = _make_button("ContinueButton", Callable(self, "_continue_game"))
	_settings_button = _make_button("SettingsButton", Callable(self, "_toggle_settings"))
	_quit_button = _make_button("QuitButton", Callable(self, "_quit_game"))
	for action_button: Button in [_new_game_button, _continue_button, _settings_button, _quit_button]:
		menu_actions.add_child(action_button)

	_settings_center = CenterContainer.new()
	_settings_center.name = "SettingsCenter"
	_settings_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_center.visible = false
	add_child(_settings_center)

	var settings_panel := PanelContainer.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.custom_minimum_size = Vector2(500.0, 0.0)
	_style_panel(settings_panel, Color(0.025, 0.045, 0.06, 0.99))
	_settings_center.add_child(settings_panel)

	var settings_margin := MarginContainer.new()
	settings_margin.name = "SettingsMargin"
	for margin_name: String in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		settings_margin.add_theme_constant_override(margin_name, 28)
	settings_panel.add_child(settings_margin)

	var settings_scroll := ScrollContainer.new()
	settings_scroll.name = "SettingsScroll"
	settings_scroll.custom_minimum_size = Vector2(440.0, 510.0)
	settings_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	settings_margin.add_child(settings_scroll)

	var settings_stack := VBoxContainer.new()
	settings_stack.name = "SettingsStack"
	settings_stack.add_theme_constant_override("separation", 14)
	settings_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_scroll.add_child(settings_stack)

	_settings_title = Label.new()
	_settings_title.name = "SettingsTitle"
	_settings_title.add_theme_font_size_override("font_size", 26)
	settings_stack.add_child(_settings_title)

	_language_label = Label.new()
	_language_label.name = "LanguageLabel"
	settings_stack.add_child(_language_label)
	_language_button = _make_button("LanguageButton", Callable(self, "_toggle_locale"))
	settings_stack.add_child(_language_button)
	_keyboard_controls_button = _make_button("KeyboardControlsButton", Callable(self, "_toggle_input_bindings"))
	settings_stack.add_child(_keyboard_controls_button)

	_resolution_label = Label.new()
	_resolution_label.name = "ResolutionLabel"
	settings_stack.add_child(_resolution_label)
	_resolution_option = OptionButton.new()
	_resolution_option.name = "ResolutionOption"
	for resolution: Vector2i in SettingsService.get_resolution_presets():
		_resolution_option.add_item("%d × %d" % [resolution.x, resolution.y])
	_resolution_option.select(SettingsService.get_resolution_index())
	_resolution_option.item_selected.connect(_on_resolution_selected)
	settings_stack.add_child(_resolution_option)

	_fullscreen_checkbox = CheckBox.new()
	_fullscreen_checkbox.name = "FullscreenCheckBox"
	_fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	settings_stack.add_child(_fullscreen_checkbox)

	_master_volume_label = Label.new()
	_master_volume_label.name = "MasterVolumeLabel"
	settings_stack.add_child(_master_volume_label)
	_master_volume_slider = HSlider.new()
	_master_volume_slider.name = "MasterVolumeSlider"
	_master_volume_slider.min_value = 0.0
	_master_volume_slider.max_value = 100.0
	_master_volume_slider.step = 5.0
	_master_volume_slider.value = SettingsService.get_master_volume() * 100.0
	_master_volume_slider.value_changed.connect(_on_master_volume_changed)
	settings_stack.add_child(_master_volume_slider)

	_music_volume_label = Label.new()
	_music_volume_label.name = "MusicVolumeLabel"
	settings_stack.add_child(_music_volume_label)
	_music_volume_slider = HSlider.new()
	_music_volume_slider.name = "MusicVolumeSlider"
	_music_volume_slider.min_value = 0.0
	_music_volume_slider.max_value = 100.0
	_music_volume_slider.step = 5.0
	_music_volume_slider.value = SettingsService.get_music_volume() * 100.0
	_music_volume_slider.value_changed.connect(_on_music_volume_changed)
	settings_stack.add_child(_music_volume_slider)

	_effects_volume_label = Label.new()
	_effects_volume_label.name = "EffectsVolumeLabel"
	settings_stack.add_child(_effects_volume_label)
	_effects_volume_slider = HSlider.new()
	_effects_volume_slider.name = "EffectsVolumeSlider"
	_effects_volume_slider.min_value = 0.0
	_effects_volume_slider.max_value = 100.0
	_effects_volume_slider.step = 5.0
	_effects_volume_slider.value = SettingsService.get_effects_volume() * 100.0
	_effects_volume_slider.value_changed.connect(_on_effects_volume_changed)
	settings_stack.add_child(_effects_volume_slider)

	_sensitivity_label = Label.new()
	_sensitivity_label.name = "SensitivityLabel"
	settings_stack.add_child(_sensitivity_label)
	_sensitivity_slider = HSlider.new()
	_sensitivity_slider.name = "SensitivitySlider"
	_sensitivity_slider.min_value = SettingsService.MIN_MOUSE_SENSITIVITY
	_sensitivity_slider.max_value = SettingsService.MAX_MOUSE_SENSITIVITY
	_sensitivity_slider.step = 0.0005
	_sensitivity_slider.value = SettingsService.get_mouse_sensitivity()
	_sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	settings_stack.add_child(_sensitivity_slider)

	_controller_sensitivity_label = Label.new()
	_controller_sensitivity_label.name = "ControllerSensitivityLabel"
	settings_stack.add_child(_controller_sensitivity_label)
	_controller_sensitivity_slider = HSlider.new()
	_controller_sensitivity_slider.name = "ControllerSensitivitySlider"
	_controller_sensitivity_slider.min_value = SettingsService.MIN_CONTROLLER_LOOK_SENSITIVITY
	_controller_sensitivity_slider.max_value = SettingsService.MAX_CONTROLLER_LOOK_SENSITIVITY
	_controller_sensitivity_slider.step = 0.25
	_controller_sensitivity_slider.value = SettingsService.get_controller_look_sensitivity()
	_controller_sensitivity_slider.value_changed.connect(_on_controller_sensitivity_changed)
	settings_stack.add_child(_controller_sensitivity_slider)

	_invert_controller_y_checkbox = CheckBox.new()
	_invert_controller_y_checkbox.name = "InvertControllerYCheckBox"
	_invert_controller_y_checkbox.toggled.connect(_on_invert_controller_y_toggled)
	settings_stack.add_child(_invert_controller_y_checkbox)

	_settings_back_button = _make_button("SettingsBackButton", Callable(self, "_toggle_settings"))
	settings_stack.add_child(_settings_back_button)

	_status_label = Label.new()
	_status_label.name = "StatusMessage"
	_status_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status_label.offset_left = 40.0
	_status_label.offset_top = -58.0
	_status_label.offset_right = -40.0
	_status_label.offset_bottom = -24.0
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 16)
	_status_label.add_theme_color_override("font_color", Color(0.92, 0.82, 0.49))
	add_child(_status_label)

	_new_game_confirmation = ConfirmationDialog.new()
	_new_game_confirmation.name = "NewGameConfirmation"
	_new_game_confirmation.confirmed.connect(_start_new_game)
	_new_game_confirmation.canceled.connect(_cancel_new_game)
	add_child(_new_game_confirmation)


func _make_button(node_name: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(0.0, 44.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(Callable(AudioService, "play_ui_click"))
	button.pressed.connect(callback)
	return button


func _style_panel(panel: PanelContainer, background_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = Color(0.21, 0.42, 0.44, 0.9)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", style)


func _refresh_texts() -> void:
	_title_label.text = Localization.translate_key("MENU_TITLE")
	_subtitle_label.text = Localization.translate_key("MENU_SUBTITLE")
	_new_game_button.text = Localization.translate_key("MENU_NEW_GAME")
	_continue_button.text = Localization.translate_key("MENU_CONTINUE")
	_settings_button.text = Localization.translate_key("MENU_SETTINGS")
	_quit_button.text = Localization.translate_key("MENU_QUIT")
	_continue_button.disabled = not SaveService.has_valid_save()
	_settings_title.text = Localization.translate_key("SETTINGS_TITLE")
	_language_label.text = Localization.translate_key("SETTINGS_LANGUAGE")
	_language_button.text = Localization.translate_key("SETTINGS_LANGUAGE_BUTTON") + ": " + SettingsService.get_locale().to_upper()
	_keyboard_controls_button.text = Localization.translate_key("SETTINGS_KEYBOARD_CONTROLS")
	_resolution_label.text = Localization.translate_key("SETTINGS_RESOLUTION")
	_resolution_option.select(SettingsService.get_resolution_index())
	_fullscreen_checkbox.text = Localization.translate_key("SETTINGS_FULLSCREEN")
	_fullscreen_checkbox.set_pressed_no_signal(SettingsService.get_is_fullscreen())
	_update_master_volume_label(SettingsService.get_master_volume() * 100.0)
	_master_volume_slider.set_value_no_signal(SettingsService.get_master_volume() * 100.0)
	_update_music_volume_label(SettingsService.get_music_volume() * 100.0)
	_music_volume_slider.set_value_no_signal(SettingsService.get_music_volume() * 100.0)
	_update_effects_volume_label(SettingsService.get_effects_volume() * 100.0)
	_effects_volume_slider.set_value_no_signal(SettingsService.get_effects_volume() * 100.0)
	_settings_back_button.text = Localization.translate_key("SETTINGS_BACK")
	_update_sensitivity_label(SettingsService.get_mouse_sensitivity())
	_update_controller_sensitivity_label(SettingsService.get_controller_look_sensitivity())
	_controller_sensitivity_slider.set_value_no_signal(SettingsService.get_controller_look_sensitivity())
	_invert_controller_y_checkbox.text = Localization.translate_key("SETTINGS_INVERT_CONTROLLER_Y")
	_invert_controller_y_checkbox.set_pressed_no_signal(SettingsService.get_invert_controller_look_y())
	_status_label.text = Localization.translate_key(_status_key) if not _status_key.is_empty() else ""
	_new_game_confirmation.title = Localization.translate_key("MENU_NEW_GAME_CONFIRM_TITLE")
	_new_game_confirmation.dialog_text = Localization.translate_key("MENU_NEW_GAME_CONFIRM_MESSAGE")
	_new_game_confirmation.ok_button_text = Localization.translate_key("MENU_NEW_GAME_CONFIRM")
	_new_game_confirmation.get_cancel_button().text = Localization.translate_key("MENU_CANCEL")


func _request_new_game() -> void:
	if SaveService.has_valid_save():
		_new_game_confirmation.popup_centered()
		return
	_start_new_game()


func _cancel_new_game() -> void:
	_new_game_confirmation.hide()
	_new_game_button.grab_focus()


func _start_new_game() -> void:
	AudioService.play_ui_confirm()
	_new_game_confirmation.hide()
	EconomyService.reset_for_new_game()
	MissionService.reset_for_new_game()
	WantedSystem.reset_for_new_game()
	_enter_game()


func _continue_game() -> void:
	if not SaveService.load_game(false):
		_status_key = "MENU_NO_SAVE_FOUND"
		_refresh_texts()
		return
	_enter_game()


func _enter_game() -> void:
	var change_error: Error = get_tree().change_scene_to_file(GAME_SCENE)
	if change_error != OK:
		_status_key = "MESSAGE_SAVE_FAILED"
		_refresh_texts()


func _toggle_settings() -> void:
	_settings_center.visible = not _settings_center.visible
	$MenuCenter.visible = not _settings_center.visible
	if _settings_center.visible:
		_language_button.grab_focus()
	else:
		_settings_button.grab_focus()


func _toggle_locale() -> void:
	var next_locale: String = "ru" if SettingsService.get_locale() == "en" else "en"
	SettingsService.set_locale(next_locale)


func _on_sensitivity_changed(value: float) -> void:
	SettingsService.set_mouse_sensitivity(value)
	_update_sensitivity_label(value)


func _update_sensitivity_label(value: float) -> void:
	_sensitivity_label.text = Localization.format_key("SETTINGS_MOUSE_SENSITIVITY_VALUE", [value])


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()


func _quit_game() -> void:
	get_tree().quit()



func _on_resolution_selected(index: int) -> void:
	SettingsService.set_resolution_index(index)


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsService.set_is_fullscreen(enabled)


func _on_master_volume_changed(value: float) -> void:
	SettingsService.set_master_volume(value / 100.0)
	_update_master_volume_label(value)


func _update_master_volume_label(value: float) -> void:
	_master_volume_label.text = Localization.format_key("SETTINGS_MASTER_VOLUME_VALUE", [int(roundf(value))])



func _toggle_input_bindings() -> void:
	if not is_instance_valid(_input_bindings_panel):
		return
	_input_bindings_panel.visible = not _input_bindings_panel.visible


func _on_music_volume_changed(value: float) -> void:
	SettingsService.set_music_volume(value / 100.0)
	_update_music_volume_label(value)


func _update_music_volume_label(value: float) -> void:
	_music_volume_label.text = Localization.format_key("SETTINGS_MUSIC_VOLUME_VALUE", [int(roundf(value))])


func _on_effects_volume_changed(value: float) -> void:
	SettingsService.set_effects_volume(value / 100.0)
	_update_effects_volume_label(value)


func _update_effects_volume_label(value: float) -> void:
	_effects_volume_label.text = Localization.format_key("SETTINGS_EFFECTS_VOLUME_VALUE", [int(roundf(value))])



func _on_controller_sensitivity_changed(value: float) -> void:
	SettingsService.set_controller_look_sensitivity(value)
	_update_controller_sensitivity_label(value)


func _update_controller_sensitivity_label(value: float) -> void:
	_controller_sensitivity_label.text = Localization.format_key(
		"SETTINGS_CONTROLLER_LOOK_SENSITIVITY_VALUE",
		[value]
	)


func _on_invert_controller_y_toggled(enabled: bool) -> void:
	SettingsService.set_invert_controller_look_y(enabled)
