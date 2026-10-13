class_name Ps1
## Materials for the PlayStation-era look. Everything solid in the room uses one of these two
## shaders, which snap corners to whole pixels and map textures without perspective.

const LIT: Shader = preload("res://shaders/ps1.gdshader")
const FLAT: Shader = preload("res://shaders/ps1_flat.gdshader")
const XRAY: Shader = preload("res://shaders/xray.gdshader")
const ORGAN: Shader = preload("res://shaders/organ.gdshader")
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


# What the scanner makes of a body: a ghost of its outline, brightest at the edges
static func xray(c: Color, raster := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = XRAY
	m.render_priority = 1
	m.set_shader_parameter("lines", 1.0 if raster else 0.0)
	m.set_shader_parameter("tint", c)
	return m


# Something inside a scanned body, drawn through whatever is in front of it
static func organ(c: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = ORGAN
	m.render_priority = 2
	m.set_shader_parameter("tint", c)
	return m


static func part(parent: Node, mesh: Mesh, mat: Material, at: Vector3, size := Vector3.ONE, turn := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	mi.scale = size
	mi.rotation = turn
	parent.add_child(mi)
	return mi


# A cube one unit across
static func box() -> BoxMesh:
	return BoxMesh.new()


# A drum one unit tall and two across; with `top` at 0 it is a cone
static func drum(sides := 8, top := 1.0) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = 1.0
	m.height = 1.0
	m.radial_segments = sides
	m.rings = 1
	return m
