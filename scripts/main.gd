class_name Crypt
extends Node
## Cryptlins: a spotlight in a dark crypt and the little monster that lives in it.
## This builds the room, the lamp and the few buttons, reads the touches and keeps the save.
## A cryptlin starts as an egg (scripts/egg.gd); `pet` is null until it hatches.

enum Grab { NONE, FLOOR, PET, BALL, EGG }

const LAMP := Vector3(0, 6.2, 2.2)
const LIGHT_REACH := 2.3
const MAX_SNACKS := 3
const NAME_HEADS: Array[String] = ["Grub", "Mog", "Snag", "Fizz", "Bork", "Nib", "Skrit", "Womp", "Gloom", "Pim", "Zog", "Murk"]
const EGG_SPOT := Vector3(0, 0, 0.3)
const PET_HINT := "Tap the floor to call it over
Hold and drag to swing the lamp
Rub it to pet it, tap it to boop it
Drag the ball to throw it"
const EGG_HINT := "Keep the egg in the lamplight
Rub it to warm it up faster
Tap it and it knocks back"
const NAME_TAILS: Array[String] = ["nik", "let", "wort", "bo", "gle", "kin", "zle", "by", "mort", "ix"]

var save_path := "user://cryptlin.json"
# Set before it is added to the tree to choose what a new game's egg holds (tests); -1 for any
var first_kind := -1

var view: SubViewport
var screen: TextureRect
var camera: Camera3D
var spot: SpotLight3D
var beam: ShaderMaterial
var bounce: OmniLight3D
var motes: CPUParticles3D
var crumb_puff: CPUParticles3D
var ripple: MeshInstance3D
var sfx: Sfx
var pet: Cryptlin
var egg: Egg
var leaving := false
var ball: Ball
var snacks: Array[Snack] = []
var obstacles: Array[Vector3] = []
var nest_pos := Vector3(-1.7, 0, -1.05)

var pet_name := ""
var pet_seed := 1
var pet_kind := 0
var hatched := false
var saved_warmth := 0.0
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
var egg_button: Button
var feed_button: Button
var ball_button: Button
var ask: PanelContainer
var ask_text: Label
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
	_build_hud()
	get_viewport().size_changed.connect(_fit)
	_fit()
	if hatched:
		_spawn_pet(Vector3(randf_range(-1.0, 1.0), 0, randf_range(-0.6, 0.8)))
		_say("%s missed you" % pet_name)
	else:
		_lay_egg(fresh)
		_say("An egg!" if fresh else "Still an egg")
		show_help()


# ---------------------------------------------------------------- egg and hatchling

func _lay_egg(from_above: bool) -> void:
	egg = Egg.new()
	egg.world = self
	egg.kind = pet_kind
	egg.look_seed = pet_seed
	egg.warmth = saved_warmth
	add_child(egg)
	egg.position = EGG_SPOT
	if from_above:
		egg.drop(EGG_SPOT + Vector3(0, 5.5, 0))
	egg.cracked.connect(_on_cracked)
	egg.hatched.connect(_on_hatched)
	_sync_hud()


func _on_cracked(_stage: int) -> void:
	crumbs(egg.centre(), Egg.SHELLS[egg.kind])
	Input.vibrate_handheld(30)


func _on_hatched() -> void:
	var at := egg.position
	crumbs(egg.centre(), Egg.SHELLS[egg.kind])
	egg.burst()
	egg = null
	hatched = true
	saved_needs = {"belly": 55.0, "fun": 50.0, "energy": 85.0, "love": 10.0}
	pet_name = NAME_HEADS.pick_random() + NAME_TAILS.pick_random()
	_spawn_pet(at)
	pet.boop()
	pet.hearts.emitting = true
	sfx.play("crack", 0.7)
	Input.vibrate_handheld(60)
	_say("%s hatched! It's a %s." % [pet_name, pet.kind_name()])
	# Once it has had its moment, what a finger can do with it
	get_tree().create_timer(4.5).timeout.connect(show_help)
	save_game()


