shader_type spatial;
render_mode cull_back;
varying vec3 world_point;
void vertex() { world_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float a = sin(dot(world_point.xz, vec2(0.7, 0.35)) + TIME * 0.65 + sin(world_point.z * 0.19) * 1.3);
	float b = sin(dot(world_point.xz, vec2(-0.25, 0.85)) - TIME * 0.55 + a * 0.6);
	float crest = pow(max((a + b) * 0.5, 0.0), 12.0);
	ALBEDO = mix(vec3(0.025, 0.11, 0.14), vec3(0.12, 0.28, 0.29), a * 0.18 + 0.35) + crest * vec3(0.025, 0.035, 0.03);
	NORMAL_MAP = vec3(0.5 + a * 0.018, 0.5 + b * 0.018, 1.0);
	ROUGHNESS = 0.43; SPECULAR = 0.35; METALLIC = 0.0;
}
