class_name Crypt
extends Node
## Cryptlins: a spotlight in a dark crypt and the little monster that lives in it.
## This builds the room, the lamp and the few buttons, reads the touches and keeps the save.

enum Grab { NONE, FLOOR, PET, BALL }

const LAMP := Vector3(0, 6.2, 2.2)
const LIGHT_REACH := 2.3
const MAX_SNACKS := 3
const NAME_HEADS: Array[String] = ["Grub", "Mog", "Snag", "Fizz", "Bork", "Nib", "Skrit", "Womp", "Gloom", "Pim", "Zog", "Murk"]
const NAME_TAILS: Array[String] = ["nik", "let", "wort", "bo", "gle", "kin", "zle", "by", "mort", "ix"]

var save_path := "user://cryptlin.json"

var camera: Camera3D
var spot: SpotLight3D
var beam: ShaderMaterial
var bounce: OmniLight3D
var motes: CPUParticles3D
var crumb_puff: CPUParticles3D
var ripple: MeshInstance3D
var sfx: Sfx
var pet: Cryptlin
var ball: Ball
var snacks: Array[Snack] = []
var obstacles: Array[Vector3] = []
var nest_pos := Vector3(-1.7, 0, -1.05)

var pet_name := ""
var pet_seed := 1
var saved_needs := {}

var clock := 0.0
var save_timer := 0.0
var light_on := true
var light_level := 1.0
var light_point := Vector3.ZERO
var light_goal := Vector3.ZERO
var light_dragging := false
var hover_point := Vector3.ZERO
var hover_time := -100.0

var grab: int = Grab.NONE
var finger := -1
var press_time := 0.0
var release_time := -100.0
var press_floor := Vector3.ZERO
var moved := 0.0
var hold_point := Vector3.ZERO
var hold_vel := Vector3.ZERO

var needs_panel: Control
var buttons: HBoxContainer
var sound_button: Button
var help_button: Button
var corner: HBoxContainer
var hint: Label
var hint_tween: Tween
var lamp_button: Button
var toast: Label


func _ready() -> void:
	randomize()
	var fresh := not _load_game()
	_build_room()
	_build_lamp()
	sfx = Sfx.new()
	add_child(sfx)
	pet = Cryptlin.new()
	pet.world = self
	pet.look_seed = pet_seed
	pet.set_needs(saved_needs)
	add_child(pet)
	_build_hud()
	get_viewport().size_changed.connect(_fit)
	_fit()
	_say("Say hello to %s" % pet_name if fresh else "%s missed you" % pet_name)
	if fresh:
		show_help()


# ---------------------------------------------------------------- the room

func _build_room() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.36, 0.55)
	env.ambient_light_energy = 0.05
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.04
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	camera = Camera3D.new()
	camera.position = Vector3(0, 3.0, 5.7)
	add_child(camera)
	camera.look_at(Vector3(0, 0.5, 0))

	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = load("res://shaders/floor.gdshader")
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.mesh = plane
	floor_mesh.material_override = floor_mat
	# On its own layer, so the fill light can leave the floor outside the beam black
	floor_mesh.layers = 2
	add_child(floor_mesh)

	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.3, 0.3, 0.33)
	stone.roughness = 1.0
	_grave(stone, Vector3(1.9, 0, -2.3), -0.35, 0.08)
	_grave(stone, Vector3(-0.5, 0, -3.0), 0.15, -0.12)
	_grave(stone, Vector3(-2.9, 0, -2.0), 0.6, 0.05)

	# Its nest: a ring of rags at the edge of the light
	var rag := StandardMaterial3D.new()
	rag.albedo_color = Color(0.2, 0.14, 0.12)
	rag.roughness = 1.0
	var ring := TorusMesh.new()
	ring.inner_radius = 0.34
	ring.outer_radius = 0.62
	var nest := _mesh(ring, rag, nest_pos + Vector3(0, 0.06, 0))
	nest.scale = Vector3(1, 0.5, 1)
	var pad := CylinderMesh.new()
	pad.top_radius = 0.4
	pad.bottom_radius = 0.4
	pad.height = 0.04
	var pad_mat := rag.duplicate() as StandardMaterial3D
	pad_mat.albedo_color = Color(0.14, 0.1, 0.13)
	_mesh(pad, pad_mat, nest_pos + Vector3(0, 0.02, 0))

	# A ring that spreads where you tap to call it
	var ripple_mat := StandardMaterial3D.new()
	ripple_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ripple_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ripple_mat.albedo_color = Color(1, 0.95, 0.8, 0.0)
	var hoop := TorusMesh.new()
	hoop.inner_radius = 0.92
	hoop.outer_radius = 1.0
	ripple = _mesh(hoop, ripple_mat, Vector3(0, 0.02, 0))
	ripple.scale = Vector3(0.1, 0.02, 0.1)
	ripple.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ripple.visible = false

	var crumb_mat := StandardMaterial3D.new()
	crumb_mat.vertex_color_use_as_albedo = true
	crumb_mat.roughness = 0.9
	var crumb := BoxMesh.new()
	crumb.size = Vector3.ONE * 0.035
	crumb.material = crumb_mat
	crumb_puff = CPUParticles3D.new()
	crumb_puff.mesh = crumb
	crumb_puff.one_shot = true
	crumb_puff.emitting = false
	crumb_puff.amount = 10
	crumb_puff.lifetime = 0.6
	crumb_puff.explosiveness = 1.0
	crumb_puff.direction = Vector3.UP
	crumb_puff.spread = 60.0
	crumb_puff.initial_velocity_min = 0.8
	crumb_puff.initial_velocity_max = 1.8
	crumb_puff.gravity = Vector3(0, -7, 0)
	add_child(crumb_puff)