func _spawn_pet(at: Vector3) -> void:
	pet = Cryptlin.new()
	pet.world = self
	pet.kind = pet_kind
	pet.look_seed = pet_seed
	pet.set_needs(saved_needs)
	add_child(pet)
	pet.position = at
	pet.left.connect(_on_left)
	_sync_hud()


# The "New egg" button: asks first, since it sends the cryptlin away for good
func ask_new_egg() -> void:
	if pet == null or leaving:
		return
	if finger != -1:
		_release()
	if hint_tween != null:
		hint_tween.kill()
	hint.modulate.a = 0.0
	ask_text.text = "Let %s go off into the dark,
and hatch a new egg?" % pet_name
	ask.visible = true
	sfx.play("click")


func _answer(yes: bool) -> void:
	ask.visible = false
	sfx.play("click", 0.8)
	if yes and pet != null and not leaving:
		leaving = true
		pet.leave()
		_say("Goodbye, %s" % pet_name)
		_sync_hud()


func _on_left() -> void:
	pet.queue_free()
	pet = null
	leaving = false
	hatched = false
	for s in snacks:
		s.queue_free()
	snacks.clear()
	if ball != null:
		ball.queue_free()
		ball = null
	if grab == Grab.BALL:
		grab = Grab.NONE
		finger = -1
	# Never the same kind twice running
	pet_kind = (pet_kind + randi_range(1, Cryptlin.KINDS.size() - 1)) % Cryptlin.KINDS.size()
	pet_seed = randi() % 1000000 + 1
	saved_warmth = 0.0
	pet_name = ""
	if not light_on:
		toggle_lamp()
	_lay_egg(true)
	_say("An egg!")
	show_help()
	save_game()


# The corner panel and the buttons follow whether there is an egg, a cryptlin, or one on its way out
func _sync_hud() -> void:
	needs_panel.set("pet", pet)
	needs_panel.set("egg", egg)
	needs_panel.set("title", pet_name if pet != null else (egg.title() if egg != null else ""))
	var busy := pet == null or leaving
	feed_button.disabled = busy
	ball_button.disabled = busy
	egg_button.disabled = busy
	hint.text = PET_HINT if pet != null else EGG_HINT


# ---------------------------------------------------------------- the room

