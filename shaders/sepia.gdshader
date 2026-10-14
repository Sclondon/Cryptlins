shader_type canvas_item;
// An old photograph out of the handbook's album: whatever colours the picture had are thrown
// away for the browns of a print, and what stood in front of the camera is set against a studio
// backdrop that is paler in the middle. `faded` is a print that has been left in the light: one
// of a kind the keeper has none of. `blurred` is one taken out of focus: a kind never yet hatched,
// which can be made out as something but not as what.

uniform float faded = 0.0;
uniform float blurred = 0.0;

const vec3 DEEP = vec3(0.17, 0.1, 0.07);
const vec3 PALE = vec3(0.96, 0.87, 0.68);
const vec3 PAPER = vec3(0.87, 0.82, 0.68);

void fragment() {
	vec4 shot = texture(TEXTURE, UV);
	if (blurred > 0.5) {
		shot = vec4(0.0);
		for (int x = -3; x <= 3; x++) {
			for (int y = -3; y <= 3; y++) {
				shot += texture(TEXTURE, UV + vec2(float(x), float(y)) * 0.014);
			}
		}
		shot /= 49.0;
	}
	float grey = dot(shot.rgb, vec3(0.3, 0.59, 0.11));
	vec3 toned = mix(DEEP, PALE, smoothstep(0.02, 0.8, grey));
	float out_from = distance(UV, vec2(0.5, 0.42));
	vec3 backdrop = mix(vec3(0.64, 0.54, 0.39), vec3(0.3, 0.22, 0.15), smoothstep(0.15, 0.8, out_from));
	vec3 print = mix(backdrop, toned, shot.a);
	COLOR = vec4(mix(print, PAPER, faded * 0.5), 1.0);
}
