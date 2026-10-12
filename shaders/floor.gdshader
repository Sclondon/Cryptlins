shader_type spatial;
// The floor, laid out from world position so it needs no UVs or textures. `style` picks which:
// 0 flagstones, 1 floorboards, 2 moss, 3 checkered tiles.

uniform int style = 0;

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

vec3 flagstones(vec2 at) {
	vec2 p = at * vec2(0.8, 1.15);
	float row = floor(p.y);
	p.x += mod(row, 2.0) * 0.5 + hash(vec2(row, 3.0)) * 0.25;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float grout = smoothstep(0.0, 0.05, edge + (noise(at * 9.0) - 0.5) * 0.03);
	float tone = 0.7 + 0.3 * hash(cell);
	float grain = noise(at * 5.0) * 0.55 + noise(at * 21.0) * 0.3;
	// Worn, slightly lighter middles
	float wear = smoothstep(0.0, 0.35, edge) * 0.12;
	vec3 stone = mix(vec3(0.30, 0.29, 0.33), vec3(0.36, 0.34, 0.31), hash(cell + 7.0));
	return mix(vec3(0.035, 0.035, 0.045), stone * tone * (0.62 + 0.5 * grain + wear), grout);
}

vec3 floorboards(vec2 at) {
	// Long boards running across, their ends staggered
	vec2 p = vec2(at.x * 0.42, at.y * 2.3);
	float row = floor(p.y);
	p.x += hash(vec2(row, 5.0));
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float gap = smoothstep(0.0, 0.07, min(f.y, 1.0 - f.y)) * smoothstep(0.0, 0.012, min(f.x, 1.0 - f.x));
	float grain = noise(vec2(at.x * 2.5 + hash(cell) * 9.0, at.y * 34.0)) * 0.5 + noise(vec2(at.x * 9.0, at.y * 60.0)) * 0.25;
	float knot = smoothstep(0.1, 0.0, length((f - vec2(hash(cell + 2.0), 0.5)) * vec2(2.4, 1.0))) * step(0.7, hash(cell + 4.0));
	vec3 wood = mix(vec3(0.2, 0.15, 0.11), vec3(0.27, 0.2, 0.14), hash(cell + 11.0));
	return mix(vec3(0.03, 0.02, 0.02), wood * (0.6 + 0.6 * grain) * (1.0 - knot * 0.55), gap);
}

vec3 moss(vec2 at) {
	float lump = noise(at * 1.6) * 0.6 + noise(at * 4.5) * 0.4;
	float blade = noise(at * 19.0);
	vec3 green = mix(vec3(0.08, 0.15, 0.07), vec3(0.2, 0.32, 0.12), lump) * (0.6 + 0.7 * blade);
	// Bare stone shows through where it has not taken
	float bare = smoothstep(0.62, 0.72, noise(at * 0.9 + 4.0));
	// And the odd small flower
	vec2 patch = floor(at * 3.0);
	float flower = step(0.9, hash(patch)) * step(length(fract(at * 3.0) - vec2(hash(patch + 1.0), hash(patch + 2.0))), 0.07) * (1.0 - bare);
	return mix(mix(green, flagstones(at) * 0.9, bare), vec3(0.6, 0.55, 0.3), flower);
}

vec3 checkers(vec2 at) {
	vec2 p = at * 1.3;
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float edge = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float grout = smoothstep(0.0, 0.035, edge);
	float dark = mod(cell.x + cell.y, 2.0);
	float grime = 0.75 + 0.35 * noise(at * 6.0) - 0.25 * smoothstep(0.5, 0.8, noise(at * 1.7));
	float chip = step(0.86, hash(cell + 3.0)) * smoothstep(0.25, 0.1, length(f - vec2(hash(cell), hash(cell + 9.0))));
	vec3 tile = mix(vec3(0.4, 0.38, 0.32), vec3(0.09, 0.09, 0.12), dark);
	return mix(vec3(0.03, 0.03, 0.035), tile * grime * (1.0 - chip * 0.5), grout);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Cut into coarse texels, like a small texture laid over the floor
	vec2 at = (floor(world_pos.xz * 18.0) + 0.5) / 18.0;
	if (style == 1) {
		ALBEDO = floorboards(at);
	} else if (style == 2) {
		ALBEDO = moss(at);
	} else if (style == 3) {
		ALBEDO = checkers(at);
	} else {
		ALBEDO = flagstones(at);
	}
	ROUGHNESS = 0.96;
	SPECULAR = 0.15;
}
