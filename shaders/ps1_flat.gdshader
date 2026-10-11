shader_type spatial;
render_mode unshaded;
// Flat colour that takes no light: pupils, cracks, the pictures in the thought bubble.

#include "res://shaders/ps1_snap.gdshaderinc"

uniform vec3 tint : source_color = vec3(1.0);

void fragment() {
	ALBEDO = tint;
}
