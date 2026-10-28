shader_type spatial;
varying vec3 place;
float hash_cell(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void vertex() { place = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 grid = place.xz * vec2(0.8, 1.6);
	grid.x += mod(floor(grid.y), 2.0) * 0.5;
	vec2 cell = floor(grid);
	vec2 uv = fract(grid);
	float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	float seam = 1.0 - smoothstep(0.012, 0.026, edge);
	float grain = hash_cell(floor(place.xz * 45.0));
	float missing = step(hash_cell(cell), 0.09);
	vec3 ceramic = vec3(0.46, 0.43, 0.35) * (0.90 + hash_cell(cell + 2.0) * 0.14);
	vec3 soil = vec3(0.18, 0.075, 0.035) * (0.85 + grain * 0.25);
	ALBEDO = mix(mix(ceramic, vec3(0.055, 0.085, 0.09), seam * 0.72), soil, missing);
	ALBEDO *= 0.96 + grain * 0.06;
	ROUGHNESS = mix(0.68, 0.95, missing);
}