func _build_room() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.36, 0.55)
	env.ambient_light_energy = 0.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	# The crypt is drawn small into its own picture and blown up with hard pixels (the buttons
	# and words on top stay sharp, so they can be read on a phone)
	view = SubViewport.new()
	view.size = Vector2i(320, 240)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	camera = Camera3D.new()
	camera.environment = env
	camera.position = Vector3(0, 3.0, 5.7)
	view.add_child(camera)
	camera.look_at(Vector3(0, 0.5, 0))
	var back := CanvasLayer.new()
	back.layer = -1
	add_child(back)
	var post := ShaderMaterial.new()
	post.shader = load("res://shaders/ps1_screen.gdshader")
	screen = TextureRect.new()
	screen.texture = view.get_texture()
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_SCALE
	screen.material = post
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

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

	var stone := Ps1.mat(Color(0.3, 0.3, 0.33))
	_grave(stone, Vector3(1.9, 0, -2.3), -0.35, 0.08)
	_grave(stone, Vector3(-0.5, 0, -3.0), 0.15, -0.12)
	_grave(stone, Vector3(-2.9, 0, -2.0), 0.6, 0.05)

	# Its nest: a ring of rags at the edge of the light
	var rag := Ps1.mat(Color(0.2, 0.14, 0.12))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.34
	ring.outer_radius = 0.62
	ring.rings = 10
	ring.ring_segments = 6
	var nest := _mesh(ring, rag, nest_pos + Vector3(0, 0.06, 0))
	nest.scale = Vector3(1, 0.5, 1)
	var pad := CylinderMesh.new()
	pad.top_radius = 0.4
	pad.bottom_radius = 0.4
	pad.height = 0.04
	pad.radial_segments = 10
	_mesh(pad, Ps1.mat(Color(0.14, 0.1, 0.13)), nest_pos + Vector3(0, 0.02, 0))

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
	top.radial_segments = 8
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
	view.size = Vector2i((size * Ps1.LINES / minf(size.x, size.y)).round())
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
	sound_button.custom_minimum_size.x = 130.0 if tall else 100.0
	egg_button.custom_minimum_size.x = 150.0 if tall else 116.0
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
	feed_button = _button(buttons, "Feed", feed)
	ball_button = _button(buttons, "Ball", play_ball)
	lamp_button = _button(buttons, "Lamp off", toggle_lamp)
	buttons.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 18)

	corner = HBoxContainer.new()
	corner.add_theme_constant_override("separation", 10)
	layer.add_child(corner)
	help_button = _button(corner, "?", show_help)
	egg_button = _button(corner, "New egg", ask_new_egg)
	sound_button = _button(corner, "Sound", toggle_sound)

	# What a finger can do, since nothing on a phone hints at it
	hint = Label.new()
	hint.text = EGG_HINT
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

	# Asked before a cryptlin is sent away
	ask = PanelContainer.new()
	var card := StyleBoxFlat.new()
	card.bg_color = Color(0.1, 0.09, 0.13, 0.96)
	card.border_color = Color(0.93, 0.9, 0.8, 0.3)
	card.set_border_width_all(2)
	card.set_corner_radius_all(18)
	card.set_content_margin_all(26)
	ask.add_theme_stylebox_override("panel", card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	ask.add_child(column)
	ask_text = Label.new()
	ask_text.add_theme_font_size_override("font_size", 28)
	ask_text.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	ask_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(ask_text)
	var answers := HBoxContainer.new()
	answers.alignment = BoxContainer.ALIGNMENT_CENTER
	answers.add_theme_constant_override("separation", 16)
	column.add_child(answers)
	for b: Button in [_button(answers, "Keep", _answer.bind(false)), _button(answers, "Let go", _answer.bind(true))]:
		b.custom_minimum_size = Vector2(200, 90)
		b.add_theme_font_size_override("font_size", 30)
	layer.add_child(ask)
	ask.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	ask.grow_horizontal = Control.GROW_DIRECTION_BOTH
	ask.grow_vertical = Control.GROW_DIRECTION_BOTH
	ask.visible = false


func _button(parent: Node, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, 62)
	b.add_theme_font_size_override("font_size", 23)
	b.add_theme_color_override("font_color", Color(0.93, 0.9, 0.8))
	b.add_theme_color_override("font_disabled_color", Color(0.93, 0.9, 0.8, 0.25))
	for style_name: String in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.16, 0.14, 0.2, 0.75 if style_name == "normal" else 0.95)
		if style_name == "pressed":
			box.bg_color = Color(0.3, 0.26, 0.2, 0.95)
		box.border_color = Color(0.93, 0.9, 0.8, 0.25)
		if style_name == "disabled":
			box.bg_color = Color(0.16, 0.14, 0.2, 0.35)
			box.border_color = Color(0.93, 0.9, 0.8, 0.1)
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
	if ask.visible:
		return
	if hint_tween != null:
		hint_tween.kill()
	hint_tween = create_tween()
	hint_tween.tween_property(hint, "modulate:a", 1.0, 0.4)
	hint_tween.tween_interval(7.0)
	hint_tween.tween_property(hint, "modulate:a", 0.0, 1.2)


func feed() -> void:
	if pet == null or leaving:
		return
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
	if pet == null or leaving:
		return
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
	sound_button.text = "Muted" if sfx.muted else "Sound"


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
	return ask.visible or buttons.get_global_rect().has_point(p) or corner.get_global_rect().has_point(p)


