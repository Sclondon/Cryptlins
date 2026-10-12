class_name Ps1
## Materials for the PlayStation-era look. Everything solid in the room uses one of these two
## shaders, which snap corners to whole pixels and map textures without perspective.

const LIT: Shader = preload("res://shaders/ps1.gdshader")
const FLAT: Shader = preload("res://shaders/ps1_flat.gdshader")
# The room is drawn this many pixels high (or wide, on an upright phone) and blown up
const LINES := 240.0


static func mat(c: Color, glow := 0.0, rim := 0.0, tex: Texture2D = null) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = LIT
	m.set_shader_parameter("tint", c)
	m.set_shader_parameter("glow", glow)
	m.set_shader_parameter("rim", rim)
	if tex != null:
		m.set_shader_parameter("tex", tex)
	return m


static func flat(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = FLAT
	m.set_shader_parameter("tint", c)
	return m


# A ball of radius 1 with few enough faces to see them
static func ball() -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = 1.0
	m.height = 2.0
	m.radial_segments = 10
	m.rings = 5
	return m
