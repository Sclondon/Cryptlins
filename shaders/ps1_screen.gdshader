shader_type canvas_item;
// The picture the room is drawn into, blown up with hard pixels and cut down to 15-bit colour
// with the PlayStation's own 4x4 dither pattern.

const float DITHER[16] = float[](-4.0, 0.0, -3.0, 1.0, 2.0, -2.0, 3.0, -1.0, -3.0, 1.0, -4.0, 0.0, 3.0, -1.0, 2.0, -2.0);

void fragment() {
	vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
	vec3 c = texture(TEXTURE, (px + 0.5) * TEXTURE_PIXEL_SIZE).rgb * 255.0;
	c += DITHER[int(mod(px.x, 4.0)) + int(mod(px.y, 4.0)) * 4];
	c = floor(clamp(c, 0.0, 255.0) / 8.0) * 8.0 / 248.0;
	COLOR = vec4(c, 1.0);
}
