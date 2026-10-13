shader_type spatial;
render_mode unshaded, blend_add, depth_draw_always, shadows_disabled;
// The first of the two times a body that can be seen through is drawn (see ghost.gdshader): it
// adds nothing to the picture and leaves its depth there, so that only the nearest of its parts
// is drawn the second time.

#include "res://shaders/ps1_snap.gdshaderinc"

void fragment() {
	ALBEDO = vec3(0.0);
}