# The crypt is drawn smaller than the screen, so touches are scaled down to it and back
func _in_view(at: Vector2) -> Vector2:
	return at * Vector2(view.size) / get_viewport().get_visible_rect().size


# Where a point in the crypt is on the screen
func screen_of(world: Vector3) -> Vector2:
	return camera.unproject_position(world) * get_viewport().get_visible_rect().size / Vector2(view.size)


func _floor_at(at: Vector2, height := 0.0, reach := 4.2) -> Vector3:
	var from := camera.project_ray_origin(_in_view(at))
	var dir := camera.project_ray_normal(_in_view(at))
	var t := 60.0
	if dir.y < -0.001:
		t = minf((height - from.y) / dir.y, 60.0)
	var p := from + dir * t
	p.y = height
	var flat := Vector2(p.x, p.z).limit_length(reach)
	return Vector3(flat.x, height, flat.y)


func _ray_hits(at: Vector2, centre: Vector3, radius: float) -> bool:
	var from := camera.project_ray_origin(_in_view(at))
	var dir := camera.project_ray_normal(_in_view(at))
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
				if moved > 14.0 and pet != null:
					pet.stroke()
			Grab.EGG:
				if moved > 14.0 and egg != null:
					egg.rub()
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
		if pet != null:
			pet.notice_ball()
	elif egg != null and _ray_hits(e.position, egg.centre(), 0.6):
		grab = Grab.EGG
	elif pet != null and not leaving and _ray_hits(e.position, pet.body_centre(), 0.7):
		grab = Grab.PET
	else:
		grab = Grab.FLOOR
		press_floor = _floor_at(e.position, 0.0, LIGHT_REACH)


func _release() -> void:
	var quick := clock - press_time < 0.3 and moved < 14.0
	match grab:
		Grab.BALL:
			if ball != null:
				ball.held = false
				ball.vel = hold_vel.limit_length(7.5)
			if pet != null:
				pet.notice_ball()
		Grab.PET:
			if quick and pet != null:
				pet.boop()
				Input.vibrate_handheld(20)
		Grab.EGG:
			if quick and egg != null:
				egg.tap()
				Input.vibrate_handheld(20)
		Grab.FLOOR:
			if quick and not light_dragging and pet != null:
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
		"kind": pet_kind,
		"seed": pet_seed,
		"hatched": hatched,
		"warmth": egg.warmth if egg != null else 0.0,
		"needs": pet.get_needs() if pet != null else {},
		"time": Time.get_unix_time_from_system(),
	}))


# Reads the save and lets time pass for the hours away; false if there was none (a new cryptlin)
func _load_game() -> bool:
	var data: Variant = null
	if FileAccess.file_exists(save_path):
		data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not data is Dictionary:
		pet_seed = randi() % 1000000 + 1
		pet_kind = first_kind if first_kind >= 0 else randi() % Cryptlin.KINDS.size()
		return false
	var d: Dictionary = data
	pet_name = str(d.get("name", "Grubnik"))
	pet_seed = int(d.get("seed", 1))
	# Saves from before there were eggs hold a hatched gremlin
	pet_kind = clampi(int(d.get("kind", 0)), 0, Cryptlin.KINDS.size() - 1)
	hatched = bool(d.get("hatched", true))
	saved_warmth = clampf(float(d.get("warmth", 0.0)), 0.0, 99.0)
	saved_needs = d.get("needs", {})
	# It gets hungry and bored while you are gone, but never desperately, and it sleeps well
	var away := clampf(Time.get_unix_time_from_system() - float(d.get("time", 0.0)), 0.0, 8.0 * 3600.0)
	saved_needs["belly"] = maxf(float(saved_needs.get("belly", 50.0)) - away / 120.0, 12.0)
	saved_needs["fun"] = maxf(float(saved_needs.get("fun", 50.0)) - away / 150.0, 12.0)
	saved_needs["energy"] = minf(float(saved_needs.get("energy", 50.0)) + away / 60.0, 100.0)
	return true


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED] and needs_panel != null:
		save_game()
