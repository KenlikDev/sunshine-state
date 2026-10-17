extends Node

signal time_of_day_changed(hour: float)

@export_range(60.0, 3600.0, 15.0) var full_day_duration_seconds: float = 900.0
@export_range(0.0, 23.99, 0.25) var starting_hour: float = 9.5
@export var advance_time: bool = true

const DAY_BACKGROUND: Color = Color(0.49, 0.72, 0.86, 1.0)
const TWILIGHT_BACKGROUND: Color = Color(0.80, 0.42, 0.31, 1.0)
const NIGHT_BACKGROUND: Color = Color(0.018, 0.032, 0.09, 1.0)
const DAY_AMBIENT: Color = Color(0.72, 0.77, 0.82, 1.0)
const NIGHT_AMBIENT: Color = Color(0.18, 0.22, 0.36, 1.0)
const TWILIGHT_SUN_COLOR: Color = Color(1.0, 0.46, 0.28, 1.0)
const DAY_SUN_COLOR: Color = Color(1.0, 0.96, 0.86, 1.0)
const DAY_SKY_TOP: Color = Color(0.11, 0.43, 0.70, 1.0)
const TWILIGHT_SKY_TOP: Color = Color(0.36, 0.18, 0.36, 1.0)
const NIGHT_SKY_TOP: Color = Color(0.012, 0.024, 0.075, 1.0)
const DAY_SKY_HORIZON: Color = Color(0.71, 0.86, 0.90, 1.0)
const TWILIGHT_SKY_HORIZON: Color = Color(0.98, 0.44, 0.31, 1.0)
const NIGHT_SKY_HORIZON: Color = Color(0.075, 0.11, 0.22, 1.0)
const DAY_GROUND_HORIZON: Color = Color(0.59, 0.68, 0.67, 1.0)
const NIGHT_GROUND_HORIZON: Color = Color(0.045, 0.075, 0.13, 1.0)

var _time_of_day_hours: float = 9.5

@onready var _world_environment: WorldEnvironment = get_parent().get_node("WorldEnvironment") as WorldEnvironment
@onready var _sunlight: DirectionalLight3D = get_parent().get_node("Sunlight") as DirectionalLight3D


func _ready() -> void:
	add_to_group("day_night_cycle")
	_time_of_day_hours = fposmod(starting_hour, 24.0)
	_apply_time_of_day()
	SaveService.restore_pending_world_time(self)


func _process(delta: float) -> void:
	if not advance_time or full_day_duration_seconds <= 0.0:
		return
	_time_of_day_hours = fposmod(
		_time_of_day_hours + delta * 24.0 / full_day_duration_seconds,
		24.0
	)
	_apply_time_of_day()


func get_time_of_day() -> float:
	return _time_of_day_hours


func set_time_of_day(hour: float) -> void:
	_time_of_day_hours = fposmod(hour, 24.0)
	_apply_time_of_day()


func _apply_time_of_day() -> void:
	if not is_instance_valid(_world_environment) or not is_instance_valid(_sunlight):
		return

	var solar_angle: float = TAU * (_time_of_day_hours - 6.0) / 24.0
	var sun_height: float = sin(solar_angle)
	var daylight: float = clampf((sun_height + 0.15) / 0.78, 0.0, 1.0)
	var twilight: float = clampf(1.0 - absf(sun_height) * 3.5, 0.0, 1.0)
	var environment: Environment = _world_environment.environment

	var daylight_background: Color = NIGHT_BACKGROUND.lerp(DAY_BACKGROUND, daylight)
	environment.background_color = daylight_background.lerp(
		TWILIGHT_BACKGROUND,
		twilight * (1.0 - daylight) * 0.85
	)
	environment.ambient_light_color = NIGHT_AMBIENT.lerp(DAY_AMBIENT, daylight)
	environment.ambient_light_energy = lerpf(0.22, 0.82, daylight)
	var sky_resource: Sky = environment.sky
	if sky_resource != null and sky_resource.sky_material is ProceduralSkyMaterial:
		var sky_material: ProceduralSkyMaterial = sky_resource.sky_material as ProceduralSkyMaterial
		var twilight_mix: float = twilight * (1.0 - daylight)
		sky_material.sky_top_color = NIGHT_SKY_TOP.lerp(DAY_SKY_TOP, daylight).lerp(TWILIGHT_SKY_TOP, twilight_mix)
		sky_material.sky_horizon_color = NIGHT_SKY_HORIZON.lerp(DAY_SKY_HORIZON, daylight).lerp(TWILIGHT_SKY_HORIZON, twilight_mix)
		sky_material.ground_horizon_color = NIGHT_GROUND_HORIZON.lerp(DAY_GROUND_HORIZON, daylight)
		sky_material.ground_bottom_color = NIGHT_BACKGROUND.lerp(Color(0.18, 0.21, 0.22, 1.0), daylight)

	_sunlight.rotation_degrees = Vector3(-sun_height * 70.0, 32.0, 0.0)
	_sunlight.light_color = TWILIGHT_SUN_COLOR.lerp(DAY_SUN_COLOR, daylight)
	_sunlight.light_energy = 1.15 * daylight
	_sunlight.visible = daylight > 0.005
	time_of_day_changed.emit(_time_of_day_hours)
