shader_type spatial;
render_mode blend_mix, depth_draw_never;
uniform sampler2D soil : source_color, filter_linear_mipmap_anisotropic;
varying vec3 ground_point;
void vertex() { ground_point = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float edge = smoothstep(0.0, 0.22, min(UV.x, 1.0 - UV.x));
	ALBEDO = mix(texture(soil, ground_point.xz * 0.4).rgb, vec3(0.28, 0.14, 0.07), 0.35);
	ROUGHNESS = 1.0;
	ALPHA = edge * 0.38;
}
