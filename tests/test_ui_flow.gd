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
	var original_master_volume: float = SettingsService.get_master_volume()
	var original_fullscreen: bool = SettingsService.get_is_fullscreen()
	var original_resolution_index: int = SettingsService.get_resolution_index()
	SettingsService.set_locale("en")
	SettingsService.set_mouse_sensitivity(0.0025)
	SettingsService.set_master_volume(0.8)
	SettingsService.set_is_fullscreen(false)
	SettingsService.set_resolution_index(0)

	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	_check(menu_scene != null, "Main menu scene loads.")
	if menu_scene == null:
		_finish(1)
		return
	var menu: Control = menu_scene.instantiate() as Control
	add_child(menu)
	await get_tree().process_frame

	var title: Label = menu.find_child("Title", true, false) as Label
	var continue_button: Button = menu.find_child("ContinueButton", true, false) as Button
	var settings_button: Button = menu.find_child("SettingsButton", true, false) as Button
	var sensitivity_slider: HSlider = menu.find_child("SensitivitySlider", true, false) as HSlider
	var language_button: Button = menu.find_child("LanguageButton", true, false) as Button
	var settings_back_button: Button = menu.find_child("SettingsBackButton", true, false) as Button
	var resolution_option: OptionButton = menu.find_child("ResolutionOption", true, false) as OptionButton
	var fullscreen_checkbox: CheckBox = menu.find_child("FullscreenCheckBox", true, false) as CheckBox
	var master_volume_slider: HSlider = menu.find_child("MasterVolumeSlider", true, false) as HSlider
	_check(title != null, "Main menu displays a title.")
	_check(continue_button != null, "Main menu exposes a continue action.")
	_check(settings_button != null, "Main menu exposes settings.")
	_check(sensitivity_slider != null, "Settings expose a mouse-sensitivity slider.")
	_check(resolution_option != null, "Settings expose supported window resolutions.")
	_check(fullscreen_checkbox != null, "Settings expose a fullscreen toggle.")
	_check(master_volume_slider != null, "Settings expose a master-volume slider.")
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
	if resolution_option != null:
		resolution_option.select(1)
		resolution_option.item_selected.emit(1)
		_check(SettingsService.get_resolution_index() == 1, "Selecting a resolution updates saved display settings.")
	if fullscreen_checkbox != null:
		fullscreen_checkbox.set_pressed_no_signal(true)
		fullscreen_checkbox.toggled.emit(true)
		_check(SettingsService.get_is_fullscreen(), "The fullscreen toggle updates display settings.")

	var display_config := ConfigFile.new()
	_check(display_config.load(SettingsService.SETTINGS_PATH) == OK, "Display and audio settings are saved.")
	_check(is_equal_approx(float(display_config.get_value("audio", "master_volume", 0.0)), 0.65), "Master volume persists.")
	_check(int(display_config.get_value("display", "resolution_index", -1)) == 1, "Resolution choice persists.")
	_check(bool(display_config.get_value("display", "fullscreen", false)), "Fullscreen state persists.")

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
	SettingsService.set_master_volume(original_master_volume)
	SettingsService.set_is_fullscreen(original_fullscreen)
	SettingsService.set_resolution_index(original_resolution_index)
	SaveService.delete_save_files()
	save_menu.queue_free()
	menu.queue_free()
	await get_tree().process_frame
	_finish(0 if _failures.is_empty() else 1)


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
