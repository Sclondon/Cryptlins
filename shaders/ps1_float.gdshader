shader_type canvas_item;
// The same hard pixels and 15-bit colour as ps1_screen, for a picture with nothing behind its
// things: what the picture left empty stays clear, so they float over whatever is underneath.

const float DITHER[16] = float[](-4.0, 0.0, -3.0, 1.0, 2.0, -2.0, 3.0, -1.0, -3.0, 1.0, -4.0, 0.0, 3.0, -1.0, 2.0, -2.0);

void fragment() {
	vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
	vec4 t = texture(TEXTURE, (px + 0.5) * TEXTURE_PIXEL_SIZE);
	vec3 c = t.rgb * 255.0;
	c += DITHER[int(mod(px.x, 4.0)) + int(mod(px.y, 4.0)) * 4];
	c = floor(clamp(c, 0.0, 255.0) / 8.0) * 8.0 / 248.0;
	COLOR = vec4(c, step(0.5, t.a));
}
