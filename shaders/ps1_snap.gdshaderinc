// The two things that make 32-bit-era 3D wobble and swim: corners land on whole pixels of the
// low-resolution picture, and textures are stretched flat across each triangle, not in perspective.
// A shader that moves its corners first (the shells of fur.gdshader) defines SHELLS and a
// shell_at() before it includes this.

varying vec3 affine;

void vertex() {
#ifdef SHELLS
	VERTEX = shell_at(VERTEX, NORMAL, UV, MODEL_MATRIX);
#endif
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (clip.w > 0.0) {
		vec2 grid = VIEWPORT_SIZE * 0.5;
		clip.xy = floor(clip.xy / clip.w * grid + 0.5) / grid * clip.w;
	}
	POSITION = clip;
	affine = vec3(UV * clip.w, clip.w);
}
