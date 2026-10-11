// The two things that make 32-bit-era 3D wobble and swim: corners land on whole pixels of the
// low-resolution picture, and textures are stretched flat across each triangle, not in perspective.

varying vec3 affine;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (clip.w > 0.0) {
		vec2 grid = VIEWPORT_SIZE * 0.5;
		clip.xy = floor(clip.xy / clip.w * grid + 0.5) / grid * clip.w;
	}
	POSITION = clip;
	affine = vec3(UV * clip.w, clip.w);
}
