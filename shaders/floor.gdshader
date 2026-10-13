shader_type spatial;
// The floor, laid out from world position so it needs no UVs or textures. `style` picks which:
// 0 flagstones, 1 floorboards, 2 moss, 3 checkered tiles, 4 dirt, 5 sand, 6 gravel, 7 snow, 8 mud,
// 9 straw, 10 carpet.
// Where the pool lies there is no floor: the water (water.gdshader) is a little below it.

#include "res://shaders/shore.gdshaderinc"

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

vec3 dirt(vec2 at) {
	float clod = noise(at * 2.2) * 0.55 + noise(at * 7.0) * 0.3 + noise(at * 23.0) * 0.15;
	vec3 earth = mix(vec3(0.13, 0.085, 0.05), vec3(0.3, 0.2, 0.12), clod);
	// Damp patches, and the odd pebble and root
	earth *= 1.0 - 0.35 * smoothstep(0.55, 0.75, noise(at * 1.1 + 9.0));
	vec2 cell = floor(at * 4.0);
	float pebble = step(0.8, hash(cell)) * step(length(fract(at * 4.0) - vec2(hash(cell + 1.0), hash(cell + 2.0))), 0.09);
	return mix(earth, vec3(0.36, 0.34, 0.31) * (0.7 + 0.4 * hash(cell + 5.0)), pebble);
}

vec3 sand(vec2 at) {
	// Raked into ripples that wander a little
	float ripple = sin(at.y * 16.0 + noise(at * 1.5) * 5.0) * 0.5 + 0.5;
	float grain = noise(at * 30.0);
	vec3 pale = mix(vec3(0.5, 0.41, 0.25), vec3(0.68, 0.58, 0.38), ripple * 0.6 + grain * 0.4);
	vec2 cell = floor(at * 2.5);
	float shell = step(0.9, hash(cell)) * step(length(fract(at * 2.5) - vec2(hash(cell + 1.0), hash(cell + 2.0))), 0.06);
	return mix(pale, vec3(0.85, 0.8, 0.72), shell);
}

vec3 gravel(vec2 at) {
	// Small stones packed together: the nearest of a scatter of points
	vec2 p = at * 5.5;
	vec2 cell = floor(p);
	float best = 9.0;
	vec2 which = cell;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = cell + vec2(float(x), float(y));
			float d = length(p - c - vec2(hash(c), hash(c + 3.0)));
			if (d < best) {
				best = d;
				which = c;
			}
		}
	}
	vec3 stone = mix(vec3(0.3, 0.3, 0.33), vec3(0.47, 0.42, 0.36), hash(which + 7.0)) * (0.65 + 0.5 * hash(which + 2.0));
	return mix(stone, vec3(0.05, 0.05, 0.06), smoothstep(0.3, 0.52, best));
}

vec3 snow(vec2 at) {
	// Drifts of it, blue in the hollows, with a crust that glints and the dark floor showing
	// through where it has been trodden away
	float drift = noise(at * 1.3) * 0.6 + noise(at * 4.0) * 0.4;
	vec3 white = mix(vec3(0.44, 0.52, 0.66), vec3(0.74, 0.78, 0.82), drift) * (0.92 + 0.12 * noise(at * 26.0));
	float glint = step(0.955, hash(floor(at * 18.0)));
	float bare = smoothstep(0.76, 0.82, noise(at * 0.8 + 11.0));
	return mix(white + glint * 0.14, vec3(0.15, 0.14, 0.17), bare * 0.85);
}

vec3 mud(vec2 at) {
	// Dark and wet, churned into ruts, with grey water standing in the hollows
	float lump = noise(at * 1.7) * 0.6 + noise(at * 5.0) * 0.4;
	vec3 wet = mix(vec3(0.09, 0.06, 0.035), vec3(0.24, 0.155, 0.085), lump);
	float rut = smoothstep(0.35, 0.6, abs(sin(at.x * 3.2 + noise(at * 0.8) * 4.0)));
	wet *= 0.72 + 0.4 * rut;
	float hollow = noise(at * 1.1 + 5.0);
	float standing = smoothstep(0.6, 0.65, hollow);
	float rim = smoothstep(0.54, 0.6, hollow) * (1.0 - standing);
	wet += rim * vec3(0.1, 0.085, 0.06);
	return mix(wet, vec3(0.1, 0.14, 0.19) * (0.8 + 0.5 * noise(at * 3.0)), standing);
}

vec3 straw(vec2 at) {
	// Stalks lying every way, three layers of them over the dark of the floor
	float stalks = 0.0;
	for (int layer = 0; layer < 3; layer++) {
		float turn = 0.5 + float(layer) * 1.05;
		vec2 p = vec2(at.x * cos(turn) - at.y * sin(turn), at.x * sin(turn) + at.y * cos(turn));
		float streak = noise(vec2(p.x * 20.0, p.y * 1.5 + float(layer) * 7.0));
		stalks = max(stalks, smoothstep(0.5, 0.7, streak) * (0.65 + 0.175 * float(layer)));
	}
	vec3 gold = mix(vec3(0.26, 0.18, 0.06), vec3(0.8, 0.64, 0.24), stalks);
	return gold * (0.75 + 0.35 * noise(at * 2.0));
}

vec3 carpet(vec2 at) {
	// The waiting room's old carpet: red, with a gold and blue figure in a lattice, its weave
	// showing and worn through to the backing in patches
	vec2 f = fract(at * 1.5 + 0.5) - 0.5;
	float figure = abs(f.x) + abs(f.y);
	vec3 pile = vec3(0.5, 0.06, 0.08);
	pile = mix(pile, vec3(0.66, 0.5, 0.16), step(figure, 0.31) * step(0.2, figure));
	pile = mix(pile, vec3(0.1, 0.14, 0.34), step(figure, 0.11));
	pile = mix(pile, vec3(0.24, 0.035, 0.06), step(0.46, max(abs(f.x), abs(f.y))));
	float weave = 0.86 + 0.14 * mod(floor(at.x * 18.0) + floor(at.y * 18.0), 2.0);
	float worn = smoothstep(0.7, 0.82, noise(at * 0.9 + 7.3));
	return mix(pile * weave, vec3(0.34, 0.28, 0.2) * (0.75 + 0.35 * noise(at * 20.0)), worn * 0.85);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Cut into coarse texels, like a small texture laid over the floor
	vec2 at = (floor(world_pos.xz * 18.0) + 0.5) / 18.0;
	float off = wade(at);
	if (off > 0.0) {
		discard;
	}
	if (style == 1) {
		ALBEDO = floorboards(at);
	} else if (style == 2) {
		ALBEDO = moss(at);
	} else if (style == 3) {
		ALBEDO = checkers(at);
	} else if (style == 4) {
		ALBEDO = dirt(at);
	} else if (style == 5) {
		ALBEDO = sand(at);
	} else if (style == 6) {
		ALBEDO = gravel(at);
	} else if (style == 7) {
		ALBEDO = snow(at);
	} else if (style == 8) {
		ALBEDO = mud(at);
	} else if (style == 9) {
		ALBEDO = straw(at);
	} else if (style == 10) {
		ALBEDO = carpet(at);
	} else {
		ALBEDO = flagstones(at);
	}
	// Damp and dark for a hand's breadth back from the water's edge
	ALBEDO *= mix(0.5, 1.0, smoothstep(0.0, 0.3, -off));
	ROUGHNESS = 0.96;
	SPECULAR = 0.15;
}
