shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, shadows_disabled;
// What the scanner shows inside a body: flat colour, drawn through whatever is in front of it.

#include "res://shaders/ps1_snap.gdshaderinc"

uniform vec3 tint : source_color = vec3(1.0);

void fragment() {
	ALBEDO = tint;
	ALPHA = 1.0;
}
