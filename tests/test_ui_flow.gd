extends Node

var _failures: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var watchdog: SceneTreeTimer = get_tree().create_timer(20.0)
	watchdog.timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_tests")


func _run_tests() -> void:
	SaveService.delete_save_files()
	var original_locale: String = SettingsService.get_locale()
	var original_sensitivity: float = SettingsService.get_mouse_sensitivity()
	var original_controller_sensitivity: float = SettingsService.get_controller_look_sensitivity()
	var original_controller_y_inverted: bool = SettingsService.get_invert_controller_look_y()
	var original_master_volume: = SettingsService.get_master_volume()
	var original_music_volume: float = SettingsService.get_music_volume()
	var original_effects_volume: float = SettingsService.get_effects_volume()
	var original_fullscreen: bool = SettingsService.get_is_fullscreen()
	var original_resolution_index: int = SettingsService.get_resolution_index()
	var original_ui_scale: float = SettingsService.get_ui_scale()
	var original_high_contrast_hud: bool = SettingsService.get_high_contrast_hud()
	var original_bindings: Dictionary = {}
	for action: StringName in SettingsService.REMAPPABLE_ACTIONS:
		original_bindings[action] = SettingsService.get_binding_keycode(action)
	SettingsService.set_locale("en")
	SettingsService.set_mouse_sensitivity(0.0025)
	SettingsService.set_controller_look_sensitivity(2.5)
	SettingsService.set_invert_controller_look_y(false)
	SettingsService.set_master_volume(0.8)
	SettingsService.set_music_volume(0.28)
	SettingsService.set_effects_volume(0.75)
	SettingsService.set_is_fullscreen(false)
	SettingsService.set_resolution_index(0)
	SettingsService.set_ui_scale(1.0)
	SettingsService.set_high_contrast_hud(false)

	_check(
		_has_joypad_motion(&"move_forward", JOY_AXIS_LEFT_Y, -1.0),
		"Gamepad left-stick input accelerates or moves forward."
	)
	_check(
		_has_joypad_motion(&"move_right", JOY_AXIS_LEFT_X, 1.0),
		"Gamepad left-stick input steers or moves right."
	)
	_check(_has_joypad_button(&"jump", JOY_BUTTON_A), "Gamepad A performs jump or vehicle braking.")
	_check(_has_joypad_button(&"interact", JOY_BUTTON_X), "Gamepad X performs interaction.")
	_check(_has_joypad_button(&"aim_weapon", JOY_BUTTON_LEFT_SHOULDER), "Gamepad left shoulder aims.")
	_check(_has_joypad_button(&"fire_weapon", JOY_BUTTON_RIGHT_SHOULDER), "Gamepad right shoulder fires.")
	_check(_has_joypad_button(&"ui_accept", JOY_BUTTON_A), "Gamepad A activates focused UI controls.")
	_check(_has_joypad_button(&"ui_cancel", JOY_BUTTON_B), "Gamepad B backs out or toggles pause.")

	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	_check(menu_scene != null, "Main menu scene loads.")
	if menu_scene == null:
		_finish(1)
		return
	var menu: Control = menu_scene.instantiate() as Control
	add_child(menu)
	var hud_scene: PackedScene = load("res://scenes/ui/game_hud.tscn")
	var hud: CanvasLayer = hud_scene.instantiate() as CanvasLayer if hud_scene != null else null
	if hud != null:
		add_child(hud)
	await get_tree().process_frame

	var title: Label = menu.find_child("Title", true, false) as Label
	var continue_button: Button = menu.find_child("ContinueButton", true, false) as Button
	var settings_button: Button = menu.find_child("SettingsButton", true, false) as Button
	var sensitivity_slider: HSlider = menu.find_child("SensitivitySlider", true, false) as HSlider
	var controller_sensitivity_slider: HSlider = menu.find_child("ControllerSensitivitySlider", true, false) as HSlider
	var invert_controller_y_checkbox: CheckBox = menu.find_child("InvertControllerYCheckBox", true, false) as CheckBox
	var language_button: Button = menu.find_child("LanguageButton", true, false) as Button
	var settings_back_button: Button = menu.find_child("SettingsBackButton", true, false) as Button
	var resolution_option: OptionButton = menu.find_child("ResolutionOption", true, false) as OptionButton
	var fullscreen_checkbox: CheckBox = menu.find_child("FullscreenCheckBox", true, false) as CheckBox
	var master_volume_slider: HSlider = menu.find_child("MasterVolumeSlider", true, false) as HSlider
	var music_volume_slider: HSlider = menu.find_child("MusicVolumeSlider", true, false) as HSlider
	var effects_volume_slider: HSlider = menu.find_child("EffectsVolumeSlider", true, false) as HSlider
	var ui_scale_slider: HSlider = menu.find_child("UIScaleSlider", true, false) as HSlider
	var high_contrast_hud_checkbox: CheckBox = menu.find_child("HighContrastHUDCheckBox", true, false) as CheckBox
	var keyboard_controls_button: Button = menu.find_child("KeyboardControlsButton", true, false) as Button
	var bindings_panel: Control = menu.find_child("InputBindingsPanel", true, false) as Control
	_check(title != null, "Main menu displays a title.")
	_check(continue_button != null, "Main menu exposes a continue action.")
	_check(settings_button != null, "Main menu exposes settings.")
	_check(sensitivity_slider != null, "Settings expose a mouse-sensitivity slider.")
	_check(controller_sensitivity_slider != null, "Settings expose a dedicated gamepad look-sensitivity slider.")
	_check(invert_controller_y_checkbox != null, "Settings expose vertical-axis inversion for the gamepad camera.")
	_check(resolution_option != null, "Settings expose supported window resolutions.")
	_check(fullscreen_checkbox != null, "Settings expose a fullscreen toggle.")
	_check(master_volume_slider != null, "Settings expose a master-volume slider.")
	_check(music_volume_slider != null, "Settings expose a separate music-volume slider.")
	_check(effects_volume_slider != null, "Settings expose a separate effects-volume slider.")
	_check(ui_scale_slider != null, "Accessibility settings expose a UI-scale slider.")
	_check(high_contrast_hud_checkbox != null, "Accessibility settings expose a high-contrast HUD toggle.")
	_check(hud != null, "The game HUD loads for accessibility regression checks.")
	_check(keyboard_controls_button != null, "Settings expose a keyboard-controls panel.")
	_check(bindings_panel != null and not bindings_panel.visible, "Keyboard bindings panel begins closed.")
	if title != null:
		_check(title.text == Localization.translate_key("MENU_TITLE"), "Main menu text follows the active locale.")
	if continue_button != null:
		_check(
			continue_button.disabled == not SaveService.has_valid_save(),
			"Continue is enabled only when a valid primary or backup save exists."
		)
		_check(continue_button.disabled, "Continue is disabled in a clean profile without a save.")

	if settings_button != null:
		settings_button.pressed.emit()
	var settings_center: Control = menu.find_child("SettingsCenter", true, false) as Control
	_check(settings_center != null and settings_center.visible, "Settings can be opened from the main menu.")
	if sensitivity_slider != null:
		sensitivity_slider.value = 0.004
		await get_tree().process_frame
		_check(
			is_equal_approx(SettingsService.get_mouse_sensitivity(), 0.004),
			"Changing the sensitivity slider updates the stored setting."
		)
		var saved_settings := ConfigFile.new()
		_check(saved_settings.load(SettingsService.SETTINGS_PATH) == OK, "User settings are written to disk.")
		_check(
			is_equal_approx(float(saved_settings.get_value("controls", "mouse_sensitivity", 0.0)), 0.004),
			"Camera sensitivity persists outside the running menu."
		)
	if master_volume_slider != null:
		master_volume_slider.value = 65.0
		_check(
			is_equal_approx(SettingsService.get_master_volume(), 0.65),
			"Changing master volume updates AudioServer settings."
		)
	if music_volume_slider != null:
		music_volume_slider.value = 35.0
		_check(is_equal_approx(SettingsService.get_music_volume(), 0.35), "Music volume changes independently.")
	if effects_volume_slider != null:
		effects_volume_slider.value = 60.0
		_check(is_equal_approx(SettingsService.get_effects_volume(), 0.60), "Effects volume changes independently.")
	if ui_scale_slider != null:
		ui_scale_slider.value = 1.2
		_check(
			is_equal_approx(SettingsService.get_ui_scale(), 1.2),
			"UI scaling follows the accessibility slider."
		)
		_check(
			is_equal_approx(get_tree().root.content_scale_factor, 1.2),
			"UI scale is applied to the root window."
		)
	if high_contrast_hud_checkbox != null:
		high_contrast_hud_checkbox.set_pressed_no_signal(true)
		high_contrast_hud_checkbox.toggled.emit(true)
		_check(SettingsService.get_high_contrast_hud(), "High-contrast HUD mode is saved.")
		if hud != null:
			_check(
				bool(hud.call("is_high_contrast_hud_active")),
				"An active HUD applies the high-contrast palette immediately."
			)
	if resolution_option != null:
		resolution_option.select(1)
		resolution_option.item_selected.emit(1)
		_check(SettingsService.get_resolution_index() == 1, "Selecting a resolution updates saved display settings.")
	if fullscreen_checkbox != null:
		fullscreen_checkbox.set_pressed_no_signal(true)
		fullscreen_checkbox.toggled.emit(true)
		_check(SettingsService.get_is_fullscreen(), "The fullscreen toggle updates display settings.")

	if controller_sensitivity_slider != null:
		controller_sensitivity_slider.value = 4.5
		_check(
			is_equal_approx(SettingsService.get_controller_look_sensitivity(), 4.5),
			"Gamepad look sensitivity can be configured independently of mouse sensitivity."
		)
	if invert_controller_y_checkbox != null:
		invert_controller_y_checkbox.set_pressed_no_signal(true)
		invert_controller_y_checkbox.toggled.emit(true)
		_check(
			SettingsService.get_invert_controller_look_y(),
			"The invert-Y option updates controller camera settings."
		)

	var display_config := ConfigFile.new()
	_check(display_config.load(SettingsService.SETTINGS_PATH) == OK, "Display, audio, and input settings are saved.")
	_check(
		is_equal_approx(float(display_config.get_value("controls", "controller_look_sensitivity", 0.0)), 4.5),
		"Gamepad camera sensitivity persists in the controls section."
	)
	_check(
		bool(display_config.get_value("controls", "invert_controller_look_y", false)),
		"Vertical-axis inversion persists in the controls section."
	)
	_check(is_equal_approx(float(display_config.get_value("audio", "master_volume", 0.0)), 0.65), "Master volume persists.")
	_check(is_equal_approx(float(display_config.get_value("audio", "music_volume", 0.0)), 0.35), "Music volume persists independently.")
	_check(is_equal_approx(float(display_config.get_value("audio", "effects_volume", 0.0)), 0.60), "Effects volume persists independently.")
	_check(int(display_config.get_value("display", "resolution_index", -1)) == 1, "Resolution choice persists.")
	_check(bool(display_config.get_value("display", "fullscreen", false)), "Fullscreen state persists.")
	_check(is_equal_approx(float(display_config.get_value("accessibility", "ui_scale", 0.0)), 1.2), "UI scaling persists.")
	_check(bool(display_config.get_value("accessibility", "high_contrast_hud", false)), "High-contrast HUD preference persists.")

	if keyboard_controls_button != null and bindings_panel != null:
		keyboard_controls_button.pressed.emit()
		_check(bindings_panel.visible, "Keyboard controls panel opens from settings.")
		var forward_row: Control = bindings_panel.find_child("BindingRow_move_forward", true, false) as Control
		var forward_change_button: Button = (
			forward_row.find_child("ChangeButton", true, false) as Button
			if forward_row != null else null
		)
		_check(forward_change_button != null, "Movement rows expose a rebind action.")
		if forward_change_button != null:
			forward_change_button.pressed.emit()
			var up_event := InputEventKey.new()
			up_event.pressed = true
			up_event.physical_keycode = KEY_UP
			up_event.keycode = KEY_UP
			SettingsService.call("_input", up_event)
			_check(
				SettingsService.get_binding_keycode(&"move_forward") == KEY_UP,
				"A captured key replaces the default movement binding."
			)
			var binding_config := ConfigFile.new()
			_check(binding_config.load(SettingsService.SETTINGS_PATH) == OK, "Key bindings are persisted to disk.")
			_check(
				int(binding_config.get_value("input", "move_forward", 0)) == KEY_UP,
				"The new movement key code is saved in user settings."
			)
			SettingsService.begin_rebind(&"move_forward")
			var duplicate_event := InputEventKey.new()
			duplicate_event.pressed = true
			duplicate_event.physical_keycode = SettingsService.get_binding_keycode(&"move_backward")
			duplicate_event.keycode = duplicate_event.physical_keycode
			SettingsService.call("_input", duplicate_event)
			_check(
				SettingsService.get_binding_keycode(&"move_forward") == KEY_UP,
				"A key already used by another action is rejected."
			)
		SettingsService.reset_all_bindings()
		_check(
			SettingsService.get_binding_keycode(&"move_forward") == SettingsService.get_default_binding_keycode(&"move_forward"),
			"Reset Defaults restores the original movement binding."
		)
		for action: StringName in SettingsService.REMAPPABLE_ACTIONS:
			var original_code: int = int(original_bindings[action])
			if original_code == SettingsService.get_default_binding_keycode(action):
				SettingsService.reset_binding(action)
			else:
				SettingsService.set_binding_keycode(action, original_code)
		bindings_panel.visible = false

	if language_button != null:
		language_button.pressed.emit()
	_check(SettingsService.get_locale() == "ru", "The settings locale control switches to Russian.")
	var locale_config := ConfigFile.new()
	_check(locale_config.load(SettingsService.SETTINGS_PATH) == OK, "The locale setting is written to disk.")
	_check(String(locale_config.get_value("display", "locale", "")) == "ru", "Locale choice persists in the settings file.")
	if title != null:
		_check(title.text == Localization.translate_key("MENU_TITLE"), "Menu labels refresh when language changes.")
	if language_button != null:
		language_button.pressed.emit()
	_check(SettingsService.get_locale() == "en", "The settings locale control switches back to English.")
	if settings_back_button != null:
		settings_back_button.pressed.emit()
	_check(not settings_center.visible, "The settings panel can be closed.")

	var pause_scene: PackedScene = load("res://scenes/ui/pause_menu.tscn")
	_check(pause_scene != null, "Pause menu scene loads.")
	if pause_scene != null:
		var pause_menu: CanvasLayer = pause_scene.instantiate() as CanvasLayer
		add_child(pause_menu)
		await get_tree().process_frame
		var restart_mission_button: Button = pause_menu.find_child("RestartMissionButton", true, false) as Button
		_check(restart_mission_button != null, "Pause menu exposes mission restart without a keyboard shortcut.")
		var pause_event := InputEventAction.new()
		pause_event.action = &"ui_cancel"
		pause_event.pressed = true
		pause_menu.call("_input", pause_event)
		_check(get_tree().paused, "Escape opens the pause menu and pauses the scene tree.")
		var pause_settings: Control = pause_menu.find_child("SettingsCenter", true, false) as Control
		pause_menu.call("_toggle_settings")
		_check(
			pause_settings != null and pause_settings.visible,
			"Settings can be opened without unpausing gameplay."
		)
		pause_menu.call("_toggle_settings")
		pause_menu.call("_input", pause_event)
		_check(not get_tree().paused, "Escape resumes gameplay and restores scene processing.")
		var mission_id_before_restart: String = MissionService.get_current_mission_id()
		if restart_mission_button != null and not mission_id_before_restart.is_empty():
			pause_menu.call("open_pause_menu")
			_check(not restart_mission_button.disabled, "The active mission can be restarted from the pause menu.")
			restart_mission_button.pressed.emit()
			_check(not get_tree().paused, "Restarting a mission resumes gameplay.")
			_check(
				MissionService.get_mission_state(mission_id_before_restart) == "ACTIVE",
				"The pause-menu action returns the current mission to its active state."
			)
		pause_menu.queue_free()

	_check(SaveService.save_game(false), "The UI regression can create a valid save for overwrite-protection checks.")
	var save_menu: Control = menu_scene.instantiate() as Control
	add_child(save_menu)
	await get_tree().process_frame
	var save_continue_button: Button = save_menu.find_child("ContinueButton", true, false) as Button
	var new_game_button: Button = save_menu.find_child("NewGameButton", true, false) as Button
	var confirmation: ConfirmationDialog = save_menu.find_child("NewGameConfirmation", true, false) as ConfirmationDialog
	_check(
		save_continue_button != null and not save_continue_button.disabled,
		"Continue becomes available when a valid save exists."
	)
	var balance_before_new_game: int = EconomyService.get_balance()
	var mission_before_new_game: String = MissionService.get_current_mission_id()
	if new_game_button != null:
		new_game_button.pressed.emit()
	_check(
		confirmation != null and confirmation.visible,
		"Starting over asks for explicit confirmation when a save exists."
	)
	_check(
		EconomyService.get_balance() == balance_before_new_game
		and MissionService.get_current_mission_id() == mission_before_new_game,
		"Opening the confirmation dialog does not reset active progression."
	)
	if confirmation != null:
		confirmation.get_cancel_button().pressed.emit()
		_check(not confirmation.visible, "Cancel closes the new-game confirmation dialog.")
	_check(
		EconomyService.get_balance() == balance_before_new_game
		and MissionService.get_current_mission_id() == mission_before_new_game,
		"Canceling the confirmation leaves existing progression untouched."
	)

	SettingsService.set_locale(original_locale)
	SettingsService.set_mouse_sensitivity(original_sensitivity)
	SettingsService.set_controller_look_sensitivity(original_controller_sensitivity)
	SettingsService.set_invert_controller_look_y(original_controller_y_inverted)
	SettingsService.set_master_volume(original_master_volume)
	SettingsService.set_music_volume(original_music_volume)
	SettingsService.set_effects_volume(original_effects_volume)
	SettingsService.set_is_fullscreen(original_fullscreen)
	SettingsService.set_resolution_index(original_resolution_index)
	SettingsService.set_ui_scale(original_ui_scale)
	SettingsService.set_high_contrast_hud(original_high_contrast_hud)
	SaveService.delete_save_files()
	save_menu.queue_free()
	menu.queue_free()
	if is_instance_valid(hud):
		hud.queue_free()
	await get_tree().process_frame
	_finish(0 if _failures.is_empty() else 1)


func _has_joypad_button(action: StringName, button_index: int) -> bool:
	if not InputMap.has_action(action):
		return false
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button_index:
			return true
	return false


func _has_joypad_motion(action: StringName, axis: int, axis_value: float) -> bool:
	if not InputMap.has_action(action):
		return false
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
			if motion.axis == axis and is_equal_approx(motion.axis_value, axis_value):
				return true
	return false


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)


func _finish(exit_code: int) -> void:
	get_tree().paused = false
	if exit_code == 0 and _failures.is_empty():
		print("UI-flow checks passed.")
	else:
		for failure: String in _failures:
			push_error(failure)
	get_tree().quit(exit_code)


func _on_watchdog_timeout() -> void:
	push_error("UI-flow regression timed out before completing all checks.")
	get_tree().quit(1)
