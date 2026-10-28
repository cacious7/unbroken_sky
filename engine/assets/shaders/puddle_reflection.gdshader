shader_type spatial;
// SC06 puddle: dark standing water showing a planar reflection rendered by a mirrored
// camera (culvert_mimic.gd). The reflection image is vertically flipped, so it is
// sampled at the flipped screen position, with a small ripple.
render_mode unshaded, cull_disabled;

uniform sampler2D reflection : source_color, filter_linear, repeat_disable;
uniform vec4 water : source_color = vec4(0.07, 0.11, 0.14, 1.0);
uniform vec4 sky : source_color = vec4(0.36, 0.4, 0.5, 1.0);
uniform float strength = 0.8;

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 ripple = vec2(sin(world.x * 9.0 + TIME * 1.7), cos(world.z * 11.0 + TIME * 1.3)) * 0.004;
	vec4 seen = texture(reflection, vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y) + ripple);
	float glancing = clamp(1.0 - abs(dot(NORMAL, VIEW)), 0.0, 1.0);
	vec3 surface = mix(water.rgb, sky.rgb, 0.08 + 0.3 * glancing * glancing);
	ALBEDO = mix(surface, seen.rgb * vec3(0.62, 0.72, 0.8), seen.a * strength);
}
