extends Node

var _failures: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var watchdog: SceneTreeTimer = get_tree().create_timer(20.0)
	watchdog.timeout.connect(_on_watchdog_timeout)
	call_deferred("_run_tests")


func _run_tests() -> void:
	var original_locale: String = SettingsService.get_locale()
	var original_sensitivity: float = SettingsService.get_mouse_sensitivity()
	SettingsService.set_locale("en")
	SettingsService.set_mouse_sensitivity(0.0025)

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
	_check(title != null, "Main menu displays a title.")
	_check(continue_button != null, "Main menu exposes a continue action.")
	_check(settings_button != null, "Main menu exposes settings.")
	_check(sensitivity_slider != null, "Settings expose a mouse-sensitivity slider.")
	if title != null:
		_check(title.text == Localization.translate_key("MENU_TITLE"), "Main menu text follows the active locale.")
	if continue_button != null:
		_check(
			continue_button.disabled == not SaveService.has_valid_save(),
			"Continue is enabled only when a valid primary or backup save exists."
		)

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

	SettingsService.set_locale(original_locale)
	SettingsService.set_mouse_sensitivity(original_sensitivity)
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
