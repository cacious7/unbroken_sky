shader_type spatial;
render_mode cull_disabled;
uniform vec4 water_color : source_color = vec4(0.45, 0.74, 0.8, 1.0);
void fragment() {
	float ribbon = sin(UV.y * 85.0 - TIME * 28.0 + sin(UV.x * 18.0));
	ALBEDO = water_color.rgb * (0.82 + ribbon * 0.14);
	ROUGHNESS = 0.18;
	METALLIC = 0.12;
}