func _mesh(mesh: Mesh, mat: Material, at: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	return mi


func _grave(mat: Material, at: Vector3, turn: float, lean: float) -> void:
	var slab := BoxMesh.new()
	slab.size = Vector3(0.7, 0.9, 0.16)
	var top := CylinderMesh.new()
	top.top_radius = 0.35
	top.bottom_radius = 0.35
	top.height = 0.16
	var stone := _mesh(slab, mat, at + Vector3(0, 0.42, 0))
	stone.rotation = Vector3(lean, turn, lean * 0.6)
	var arch := MeshInstance3D.new()
	arch.mesh = top
	arch.material_override = mat
	arch.position = Vector3(0, 0.45, 0)
	arch.rotation.x = PI * 0.5
	stone.add_child(arch)
	obstacles.append(at)


func _build_lamp() -> void:
	spot = SpotLight3D.new()
	spot.position = LAMP
	spot.spot_range = 16.0
	spot.spot_angle = 22.0
	spot.spot_angle_attenuation = 0.5
	spot.spot_attenuation = 0.35
	spot.light_color = Color(1.0, 0.93, 0.78)
	spot.light_energy = 2.8
	spot.shadow_enabled = true
	spot.shadow_blur = 1.5
	spot.shadow_bias = 0.12
	spot.shadow_normal_bias = 2.5
	add_child(spot)
	spot.look_at(Vector3.ZERO, Vector3.FORWARD)

	beam = ShaderMaterial.new()
	beam.shader = load("res://shaders/beam.gdshader")
	beam.set_shader_parameter("reach", LAMP.length())
	beam.set_shader_parameter("spread", tan(deg_to_rad(21.0)))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.1
	cone.bottom_radius = LAMP.length() * tan(deg_to_rad(21.0))
	cone.height = LAMP.length()
	cone.cap_top = false
	cone.cap_bottom = false
	cone.radial_segments = 48
	var haze := MeshInstance3D.new()
	haze.mesh = cone
	haze.material_override = beam
	haze.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	haze.rotation.x = PI * 0.5
	haze.position = Vector3(0, 0, -LAMP.length() * 0.5)
	spot.add_child(haze)

	# Light thrown back off the floor, so what stands in the beam is not black underneath
	bounce = OmniLight3D.new()
	bounce.light_color = Color(1.0, 0.86, 0.66)
	bounce.omni_range = 5.0
	bounce.light_specular = 0.0
	bounce.light_cull_mask = 1
	add_child(bounce)

	# Dust drifting in the beam
	var mote_mat := StandardMaterial3D.new()
	mote_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mote_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mote_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mote_mat.albedo_color = Color(1.0, 0.93, 0.78, 0.35)
	var speck := QuadMesh.new()
	speck.size = Vector2(0.016, 0.016)
	speck.material = mote_mat
	motes = CPUParticles3D.new()
	motes.mesh = speck
	motes.amount = 45
	motes.lifetime = 9.0
	motes.preprocess = 9.0
	motes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	motes.emission_sphere_radius = 1.35
	motes.spread = 180.0
	motes.gravity = Vector3(0, -0.01, 0)
	motes.initial_velocity_min = 0.02
	motes.initial_velocity_max = 0.08
	motes.position = Vector3(0, 1.7, 0)
	motes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(motes)


# Phones held upright keep the whole pool of light in view by fixing the width instead of the height
func _fit() -> void:
	var size := get_viewport().get_visible_rect().size
	if size.x < size.y:
		camera.keep_aspect = Camera3D.KEEP_WIDTH
		camera.fov = 48.0
	else:
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.fov = 42.0
	if buttons == null:
		return
	# Thumb-sized: on an upright phone the three buttons share the whole width
	var tall := size.x < size.y
	var each := minf((size.x - 60.0) / 3.0, 260.0) if tall else 180.0
	for b: Button in buttons.get_children():
		b.custom_minimum_size = Vector2(each, 100.0 if tall else 76.0)
		b.add_theme_font_size_override("font_size", 32 if tall else 26)
	for b: Button in corner.get_children():
		b.custom_minimum_size = Vector2(b.custom_minimum_size.x, 80.0 if tall else 58.0)
		b.add_theme_font_size_override("font_size", 26 if tall else 20)
	sound_button.custom_minimum_size.x = 170.0 if tall else 132.0
	help_button.custom_minimum_size.x = 80.0 if tall else 58.0
	buttons.size = Vector2.ZERO
	buttons.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 30 if tall else 16)
	corner.size = Vector2.ZERO
	corner.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 14)
	needs_panel.scale = Vector2.ONE * (1.4 if tall else 1.0)
	hint.add_theme_font_size_override("font_size", 28 if tall else 20)
	toast.position.y = 210.0 if tall else 80.0
	# The hint sits over the empty dark: above the buttons on a phone, under the greeting on a wide screen
	hint.size = Vector2.ZERO
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM if tall else Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 150 if tall else 135)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN if tall else Control.GROW_DIRECTION_END


