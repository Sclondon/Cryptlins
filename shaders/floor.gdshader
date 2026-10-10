shader_type spatial;
// Crypt flagstones, laid out from world position so the floor needs no UVs or textures.

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz * vec2(0.8, 1.15);
	float row = floor(p.y);
	p.x += mod(row, 2.0) * 0.5 + hash(vec2(row, 3.0)) * 0.25;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float grout = smoothstep(0.0, 0.05, edge + (noise(world_pos.xz * 9.0) - 0.5) * 0.03);
	float tone = 0.7 + 0.3 * hash(cell);
	float grain = noise(world_pos.xz * 5.0) * 0.55 + noise(world_pos.xz * 21.0) * 0.3;
	// Worn, slightly lighter middles
	float wear = smoothstep(0.0, 0.35, edge) * 0.12;
	vec3 stone = mix(vec3(0.30, 0.29, 0.33), vec3(0.36, 0.34, 0.31), hash(cell + 7.0));
	ALBEDO = mix(vec3(0.035, 0.035, 0.045), stone * tone * (0.62 + 0.5 * grain + wear), grout);
	ROUGHNESS = 0.96;
	SPECULAR = 0.15;
}
