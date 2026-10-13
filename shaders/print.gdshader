shader_type spatial;
render_mode unshaded, blend_mul, depth_draw_never, shadows_disabled;
// A footprint (see scripts/track.gd): it darkens whatever floor is under it by `depth`, so it
// shows on any ground and can fade away to nothing.

#include "res://shaders/ps1_snap.gdshaderinc"

uniform float depth = 0.3;

void fragment() {
	ALBEDO = vec3(1.0 - depth);
}