# ---------------------------------------------------------------- the buttons

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	needs_panel = Control.new()
	needs_panel.set_script(load("res://scripts/hud.gd"))
	needs_panel.set("pet", pet)
	needs_panel.set("title", pet_name)
	needs_panel.position = Vector2(18, 16)
	needs_panel.size = Vector2(200, 130)
	needs_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(needs_panel)

	buttons = HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	layer.add_child(buttons)
	_button(buttons, "Feed", feed)
	_button(buttons, "Ball", play_ball)
	lamp_button = _button(buttons, "Lamp off", toggle_lamp)
	buttons.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 18)

	corner = HBoxContainer.new()
	corner.add_theme_constant_override("separation", 10)
	layer.add_child(corner)
	help_button = _button(corner, "?", show_help)
	sound_button = _button(corner, "Sound on", toggle_sound)

	# What a finger can do, since nothing on a phone hints at it
	hint = Label.new()
	hint.text = "Tap the floor to call it over
Hold and drag to swing the lamp
Rub it to pet it, tap it to boop it
Drag the ball to throw it"
	hint.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 8)
	hint.add_theme_constant_override("line_spacing", 8)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.modulate.a = 0.0
	layer.add_child(hint)
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 150)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN

	toast = Label.new()
	toast.add_theme_font_size_override("font_size", 28)
	toast.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.modulate.a = 0.0
	layer.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 80)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 62)
	b.add_theme_font_size_override("font_size", 23)
	b.add_theme_color_override("font_color", Color(0.93, 0.9, 0.8))
	for style_name: String in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.16, 0.14, 0.2, 0.75 if style_name == "normal" else 0.95)
		if style_name == "pressed":
			box.bg_color = Color(0.3, 0.26, 0.2, 0.95)
		box.border_color = Color(0.93, 0.9, 0.8, 0.25)
		box.set_border_width_all(2)
		box.set_corner_radius_all(14)
		b.add_theme_stylebox_override(style_name, box)
	b.pressed.connect(action)
	parent.add_child(b)
	return b


func _say(text: String) -> void:
	toast.text = text
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.6)
	tw.tween_interval(2.6)
	tw.tween_property(toast, "modulate:a", 0.0, 1.2)


func show_help() -> void:
	if hint_tween != null:
		hint_tween.kill()
	hint_tween = create_tween()
	hint_tween.tween_property(hint, "modulate:a", 1.0, 0.4)
	hint_tween.tween_interval(7.0)
	hint_tween.tween_property(hint, "modulate:a", 0.0, 1.2)


