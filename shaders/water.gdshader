shader_type spatial;
// The pool: a sheet of water a little below the floor. It is the colour of the ground under it
// at the edge and darker the further out it is, it moves, and where the lamp falls on it it
// glints. It gives off a little light of its own, so that it is still water with the lamp out.

#include "res://shaders/ps1_snap.gdshaderinc"
#include "res://shaders/shore.gdshaderinc"

uniform vec3 bed : source_color = vec3(0.3, 0.2, 0.13);
// Where the lamp is pointing, its colour, and how hard it is burning (0 when it is out)
uniform vec3 lamp = vec3(0.0);
uniform vec3 lamp_tint : source_color = vec3(1.0, 0.93, 0.78);
uniform float lamp_glow = 1.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	// The same coarse texels as the floor, and moving in steps, not smoothly
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 at = (floor(world.xz * 18.0) + 0.5) / 18.0;
	float t = floor(TIME * 9.0) / 9.0;
	float off = wade(at);
	// Mud showing through the shallows, green water over the shelf, and dark out in the middle
	vec3 c = mix(vec3(0.07, 0.3, 0.3), vec3(0.02, 0.1, 0.24), smoothstep(0.25, 1.5, off));
	c = mix(bed * 0.45, c, smoothstep(-0.02, 0.4, off));
	// A slow swell, and the lines of small ripples running across it
	float swell = noise(at * vec2(1.3, 2.6) + vec2(t * 0.11, t * 0.07));
	float ripple = smoothstep(0.6, 0.72, noise(at * vec2(2.2, 8.0) + vec2(t * 0.22, -t * 0.16)));
	// It laps at the edge
	float lap = smoothstep(0.07, 0.0, abs(off - 0.05 - sin(t * 1.3 + at.x * 3.0 + at.y * 2.0) * 0.03));
	c = c * (0.75 + 0.5 * swell) + vec3(0.1, 0.16, 0.18) * (ripple * 0.5 + lap * 0.6);
	// The lamp on the water: broken glints about where it points, that come and go
	float beam = 1.0 - smoothstep(0.3, 2.6, distance(at, lamp.xz));
	float glint = step(0.7, noise(at * vec2(3.0, 12.0) + vec2(t * 0.4, t * 0.27))) * step(0.45, noise(at * 6.0 - vec2(t * 0.6)));
	ALBEDO = c;
	EMISSION = c * 0.3 + vec3(0.05, 0.1, 0.13) * (ripple + lap) +lamp_tint * lamp_glow * beam * glint * 0.45;
	ROUGHNESS = 0.6;
	SPECULAR = 0.3;
}
