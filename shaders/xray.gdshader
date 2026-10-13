shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// A body under the scanner: nothing where you look straight through it, a glow where its
// surface turns away, so it reads as an outline you can see inside.

#include "res://shaders/ps1_snap.gdshaderinc"

uniform vec3 tint : source_color = vec3(0.3, 0.8, 1.0);

void fragment() {
	float edge = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	ALBEDO = tint * (0.05 + edge * edge * 0.6);
}