func feed() -> void:
	if snacks.size() >= MAX_SNACKS:
		sfx.play("click", 0.7)
		return
	var a := randf() * TAU
	var at := light_point + Vector3(cos(a), 0, sin(a)) * sqrt(randf()) * 1.5
	var snack := Snack.new(randi() % 3)
	add_child(snack)
	snack.drop(at + Vector3(0, 5.5, 0))
	snack.thud.connect(func(strength: float) -> void: sfx.play("thud", 1.3, clampf(strength * 2.0 - 16.0, -24.0, -4.0)))
	snacks.append(snack)
	sfx.play("click")


func play_ball() -> void:
	if ball == null:
		ball = Ball.new()
		add_child(ball)
		ball.position = Vector3(randf_range(-1.0, 1.0), 1.4, 4.4)
		ball.vel = Vector3(randf_range(-0.8, 0.8), 2.6, -4.2)
		ball.bounced.connect(func(strength: float) -> void: sfx.play("boing", 1.0, clampf(strength * 3.0 - 16.0, -24.0, -3.0)))
	else:
		var a := randf() * TAU
		ball.vel += Vector3(cos(a) * 2.5, 4.2, sin(a) * 2.5)
	pet.notice_ball()
	sfx.play("click")


func toggle_lamp() -> void:
	light_on = not light_on
	light_dragging = false
	lamp_button.text = "Lamp off" if light_on else "Lamp on"
	sfx.play("click", 0.8)


func toggle_sound() -> void:
	sfx.muted = not sfx.muted
	sound_button.text = "Sound off" if sfx.muted else "Sound on"


# ---------------------------------------------------------------- things the cryptlin asks of the room

func hover_fresh() -> bool:
	return clock - hover_time < 2.0


func nearest_snack(from: Vector3) -> Snack:
	var best: Snack = null
	for s in snacks:
		if best == null or s.position.distance_squared_to(from) < best.position.distance_squared_to(from):
			best = s
	return best


func remove_snack(snack: Snack) -> void:
	snacks.erase(snack)
	snack.queue_free()


func crumbs(at: Vector3, colour: Color) -> void:
	crumb_puff.position = at
	crumb_puff.color = colour
	crumb_puff.restart()


# ---------------------------------------------------------------- every frame

func _process(delta: float) -> void:
	clock += delta
	# A finger resting on the floor takes hold of the lamp
	if grab == Grab.FLOOR and not light_dragging and light_on and clock - press_time > 0.3:
		light_dragging = true
		light_goal = press_floor
	if not light_dragging and clock - release_time > 2.5:
		light_goal = Vector3.ZERO
	light_point = light_point.lerp(light_goal, 1.0 - exp(-delta * (9.0 if light_dragging else 1.6)))
	spot.look_at(light_point, Vector3.FORWARD)
	light_level = move_toward(light_level, 1.0 if light_on else 0.0, delta * 5.0)
	spot.light_energy = 2.8 * light_level * (1.0 + sin(clock * 13.0) * sin(clock * 3.1) * 0.025)
	spot.visible = light_level > 0.001
	beam.set_shader_parameter("strength", 0.2 * light_level)
	beam.set_shader_parameter("apex", spot.global_position)
	beam.set_shader_parameter("axis", -spot.global_basis.z)
	bounce.light_energy = 0.55 * light_level
	bounce.position = light_point + Vector3(0, 1.1, 2.6)
	motes.visible = light_level > 0.5
	motes.position = Vector3(light_point.x * 0.72, 1.7, light_point.z * 0.72)

	if grab == Grab.BALL and ball != null:
		var before := ball.position
		ball.position = ball.position.lerp(hold_point, 1.0 - exp(-delta * 18.0))
		if delta > 0.0:
			hold_vel = hold_vel.lerp((ball.position - before) / delta, 0.35)

	if ripple.visible:
		var grown := ripple.scale.x + delta * 1.4
		ripple.scale = Vector3(grown, 0.02, grown)
		var mat := ripple.material_override as StandardMaterial3D
		mat.albedo_color.a = clampf(0.6 - grown, 0.0, 0.5)
		ripple.visible = grown < 0.6

	camera.position = Vector3(sin(clock * 0.21) * 0.12, 3.0 + sin(clock * 0.17) * 0.05, 5.7)
	camera.look_at(Vector3(0, 0.5, 0))

	save_timer += delta
	if save_timer > 10.0:
		save_game()


# ---------------------------------------------------------------- touch

