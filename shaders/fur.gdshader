shader_type spatial;
// Long shaggy hair, for the kinds that are mostly hair (see Ps1.fur). The coat is streaked down
// the lie of the hair, and over it go a few "shells": the same mesh drawn again, each pushed
// further off the skin and left to hang, and each with more of it cut away, so that what is left
// stands off the body as hanging locks and its outline is ragged. Nothing here is see-through or
// reads the screen. The hair lies down the mesh's texture coordinates, which go round the body
// from the front (x) and from the top down (y), as a ball's do.

uniform vec3 tint : source_color = vec3(1.0);
uniform sampler2D tex : source_color, filter_nearest, hint_default_white;
uniform float glow = 0.0;
uniform float rim = 0.0;
uniform float gain = 1.0;
// Which layer this is: 0 the skin, up to 1 for the tips of the longest hair
uniform float shell = 0.0;
// How long the hair is, in the mesh's own measure, and how much of that it hangs down by
uniform float hair = 0.12;
uniform float hang = 0.7;
// How many locks there are round the body, and how many rows of them from top to bottom: few
// and fat, because fine ones are lost at this size
uniform float locks = 14.0;
uniform float rows = 2.5;
// How far the strands differ in tone, how much darker the hair is at the skin, and how much
// lighter at its tips
uniform float streak = 0.45;
uniform float root_shade = 0.4;
uniform float tip_bleach = 0.18;
// Where its face is: this far round from the front (0 to 1, the middle of the back) and from
// this far down, the hair is cut to `face_hair` of its length so that its eyes show
uniform float face = 0.0;
uniform float face_from = 0.4;
uniform float face_hair = 0.2;

// Where a corner of a shell goes: off the skin along its normal, and down
vec3 shell_at(vec3 at, vec3 normal, vec2 uv, mat4 model) {
	if (shell <= 0.0) {
		return at;
	}
	vec3 down = normalize((vec4(0.0, -1.0, 0.0, 0.0) * model).xyz);
	float about = min(uv.x, 1.0 - uv.x) * 2.0;
	float shorn = (1.0 - smoothstep(face, face + 0.12, about)) * smoothstep(face_from - 0.1, face_from, uv.y);
	float long = hair * mix(1.0, face_hair, shorn * step(0.001, face));
	return at + (normal + down * hang * shell) * long * shell;
}

#define SHELLS
#include "res://shaders/ps1_snap.gdshaderinc"

// (no sines: they come out differently, and coarser, on the phone and web renderers)
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

// Smooth noise, 0 to 1
float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x), mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 uv = affine.xy / affine.z;
	// Strands: narrow round the body and long down it
	float strand = noise(vec2(uv.x * locks * 3.0, uv.y * rows * 1.5));
	if (shell > 0.0) {
		// What is left of this layer: a lock wherever the hair is longer than this layer is
		// high. Each row of locks starts somewhere else round the body, and each lock is
		// widest at its top and drawn down to a point.
		float row = floor(uv.y * rows);
		vec2 lock = vec2(uv.x * locks + hash(vec2(row, 7.0)) * 5.0, uv.y * rows);
		float height = hash(floor(lock)) * 0.7 + strand * 0.3;
		vec2 within = fract(lock);
		float across = abs(within.x - 0.5) * 2.0;
		if (height < shell * 0.9 || across > (1.15 - shell * 0.6) * (1.0 - within.y * 0.75)) {
			discard;
		}
	}
	vec3 c = tint * texture(tex, uv).rgb * gain;
	c *= (1.0 + (strand - 0.5) * streak) * mix(1.0 - root_shade, 1.0 + tip_bleach, shell);
	ALBEDO = c;
	EMISSION = c * glow;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
	// The strands break the rim of light up
	RIM = rim * (0.5 + strand);
	RIM_TINT = 0.7;
}
