shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled;
// Something pale lying on the floor for a while, such as a patch of frost (see scripts/track.gd):
// it lightens whatever floor is under it by `depth` of its tint, and can fade away to nothing.

#include "res://shaders/ps1_snap.gdshaderinc"

uniform vec3 tint : source_color = vec3(0.6, 0.75, 0.9);
uniform float depth = 0.3;

void fragment() {
	ALBEDO = tint * depth;
}