func _over_ui(p: Vector2) -> bool:
	return buttons.get_global_rect().has_point(p) or corner.get_global_rect().has_point(p)


func _floor_at(screen: Vector2, height := 0.0, reach := 4.2) -> Vector3:
	var from := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	var t := 60.0
	if dir.y < -0.001:
		t = minf((height - from.y) / dir.y, 60.0)
	var p := from + dir * t
	p.y = height
	var flat := Vector2(p.x, p.z).limit_length(reach)
	return Vector3(flat.x, height, flat.y)


func _ray_hits(screen: Vector2, centre: Vector3, radius: float) -> bool:
	var from := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	var along := (centre - from).dot(dir)
	return along > 0.0 and (from + dir * along).distance_to(centre) < radius


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event)
		elif event.index == finger:
			_release()
	elif event is InputEventScreenDrag and event.index == finger:
		moved += event.relative.length()
		match grab:
			Grab.BALL:
				hold_point = _floor_at(event.position, 0.75, 3.8)
			Grab.PET:
				if moved > 14.0:
					pet.stroke()
			Grab.FLOOR:
				press_floor = _floor_at(event.position, 0.0, LIGHT_REACH)
				if light_on and (light_dragging or moved > 26.0):
					light_dragging = true
					light_goal = press_floor
	elif event is InputEventMouseMotion:
		hover_point = _floor_at(event.position)
		hover_time = clock
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F: feed()
			KEY_B: play_ball()
			KEY_L: toggle_lamp()
			KEY_M: toggle_sound()


func _press(e: InputEventScreenTouch) -> void:
	if finger != -1 or _over_ui(e.position):
		return
	finger = e.index
	press_time = clock
	moved = 0.0
	if ball != null and _ray_hits(e.position, ball.global_position, 0.5):
		grab = Grab.BALL
		ball.held = true
		ball.vel = Vector3.ZERO
		hold_vel = Vector3.ZERO
		hold_point = _floor_at(e.position, 0.75, 3.8)
		pet.notice_ball()
	elif _ray_hits(e.position, pet.body_centre(), 0.7):
		grab = Grab.PET
	else:
		grab = Grab.FLOOR
		press_floor = _floor_at(e.position, 0.0, LIGHT_REACH)


func _release() -> void:
	var quick := clock - press_time < 0.3 and moved < 14.0
	match grab:
		Grab.BALL:
			ball.held = false
			ball.vel = hold_vel.limit_length(7.5)
			pet.notice_ball()
		Grab.PET:
			if quick:
				pet.boop()
				Input.vibrate_handheld(20)
		Grab.FLOOR:
			if quick and not light_dragging:
				pet.call_to(press_floor)
				ripple.position = Vector3(press_floor.x, 0.02, press_floor.z)
				ripple.scale = Vector3(0.08, 0.02, 0.08)
				ripple.visible = true
	light_dragging = false
	release_time = clock
	grab = Grab.NONE
	finger = -1


# ---------------------------------------------------------------- the save

func save_game() -> void:
	save_timer = 0.0
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"name": pet_name,
		"seed": pet_seed,
		"needs": pet.get_needs(),
		"time": Time.get_unix_time_from_system(),
	}))


# Reads the save and lets time pass for the hours away; false if there was none (a new cryptlin)
func _load_game() -> bool:
	var data: Variant = null
	if FileAccess.file_exists(save_path):
		data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		pet_seed = randi() % 1000000 + 1
		pet_name = NAME_HEADS.pick_random() + NAME_TAILS.pick_random()
		saved_needs = {"belly": 55.0, "fun": 50.0, "energy": 85.0, "love": 10.0}
		return false
	var d: Dictionary = data
	pet_name = str(d.get("name", "Grubnik"))
	pet_seed = int(d.get("seed", 1))
	saved_needs = d.get("needs", {})
	# It gets hungry and bored while you are gone, but never desperately, and it sleeps well
	var away := clampf(Time.get_unix_time_from_system() - float(d.get("time", 0.0)), 0.0, 8.0 * 3600.0)
	saved_needs["belly"] = maxf(float(saved_needs.get("belly", 50.0)) - away / 120.0, 12.0)
	saved_needs["fun"] = maxf(float(saved_needs.get("fun", 50.0)) - away / 150.0, 12.0)
	saved_needs["energy"] = minf(float(saved_needs.get("energy", 50.0)) + away / 60.0, 100.0)
	return true


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED] and pet != null:
		save_game()
