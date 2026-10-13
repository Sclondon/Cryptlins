shader_type spatial;
// The basement's walls: the same dark brick as the station above, laid out from world position
// so it needs no UVs or textures. `across` picks which way the wall runs (x for the back wall,
// z for the side ones).

uniform vec3 across = vec3(1.0, 0.0, 0.0);

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Cut into coarse texels, like a small texture laid over the wall
	vec2 at = (floor(vec2(dot(world_pos, across), world_pos.y) * 18.0) + 0.5) / 18.0;
	vec2 p = at / vec2(0.7, 0.35);
	float row = floor(p.y);
	p.x += mod(row, 2.0) * 0.5;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float mortar = step(0.06, f.x) * step(f.x, 0.94) * step(0.12, f.y) * step(f.y, 0.88);
	float shade = 0.75 + 0.5 * hash(cell);
	vec3 brick = vec3(0.3, 0.2, 0.16) * shade;
	// Soot and damp darken it in patches, most of all low down
	float grime = hash(floor(at * 3.0)) * 0.25 + smoothstep(1.2, 0.0, world_pos.y) * 0.25;
	ALBEDO = mix(vec3(0.07, 0.055, 0.05), brick, mortar) * (1.0 - grime);
	ROUGHNESS = 1.0;
	SPECULAR = 0.05;
}
