extends Node

signal effect_requested(effect_id: StringName)

const MUSIC_SAMPLE_RATE: int = 11025
const MUSIC_BAR_SECONDS: float = 4.0
const MUSIC_ROOTS: Array[float] = [110.0, 98.0, 130.5, 87.0]
const SUPPORTED_EFFECTS: Array[StringName] = [
	&"ui_click",
	&"ui_confirm",
	&"weapon_fire",
	&"vehicle_impact",
	&"actor_hit"
]

var _music_player: AudioStreamPlayer
var _effect_cache: Dictionary = {}


func _ready() -> void:
	_ensure_audio_bus("Music")
	_ensure_audio_bus("Effects")
	SettingsService.music_volume_changed.connect(_on_music_volume_changed)
	SettingsService.effects_volume_changed.connect(_on_effects_volume_changed)
	_apply_music_volume(SettingsService.get_music_volume())
	_apply_effects_volume(SettingsService.get_effects_volume())

	if DisplayServer.get_name() == "headless":
		return

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "ProceduralAmbientMusic"
	_music_player.bus = "Music"
	_music_player.volume_db = -5.0
	_music_player.stream = build_ambient_music_stream()
	add_child(_music_player)
	_music_player.play()


func build_ambient_music_stream() -> AudioStreamWAV:
	var duration_seconds: float = MUSIC_BAR_SECONDS * float(MUSIC_ROOTS.size())
	var sample_count: int = int(roundf(duration_seconds * float(MUSIC_SAMPLE_RATE)))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)

	for sample_index: int in range(sample_count):
		var time_seconds: float = float(sample_index) / float(MUSIC_SAMPLE_RATE)
		var bar_index: int = mini(
			int(time_seconds / MUSIC_BAR_SECONDS),
			MUSIC_ROOTS.size() - 1
		)
		var bar_time: float = fposmod(time_seconds, MUSIC_BAR_SECONDS)
		var root: float = MUSIC_ROOTS[bar_index]
		var sample_value: float = (
			sin(TAU * root * 0.5 * bar_time) * 0.16
			+ sin(TAU * root * bar_time) * 0.20
			+ sin(TAU * root * 1.5 * bar_time) * 0.11
			+ sin(TAU * root * 2.0 * bar_time) * 0.06
		)
		var pulse: float = 0.9 + 0.08 * sin(TAU * 0.25 * time_seconds)
		var edge_distance: float = minf(time_seconds, duration_seconds - time_seconds)
		var edge_envelope: float = clampf(edge_distance / 0.06, 0.0, 1.0)
		sample_value *= pulse * edge_envelope
		pcm.encode_s16(sample_index * 2, clampi(roundi(sample_value * 32767.0), -32768, 32767))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MUSIC_SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = pcm
	return stream


func build_effect_stream(effect_id: StringName) -> AudioStreamWAV:
	if not SUPPORTED_EFFECTS.has(effect_id):
		return null

	var duration_seconds: float = _effect_duration(effect_id)
	var sample_rate: int = 22050
	var sample_count: int = maxi(1, int(roundf(duration_seconds * float(sample_rate))))
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)

	for sample_index: int in range(sample_count):
		var time_seconds: float = float(sample_index) / float(sample_rate)
		var progress: float = clampf(time_seconds / duration_seconds, 0.0, 1.0)
		var sample_value: float = 0.0

		match effect_id:
			&"ui_click":
				var phase: float = TAU * (1180.0 * time_seconds - 420.0 * time_seconds * time_seconds / (2.0 * duration_seconds))
				sample_value = sin(phase) * exp(-progress * 5.0) * 0.22
			&"ui_confirm":
				var first_tone: float = sin(TAU * 660.0 * time_seconds) * exp(-progress * 3.8)
				var second_time: float = maxf(0.0, time_seconds - 0.065)
				var second_tone: float = (
					sin(TAU * 880.0 * second_time) * exp(-second_time * 7.0)
					if time_seconds >= 0.065 else 0.0
				)
				sample_value = (first_tone * 0.15 + second_tone * 0.13)
			&"weapon_fire":
				var noise: float = (
					sin(float(sample_index) * 12.9898) * 0.52
					+ sin(float(sample_index) * 78.233) * 0.28
				)
				sample_value = (
					noise * 0.28 + sin(TAU * 92.0 * time_seconds) * 0.35
				) * exp(-progress * 7.5) * 0.48
			&"vehicle_impact":
				var impact_noise: float = (
					sin(float(sample_index) * 15.371) * 0.42
					+ sin(float(sample_index) * 49.117) * 0.30
					+ sin(float(sample_index) * 91.713) * 0.18
				)
				sample_value = (
					impact_noise * 0.30
					+ sin(TAU * 58.0 * time_seconds) * 0.44
				) * exp(-progress * 5.2) * 0.55
			&"actor_hit":
				var hit_phase: float = TAU * (220.0 * time_seconds - 110.0 * time_seconds * time_seconds / (2.0 * duration_seconds))
				var hit_noise: float = sin(float(sample_index) * 37.719) * 0.22
				sample_value = (sin(hit_phase) * 0.5 + hit_noise) * exp(-progress * 6.0) * 0.34

		var edge_envelope: float = clampf(minf(progress, 1.0 - progress) / 0.06, 0.0, 1.0)
		sample_value *= edge_envelope
		pcm.encode_s16(sample_index * 2, clampi(roundi(sample_value * 32767.0), -32768, 32767))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = pcm
	return stream


func play_effect(effect_id: StringName) -> void:
	effect_requested.emit(effect_id)
	if DisplayServer.get_name() == "headless" or not SUPPORTED_EFFECTS.has(effect_id):
		return

	var stream: AudioStreamWAV = _get_cached_effect_stream(effect_id)
	if not is_instance_valid(stream):
		return
	var player := AudioStreamPlayer.new()
	player.name = "Effect_%s" % String(effect_id)
	player.bus = "Effects"
	player.volume_db = -1.5
	player.stream = stream
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


func play_ui_click() -> void:
	play_effect(&"ui_click")


func play_ui_confirm() -> void:
	play_effect(&"ui_confirm")


func play_weapon_fire() -> void:
	play_effect(&"weapon_fire")


func play_vehicle_impact() -> void:
	play_effect(&"vehicle_impact")


func play_actor_hit() -> void:
	play_effect(&"actor_hit")


func _get_cached_effect_stream(effect_id: StringName) -> AudioStreamWAV:
	var cached: Variant = _effect_cache.get(effect_id, null)
	if cached is AudioStreamWAV:
		return cached as AudioStreamWAV
	var stream: AudioStreamWAV = build_effect_stream(effect_id)
	if is_instance_valid(stream):
		_effect_cache[effect_id] = stream
	return stream


func _effect_duration(effect_id: StringName) -> float:
	match effect_id:
		&"ui_click":
			return 0.07
		&"ui_confirm":
			return 0.18
		&"weapon_fire":
			return 0.17
		&"vehicle_impact":
			return 0.26
		&"actor_hit":
			return 0.14
	return 0.1


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var bus_index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _apply_music_volume(value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index("Music")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, -80.0 if value <= 0.001 else linear_to_db(value))


func _apply_effects_volume(value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index("Effects")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, -80.0 if value <= 0.001 else linear_to_db(value))


func _on_music_volume_changed(value: float) -> void:
	_apply_music_volume(value)


func _on_effects_volume_changed(value: float) -> void:
	_apply_effects_volume(value)
