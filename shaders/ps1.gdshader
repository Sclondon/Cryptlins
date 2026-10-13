shader_type spatial;
// Every lit surface in the room (see scripts/ps1.gd).

#include "res://shaders/ps1_snap.gdshaderinc"

uniform vec3 tint : source_color = vec3(1.0);
uniform sampler2D tex : source_color, filter_nearest, hint_default_white;
uniform float glow = 0.0;
uniform float rim = 0.0;
// How much brighter than its texture a surface is drawn: a painted coat is kept at half strength,
// so that its markings can be paler than the coat as well as darker.
uniform float gain = 1.0;

void fragment() {
	vec3 c = tint * texture(tex, affine.xy / affine.z).rgb * gain;
	ALBEDO = c;
	EMISSION = c * glow;
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
	RIM = rim;
	RIM_TINT = 0.7;
}
