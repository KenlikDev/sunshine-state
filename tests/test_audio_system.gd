extends Node

var _failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var music: AudioStreamWAV = AudioService.build_ambient_music_stream()
	_check(music != null, "The procedural ambient music stream can be generated.")
	if music != null:
		_check(music.format == AudioStreamWAV.FORMAT_16_BITS, "Ambient music uses signed 16-bit PCM.")
		_check(music.mix_rate == 11025, "Ambient music uses the configured low-cost sample rate.")
		_check(music.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Ambient music loops continuously.")
		_check(music.data.size() > 100000, "Ambient music contains a multi-bar original score.")
		_check(music.loop_end > music.loop_begin, "Ambient music has a valid loop range.")

	for effect_id: StringName in AudioService.SUPPORTED_EFFECTS:
		var effect: AudioStreamWAV = AudioService.build_effect_stream(effect_id)
		_check(effect != null, "Supported effect '%s' can be synthesized." % String(effect_id))
		if effect != null:
			_check(effect.format == AudioStreamWAV.FORMAT_16_BITS, "Effect '%s' uses 16-bit PCM." % String(effect_id))
			_check(effect.mix_rate == 22050, "Effect '%s' uses the configured SFX sample rate." % String(effect_id))
			_check(not effect.data.is_empty(), "Effect '%s' contains generated audio samples." % String(effect_id))
			_check(effect.loop_mode == AudioStreamWAV.LOOP_DISABLED, "Effect '%s' plays once." % String(effect_id))

	var original_music: float = SettingsService.get_music_volume()
	var original_effects: float = SettingsService.get_effects_volume()
	SettingsService.set_music_volume(0.37)
	SettingsService.set_effects_volume(0.62)
	_check(is_equal_approx(SettingsService.get_music_volume(), 0.37), "Music volume setting changes.")
	_check(is_equal_approx(SettingsService.get_effects_volume(), 0.62), "Effects volume setting changes.")
	var config := ConfigFile.new()
	_check(config.load(SettingsService.SETTINGS_PATH) == OK, "Audio settings persist to the user settings file.")
	_check(is_equal_approx(float(config.get_value("audio", "music_volume", 0.0)), 0.37), "Music volume is persisted.")
	_check(is_equal_approx(float(config.get_value("audio", "effects_volume", 0.0)), 0.62), "Effects volume is persisted.")
	SettingsService.set_music_volume(original_music)
	SettingsService.set_effects_volume(original_effects)

	if _failures.is_empty():
		print("Audio-system checks passed.")
	else:
		for failure: String in _failures:
			push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures.append(description)
