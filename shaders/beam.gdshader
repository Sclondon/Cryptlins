shader_type spatial;
render_mode unshaded, blend_add, cull_back, depth_draw_never, shadows_disabled;
// The haze in the spotlight's beam. The cone mesh only says where to draw: the brightness of each
// pixel comes from how much of the beam the line of sight passes through (its nearest approach
// to the beam's axis, against the beam's width there), so it fades to nothing at the edges.

uniform vec3 tint : source_color = vec3(1.0, 0.93, 0.78);
uniform float strength = 0.15;
uniform vec3 apex = vec3(0.0, 6.0, 0.0);
uniform vec3 axis = vec3(0.0, -1.0, 0.0);
uniform float spread = 0.38; // tan of the half angle
uniform float reach = 6.5;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 ray = normalize(world_pos - CAMERA_POSITION_WORLD);
	vec3 w = CAMERA_POSITION_WORLD - apex;
	float b = dot(ray, axis);
	float d = dot(ray, w);
	float e = dot(axis, w);
	float denom = max(1.0 - b * b, 0.0001);
	float t = (b * e - d) / denom;
	float s = clamp((e - b * d) / denom, 0.05, reach);
	float miss = length(w + ray * t - axis * s) / (s * spread);
	float through = sqrt(max(1.0 - miss * miss, 0.0));
	// Thick near the lamp, thinning out toward the floor
	float along = s / reach;
	float fade = mix(1.0, 0.25, along) * (1.0 - smoothstep(0.8, 1.0, along));
	ALBEDO = tint * strength * through * through * through * fade;
}
