shader_type spatial;
render_mode depth_draw_never, shadows_disabled;
// A body that can be seen through (see Ps1.ghost): the phantom kangaroo. It is lit as any other
// surface is and mixed with the room behind it. Its parts run into one another, and so that none
// of them shows through the next it is drawn twice: first every part of it is put down as depth
// and nothing else (ghost_depth.gdshader, the pass after this one, which is drawn before it),
// and then this draws only what is nearest the eye.

#include "res://shaders/ps1_snap.gdshaderinc"

uniform vec3 tint : source_color = vec3(1.0);
uniform sampler2D tex : source_color, filter_nearest, hint_default_white;
uniform float glow = 0.0;
uniform float rim = 0.0;
uniform float gain = 1.0;
// From the room into the creature's own measure, set by it as it moves: how much of it is there
// goes by how high up it a place is and how far back along its tail
uniform mat4 root = mat4(1.0);
// How much of it is there at its feet and at its head (which is so high), how much less at the
// end of its tail, how much more where it turns away from the eye, and this much more again all
// over (its face)
uniform float low = 0.3;
uniform float high = 0.55;
uniform float tall = 0.9;
uniform float trail = 0.18;
uniform float edge = 0.3;
uniform float more = 0.0;
// All of that is taken down to nothing as this goes to nothing
uniform float fade = 1.0;

void fragment() {
	vec3 at = (root * (INV_VIEW_MATRIX * vec4(VERTEX, 1.0))).xyz;
	float turned = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	turned *= turned;
	float there = mix(low, high, smoothstep(0.05, tall, at.y));
	there -= trail * smoothstep(-0.25, -0.75, at.z);
	there += edge * turned + more;
	vec3 c = tint * texture(tex, affine.xy / affine.z).rgb * gain;
	ALBEDO = c;
	// A light of its own, and more of it round its outline, so that it is found with the lamp out
	EMISSION = c * (glow + turned * rim * 1.2);
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
	RIM = rim;
	RIM_TINT = 0.7;
	ALPHA = clamp(there, 0.0, 1.0) * fade;
}
