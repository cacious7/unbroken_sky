shader_type spatial;
render_mode cull_disabled;
void vertex() {
	float anchored = sin(UV.x * 3.14159265);
	VERTEX.y += anchored * (sin(TIME * 1.7 + UV.y * 5.0) * 0.055 + sin(TIME * 2.5 + UV.x * 8.0) * 0.025);
}
void fragment() {
	float stripe = smoothstep(0.08, 0.12, abs(sin(UV.x * 18.85)));
	ALBEDO = mix(vec3(0.025, 0.14, 0.16), vec3(0.57, 0.65, 0.60), stripe);
	ROUGHNESS = 0.95;
}
