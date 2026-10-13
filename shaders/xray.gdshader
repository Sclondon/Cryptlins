shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;
// A body under the scanner: nothing where you look straight through it, a glow where its
// surface turns away, so it reads as an outline you can see inside. With `lines` it is drawn as
// the scanner's raster: every other line of the picture brighter, and a bright band across it
// at the height the scanner's sweep has got to.

#include "res://shaders/ps1_snap.gdshaderinc"

uniform vec3 tint : source_color = vec3(0.3, 0.8, 1.0);
uniform float lines = 0.0;
uniform float band = -10.0;

void fragment() {
	float edge = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	float glow = 0.05 + edge * edge * 0.6;
	float raster = mix(1.0, 0.45 + 1.1 * step(1.0, mod(FRAGCOORD.y, 2.0)), lines);
	float height = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	float sweep = lines * smoothstep(0.1, 0.0, abs(height - band));
	ALBEDO = tint * (glow * raster + 0.08 * lines * raster + sweep * 0.55);
}
