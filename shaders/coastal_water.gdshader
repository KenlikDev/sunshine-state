shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 deep_water : source_color = vec4(0.035, 0.23, 0.37, 1.0);
uniform vec4 aqua_water : source_color = vec4(0.08, 0.49, 0.60, 1.0);
uniform vec4 night_water : source_color = vec4(0.012, 0.055, 0.12, 1.0);
uniform float wave_height : hint_range(0.0, 0.18, 0.005) = 0.065;
uniform float wave_speed : hint_range(0.1, 2.0, 0.05) = 0.8;
uniform float night_factor : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float broad_wave = sin(world_position.x * 0.105 + TIME * wave_speed);
	float cross_wave = sin(
		world_position.z * 0.19
		- TIME * wave_speed * 1.25
		+ world_position.x * 0.035
	);
	VERTEX.y += (broad_wave * 0.62 + cross_wave * 0.38) * wave_height;
}

void fragment() {
	float broad_ripple = 0.5 + 0.5 * sin(UV.x * 44.0 + UV.y * 13.0 + TIME * wave_speed);
	float fine_ripple = 0.5 + 0.5 * sin(UV.x * 91.0 - UV.y * 23.0 - TIME * wave_speed * 1.4);
	float highlight = smoothstep(0.76, 0.94, broad_ripple * 0.64 + fine_ripple * 0.36);
	vec3 water_color = mix(deep_water.rgb, aqua_water.rgb, broad_ripple * 0.55);
	water_color = mix(water_color, night_water.rgb, night_factor * 0.88);

	ALBEDO = water_color + vec3(highlight * 0.055 * (1.0 - night_factor * 0.45));
	METALLIC = 0.12;
	ROUGHNESS = mix(0.23, 0.38, night_factor);
	SPECULAR = 0.72;
	EMISSION = vec3(highlight * 0.012) + night_factor * vec3(0.004, 0.015, 0.03);
}
