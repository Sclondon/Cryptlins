extends SceneTree
## Smoke test: the egg and hatching, naming, the shelf (food, toys, things for the room, ground),
## the pool and the kinds that need one,
## the lamp, petting, calling, sleep, time passing while away, the scanner, the notebook and
## sending it off for a new egg.
## godot --headless --fixed-fps 60 --path . -s tests/smoke.gd [-- --kind=0..29]
## (touches are sent as window pixels, like a real finger)

# The save this run uses: one for each kind, so that several can be run at once
var save := "user://smoke_test.json"

var main: Den
var failures := 0
var kind := 0
# Something more to tell this run's save by (--tag=), for two checkouts of the game run at once
var tag := ""


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--kind="):
			kind = int(arg.trim_prefix("--kind="))
		if arg.begins_with("--tag="):
			tag = "_" + arg.trim_prefix("--tag=")
	save = "user://smoke_test_%d%s.json" % [kind, tag]
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save))
	main = _start()
	_run.call_deferred()


func _start() -> Den:
	var m: Den = load("res://main.tscn").instantiate()
	m.save_path = save
	m.first_kind = kind
	m.ask_names = false
	root.add_child(m)
	return m


func _restart() -> void:
	main.save_game()
	main.queue_free()
	await _frames(3)
	main = _start()
	await _frames(5)


# Shuts the game, lets this long go by on the clock, and opens it again
func _come_back_after(seconds: float) -> void:
	main.save_game()
	main.queue_free()
	await _frames(3)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save))
	data["time"] = float(data["time"]) - seconds
	var f := FileAccess.open(save, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()
	main = _start()
	await _frames(5)


# What is its own about how one looks: the same every time for the one seed, not the same from
# seed to seed, colours it has always had for a seed from before there were more, and a body
# whose proportions stay inside what its kind allows
func _looks(pet: Cryptlin) -> void:
	var k := pet.kind
	check(Cryptlin.looks(k, 7) == Cryptlin.looks(k, 7) and Cryptlin.colours(k, 7) == Cryptlin.colours(k, 7), "one seed always looks the same")
	var heads := {}
	var coats := {}
	var odd := {}
	var kept := true
	for s in 40:
		var drawn := Cryptlin.looks(k, s + 1)
		heads[snappedf(Cryptlin.span(k, "head", drawn["head"]), 0.05)] = true
		coats[drawn["marks"][0]] = true
		for extra: String in drawn["extras"]:
			odd[extra] = true
			kept = kept and extra in Cryptlin.EXTRAS[k]
		# The coat is one of those its kind has always had, give or take the drift
		var fur := Cryptlin.colours(k, s + 1)[0]
		var near := false
		for old: Color in Cryptlin.FURS[k]:
			near = near or (absf(fur.r - old.r) + absf(fur.g - old.g) + absf(fur.b - old.b) < 0.45)
		kept = kept and near
	# (a kind whose coat takes only some of the markings has those and plain)
	var takes: Array = Cryptlin.SHAPES[k].get("marks", [])
	var sorts := 5 if takes.is_empty() else mini(5, takes.size() + 1)
	check(heads.size() >= 5 and coats.size() >= sorts and not odd.is_empty(), "forty seeds give heads of %d sizes, %d sorts of coat and %d odd things" % [heads.size(), coats.size(), odd.size()])
	check(kept, "each in a colour its kind has always had, with only the odd things its kind can have")
	check(Cryptlin.new_seed() > Cryptlin.OLD_SEEDS, "a new one has a seed from since there were more colours")
	check(pet.eye_sizes.size() == pet.eyes.size() and pet.head_size > 0.8 and pet.head_size < 1.35, "its own is built to its proportions")
	var tex := Cryptlin.coat([Cryptlin.Mark.SPOTS, 5, Cryptlin.Mark.SOCKS], Color(0.4, 0.5, 0.3)).get_image()
	var shades := {}
	for y in Cryptlin.COAT:
		for x in Cryptlin.COAT:
			shades[tex.get_pixel(x, y).to_html(false)] = true
	check(shades.size() >= 2 and tex.get_pixel(3, 2) == tex.get_pixel(Cryptlin.COAT - 4, 2), "a marked coat is painted in more than one shade, the same on both sides")


# One from under the ground: it digs a great deal, whatever the floor, is at home in a dim room
# and not under the bright lamp, and does not see far
func _digger(pet: Cryptlin) -> void:
	var was := main.floor_style
	var digs := [0, 0]
	for hard in 2:
		main.set_ground(0 if hard == 1 else 4)
		for i in 200:
			pet.belly = 90.0
			pet.fun = 90.0
			pet.energy = 90.0
			pet.beg_cooldown = 99.0
			pet._enter(Cryptlin.State.IDLE, 1.0)
			pet._decide()
			if pet.state == Cryptlin.State.DIG:
				digs[hard] += 1
	pet._enter(Cryptlin.State.IDLE, 1.0)
	pet.beg_cooldown = 0.0
	main.set_ground(was)
	check(digs[0] > 25 and digs[1] > 8 and digs[0] > digs[1], "it digs a great deal on dirt and has a go at flagstones too (%d and %d times in 200)" % digs)
	var comfort := {}
	for mode: int in [Den.Lamp.BRIGHT, Den.Lamp.LOW, Den.Lamp.OFF]:
		main.lamp_mode = mode
		comfort[mode] = main.comfort_of(pet)
	main.lamp_mode = Den.Lamp.BRIGHT
	check(pet.fav_lamp == Den.Lamp.LOW and comfort[Den.Lamp.LOW] > comfort[Den.Lamp.BRIGHT] + 20.0 and comfort[Den.Lamp.OFF] > comfort[Den.Lamp.BRIGHT] + 20.0, "it wants the lamp low or off, and is not at ease under the bright one")
	check(pet._sees(pet.position + Vector3(0.5, 0, 0)) and not pet._sees(pet.position + Vector3(2.0, 0, 0)), "and it does not see far")


# One that is mostly hair and heavy on its feet: its coat is the hair shader with its shells over
# it, which the scanner takes off and puts back, and it leaves a trail of prints that fade, are
# never too many, last longer on a soft floor, and are nothing to do with how the room suits it
func _tracker(pet: Cryptlin) -> void:
	var shells := 0
	var layer := pet.fur.next_pass as ShaderMaterial
	while layer != null:
		shells += 1
		layer = layer.next_pass as ShaderMaterial
	check(pet.fur.shader == Ps1.FUR and shells >= 2, "its coat is long hair, in %d layers" % shells)
	pet.xray(true)
	var bare := true
	for mi: MeshInstance3D in pet.skin:
		bare = bare and mi.material_override == pet.scan_skin
	pet.xray(false)
	var coated := 0
	for mi in pet.find_children("*", "MeshInstance3D", true, false):
		if mi.material_override == pet.fur:
			coated += 1
	check(bare and coated >= 1, "the scanner takes its hair off and puts it back")
	if pet.glances:
		await _ape(pet)
	var was := main.floor_style
	var comfort := main.comfort_of(pet)
	var lasts := [0.0, 0.0]
	var trail := 0
	for soft in 2:
		main.set_ground(5 if soft == 1 else 0)
		pet.position = Vector3(-1.2, 0, 0.3)
		pet.target = Vector3(1.4, 0, 1.2)
		pet._enter(Cryptlin.State.WANDER)
		await _until(func() -> bool: return pet.state != Cryptlin.State.WANDER, 500)
		trail = main.tracks.size()
		if trail > 0:
			lasts[soft] = main.tracks[0].lasts * main.tracks[0].depth
	check(trail >= 3 and lasts[1] > lasts[0] and lasts[0] > 0.0, "it leaves footprints as it walks (%d), deeper and longer lasting on sand than on flagstones" % trail)
	main.set_ground(was)
	for i in Den.MAX_TRACKS + 12:
		main.leave_print("sasquatch", Vector3(randf_range(-1.0, 1.0), 0, 0.5), 0.0, 1.0, 1.0)
	check(main.tracks.size() == Den.MAX_TRACKS, "there are never more than %d of them" % Den.MAX_TRACKS)
	check(main.messes.is_empty() and is_equal_approx(main.comfort_of(pet), comfort), "they are no mess, and make the room no worse for it")
	main.save_game()
	check(not FileAccess.get_file_as_string(save).contains("track"), "they are not kept in the save")
	for print in main.tracks:
		print.age = print.lasts - 0.01
	await _frames(4)
	main.leave_print("sasquatch", Vector3(0, 0, 0.5), 0.0, 1.0, 1.0)
	check(main.tracks.size() == 1, "and they fade away")
	pet._enter(Cryptlin.State.IDLE, 1.0)


# The squatchling is an ape that goes upright: a head of its own on top of its shoulders with its
# eyes in it, taller than it is wide, with arms that hang to its knees and bones the length of
# them; plain or all but; hairier and bigger in the foot newly hatched; and as it walks off it
# leans into its stride and now and then looks back over its shoulder without breaking it
func _ape(pet: Cryptlin) -> void:
	var was := pet.get_needs()
	pet.set_needs({"age": Cryptlin.GROW_AGE})
	pet.grow = pet.size_goal()
	pet._enter(Cryptlin.State.IDLE, 5.0)
	await _frames(30)
	var headed := pet.neck.get_parent() == pet.torso and pet.neck.position.y > pet.arms[0].position.y and pet.top_y > pet.neck_y + 0.3
	for eye in pet.eyes:
		headed = headed and eye.get_parent() == pet.neck and eye.position.y > 0.0
	check(headed and pet.eyes.size() == 2, "it has a head of its own on top of its shoulders, with its eyes in it")
	# (stood up straight with its arms at rest, whatever it had been about to do with them)
	for frame in 40:
		pet.sit_goal = 0.0
		pet.arm_goal = Cryptlin.REST_ARM
		pet.velocity = Vector3.ZERO
		await _frames(1)
	var low := 9.0
	var wide := 0.0
	for mi: MeshInstance3D in pet.arms[1].find_children("*", "MeshInstance3D", true, false):
		var at := pet.to_local(mi.global_position)
		low = minf(low, at.y)
		wide = maxf(wide, at.x)
	check(pet.top_y + pet.stand > wide * 2.0 * 1.15 and low < pet.legs[0].position.y and low > 0.05, "it is taller than it is wide, and its arms hang to its knees")
	pet.xray(true)
	var boned := 0.0
	for part in pet.insides:
		if part is MeshInstance3D and pet.arms[1].is_ancestor_of(part):
			boned += (part.mesh as CapsuleMesh).height
	pet.xray(false)
	check(boned > 0.4 and pet.inside_at("brain").y > pet.inside_at("lungs").y + 0.2 * pet.grow, "its insides are an upright ape's: long bones in its arms, and its brain well above its chest")
	var plain := true
	for s in 40:
		for mark: int in [Cryptlin.looks(pet.kind, s + 1)["marks"][0], Cryptlin.looks(pet.kind, s + 1)["marks"][2]]:
			plain = plain and not mark in [Cryptlin.Mark.SPOTS, Cryptlin.Mark.STRIPES, Cryptlin.Mark.FRECKLES, Cryptlin.Mark.PATCHES]
	check(plain, "no spots or stripes on any of forty of them")
	var foot := pet.feet[0].scale.x
	var hair: float = pet.fur.get_shader_parameter("hair")
	var edge: float = pet.fur.get_shader_parameter("edge")
	pet.set_needs({"age": 0.0})
	pet.grow = pet.size_goal()
	await _frames(3)
	check(pet.feet[0].scale.x > foot * 1.2 and float(pet.fur.get_shader_parameter("hair")) > hair * 1.5 and edge > 0.0, "a baby has bigger feet for its size and more hair, and the hair is cut only at its outline")
	pet.set_needs({"age": Cryptlin.GROW_AGE})
	pet.grow = pet.size_goal()
	pet.position = Vector3(0.8, 0, 1.6)
	pet.target = Vector3(-0.8, 0, -0.8)
	pet.back_again = 99.0
	pet._enter(Cryptlin.State.WANDER)
	await _frames(50)
	var lean := pet.torso.rotation.x
	var ahead := absf(pet.head_yaw)
	pet.glance_back(1.0)
	await _frames(40)
	var round := absf(pet.head_yaw) + absf(pet.torso.rotation.y)
	var going := pet.state == Cryptlin.State.WANDER and pet.gait > 0.5
	await _frames(90)
	check(lean > 0.15 and ahead < 0.5 and round > 1.4 and going and absf(pet.torso.rotation.y) < 0.1, "it leans into its walk, looks back over its shoulder mid-stride (%.1f round), and faces front again" % round)
	pet.back_again = 5.0
	pet.set_needs(was)
	pet.grow = pet.size_goal()
	pet._enter(Cryptlin.State.IDLE, 1.0)


# The cockatrice is the snake, and the rooster in front of it a dummy: the eyes, the mouth and
# the insides are the snake's, the dummy lags behind what the snake does, and the snake sleeps
# coiled round it
func _serpent(pet: Cryptlin) -> void:
	var alive := pet.decoy != null and not pet.decoy.is_ancestor_of(pet.mouth_node) and not pet.decoy.is_ancestor_of(pet.neck)
	for eye in pet.eyes:
		alive = alive and pet.neck.is_ancestor_of(eye)
	check(alive and pet.eyes.size() == 2, "its eyes and mouth are the snake's, and the rooster is a dummy")
	var behind := pet.to_local(pet.inside_at("stomach")).z < pet.to_local(pet.decoy.global_position).z - 0.1
	var boned := 0
	for leg in pet.legs:
		boned += leg.get_children().filter(func(part: Node) -> bool: return part in pet.insides).size()
	check(behind and boned == 0 and pet.inside_at("brain").y > pet.decoy.global_position.y, "its insides are in the snake, and there is nothing in the dummy")
	pet._enter(Cryptlin.State.SLEEP)
	await _frames(120)
	var laid := pet.neck.position.y < pet.neck_y * 0.6 and Vector2(pet.neck.position.x, pet.neck.position.z).distance_to(Vector2(pet.decoy.position.x, pet.decoy.position.z + 0.16)) < 0.45
	check(laid and absf(pet.decoy.rotation.z) > 0.8 and _joined(pet), "asleep, it is coiled round the dummy, which has tipped over")
	pet._enter(Cryptlin.State.IDLE, 3.0)
	await _frames(120)
	check(pet.neck.position.y > pet.neck_y - 0.05 and absf(pet.decoy.rotation.z) < 0.3, "and awake it rears up behind it again")
	# The snake is the rooster's tail: it comes out of the back end of the dummy, goes up from
	# there to a head held higher than the dummy's, and the two stay joined however it is thrown about
	var body: Node3D = pet.decoy.get_child(0)
	var rear := pet.to_local(pet.serpent[0].global_position)
	var tailed := rear.z < pet.to_local(body.global_position).z - 0.1 and pet.to_local(pet.serpent[2].global_position).z < rear.z and pet.to_local(pet.neck.global_position).y > pet.to_local(pet.decoy_parts[2].global_position).y + 0.2
	var held := _joined(pet)
	pet.position = Vector3(-1.0, 0, 0.6)
	pet.target = Vector3(1.2, 0, 1.0)
	pet._enter(Cryptlin.State.WANDER)
	for i in 50:
		await process_frame
		held = held and _joined(pet)
	pet.pick_up()
	pet.carry(pet.position + Vector3(0.3, 0.8, 0))
	for i in 50:
		await process_frame
		held = held and _joined(pet)
	var hung := pet.decoy.rotation.x > 0.2
	pet.put_down()
	await _until(func() -> bool: return pet.state != Cryptlin.State.HELD, 200)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	await _frames(90)
	check(tailed and held and hung, "the snake comes out of the dummy's back end like a tail, and stays joined to it walking and picked up, when the dummy hangs from it")
	pet.wiggle = 0.3
	pet._animate(0.016)
	var lagging := absf(pet.decoy.rotation.z)
	check(lagging > 0.0 and lagging < 0.2, "the dummy flops after it, a beat behind")
	pet.wiggle = 0.0


# One that hops (the jackalope) does not walk: going anywhere it leaves the ground and comes
# down again, over and over, it covers the ground it would have covered at a walk, and it keeps
# its feet on the floor when it is standing still
func _hopper(pet: Cryptlin) -> void:
	pet.position = Vector3(-1.3, 0, 0.5)
	pet.velocity = Vector3.ZERO
	pet._enter(Cryptlin.State.IDLE, 5.0)
	await _frames(20)
	var still := 0.0
	for i in 60:
		await process_frame
		still = maxf(still, maxf(pet.hop_y, pet.hop_t))
	check(still == 0.0, "standing still, it does not hop")
	pet.target = Vector3(1.4, 0, 1.1)
	pet._enter(Cryptlin.State.WANDER)
	var from := pet.position
	var meant := 0.0
	var high := 0.0
	var ups := 0
	var downs := 0
	var up := false
	var stopped := 0.0
	for i in 100:
		var before := pet.position
		await process_frame
		if pet.state != Cryptlin.State.WANDER:
			break
		meant += Vector2(pet.velocity.x, pet.velocity.z).length() / 60.0
		high = maxf(high, pet.hop_y)
		if pet.hop_y <= 0.0 and Vector2(pet.velocity.x, pet.velocity.z).length() > 0.5:
			stopped = maxf(stopped, 1.0 if pet.position.distance_to(before) < 0.002 else 0.0)
		if pet.hop_y > 0.04 and not up:
			up = true
			ups += 1
		if pet.hop_y <= 0.0 and up:
			up = false
			downs += 1
	var went := Vector2(pet.position.x - from.x, pet.position.z - from.z).length()
	check(ups >= 3 and downs >= 2 and high > 0.06 and stopped > 0.0, "going somewhere, it hops: off the ground and down again (%d times, %.2f high), with a pause between" % [ups, high])
	check(went > 1.0 and went > meant * 0.88 and went < meant * 1.12, "and it covers the ground it did at a walk (%.2f of %.2f)" % [went, meant])
	pet.velocity = Vector3.ZERO
	pet._enter(Cryptlin.State.IDLE, 2.0)
	await _frames(40)
	check(pet.hop_y == 0.0 and pet.hop_t == 0.0, "and is down and still again when it stops")


# Whether the cockatrice's snake and its dummy are joined: the first joint of the snake is where
# the dummy hangs from, and that is inside the dummy's body
func _joined(pet: Cryptlin) -> bool:
	var body: Node3D = pet.decoy.get_child(0)
	var inside := (body.global_transform.affine_inverse() * pet.serpent[0].global_position).length() < 1.0
	return inside and pet.serpent[0].global_position.distance_to(pet.decoy.global_position) < 0.01


# The slide-rock bolter is a whale to look at, long along the ground from its mouth to its
# flukes, with its insides drawn out along it; it is no water kind, and it heaves itself along
func _whale(pet: Cryptlin) -> void:
	check(not pet.needs_water() and pet.tail.position.z < -0.7 and pet.mouth_node.position.z > 0.3 and pet.head_turn < 0.6, "it lies long along the ground, mouth to flukes, and wants no water")
	pet.xray(true)
	var organs: Node3D = pet.stomach.get_parent()
	check(organs.scale.z > organs.scale.y * 2.0 and pet.inside_at("brain").y > pet.inside_at("stomach").y, "its insides are drawn out along it")
	pet.xray(false)
	pet.position = Vector3(-1.2, 0, 0.6)
	pet.target = Vector3(1.3, 0, 0.9)
	pet._enter(Cryptlin.State.WANDER)
	var most := 0.0
	var least := 9.0
	for i in 90:
		await _frames(1)
		most = maxf(most, pet.torso.scale.z)
		least = minf(least, pet.torso.scale.z)
	check(most - least > 0.04, "it bunches up and stretches out as it hauls itself along")
	pet._enter(Cryptlin.State.IDLE, 1.0)


# The yeti: a coat of the long hair, off-white (never so pale as to be one flat white under the
# lamp) with blue in its shadows; a ball of fluff newly hatched, which grows into a pear with
# its shoulders higher and its arms longer
func _snowball(pet: Cryptlin) -> void:
	var tint: Color = pet.fur.get_shader_parameter("tint")
	var shadow: Color = pet.fur.get_shader_parameter("shadow")
	check(pet.fur.shader == Ps1.FUR and pet.fur.next_pass != null and maxf(tint.r, maxf(tint.g, tint.b)) < 0.85 and shadow.b > shadow.r, "its coat is long hair, off-white, with blue in its shadows")
	# It is quiet to look at: the locks of its coat are few and drawn only at its outline, with
	# next to no streaking; nothing is painted on it but a big patch or a pale belly; its face is
	# a dark mask with big eyes in it; and its arms are a darker shade than its body
	var quiet := float(pet.fur.get_shader_parameter("edge")) > 0.0 and float(pet.fur.get_shader_parameter("streak")) < 0.15 and float(pet.fur.get_shader_parameter("locks")) <= 8.0
	for s in 40:
		for mark: int in [Cryptlin.looks(pet.kind, s + 1)["marks"][0], Cryptlin.looks(pet.kind, s + 1)["marks"][2]]:
			quiet = quiet and mark in [Cryptlin.Mark.PLAIN, Cryptlin.Mark.PATCHES, Cryptlin.Mark.BELLY]
		quiet = quiet and not "whiskers" in Cryptlin.looks(pet.kind, s + 1)["extras"]
	check(quiet, "its coat is one solid thing, ragged only at its outline, with no spots, stripes or whiskers on any of forty of them")
	var face: MeshInstance3D = pet.neck.get_child(1)
	var skin: Color = (face.material_override as ShaderMaterial).get_shader_parameter("tint")
	var sleeve: Color = ((pet.arms[0].get_child(0) as MeshInstance3D).material_override as ShaderMaterial).get_shader_parameter("tint")
	var eye: MeshInstance3D = pet.eyes[0].get_child(0)
	check(skin.v < tint.v * 0.7 and face.scale.x > 0.18 and eye.scale.x >= 0.045 and sleeve.v < tint.v * 0.95, "its face is a big dark mask with big eyes, and its arms a darker shade than its body")
	var was := pet.get_needs()
	pet.set_needs({"age": 0.0})
	pet.grow = pet.size_goal()
	await _frames(3)
	var ball := pet.podge.scale.y
	var low := pet.shoulders.position.y
	var short := pet.arms[0].scale.y
	pet.set_needs({"age": Cryptlin.GROW_AGE})
	pet.grow = pet.size_goal()
	await _frames(3)
	check(ball < pet.podge.scale.y * 0.8 and low < pet.shoulders.position.y - 0.1 and short < pet.arms[0].scale.y, "a baby is a ball of fluff, and grows into its shape")
	pet.set_needs(was)
	pet.grow = pet.size_goal()


# The one thing its kind does that no other does: it is not known until it is seen; given what
# it needs (light, another of them at a loose end, a toy, a thing in the room, a pool for those
# whose knack is in the water) it is one of the things it may take it into its head to do; the
# turn comes off, and is written in the notebook; and when it is over nothing is left changed
func _knack(pet: Cryptlin, mate: Cryptlin) -> void:
	check(not pet.me.known.get("knack", false) and main.notebook._notes(pet).contains("Its knack: ?"), "its knack is not written down before it has been seen")
	var wet := pet.kind in [Cryptlin.Kind.NESSIE, Cryptlin.Kind.KELPIE]
	if wet:
		main.place_decor(Decor.Kind.POOL, Den.middle(Den.Shore.BACK))
	var skull := main.place_decor(Decor.Kind.SKULL, Vector3(1.6, 0, 1.2))
	main.play_ball(Ball.Kind.BALL)
	main.ball.position = Vector3(-1.6, 0.2, 1.3)
	main.ball.vel = Vector3.ZERO
	if pet.kind in [Cryptlin.Kind.FROGMAN, Cryptlin.Kind.BOLTER]:
		# (something to eat, lying a little way off)
		main.feed((pet.yuck_food + 1) % Snack.NAMES.size(), Vector3(0.9, 1.5, 1.5))
	for p: Cryptlin in [pet, mate]:
		p.set_needs({"belly": 90.0, "energy": 90.0, "fun": 50.0, "health": 100.0, "bowel": 0.0, "bladder": 0.0})
		p.fight_cooldown = 9999.0
		p.ball_cooldown = 9999.0
		p.beg_cooldown = 9999.0
		p._enter(Cryptlin.State.IDLE, 60.0)
	pet.position = Vector3(-0.6, 0, 0.9)
	mate.position = Vector3(0.6, 0, 0.9)
	mate.belly = 100.0
	pet.belly = 100.0
	await _frames(30)
	await _until(func() -> bool: return main.snacks.all(func(food: Snack) -> bool: return food.landed), 300)
	# (hungry enough to want what is lying there, for the one that fetches it with its knack)
	if pet.kind == Cryptlin.Kind.FROGMAN:
		pet.belly = 60.0
	if pet.kind == Cryptlin.Kind.WORM:
		# (and a clean floor, for the one that will not add to two puddles)
		for m: Mess in main.messes.filter(func(left: Mess) -> bool: return left.kind == Mess.Kind.PUDDLE):
			main.clear_mess(m)
	pet.knack.again = 0.0
	check(pet.knack.ready(), "with what it needs to hand, it is ready to do it")
	var turns := 0
	for i in 600:
		pet.knack.again = 0.0
		pet._enter(Cryptlin.State.IDLE, 1.0)
		mate._enter(Cryptlin.State.IDLE, 60.0)
		pet._decide()
		if pet.state == Cryptlin.State.TRICK:
			turns += 1
	check(turns >= 3, "it is one of the things it takes it into its head to do (%d times in 600)" % turns)
	pet._enter(Cryptlin.State.IDLE, 1.0)
	mate._enter(Cryptlin.State.IDLE, 60.0)
	pet.position = Vector3(-0.6, 0, 0.9)
	pet.knack.again = 0.0
	# (and no finger has been near the screen for a good while)
	main.press_time = -100.0
	main.release_time = -100.0
	pet._enter(Cryptlin.State.TRICK)
	var came_off := await _until(func() -> bool: return pet.state != Cryptlin.State.TRICK, 1800)
	check(came_off and pet.knack.done, "it does it: it %s" % Knack.NOTES[pet.kind])
	if pet.kind == Cryptlin.Kind.FLATWOODS:
		check(mate.state == Cryptlin.State.SPELL and mate.knack.spell == "queasy" and pet.knack.fog == null, "the one beside it is left queasy for a moment, and the mist is gone")
	if pet.kind == Cryptlin.Kind.DEVIL:
		check(pet.visible and pet.knack.soot == null and pet.lift <= 0.0 and pet.position.z > -Den.half.y + 1.0, "it is back out of the vent, down in the light, and has shaken the soot off")
	if pet.kind == Cryptlin.Kind.WORM:
		var spat := main.messes.filter(func(left: Mess) -> bool: return left.kind == Mess.Kind.PUDDLE)
		check(spat.size() == 1 and spat[0].position.distance_to(pet.position) > 0.5 and spat[0].position.distance_to(mate.position) > 0.4 and pet.knack.gob == null, "what it spat is a puddle on the floor a little way off, and not on the one beside it")
		main.leave_mess(Mess.Kind.PUDDLE, Vector3(1.8, 0, 1.6), mate)
		pet.knack.again = 0.0
		check(not pet.knack.ready() and not pet.eyes[0].visible and not pet.needs_water(), "it leaves off while there are two puddles lying, it has no eyes to be seen, and it is no water kind")
		for m: Mess in main.messes.filter(func(left: Mess) -> bool: return left.kind == Mess.Kind.PUDDLE):
			main.clear_mess(m)
		pet.knack.again = 60.0
	check(pet.me.known.get("knack", false) and main.notebook._notes(pet).contains(Knack.NOTES[pet.kind]), "and once seen it is written in the notebook")
	check(not pet.knack.ready(), "it does not do it again at once")
	await _until(func() -> bool: return mate.state != Cryptlin.State.SPELL and mate.state != Cryptlin.State.FLOUNDER and pet.lift <= 0.0 and main.weird <= 0.0, 900)
	await _frames(90)
	var clean := main.weird <= 0.0 and is_zero_approx(pet.dive) and is_zero_approx(pet.torso.position.x) and pet.skin.is_empty() and mate.skin.is_empty() and pet.visible and mate.visible and main.flicker <= 0.0
	check(clean and pet.lift <= 0.05 and mate.lift <= 0.05 and mate.health >= 100.0 and not main.would_pair(pet, mate), "and when it is over nothing is left changed, and nobody the worse")
	main._clear_toys()
	main.remove_decor(skull)
	if wet:
		main.remove_decor(main.decor_of(Decor.Kind.POOL))
	for p: Cryptlin in [pet, mate]:
		p.ball_cooldown = 0.0
		p.beg_cooldown = 0.0
		p._enter(Cryptlin.State.IDLE, 1.0)


# The kongamato's knack when there is a pool: it is ready with nothing else in the room, goes up,
# comes down low across the water, and ends its turn standing on dry floor with nothing changed
func _skimmer(pet: Cryptlin) -> void:
	main.place_decor(Decor.Kind.POOL, Den.middle(Den.Shore.BACK))
	await _frames(30)
	pet.position = Den.on_dry(Vector3(-1.0, 0, 1.2), 0.4, 0.3)
	pet.set_needs({"belly": 90.0, "energy": 90.0, "fun": 50.0, "health": 100.0, "bowel": 0.0, "bladder": 0.0})
	pet._enter(Cryptlin.State.IDLE, 1.0)
	pet.knack.again = 0.0
	check(pet.knack.ready() and pet.knack._skittle() == null, "with a pool and nothing to knock over, it is ready to skim it")
	pet._enter(Cryptlin.State.TRICK)
	var over_water := 0.0
	var lowest := 9.0
	for i in 1500:
		await process_frame
		if pet.state != Cryptlin.State.TRICK:
			break
		if Den.wade(pet.position) > 0.2:
			over_water = maxf(over_water, Den.wade(pet.position))
			lowest = minf(lowest, pet.position.y)
	check(pet.knack.done and over_water > 0.3 and lowest > 0.0 and lowest < 0.6, "it comes down low over the water (%.2f out, %.2f up) and skims it" % [over_water, lowest])
	await _frames(60)
	check(pet.lift <= 0.05 and not pet.needs_water() and Den.wade(pet.position) <= 0.15 and is_zero_approx(pet.rotation.x), "and lands on dry floor, none the wetter")
	main.remove_decor(main.decor_of(Decor.Kind.POOL))
	pet._enter(Cryptlin.State.IDLE, 1.0)


# The mermaid: a water kind with no legs to it, one tail that is a stub on a baby and grows, hair
# of its own, a fish's backbone under the scanner, and on dry floor it hauls itself along
func _halfling(pet: Cryptlin) -> void:
	check(pet.needs_water() and pet.legs[0].get_child_count() == 0 and pet.legs[1].get_child_count() == 0 and pet.tresses != null and pet.tail.get_child_count() > 0, "it lives in water, and has hair, a tail and no legs")
	var was := pet.get_needs()
	pet.set_needs({"age": 0.0})
	pet.grow = pet.size_goal()
	await _frames(3)
	var short := pet.stub.scale.z
	pet.set_needs({"age": Cryptlin.GROW_AGE})
	pet.grow = pet.size_goal()
	await _frames(3)
	check(short < pet.stub.scale.z * 0.8, "a baby has a stub of a tail, and grows the rest")
	pet.set_needs(was)
	pet.grow = pet.size_goal()
	pet.xray(true)
	check(pet.long_bones.size() >= 8 and pet.inside_at("brain").y > pet.inside_at("stomach").y, "under the scanner it has a backbone down its tail, with fine bones off it")
	pet.xray(false)
	pet.position = Vector3(-1.2, 0, 0.6)
	pet.target = Vector3(1.3, 0, 0.9)
	pet._enter(Cryptlin.State.WANDER)
	var most := 0.0
	var least := 9.0
	for i in 90:
		await _frames(1)
		most = maxf(most, pet.torso.scale.z)
		least = minf(least, pet.torso.scale.z)
	check(most - least > 0.04 and is_zero_approx(pet.loll) and pet.heave == 0.0, "on dry floor it hauls itself along, bunching up and stretching out, with its tail down")
	pet._enter(Cryptlin.State.IDLE, 1.0)


# How many things there are to have on the wheel just now: all of them, but for the grave marker
# (which is only there when one is put away) and whatever is out in the room
func _all_but_in_use() -> int:
	return Items.LIST.filter(func(item: Dictionary) -> bool: return not item["id"] in Items.KEPT and not main.in_room_now(item["id"])).size()


# What is out in the room is not on the wheel: a thing stood in the room leaves it and the rest
# close up, and put away it is back in its place; so with the nest and the ground in use, and
# the toy on the floor; the tools never leave it; inside a page with a shop, what has run out
# leaves it and comes back when there is more; a toy bought is the room's own once it has been
# out; and the wheel still works with next to nothing on it
func _in_and_out(pet: Cryptlin) -> void:
	var shelf := main.shelf
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 60.0)
	pet.position = Vector3(-2.0, 0, -1.4)
	pet.ball_cooldown = 9999.0
	await _frames(2)
	var before: Array[String] = shelf.ids.duplicate()
	var at := before.find("skull")
	var from := _on_shelf("skull")
	await _slide(from, _screen(Vector3(0.6, 0, 0.6)), 16, from - Vector2(0, 190))
	var skull := main.decor_of(Decor.Kind.SKULL)
	check(skull != null and not shelf.ids.has("skull") and shelf.ids.size() == before.size() - 1, "a thing dragged up into the room is no longer on the wheel")
	check(shelf.ids[at - 1] == before[at - 1] and shelf.ids[at] == before[at + 1] and is_equal_approx(shelf.spots[at] - shelf.spots[at - 1], 1.0), "and its neighbours close up where it was")
	check(await _until(func() -> bool: return shelf.going.is_empty() and shelf.slips.all(func(slip: float) -> bool: return is_zero_approx(slip)), 200) and shelf.rim.get_child_count() == shelf.ids.size(), "its model is gone from the wheel, and the rest have slid round")
	# Carried down over the wheel, it leaves the room and the wheel shows its place; carried back
	# up, it is in the room again; let go on the floor it has only been moved
	var grip := _screen(skull.position + Vector3(0, 0.2, 0))
	var low := _px(Vector2(shelf.global_position.x + shelf.size.x * 0.5, shelf.global_position.y + shelf.size.y * 0.7))
	_touch(grip, true)
	await _frames(2)
	for i in 10:
		_drag(grip.lerp(low, (i + 1) / 10.0), (low - grip) / 10.0)
		await _frames(1)
	check(main.stowing == "skull" and not skull.visible and shelf.ids.has("skull") and shelf.sought == "skull", "a thing carried down over the wheel leaves the room, and the wheel makes room for it")
	check(await _until(func() -> bool: return shelf.where("skull").distance_to(shelf.global_position + Vector2(shelf.size.x * 0.5, Shelf.CREST * shelf.size.y / Shelf.TALL)) < 3.0, 120), "and turns to show its place")
	var back_up := _screen(Vector3(-0.4, 0, 0.5))
	for i in 10:
		_drag(low.lerp(back_up, (i + 1) / 10.0), (back_up - low) / 10.0)
		await _frames(1)
	check(main.stowing == "" and skull.visible and not shelf.ids.has("skull"), "carried back up, it is in the room again and off the wheel")
	_touch(back_up, false)
	await _frames(3)
	check(main.decor_of(Decor.Kind.SKULL) == skull and skull.visible and skull.position.distance_to(Vector3(-0.4, 0, 0.5)) < 0.4 and not shelf.ids.has("skull"), "let go on the floor, it has only been moved")
	# Put away for good: on a wide screen and an upright one, with a finger and with a mouse, on
	# the wheel and down in the corner where its rim has sunk out of sight
	var was := root.size
	var ways := 0
	for way in 4:
		root.size = Vector2i(540, 1170) if way % 2 == 1 else Vector2i(1280, 720)
		await _frames(5)
		if main.decor_of(Decor.Kind.SKULL) == null:
			main.place_decor(Decor.Kind.SKULL, Vector3(0.5, 0, 0.6))
		skull = main.decor_of(Decor.Kind.SKULL)
		pet._enter(Cryptlin.State.IDLE, 60.0)
		pet.position = Vector3(-1.4, 0, -1.4)
		await _frames(3)
		var rect := main.get_viewport().get_visible_rect().size
		var from_it := _screen(skull.position + Vector3(0, 0.2, 0))
		var to_it := _on_shelf("bone") if way < 2 else _px(Vector2(18.0, rect.y - 12.0))
		if way == 0 or way == 3:
			await _slide(from_it, to_it)
		else:
			await _mouse_slide(from_it, to_it)
		if main.decor_of(Decor.Kind.SKULL) == null and shelf.ids.has("skull") and main.stowing == "":
			ways += 1
	root.size = was
	await _frames(5)
	check(ways == 4 and shelf.ids == before, "dragged down and let go there it is put away, back in its place: wide and upright, by finger and by mouse, on the wheel or in the corner under it (%d ways of 4)" % ways)
	# One of them tucked into the thing that is put away
	var cave := main.place_decor(Decor.Kind.CAVE, Vector3(1.0, 0, -0.6))
	await _until(func() -> bool: return _settled(pet), 900)
	pet.set_needs({"belly": 80.0, "energy": 90.0, "bowel": 0.0, "bladder": 0.0})
	pet.position = Vector3(0.2, 0, 0.6)
	pet._enter(Cryptlin.State.LURK)
	pet.visiting = cave
	pet.target = cave.position
	await _until(func() -> bool: return pet.state == Cryptlin.State.LURK and pet.step == 1, 900)
	pet.flash_time = 0.0
	main.remove_decor(cave)
	check(pet.state == Cryptlin.State.STARTLED and pet.feeling == Cryptlin.Feeling.GRUMPY and pet.visible and main.decor_of(Decor.Kind.CAVE) == null, "one that was tucked into a thing when it is put away is turned out, and is put out about it")
	await _until(func() -> bool: return _settled(pet), 900)
	if pet.needs_water():
		var pond := main.place_decor(Decor.Kind.POOL, Den.middle(Den.Shore.BACK))
		pet._enter(Cryptlin.State.VISIT)
		pet.visiting = pond
		await _until(func() -> bool: return Den.wade(pet.position) > 0.3, 900)
		pet.flash_time = 0.0
		main.remove_decor(pond)
		check(pet.feeling == Cryptlin.Feeling.GRUMPY and Den.shore == Den.Shore.NONE and Den.wade(pet.position) < 0.0, "and so is one that was wading in the pool when that is")
		await _until(func() -> bool: return _settled(pet), 900)
	check(shelf.ids == before, "with it all put away, the wheel is as it was")
	pet._enter(Cryptlin.State.IDLE, 60.0)
	# The nest and the ground
	var bed := main.nest_style
	var other_bed := (bed + 1) % Decor.NESTS.size()
	check(not shelf.ids.has(Items.id_of("nest", bed)) and shelf.ids.has(Items.id_of("nest", other_bed)), "the nest that is in use is not on the wheel")
	await _tap(_on_shelf(Items.id_of("nest", other_bed)))
	check(main.nest_style == other_bed and shelf.ids.has(Items.id_of("nest", bed)) and not shelf.ids.has(Items.id_of("nest", other_bed)), "another put down in its place, the old one is back on it")
	main.set_nest(bed)
	var ground := main.floor_style
	var other_ground := (ground + 1) % Den.GROUNDS.size()
	check(not shelf.ids.has(Items.id_of("ground", ground)), "nor is the ground that is laid")
	await _tap(_on_shelf(Items.id_of("ground", other_ground)))
	check(main.floor_style == other_ground and shelf.ids.has(Items.id_of("ground", ground)) and not shelf.ids.has(Items.id_of("ground", other_ground)), "until another is")
	main.set_ground(ground)
	check(shelf.ids == before, "and with everything as it was, so is the wheel")
	# The toy
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 60.0)
	pet.position = Vector3(-2.0, 0, -1.4)
	await _tap(_on_shelf("bell"))
	check(main.ball != null and main.ball.kind == Ball.Kind.BELL and not shelf.ids.has("bell"), "a toy thrown in is off the wheel while it is on the floor")
	pet.ball_cooldown = 9999.0
	pet._enter(Cryptlin.State.IDLE, 60.0)
	main.ball.vel = Vector3.ZERO
	main.ball.position = Vector3(0.6, Ball.R, 0.9)
	await _frames(3)
	await _slide(_screen(main.ball.global_position), _on_shelf("bone"))
	check(main.ball == null and shelf.ids == before, "picked up and carried down to the wheel, it is put away and back in its place")
	# The tools
	main.start_scan()
	check(shelf.ids.has("scanner") and shelf.out.get("scanner", false) and shelf.ids.has("broom") and shelf.ids.has("notebook"), "the tools stay on it whatever they are doing")
	main.stop_scan()
	# With a shop
	main.embedded = true
	main.stock = {}
	main._sync()
	var free := Items.FREE.filter(func(id: String) -> bool: return not main.in_room_now(id))
	check(shelf.ids.size() == free.size() and shelf.ids[0] == "scanner" and shelf.ids[1] == "broom" and shelf.ids.back() == "notebook", "with a shop and nothing bought, the wheel holds the tools and what comes free and is not in use (%s)" % ", ".join(shelf.ids))
	main.stock = {"fish": 1, "stone": 1}
	main._sync()
	var stocked: Array[String] = shelf.ids.duplicate()
	check(stocked.has("fish") and shelf.counts.get("fish") == 1 and stocked.has("stone") and shelf.counts.get("stone") == 1, "what is bought is on it, with how many")
	pet.belly = 100.0
	main.feed(Snack.Kind.FISH)
	check(main.left_of("fish") == 0 and not shelf.ids.has("fish") and shelf.ids.size() == stocked.size() - 1, "the last of a thing used, it leaves the wheel")
	main.stock["fish"] = 2
	main._sync()
	check(shelf.ids == stocked and shelf.counts.get("fish") == 2, "and more of it from the page puts it back in its place")
	main.play_ball(Ball.Kind.STONE)
	check(main.ball != null and main.ball.bought and main.left_of("stone") == 0 and not shelf.ids.has("stone"), "a toy bought and brought out is taken from stock, and is the room's from then on")
	main._clear_toys()
	check(main.toybox.get("stone", []).size() == 1 and shelf.ids.has("stone") and shelf.counts.get("stone") == 1, "put away, it is on the wheel again, though there are none in stock")
	main.stock = {}
	main._sync()
	check(shelf.ids.has("stone") and main.owns("stone") and not main.owns("bell"), "and stays there whatever the page says is left")
	main.dev.visible = true
	main._sync()
	check(shelf.ids.size() == _all_but_in_use(), "the test panel puts everything on it that is not out in the room")
	main.play_ball(Ball.Kind.GLOW)
	check(not main.ball.bought and not shelf.ids.has("glow"), "and what it lends is not the room's to keep")
	main._clear_toys()
	main.dev.visible = false
	main._sync()
	check(not main.owns("glow") and main.toybox.get("glow", []).is_empty(), "nor is it on the wheel once the panel is shut")
	# Next to nothing on it, and nothing at all
	var few: Array[String] = ["scanner", "broom", "notebook"]
	shelf.stock(few)
	var reached := 0
	for id in few:
		shelf.show_item(id)
		await _frames(2)
		if shelf.has_point(shelf.where(id)) and shelf.item_at(shelf.where(id)) == id:
			reached += 1
	await _tap(_on_shelf("notebook"))
	check(reached == 3 and main.notebook.visible, "with only the tools on it, each comes to the top and answers")
	main.notebook.close()
	var none: Array[String] = []
	shelf.stock(none)
	await _frames(30)
	check(shelf.ids.is_empty() and shelf.item_at(shelf.global_position + shelf.size * 0.5) == "" and not shelf.can_scroll(1.0) and shelf.rim.get_child_count() == 0, "and with nothing on it at all it comes to no harm")
	main.embedded = false
	main.toybox.clear()
	main._sync()
	await _frames(30)
	check(shelf.ids == before, "played by itself again, everything is back")


# Toys wear out with being played with: so much a kick, more from a rough kind or nature and
# less from a gentle one or a baby; it shows, scuffed and then far gone; it is kept with the
# room, on the floor or put away; and at the last it breaks, in front of a cryptlin that is
# startled or pleased as its nature has it, leaves its bits to be swept up, and is not on the
# wheel afterwards: for some hours if it is one there is no end of, for good if it was bought
func _toys() -> void:
	var pet := main.who().pet
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 60.0)
	pet.ball_cooldown = 9999.0
	main.scuffs.clear()
	main.play_ball(Ball.Kind.BALL)
	var toy := main.ball
	var kicks := Ball.WORN_OUT / Ball.WEARS[Ball.Kind.BALL]
	check(toy.wear == 0.0 and toy.stage() == 0 and kicks >= 150.0 and Ball.WEARS[Ball.Kind.STONE] < Ball.WEARS[Ball.Kind.BALL] and Ball.WEARS[Ball.Kind.GLOW] > Ball.WEARS[Ball.Kind.BALL], "a new ball takes %d kicks from an ordinary one, a stone more and the orb fewer" % kicks)
	var natures := [pet.nature, pet.nature2]
	var age := pet.age
	pet.nature = 6
	pet.nature2 = 5
	var hard := pet.rough()
	pet.nature = 2
	pet.nature2 = 4
	var soft := pet.rough()
	pet.age = 0.0
	var young := pet.rough()
	pet.age = age
	pet.nature = natures[0]
	pet.nature2 = natures[1]
	check(hard > soft * 2.0 and young < soft and Cryptlin.ROUGH[Cryptlin.Kind.BOLTER] > Cryptlin.ROUGH[Cryptlin.Kind.FAE] * 2.0 and Cryptlin.ROUGH.size() == Cryptlin.KINDS.size(), "a grumpy, bold one is far harder on a toy than a shy, cuddly one, a baby gentler still, and a bolter than a fae")
	main.wear_toy(toy, pet)
	check(is_equal_approx(toy.wear, Ball.WEARS[Ball.Kind.BALL] * pet.rough()), "each kick wears it a little (%.2f)" % toy.wear)
	var new_look: Image = toy.mesh.material_override.get_shader_parameter("tex").get_image()
	var tall := toy.mesh.basis.get_scale().y
	toy.wear = Ball.SCUFFED
	toy.show_wear()
	var scuffed: Image = toy.mesh.material_override.get_shader_parameter("tex").get_image()
	check(toy.stage() == 1 and scuffed.get_data() != new_look.get_data(), "a third of the way gone it is scuffed")
	toy.wear = Ball.FAR_GONE
	toy.show_wear()
	var patched: Image = toy.mesh.material_override.get_shader_parameter("tex").get_image()
	check(toy.stage() == 2 and patched.get_data() != scuffed.get_data() and toy.mesh.basis.get_scale().y < tall * 0.85 and toy.bounce < toy.spring, "and far gone it is patched, sagging and has lost its bounce")
	# Kept with the room
	toy.wear = 80.0
	toy.vel = Vector3.ZERO
	toy.position = Vector3(0.7, Ball.R, 0.5)
	await _restart()
	pet = main.who().pet
	pet.ball_cooldown = 9999.0
	pet._enter(Cryptlin.State.IDLE, 60.0)
	check(main.ball != null and main.ball.kind == Ball.Kind.BALL and is_equal_approx(main.ball.wear, 80.0) and main.ball.stage() == 2 and main.ball.position.distance_to(Vector3(0.7, Ball.R, 0.5)) < 0.3 and not main.shelf.ids.has("ball"), "the toy on the floor is kept with the room, as worn as it was")
	main._clear_toys()
	check(is_equal_approx(main.scuffs.get("ball", 0.0), 80.0) and main.shelf.ids.has("ball"), "put away, it is as worn as it was")
	await _restart()
	pet = main.who().pet
	pet.ball_cooldown = 9999.0
	main.play_ball(Ball.Kind.BALL)
	check(is_equal_approx(main.ball.wear, 80.0) and main.ball.stage() == 2, "and comes out again no better, the next day or any other")
	# The end of it
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 60.0)
	pet.position = Vector3(0.2, 0, 0.6)
	pet.flash_time = 0.0
	main.ball.vel = Vector3.ZERO
	main.ball.position = Vector3(0.5, Ball.R, 0.7)
	main.ball.wear = Ball.WORN_OUT - 0.01
	var clean := main.comfort_of(pet)
	var loose := main.get_child_count()
	main.wear_toy(main.ball, pet)
	check(main.ball == null and not main.messes.is_empty() and main.messes.back().kind == Mess.Kind.BITS and main.messes.back().position.distance_to(Vector3(0.5, 0, 0.7)) < 0.2, "one kick more and it comes apart, and its bits lie where it was")
	check(main.get_child_count() >= loose + 6, "with the pieces of it flying")
	var pleased := Cryptlin.NATURE_ROUGH[pet.nature] > 1.0
	check(pet.feeling == (Cryptlin.Feeling.EXCITED if pleased else Cryptlin.Feeling.SCARED) and (pleased or pet.state == Cryptlin.State.STARTLED), "the %s one is %s" % [Cryptlin.NATURES[pet.nature]["title"], "pleased with itself" if pleased else "startled"])
	check(main.toast.modulate.a == 0.0 or main.toast.text.findn("ball") < 0, "nothing is written on the screen about it")
	check(not main.shelf.ids.has("ball") and not main.owns("ball") and main.scuffs.is_empty() and main.comfort_of(pet) < clean, "it is not on the wheel, and the bits spoil the place a little")
	await _frames(60)
	check(main.get_child_count() <= loose, "the pieces come down and are gone")
	main.sweep_one()
	check(await _until(func() -> bool: return not main.messes.any(func(m: Mess) -> bool: return m.kind == Mess.Kind.BITS), 200), "the broom sweeps up what is left")
	await _restart()
	pet = main.who().pet
	check(main.ball == null and not main.shelf.ids.has("ball"), "and it is still gone the next time")
	main.dev.visible = true
	main._sync()
	check(main.shelf.ids.has("ball"), "(the test panel has one all the same)")
	main.dev.visible = false
	main.broken["ball"] = Time.get_unix_time_from_system() - 1.0
	main._sync()
	main.play_ball(Ball.Kind.BALL)
	check(main.ball != null and main.ball.wear == 0.0 and not main.ball.bought, "of a kind there is no end of, there is a new one some hours on")
	main._clear_toys()
	# One that was bought
	main.embedded = true
	main.stock = {"glow": 1}
	main._sync()
	main.play_ball(Ball.Kind.GLOW)
	main.ball.wear = Ball.WORN_OUT
	main.wear_toy(main.ball, pet)
	main.stock = {"glow": 0}
	main._sync()
	check(main.ball == null and not main.owns("glow") and main.toybox.get("glow", []).is_empty() and not main.broken.has("glow") and not main.shelf.ids.has("glow"), "one that was bought is gone for good when it breaks")
	main.embedded = false
	for m in main.messes.duplicate():
		main.clear_mess(m)
	main._sync()
	pet.ball_cooldown = 0.0
	pet._enter(Cryptlin.State.IDLE, 1.0)


# The notebook on a wide screen and on an upright phone, with four in the room, long names and
# everything found out: it keeps inside the screen with a margin all round, every leaf's words
# fit the leaf with nothing cut off, between them the leaves of a chapter hold every word of it,
# and it is set in its own typewriter face
func _pages() -> void:
	var book := main.notebook
	var was := root.size
	var names := {}
	for r in main.residents:
		names[r] = r.name
		r.name = "Bartholomew Mog"
		if r.pet != null:
			for what: String in ["food", "yuck", "toy", "ground", "lamp", "water", "knack", "decor-" + Decor.IDS[r.pet.hate_decor]]:
				r.known[what + "?"] = r.known.get(what, false)
				r.known[what] = true
	check(book.title.text == "Cryptlin Handbook" and book.title.is_visible_in_tree() and Items.find("notebook")["name"] == "Cryptlin Handbook", "the notebook is the Cryptlin Handbook, and says so at the head of its leaves")
	check(book.heading.get_theme_font("font") == Notebook.FACE and book.body.get_theme_font("font") == Notebook.FACE and FileAccess.file_exists("res://fonts/SpecialElite-LICENSE.txt"), "the notebook is set in its own face, whose licence is kept with it")
	for shape: Vector2i in [Vector2i(1280, 720), Vector2i(540, 1170), Vector2i(720, 720)]:
		root.size = shape
		await _frames(5)
		var screen := Rect2(Vector2.ZERO, main.get_viewport().get_visible_rect().size)
		book.open_at(0)
		await _frames(2)
		var inside := screen.grow(-Notebook.EDGE + 0.5).encloses(book.get_global_rect())
		var spilt: Array[String] = []
		var words := {}
		for i in book.pages():
			await _frames(2)
			var frame := book.leaf.get_global_rect()
			var fits := book.body.get_minimum_size().y <= frame.size.y + 0.5 and book.body.get_visible_line_count() == book.body.get_line_count() and book.get_global_rect().grow(1.0).encloses(frame)
			for part: Control in [book.title, book.heading, book.rename, book.sound, book.folio]:
				fits = fits and (not part.is_visible_in_tree() or book.get_global_rect().encloses(part.get_global_rect()))
			inside = inside and screen.grow(-Notebook.EDGE + 0.5).encloses(book.get_global_rect())
			if not fits:
				spilt.append("%d (%s)" % [i + 1, book.heading.text])
			words[book.chapter] = str(words.get(book.chapter, "")) + book.body.text.replace("\n", " ") + " "
			book.turn(1)
		var whole := true
		for which in book.chapters():
			whole = whole and str(words.get(which, "")).replace(" ", "") == book.said(which).replace("\n", "").replace(" ", "")
		check(inside, "%d by %d: the notebook keeps inside the screen, with a margin all round" % [shape.x, shape.y])
		check(spilt.is_empty() and whole, "  and each of its %d leaves holds its words whole, with none lost between them %s" % [book.pages(), spilt])
		check(book.pages() >= book.chapters() and (shape.y > 1000 or book.pages() > book.chapters()), "  a chapter too long for one leaf runs over onto the next (%d leaves for %d chapters)" % [book.pages(), book.chapters()])
	for r in main.residents:
		r.name = names[r]
		for what: String in r.known.keys():
			if what.ends_with("?"):
				r.known[what.trim_suffix("?")] = r.known[what]
				r.known.erase(what)
		for what: String in r.known.keys():
			if not r.known[what]:
				r.known.erase(what)
	root.size = was
	await _frames(5)
	book.open_at(0)


# The broom: always on the wheel and nobody's to buy; a tap on a mess does nothing to it; the
# broom dragged up off the wheel and over it sweeps it up, with a few strokes and some dust; a
# tap on the broom sends it to sweep one up by itself; and it sweeps up a puddle and a heap too
func _broom(pet: Cryptlin, dropping: Mess, clean: float) -> void:
	check(main.shelf.ids.has("broom") and main.shelf.ids[1] == "broom" and "broom" in Items.FREE and main.left_of("broom") == -1, "the broom rides the wheel next to the scanner, and is nobody's to buy")
	await _tap(_screen(dropping.position + Vector3(0, 0.06, 0)))
	await _frames(10)
	check(main.droppings() == 1 and dropping in main.messes, "a tap on a dropping does not clear it up")
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 20.0)
	pet.position = Den.in_room(dropping.position + Vector3(-1.6 if dropping.position.x > 0.0 else 1.6, 0, 0), 0.4)
	# Up off the wheel on a finger, and across the floor to it
	var from := _on_shelf("broom")
	var over := _screen(dropping.position)
	_touch(from, true)
	await _frames(2)
	for i in 12:
		_drag(from.lerp(from - Vector2(0, 200), (i + 1) / 12.0), Vector2(0, -200) / 12.0)
		await _frames(1)
	check(main.grab == Den.Grab.BROOM and main.broom.visible and main.shelf.ids.has("broom"), "dragged up off the wheel, the broom is on the finger (and still on the wheel: it is a tool)")
	var above := from - Vector2(0, 200)
	for i in 12:
		_drag(above.lerp(over, (i + 1) / 12.0), (over - above) / 12.0)
		await _frames(1)
	check(await _until(func() -> bool: return main.sweeping == dropping, 60), "brought over the dropping, it sets about it")
	var brush: Node3D = main.broom.get_node("brush")
	var least := 9.0
	var most := -9.0
	var puffs := 0
	main.crumb_puff.emitting = false
	for i in 300:
		if not dropping in main.messes:
			break
		least = minf(least, brush.position.x)
		most = maxf(most, brush.position.x)
		# (each puff is counted and put out, so that the next shows as a new one)
		if main.crumb_puff.emitting:
			puffs += 1
			main.crumb_puff.emitting = false
		await _frames(1)
	check(most - least > 0.15 and puffs >= 2, "the brush goes back and forth, and the dust flies (%d times)" % puffs)
	check(main.droppings() == 0 and not dropping in main.messes and main.comfort_of(pet) > clean - 0.1, "and the dropping is swept up, and the cryptlin at home again")
	check(main.broom.visible and main.grab == Den.Grab.BROOM, "the broom stays on the finger")
	_touch(over, false)
	await _frames(3)
	check(not main.broom.visible and main.grab == Den.Grab.NONE, "let go, it goes back to the wheel")
	# A tap on it sends it to a mess by itself
	var puddle := main.leave_mess(Mess.Kind.PUDDLE, Vector3(0.6, 0, 0.9), pet)
	var heap := main.leave_mess(Mess.Kind.HEAP, Vector3(-0.6, 0, 0.9), pet)
	await _tap(_on_shelf("broom"))
	check(main.broom.visible and main.sweeping == puddle, "a tap on the broom sends it to sweep up what spoils the place first (the puddle before the heap)")
	check(await _until(func() -> bool: return main.messes.size() == 1, 200) and main.messes[0] == heap, "which it does")
	await _frames(30)
	check(not main.broom.visible, "and puts itself away")
	await _tap(_on_shelf("broom"))
	check(await _until(func() -> bool: return main.messes.is_empty(), 200), "a heap of earth can be swept up as well")
	await _frames(30)
	await _tap(_on_shelf("broom"))
	await _frames(5)
	check(not main.broom.visible and main.sweeping == null, "with nothing on the floor there is nothing for it to do")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _until(done: Callable, max_frames: int) -> bool:
	for i in max_frames:
		if done.call():
			return true
		await process_frame
	return done.call()


func check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
	print("%s: %s" % ["ok  " if ok else "FAIL", what])


func _screen(world: Vector3) -> Vector2:
	return root.get_final_transform() * main.screen_of(world)


# A place on the game's own screen, as window pixels
func _px(at: Vector2) -> Vector2:
	return root.get_final_transform() * at


# Where an item rides on the wheel, as window pixels (turned to the top first if it is not in reach)
func _on_shelf(id: String) -> Vector2:
	return root.get_final_transform() * main.shelf.point_of(id)


func _touch(pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)


func _drag(pos: Vector2, by: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.position = pos
	e.relative = by
	Input.parse_input_event(e)


func _tap(pos: Vector2) -> void:
	_touch(pos, true)
	await _frames(2)
	_touch(pos, false)
	await _frames(2)


# A finger down at one place, slid to another in a few steps (by way of a third, if one is
# given), and lifted
func _slide(from: Vector2, to: Vector2, steps := 8, via := Vector2.INF) -> void:
	_touch(from, true)
	await _frames(2)
	var start := from
	if via != Vector2.INF:
		for i in steps:
			_drag(from.lerp(via, float(i + 1) / steps), (via - from) / steps)
			await _frames(1)
		start = via
	for i in steps:
		_drag(start.lerp(to, float(i + 1) / steps), (to - start) / steps)
		await _frames(1)
	_touch(to, false)
	await _frames(2)


# The same with a mouse: the button down at one place, the pointer moved to another, and let up
func _mouse_slide(from: Vector2, to: Vector2, steps := 8) -> void:
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_LEFT
	button.position = from
	button.global_position = from
	button.pressed = true
	button.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(button)
	await _frames(2)
	for i in steps:
		var move := InputEventMouseMotion.new()
		move.position = from.lerp(to, float(i + 1) / steps)
		move.global_position = move.position
		move.relative = (to - from) / steps
		move.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(move)
		await _frames(1)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = to
	up.global_position = to
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


# The thing furthest round the wheel to one side whose middle is still on the screen
func _outermost(side: float) -> String:
	var screen := Rect2(Vector2.ZERO, main.get_viewport().get_visible_rect().size).grow(-8.0)
	var far := ""
	for id in main.shelf.ids:
		var at := main.shelf.where(id)
		if screen.has_point(at) and (far == "" or (at.x - main.shelf.where(far).x) * side > 0.0):
			far = id
	return far


# The wheel of things on a screen of this shape: every thing comes round to the top and answers
# there, so does every other that shows at the time, it stops at both ends, runs on when
# flicked, and a finger can tap and drag the ones furthest down the sides
func _wheel(pet: Cryptlin, shape: String) -> void:
	var shelf := main.shelf
	var screen := Rect2(Vector2.ZERO, main.get_viewport().get_visible_rect().size)
	var top := shelf.global_position + Vector2(shelf.size.x * 0.5, Shelf.CREST * shelf.size.y / Shelf.TALL)
	var first: String = shelf.ids[0]
	var last: String = shelf.ids[shelf.ids.size() - 1]
	var lost: Array[String] = []
	var fewest := 99
	var most := 0
	for id in shelf.ids:
		shelf.show_item(id)
		if shelf.where(id).distance_to(top) > 1.0:
			lost.append(id)
		var showing := 0
		for other in shelf.ids:
			var at := shelf.where(other)
			if screen.has_point(at):
				showing += 1
				if not shelf.has_point(at) or shelf.item_at(at) != other:
					lost.append("%s by %s" % [other, id])
		if id != first and id != last:
			fewest = mini(fewest, showing)
		most = maxi(most, showing)
	check(lost.is_empty(), "%s: each of the %d things comes to the top of the wheel, and every one that shows answers to a finger where it rides %s" % [shape, shelf.ids.size(), lost])
	check(fewest >= 3 and (most <= 5 or not main.tall_room), "%s: %d to %d of them show at a time" % [shape, fewest, most])
	check(not shelf.has_point(Vector2(top.x, shelf.global_position.y - 4.0)) and shelf.has_point(Vector2(top.x, screen.size.y - 4.0)) and shelf.item_at(Vector2(top.x, screen.size.y - 4.0)) == last, "%s: above it is the room, and all the way down under the top one is still that one" % shape)

	# Both ends: swept as far as it will go, it stops with the first thing at the top, or the last
	var sweep := Vector2(minf(screen.size.x * 0.4, 420.0), 0)
	shelf.show_item(shelf.ids[3])
	for i in 4:
		await _slide(_px(top - sweep * 0.5), _px(top + sweep * 0.5))
	await _frames(90)
	check(is_zero_approx(shelf.turn) and shelf.where(first).distance_to(top) < 1.0 and not shelf.can_scroll(-1.0) and shelf.can_scroll(1.0), "%s: swept one way it stops with the first thing (the %s) at the top" % [shape, first])
	await _tap(_px(top))
	check(main.scanning, "%s: where a tap uses it" % shape)
	main.stop_scan()
	shelf.show_item(shelf.ids[shelf.ids.size() - 4])
	for i in 4:
		await _slide(_px(top + sweep * 0.5), _px(top - sweep * 0.5))
	await _frames(90)
	check(is_equal_approx(shelf.turn, shelf.spots[shelf.spots.size() - 1]) and shelf.where(last).distance_to(top) < 1.0 and not shelf.can_scroll(1.0) and shelf.can_scroll(-1.0), "%s: swept the other way it stops with the last (the %s) at the top" % [shape, last])
	await _tap(_px(top))
	check(last == "notebook" and main.notebook.visible, "%s: which is the notebook, and a tap opens it" % shape)
	main.notebook.close()
	await _frames(2)

	# A flick: it runs on after the finger has gone, and comes to rest with a thing at the top
	shelf.show_item("rock")
	var was := shelf.turn
	await _slide(_px(top + sweep * 0.3), _px(top - sweep * 0.3), 4)
	var let_go := shelf.turn
	await _frames(12)
	var ran := shelf.turn - let_go
	check(let_go > was + 0.5 and ran > 0.3, "%s: a sideways drag turns it (%.1f things), and flicked it runs on (%.1f more)" % [shape, let_go - was, ran])
	check(await _until(func() -> bool: return absf(shelf.turn - shelf.spots[shelf._nearest(shelf.turn)]) < 0.01, 300), "%s: and comes to rest with a thing at the top" % shape)

	# The ones furthest down either side that still show: a tap on one, and the other dragged up
	# (with the wheel turned so that both are food, which is easy to tell has come in)
	pet.belly = 100.0
	shelf.show_item("ball")
	var left := _outermost(-1.0)
	var down := (shelf.where(left).y - top.y) / shelf._unit()
	await _tap(_px(shelf.where(left)))
	check(Items.find(left)["group"] == "food" and main.snacks.size() == 1 and main.snacks[0].kind == Items.find(left)["n"], "%s: a tap on the last one showing on the left (the %s, %.2f of a thing lower than the top) drops it in" % [shape, left, down])
	shelf.show_item("broom")
	var right := _outermost(1.0)
	var from := _px(shelf.where(right))
	await _slide(from, _screen(Vector3(0.4, 0.8, 0.3)), 16, from - Vector2(0, 190))
	check(Items.find(right)["group"] == "food" and main.snacks.size() == 2 and main.snacks[1].kind == Items.find(right)["n"] and is_equal_approx(shelf.turn, shelf.spots[1]), "%s: the last one showing on the right (the %s) comes up off the wheel on a finger, and the wheel has not turned" % [shape, right])
	main._clear_toys()
	pet._enter(Cryptlin.State.IDLE, 0.2)
	await _frames(2)


func _settled(pet: Cryptlin) -> bool:
	return pet.state in Cryptlin.INTERRUPTIBLE and not pet.airborne


# Two cryptlins made grown, fed, well, at home and fond of each other: a pair that would pair off
func _content(one: Cryptlin, mate: Cryptlin) -> void:
	for p: Cryptlin in [one, mate]:
		p.set_needs({"belly": 90.0, "energy": 90.0, "fun": 70.0, "health": 100.0, "age": Cryptlin.GROW_AGE, "bowel": 0.0, "bladder": 0.0})
		p.grow = p.adult_size
		p.fav_ground = main.floor_style
		p.fav_lamp = main.lamp_mode
		# (one from underground is made easy about the lamp, like the rest)
		p.likes.erase("dim")
		p.hate_decor = Decor.Kind.DISH
		p.comfort = main.comfort_of(p)
		p.fight_cooldown = 9999.0
		p.fond_cooldown = 9999.0
		p.me.paired = 0.0
		p.me.expecting = {}
		p._enter(Cryptlin.State.IDLE, 30.0)
	one.position = Vector3(-0.7, 0, 0.6)
	mate.position = Vector3(0.7, 0, 0.6)
	main.warm(one, mate, 90.0 - main.regard(one, mate))
	main.warm(mate, one, 90.0 - main.regard(mate, one))


# How much of the floor is under water, 0 to 1
func _wet_share() -> float:
	var wet := 0
	for i in 40:
		for j in 40:
			if Den.wade(Vector3(lerpf(-Den.half.x, Den.half.x, (i + 0.5) / 40.0), 0, lerpf(-Den.half.y, Den.half.y, (j + 0.5) / 40.0))) > 0.0:
				wet += 1
	return wet / 1600.0


# The pool: its shape, each place it fits, what is kept out of it and what is moved out when it
# arrives, the room changing shape round it, what floats in it, and what a cryptlin makes of it
# by whether it lives in water
func _pool(pet: Cryptlin) -> void:
	var pool := main.decor_of(Decor.Kind.POOL)
	await _until(func() -> bool: return _settled(pet), 900)
	pet.set_needs({"belly": 100.0, "energy": 95.0, "fun": 80.0, "bowel": 0.0, "bladder": 0.0})
	pet._enter(Cryptlin.State.IDLE, 60.0)
	# The shape of it
	check(is_equal_approx(Den.wade(Den.at_shore(0.7, 0.5)), 0.5) and is_equal_approx(Den.wade(Den.at_shore(-1.1, -0.4)), -0.4), "how far out into it a place is can be told, either side of the edge")
	check(absf(Den.wade(Den.place(-1.5, 0.0)) - Den.wade(Den.place(1.2, 0.0))) > 0.1, "an edge that wanders")
	check(Den.deep(Den.at_shore(0.0, -0.5)) == 0.0 and is_equal_approx(Den.deep(Den.at_shore(0.0, 0.3)), 0.3 * Decor.SHELVE) and Den.deep(Den.middle(Den.shore)) == Decor.DEEP, "the ground shelves down into it")
	var out := Den.on_dry(Den.middle(Den.shore), 0.3, 0.25)
	check(is_equal_approx(Den.wade(out), -0.25) and Den.on_dry(out, 0.3, 0.25).is_equal_approx(out), "and the nearest dry floor to a place in it can be found")
	for where in Den.shores():
		main.place_decor(Decor.Kind.POOL, Den.middle(where))
		check(Den.shore == where and pool.position == Den.middle(where) and _wet_share() > 0.4 and _wet_share() < 0.6, "it lies over the %s of the room, half the floor (%.2f)" % [["", "back", "left", "right"][where], _wet_share()])
	# Nothing else goes in it
	var skull := main.place_decor(Decor.Kind.SKULL, Den.middle(Den.shore))
	check(Den.wade(skull.position) <= -skull.radius + 0.001, "a thing put down in the pool stands on the dry floor beside it")
	pet.position = Vector3(-2.0, 0, 1.6)
	pet._enter(Cryptlin.State.IDLE, 60.0)
	await _frames(2)
	await _slide(_screen(skull.position + Vector3(0, 0.2, 0)), _screen(Den.middle(Den.shore)))
	check(Den.wade(skull.position) <= -skull.radius + 0.001 and Den.wade(skull.position) > -skull.radius - 0.2 and Den.shore == Den.Shore.RIGHT, "and dragged at the water it stops at the edge")
	await _slide(_screen(main.nest_pos + Vector3(0, 0.1, 0)), _screen(Den.middle(Den.shore)))
	check(Den.wade(main.nest_pos) <= -0.699 and Den.wade(main.nest_pos) > -0.9, "so does the nest")
	var spots: Array[Vector3] = [main._clear_spot(Den.middle(Den.shore), 1.1)]
	for i in 20:
		spots.append_array([main._free_spot(0.3), main.hiding_place(pet), main.nest_spot(pet), main.toilet_spot(pet)])
	check(spots.all(func(p: Vector3) -> bool: return Den.wade(p) < 0.0), "an egg, a thing, a nest, a hiding place and a dropping are all found dry floor")
	var left := main.leave_mess(Mess.Kind.DROPPING, Den.middle(Den.shore), pet)
	check(Den.wade(left.position) < 0.0, "and nothing is left lying in the water")
	main.clear_mess(left)
	# A drag moves it, and puts it away
	await _slide(_screen(Den.middle(Den.Shore.RIGHT)), _screen(Vector3(-2.0, 0, 0.5)))
	check(Den.shore == Den.Shore.LEFT and pool.position == Den.middle(Den.Shore.LEFT), "a finger on the water drags the pool over to another part of the floor")
	check(Den.wade(skull.position) < 0.0 and Den.wade(main.nest_pos) < 0.0, "and what was standing there is moved out of it")
	pet.position = Vector3(2.0, 0, 1.6)
	pet._enter(Cryptlin.State.IDLE, 60.0)
	await _frames(2)
	await _slide(_screen(Den.middle(Den.Shore.LEFT)), _on_shelf("notebook"))
	check(main.decor_of(Decor.Kind.POOL) == null and Den.shore == Den.Shore.NONE and _wet_share() == 0.0, "dragged down to the row it is put away, and the floor is whole again")
	main.move_nest(Vector3(0, 0, -1.5))
	main.place_decor(Decor.Kind.SKULL, Vector3(1.2, 0, -1.6))
	left = main.leave_mess(Mess.Kind.DROPPING, Vector3(-1.2, 0, -1.5), pet)
	pool = main.place_decor(Decor.Kind.POOL, Den.middle(Den.Shore.BACK))
	check(Den.shore == Den.Shore.BACK and Den.wade(main.nest_pos) <= -0.699 and Den.wade(skull.position) < 0.0 and Den.wade(left.position) < 0.0, "laid where things stand, it moves them out onto the dry")
	main.clear_mess(left)
	check(not main.shelf.ids.has("pool"), "while it is laid it is not on the wheel")
	main.remove_decor(pool)
	check(main.decor_of(Decor.Kind.POOL) == null and Den.shore == Den.Shore.NONE and main.shelf.ids.has("pool"), "and put away it is back there")
	# The room changing shape round it
	pool = main.place_decor(Decor.Kind.POOL, Den.middle(Den.Shore.LEFT))
	var wide := Den.half
	var lamp := Den.lamp_at
	main._reshape(Vector2(1.85, 3.1), Vector3(0, 6.3, 0.1))
	check(Den.shores() == [Den.Shore.BACK] and Den.shore == Den.Shore.BACK and pool.position == Den.middle(Den.Shore.BACK) and _wet_share() > 0.4 and _wet_share() < 0.6, "on an upright phone it fits over the back of the room, and is built again there (%.2f)" % _wet_share())
	check(Den.wade(main.nest_pos) < 0.0 and Den.wade(skull.position) < 0.0 and absf(skull.position.x) < Den.half.x, "with the things in the room brought out of it")
	var room := (1.0 - _wet_share()) * 4.0 * Den.half.x * Den.half.y
	check(room > 8.0, "which leaves four of them room on the dry half (%.1f square)" % room)
	main._reshape(wide, lamp)
	check(Den.shore == Den.Shore.BACK and pool.position == Den.middle(Den.Shore.BACK) and _wet_share() > 0.4 and _wet_share() < 0.6, "and turned back, it is built again to the wide room")
	main.remove_decor(skull)
	# Food thrown in floats, and can be got at; a toy floats back
	pet.position = Vector3(0, 0, 1.6)
	pet._enter(Cryptlin.State.IDLE, 60.0)
	main.feed((pet.yuck_food + 1) % Snack.NAMES.size(), Den.at_shore(0.3, 1.2) + Vector3(0, 2.0, 0))
	var bit: Snack = main.snacks[0]
	check(await _until(func() -> bool: return bit.landed, 300) and Den.wade(bit.position) > 0.5 and bit.position.y < 0.0, "food thrown into the pool floats")
	check(await _until(func() -> bool: return Den.wade(bit.position) < 0.2, 900) and Den.wade(bit.position) > 0.0, "and drifts in to the shallows")
	pet.belly = 30.0
	pet._enter(Cryptlin.State.IDLE, 0.2)
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500) and pet.belly > 50.0 and (pet.needs_water() or Den.wade(pet.position) <= 0.15), "where it is reached, and eaten")
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 60.0)
	main.play_ball(Ball.Kind.BALL)
	main.ball.position = Den.at_shore(-0.4, 1.3) + Vector3(0, 1.0, 0)
	main.ball.vel = Vector3.ZERO
	pet.ball_cooldown = 60.0
	check(await _until(func() -> bool: return main.ball.position.y < Ball.R * 0.9, 200) and Den.wade(main.ball.position) > 0.5, "a toy thrown into it floats")
	check(await _until(func() -> bool: return Den.wade(main.ball.position) < 0.0 and main.ball.position.y >= Ball.R - 0.001, 1500), "and comes back to the edge and out onto the floor")
	main._clear_toys()
	pet.set_needs({"belly": 100.0, "energy": 95.0, "fun": 80.0, "bowel": 0.0, "bladder": 0.0})
	if pet.needs_water():
		# One that lives in water is in and out of it as it likes
		pet._enter(Cryptlin.State.VISIT)
		check(pet.visiting == pool, "one that lives in water goes to the pool of its own accord")
		check(await _until(func() -> bool: return pet.state == Cryptlin.State.VISIT and pet.step >= 1 and Den.wade(pet.position) > 0.3 and pet.position.y < -0.1, 900), "and wades in up to its middle")
		var waded := 0
		while pet.state == Cryptlin.State.VISIT and waded < 4000:
			await _frames(10)
			waded += 10
		check(waded > 900 and pet.kicks == 2 and pet.state != Cryptlin.State.VISIT, "paddling about in one part of it and then another for a good while (%d s)" % (waded / 60))
		pet.target = Vector3(0.5, 0, 1.6)
		pet._enter(Cryptlin.State.WANDER)
		check(await _until(func() -> bool: return Den.wade(pet.position) < -0.3, 600) and is_equal_approx(pet.position.y, pet.jump_y), "it walks out of it")
		pet.target = Den.at_shore(-0.5, 1.2)
		pet._enter(Cryptlin.State.WANDER)
		check(await _until(func() -> bool: return Den.wade(pet.position) > 0.6, 600) and pet.state != Cryptlin.State.FLOUNDER, "and back in, as it likes")
		check(not pet._footing(Den.middle(Den.shore), 0.4).is_equal_approx(Den.on_dry(Den.middle(Den.shore), 0.4)), "anywhere in the room is somewhere for it to go")
		pet.fight_cooldown = 0.0
		pet._enter(Cryptlin.State.DIG)
		check(pet.state != Cryptlin.State.DIG and not pet._can_fight(), "out in the water it does not dig, and is not to be fought with")
		pet.fight_cooldown = 20.0
		pet.bowel = 100.0
		pet._enter(Cryptlin.State.IDLE, 0.1)
		check(await _until(func() -> bool: return main.droppings() == 1, 1500) and Den.wade(main.messes.back().position) < 0.0, "it gets out of the water to leave a dropping")
		main.clear_mess(main.messes.back())
		await _until(func() -> bool: return _settled(pet), 600)
		pet.energy = 40.0
		main.set_lamp(Den.Lamp.OFF)
		check(await _until(func() -> bool: return pet.state == Cryptlin.State.SLEEP, 1800) and absf(Den.wade(pet.position)) < 0.3, "and it sleeps at the edge of it (%.2f)" % Den.wade(pet.position))
		pet.energy = 70.0
		main.set_lamp(Den.Lamp.BRIGHT)
		await _until(func() -> bool: return pet.state != Cryptlin.State.SLEEP, 300)
	else:
		# One that does not keeps to the dry half
		var goes: Array[Vector3] = []
		for i in 30:
			goes.append(pet._footing(Vector3(randf_range(-9.0, 9.0), 0, randf_range(-9.0, 9.0)), 0.4))
		check(goes.all(func(p: Vector3) -> bool: return Den.wade(p) < 0.0), "one that does not live in water has nowhere to go but the dry floor")
		pet.position = Vector3(0.4, 0, 1.4)
		pet.target = Den.middle(Den.shore)
		pet._enter(Cryptlin.State.WANDER)
		await _frames(300)
		check(Den.wade(pet.position) <= 0.0 and Den.wade(pet.position) > -0.5 and pet.state != Cryptlin.State.FLOUNDER and pet.position.y >= 0.0, "walked at the water, it stops at the edge (%.2f)" % Den.wade(pet.position))
		await _until(func() -> bool: return _settled(pet), 600)
		pet._enter(Cryptlin.State.VISIT)
		pet.visiting = pool
		check(await _until(func() -> bool: return pet.state == Cryptlin.State.VISIT and pet.step >= 1, 900) and Den.wade(pet.position) <= 0.0 and Den.wade(pet.position) > -0.4, "it comes down to the edge for a drink")
		await _until(func() -> bool: return pet.state != Cryptlin.State.VISIT, 900)
		await _until(func() -> bool: return _settled(pet), 600)
		pet._enter(Cryptlin.State.IDLE, 60.0)
		pet.pick_up()
		pet.carry(Den.at_shore(0.0, 1.2) + Vector3(0, 0.8, 0))
		await _frames(40)
		check(pet.position.y > 0.6, "carried out over the pool, it hangs over it")
		pet.put_down()
		check(await _until(func() -> bool: return pet.state == Cryptlin.State.FLOUNDER, 200) and pet.position.y < -0.1, "let go there, it is in the water up to its middle")
		check(await _until(func() -> bool: return Den.wade(pet.position) <= 0.0 and pet.state != Cryptlin.State.FLOUNDER, 600) and pet.feeling == Cryptlin.Feeling.GRUMPY, "and scrambles out by the shortest way, cross")
		await _until(func() -> bool: return _settled(pet), 600)
		pet.position = Den.at_shore(0.0, -0.4)
		pet._enter(Cryptlin.State.IDLE, 60.0)
		await _frames(2)
		pet.push(Den.at_shore(0.0, 1.0) - pet.position)
		check(await _until(func() -> bool: return pet.state == Cryptlin.State.FLOUNDER, 300), "shoved in, the same")
		check(await _until(func() -> bool: return Den.wade(pet.position) <= 0.0 and pet.state != Cryptlin.State.FLOUNDER, 600), "and out it comes again")
	await _until(func() -> bool: return _settled(pet), 900)


func _run() -> void:
	# The egg
	await _frames(5)
	check(main.who().egg != null and main.who().pet == null, "a new game starts with an egg (%s)" % main.who().egg.title())
	check(main.shelf.ids.has("bone") and main.shelf.ids.has("notebook") and main.shelf.ids.size() == _all_but_in_use() and main.shelf.ids.has("egg"), "everything is on the wheel but the nest and the ground that are in use (%d things)" % main.shelf.ids.size())
	main.use("bone")
	check(main.snacks.is_empty(), "but there is nothing to feed yet")
	check(await _until(func() -> bool: return main.who().egg.landed, 300), "the egg drops into the light")
	var warm := main.who().egg.warmth
	await _frames(90)
	var gained := main.who().egg.warmth - warm
	check(gained > 0.0, "the lamp warms it (%.1f)" % main.who().egg.warmth)
	main.set_lamp(Den.Lamp.HEAT)
	warm = main.who().egg.warmth
	await _frames(90)
	check(main.who().egg.warmth - warm > gained * 1.8, "the heat lamp warms it faster")
	main.set_lamp(Den.Lamp.OFF)
	await _frames(20)
	warm = main.who().egg.warmth
	await _frames(60)
	check(is_equal_approx(main.who().egg.warmth, warm), "and not at all when it is out")
	main.set_lamp(Den.Lamp.BRIGHT)
	warm = main.who().egg.warmth
	await _tap(_screen(main.who().egg.centre()))
	check(main.who().egg.warmth > warm + 2.0, "a tap warms it a little")
	main.who().egg.warmth = 40.0
	main.save_game()
	await _restart()
	check(main.who().egg != null and main.who().kind == kind and main.who().egg.warmth > 39.0, "a saved egg is still there, as warm")
	check(main.who().egg.stage == 1, "and as cracked")
	var at := _screen(main.who().egg.centre())
	_touch(at, true)
	var most := 0
	for i in 1500:
		if main.who().pet != null:
			break
		most = maxi(most, main.who().egg.stage)
		_drag(at + Vector2(sin(i * 0.5) * 6.0, 0), Vector2(3, 0))
		await _frames(1)
	_touch(at, false)
	check(most == 2, "rubbing it cracks it further")
	check(main.who().pet != null and main.who().egg == null, "and then it hatches")
	var pet := main.who().pet
	await _frames(30)
	check(pet.kind == kind, "what was in the egg is a %s" % pet.kind_name())
	check(pet.legs.size() == 2 and pet.eyes.size() >= 1, "a cryptlin is built")
	check(pet.nature != pet.nature2 and pet.nature_name().contains(", "), "with two natures (%s)" % pet.nature_name())
	_looks(pet)
	if pet.likes.has("sight"):
		_digger(pet)
	if pet.likes.has("print"):
		await _tracker(pet)
	if pet.decoy != null:
		await _serpent(pet)
	if pet.hops != "":
		await _hopper(pet)
	if pet.heave > 0.0:
		await _whale(pet)
	if pet.podge != null:
		await _snowball(pet)
	if pet.stub != null:
		await _halfling(pet)
	check(pet.is_baby() and pet.growing_left() > 24.0 * 3600.0, "a baby, with more than a day of growing to do")

	# Its name
	check(main.who().name != "", "it has a name made up for it (%s)" % main.who().name)
	main.open_namer(main.who())
	check(main.namer.visible, "and you are asked what to call it")
	main._name_roll()
	main.name_edit.text = "  Smoke  "
	main._name_done()
	check(not main.namer.visible and main.who().name == "Smoke", "what you type is its name")
	await _until(func() -> bool: return _settled(pet), 600)

	# Feeding, from the shelf
	pet.belly = 30.0
	pet.energy = 90.0
	var food := Items.id_of("food", (pet.yuck_food + 1) % Snack.NAMES.size())  # anything but the one it will not eat
	await _tap(_on_shelf(food))
	check(main.snacks.size() == 1, "a tap on food on the shelf drops it in")
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500), "it finds it and eats it")
	check(pet.belly > 55.0, "eating fills its belly (%.0f)" % pet.belly)
	await _until(func() -> bool: return _settled(pet), 600)
	pet.belly = 30.0
	await _slide(_on_shelf(food), _screen(Vector3(-1.0, 0.9, 0.5)), 24, _on_shelf(food) - Vector2(0, 160))
	check(main.snacks.size() == 1 and main.snacks[0].position.x < -0.5, "dragged up off the shelf, it drops where you let go")
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500), "and is eaten too")

	# Food on the end of a finger stays there, and food lying in the room can be picked up again
	await _until(func() -> bool: return _settled(pet), 600)
	pet.belly = 100.0
	pet.position = Vector3(-1.6, 0, -1.2)
	pet._enter(Cryptlin.State.IDLE, 30.0)
	var from_row := _on_shelf(food)
	var above := _screen(Vector3(0.5, 0.75, 1.0))
	_touch(from_row, true)
	await _frames(2)
	for i in 10:
		_drag(from_row.lerp(above, (i + 1) / 10.0), (above - from_row) / 10.0)
		await _frames(1)
	await _frames(20)
	check(main.held_snack != null and main.held_snack.held and main.snacks.is_empty(), "food dragged up off the row hangs on the finger")
	var hung := main.held_snack.position
	await _frames(60)
	check(main.held_snack.position.distance_to(hung) < 0.02, "held still for a second, it has not sunk")
	check(_screen(main.held_snack.position).distance_to(above) < 30.0, "and is under the finger")
	_touch(above, false)
	await _frames(2)
	check(main.snacks.size() == 1 and main.held_snack == null, "let go, it drops")
	await _until(func() -> bool: return main.snacks[0].landed, 300)
	var lying: Snack = main.snacks[0]
	var on_it := _screen(lying.position + Vector3(0, 0.08, 0))
	var over := _screen(Vector3(1.2, 0.75, 0.4))
	_touch(on_it, true)
	await _frames(2)
	check(main.held_snack == lying and main.snacks.is_empty(), "a finger on food lying in the room picks it up, and it is nobody's while it is held")
	for i in 10:
		_drag(on_it.lerp(over, (i + 1) / 10.0), (over - on_it) / 10.0)
		await _frames(1)
	await _frames(20)
	check(lying.position.x > 0.8 and lying.position.y > 0.4, "and carries it")
	_touch(over, false)
	await _frames(2)
	check(main.snacks.size() == 1 and main.snacks[0] == lying, "let go, it is anybody's again")
	pet.belly = 30.0
	pet._enter(Cryptlin.State.IDLE, 0.2)
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500) and pet.belly > 50.0, "and is eaten")

	# The wheel of things, on a wide screen and on an upright phone
	await _until(func() -> bool: return _settled(pet), 600)
	var screen := root.size
	root.size = Vector2i(1280, 720)
	await _frames(5)
	check(not main.tall_room and main.shelf.size.x > 1200.0, "laid flat, the room is the wide one")
	await _wheel(pet, "wide")
	root.size = Vector2i(540, 1170)
	await _frames(5)
	check(main.tall_room and main.shelf.size.x < 800.0, "stood upright, it is the tall one")
	await _wheel(pet, "upright")
	root.size = screen
	await _frames(5)

	# The ball
	pet.fun = 20.0
	await _until(func() -> bool: return _settled(pet), 600)
	await _tap(_on_shelf("ball"))
	check(main.ball != null, "a tap on the ball throws it in")
	check(await _until(func() -> bool: return pet.kicks_total > 0, 1500), "it chases the ball and kicks it")
	check(pet.fun > 25.0, "playing is fun (%.0f)" % pet.fun)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.CHASE_BALL, 2400), "it tires of the ball in the end")
	await _until(func() -> bool: return main.ball.speed() < 0.3 and main.ball.position.y < 0.2, 900)
	check(absf(main.ball.position.x) <= Den.half.x and absf(main.ball.position.z) <= Den.half.y, "the ball stays inside the walls")

	# Picking the ball up and throwing it
	main.ball.vel = Vector3.ZERO
	main.ball.position = Vector3(-0.8, Ball.R, 0.8)
	await _frames(2)
	at = _screen(main.ball.global_position)
	_touch(at, true)
	await _frames(2)
	check(main.ball.held, "a finger on the ball picks it up")
	for i in 10:
		at += Vector2(12, -4)
		_drag(at, Vector2(12, -4))
		await _frames(1)
	_touch(at, false)
	await _frames(2)
	check(not main.ball.held and main.ball.speed() > 0.5, "letting go throws it")

	# Petting and booping
	await _until(func() -> bool: return _settled(pet) and pet.ball_cooldown > 0.0, 2400)
	main._clear_toys()
	pet._enter(Cryptlin.State.IDLE, 3.0)
	pet.position = Vector3(0.3, 0, 0.4)
	await _frames(2)
	var love := pet.love
	at = _screen(pet.body_centre())
	_touch(at, true)
	for i in 40:
		_drag(at + Vector2(sin(i * 0.5) * 6.0, 0), Vector2(3, 0))
		await _frames(1)
	check(pet.state == Cryptlin.State.PETTED, "rubbing it pets it")
	check(pet.love > love, "petting builds the bond")
	_touch(at, false)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.PETTED, 200), "it stops purring when you stop")
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	await _tap(_screen(pet.body_centre()))
	check(pet.state == Cryptlin.State.STARTLED, "a tap makes it jump")

	# Calling it over, and the lamp
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	var spot := Vector3(1.2, 0, 1.0) if pet.position.x < 0.0 else Vector3(-1.2, 0, 1.0)
	await _tap(_screen(spot))
	check(pet.state == Cryptlin.State.COME, "a tap on the floor calls it")
	check(await _until(func() -> bool: return pet.position.distance_to(spot) < 0.5, 600), "and it comes")
	var far := Vector3(-0.9, 0, 0.5) if pet.position.x > 0.0 else Vector3(0.9, 0, 0.5)
	# (near enough to see, for one that does not see far)
	if pet.likes.has("sight"):
		far = Vector3(spot.x * 0.15, 0, 0.6)
	_touch(_screen(far), true)
	await _frames(30)
	check(main.light_dragging, "a finger held on the floor takes the lamp")
	check(await _until(func() -> bool: return main.light_point.distance_to(far) < 0.4, 120), "the light follows it")
	check(await _until(func() -> bool: return pet.state == Cryptlin.State.CHASE_LIGHT, 60), "and the cryptlin chases the light")
	_touch(_screen(far), false)
	await _frames(5)
	check(not main.light_dragging, "letting go lets the lamp swing back")
	await _until(func() -> bool: return main.light_point.length() < 0.2, 300)
	var seen: Array[int] = []
	for i in 4:
		await _tap(_screen(main.bulb.global_position))
		seen.append(main.lamp_mode)
	check(seen == [Den.Lamp.LOW, Den.Lamp.HEAT, Den.Lamp.OFF, Den.Lamp.BRIGHT], "a tap on the lamp turns it low, to heat, off, and bright again")

	# Lamp off: bed
	await _until(func() -> bool: return _settled(pet), 900)
	pet.energy = 40.0
	main.set_lamp(Den.Lamp.OFF)
	check(not main.light_on, "the lamp goes out")
	check(await _until(func() -> bool: return pet.state == Cryptlin.State.SLEEP, 1800), "in the dark it goes to its nest and sleeps")
	check(pet.position.distance_to(main.nest_pos) < 0.5, "in its nest")
	var rested := pet.energy
	await _frames(120)
	check(pet.energy > rested, "sleep restores it")
	pet.energy = 70.0
	main.set_lamp(Den.Lamp.BRIGHT)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.SLEEP, 300), "the lamp coming on wakes it")

	# It lives by the clock: a minute changes next to nothing, and hours away are lived through
	pet.belly = 80.0
	pet.fun = 80.0
	pet.energy = 90.0
	await _frames(60 * 20)
	check(pet.belly > 79.5 and pet.fun > 79.0, "twenty seconds leaves it as full as it was (%.2f)" % pet.belly)
	pet.belly = 64.0
	var name := main.who().name
	var seed_was := main.who().look_seed
	await _restart()
	check(main.who().name == name and main.who().look_seed == seed_was and main.who().pet != null and main.who().pet.kind == kind, "the same cryptlin is there next time")
	check(absf(main.who().pet.belly - 64.0) < 1.0, "as full as it was left (%.0f)" % main.who().pet.belly)
	main.who().pet.belly = 100.0
	main.who().pet.energy = 90.0
	await _come_back_after(6.0 * 3600.0)
	pet = main.who().pet
	check(pet.belly < 75.0 and pet.belly > 30.0, "six hours away and it is hungrier, not starving (%.0f)" % pet.belly)
	check(pet.is_baby(), "and still a baby")
	pet.belly = 100.0
	await _come_back_after(40.0 * 3600.0)
	pet = main.who().pet
	check(pet.belly < 15.0, "left for a day and a half, it is starving (%.0f)" % pet.belly)
	check(not pet.is_baby() and is_equal_approx(pet.grow, pet.adult_size), "and has grown up, %.2f times the usual size" % pet.adult_size)
	# (what it left on the floor in that time is cleared away, so as not to be underfoot for what follows)
	for m in main.messes.duplicate():
		main.clear_mess(m)

	# Tastes: its favourite food, the one it cannot stand, and its favourite toy
	pet.set_needs({"belly": 40.0, "fun": 50.0, "energy": 90.0, "love": 40.0})
	main.who().known = {}
	pet._enter(Cryptlin.State.IDLE, 0.5)
	pet.position = Vector3(0.3, 0, 0.4)
	main.feed(pet.yuck_food)
	check(await _until(func() -> bool: return main.who().known.get("yuck", false), 1500), "it spits out %s" % Snack.PLURALS[pet.yuck_food])
	check(pet.feeling == Cryptlin.Feeling.DISGUSTED and main.snacks.is_empty(), "and is disgusted")
	check(main.toast.text.findn(Snack.PLURALS[pet.yuck_food]) < 0, "nothing is written on the screen about it")
	pet.belly = 40.0
	pet.flash_time = 0.0
	main.feed(pet.fav_food)
	check(await _until(func() -> bool: return main.who().known.get("food", false), 1500), "it loves %s" % Snack.PLURALS[pet.fav_food])
	check(pet.feeling == Cryptlin.Feeling.LOVING, "and shows it")
	check(main.shelf.marks.get(Items.id_of("food", pet.fav_food)) == "heart" and main.shelf.marks.get(Items.id_of("food", pet.yuck_food)) == "cross", "the shelf marks what it loves and what it hates")
	await _until(func() -> bool: return _settled(pet), 600)
	pet.energy = 90.0
	pet.set_needs({"fun": 20.0, "bowel": 0.0, "bladder": 0.0})
	main.play_ball(pet.fav_toy)
	check(main.ball != null and main.ball.kind == pet.fav_toy, "the %s comes out" % Ball.PLAIN[pet.fav_toy])
	check(await _until(func() -> bool: return main.who().known.get("toy", false), 2400), "and turns out to be its favourite")
	main._clear_toys()

	# Doing up its room: things it likes, one it hates, and the ground
	await _until(func() -> bool: return _settled(pet), 900)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	pet.position = Vector3(0, 0, 0.6)
	var comfort := main.comfort_of(pet)
	var liked: int = pet.like_decor[0]
	await _tap(_on_shelf(Decor.IDS[liked]))
	check(main.decor_of(liked) != null, "a tap on the %s stands it in the room" % Decor.PLAIN[liked])
	check(pet.state == Cryptlin.State.INSPECT, "and the cryptlin goes to look it over")
	check(await _until(func() -> bool: return main.who().known.get("decor+" + Decor.IDS[liked], false), 900), "it likes having it about")
	check(main.comfort_of(pet) > comfort, "and is more at home for it (%.0f)" % main.comfort_of(pet))
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	comfort = main.comfort_of(pet)
	main.use(Decor.IDS[pet.hate_decor])
	check(await _until(func() -> bool: return main.who().known.get("decor-" + Decor.IDS[pet.hate_decor], false), 900), "it cannot stand the %s" % Decor.PLAIN[pet.hate_decor])
	check(main.comfort_of(pet) < comfort, "and is less at home for it")
	main.use(Decor.IDS[pet.hate_decor])
	check(main.decor_of(pet.hate_decor) == null, "a second tap puts it away again")
	# Dragging something about the floor, and back to the shelf
	var thing := main.decor_of(liked)
	thing.position = Vector3(-1.2, 0, 0.6)
	# (well out of the way: a big one is easy to catch hold of by mistake)
	pet.position = Vector3(-2.2, 0, -1.6)
	pet._enter(Cryptlin.State.IDLE, 6.0)
	await _frames(2)
	await _slide(_screen(thing.position + Vector3(0, 0.2, 0)), _screen(Vector3(0.9, 0, 1.0)))
	check(thing.position.x > 0.4, "a thing in the room can be dragged about")
	await _slide(_screen(thing.position + Vector3(0, 0.2, 0)), _on_shelf("notebook"))
	check(main.decor_of(liked) == null, "and dragged back down to the shelf to put it away")
	# Its nest goes where you drag it
	var nest_was := main.nest_pos
	await _slide(_screen(main.nest_pos + Vector3(0, 0.1, 0)), _screen(Vector3(1.2, 0, 0.9)))
	check(main.nest_pos.distance_to(nest_was) > 1.0 and main.nest.position == main.nest_pos, "the nest goes where you drag it")
	# And where the cryptlin drags it
	nest_was = main.nest_pos
	pet._enter(Cryptlin.State.MOVE_NEST)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.MOVE_NEST, 1500) and main.nest_pos.distance_to(nest_was) > 0.5, "or where the cryptlin drags it itself")
	# Shelters to hide in, and a rock to sit on
	pet.hate_decor = Decor.Kind.DISH
	for k in Decor.IDS.size():
		var probe := Decor.new(k)
		var is_shelter := probe.hollow
		probe.free()
		if not is_shelter:
			continue
		pet.set_needs({"belly": 80.0, "energy": 90.0, "bowel": 0.0, "bladder": 0.0})
		var hole := main.place_decor(k, Vector3(-1.1, 0, -0.8))
		await _until(func() -> bool: return _settled(pet), 900)
		pet.position = Vector3(1.2, 0, 0.9)
		pet._enter(Cryptlin.State.LURK)
		check(pet.visiting == hole and await _until(func() -> bool: return pet.state == Cryptlin.State.LURK and pet.step == 1, 900) and pet.position.distance_to(hole.position) < 0.4, "it hides in the %s" % Decor.PLAIN[k])
		main.remove_decor(hole)
	var rock := main.place_decor(Decor.Kind.ROCK, Vector3(0.8, 0, -0.6))
	await _until(func() -> bool: return _settled(pet), 900)
	pet._enter(Cryptlin.State.VISIT)
	pet.visiting = rock
	check(await _until(func() -> bool: return pet.state == Cryptlin.State.VISIT and pet.lift > 0.3, 900), "and climbs up to sit on the rock")
	main.remove_decor(rock)
	# A pool: half the floor under water. A water kind is not at home without one; the rest take it or leave it
	await _until(func() -> bool: return _settled(pet), 900)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	pet.position = Vector3(0, 0, 0.9)
	main.move_nest(Vector3(-1.6, 0, -1.2))
	main.who().known.erase("water")
	var dry := main.comfort_of(pet)
	check(pet.dry() == pet.needs_water() and not main.notebook._notes(pet).contains("pool"), "nothing says yet whether it needs water")
	check(Den.shore == Den.Shore.NONE and Den.wade(Vector3(0, 0, -2.0)) < 0.0 and Den.deep(Vector3(0, 0, -2.0)) == 0.0 and Den.on_dry(Vector3(1, 0, -2), 0.3, 0.3) == Vector3(1, 0, -2), "with no pool the whole floor is dry")
	check(Den.shores() == [Den.Shore.BACK, Den.Shore.LEFT, Den.Shore.RIGHT], "in a wide room a pool fits over the back or either side")
	await _tap(_on_shelf("pool"))
	var pool := main.decor_of(Decor.Kind.POOL)
	check(pool != null and Den.shore == Den.Shore.RIGHT and pool.position == Den.middle(Den.Shore.RIGHT), "a tap on the pool lays it over the part of the floor with least on it")
	check(_wet_share() > 0.4 and _wet_share() < 0.6, "and about half the floor is under water (%.2f)" % _wet_share())
	check(not Decor.Kind.POOL in pet.like_decor and pet.hate_decor != Decor.Kind.POOL, "the pool is no part of its likes and dislikes")
	check(await _until(func() -> bool: return main.who().known.get("water", false), 900), "the cryptlin goes to look, and whether it needs water is found out")
	check(main.toast.text.findn("water") < 0 and main.toast.text.findn("pool") < 0, "nothing is written on the screen about it")
	if pet.needs_water():
		check(main.comfort_of(pet) > dry + 30.0, "a water kind is far more at home with a pool (%.0f, from %.0f)" % [main.comfort_of(pet), dry])
		check(main.shelf.marks.get("pool") == "heart" and main.notebook._notes(pet).contains("a pool to wade in"), "the shelf marks it and the notebook says so")
	else:
		check(absf(main.comfort_of(pet) - dry) < 5.0 and not main.shelf.marks.has("pool"), "its kind takes a pool as it would anything else")
		check(main.notebook._notes(pet).contains("no more than a drink"), "and the notebook says so")
	await _pool(pet)
	# A save from when the pool was a small round thing: it loads as the pool there is now, over
	# the part of the floor the old one stood in
	main.place_decor(Decor.Kind.SKULL, Vector3(-1.9, 0, 1.0))
	main.save_game()
	main.queue_free()
	await _frames(3)
	var kept: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save))
	for held: Dictionary in kept["decor"]:
		if int(held["k"]) == Decor.Kind.POOL:
			held["x"] = -1.8
			held["z"] = 0.4
	var rewritten := FileAccess.open(save, FileAccess.WRITE)
	rewritten.store_string(JSON.stringify(kept))
	rewritten.close()
	main = _start()
	await _frames(5)
	pet = main.who().pet
	pool = main.decor_of(Decor.Kind.POOL)
	check(pool != null and Den.shore == Den.Shore.LEFT and pool.position == Den.middle(Den.Shore.LEFT) and _wet_share() > 0.4, "a save with the old small pool in it loads with the pool over that side of the floor")
	check(Den.wade(main.decor_of(Decor.Kind.SKULL).position) < 0.0 and Den.wade(main.nest_pos) < 0.0, "and what stood there out on the dry")
	main.remove_decor(main.decor_of(Decor.Kind.SKULL))
	main.remove_decor(pool)
	check(Den.shore == Den.Shore.NONE and _wet_share() == 0.0, "put away, the floor is whole again")
	if pet.needs_water():
		check(pet.dry() and main.comfort_of(pet) < dry + 1.0, "without one a water kind is back to making do")
		await _until(func() -> bool: return _settled(pet), 900)
		pet.set_needs({"belly": 90.0, "energy": 95.0, "fun": 80.0})
		pet._enter(Cryptlin.State.BEG)
		check(pet.beg_for == Cryptlin.Want.WATER, "and asks for water")
	await _until(func() -> bool: return _settled(pet), 900)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	# (the ground that is laid is not on the wheel: if that is the one, another goes down first)
	if main.floor_style == pet.fav_ground:
		main.set_ground((pet.fav_ground + 1) % Den.GROUNDS.size())
		await _until(func() -> bool: return _settled(pet), 900)
		pet._enter(Cryptlin.State.IDLE, 3.0)
	await _tap(_on_shelf(Items.id_of("ground", pet.fav_ground)))
	check(main.floor_style == pet.fav_ground, "a tray of %s changes the floor" % Den.GROUND_PLAIN[pet.fav_ground])
	check(await _until(func() -> bool: return main.who().known.get("ground", false), 600), "which is the ground it is happiest on")

	# What goes in comes out: some hours after a meal it goes off and leaves a dropping
	await _until(func() -> bool: return _settled(pet), 900)
	for m in main.messes.duplicate():
		main.clear_mess(m)
	pet._enter(Cryptlin.State.IDLE, 0.5)
	pet.set_needs({"belly": 40.0, "energy": 95.0, "fun": 80.0, "digest": 0.0, "bowel": 0.0, "bladder": 0.0})
	var clean := main.comfort_of(pet)
	main.feed((pet.yuck_food + 1) % Snack.NAMES.size())
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500) and pet.digest > 50.0, "what it eats has to come out")
	await _until(func() -> bool: return _settled(pet), 600)
	pet._wear(5.0 * 3600.0, false, 1.0, false)
	check(pet.bowel >= 100.0 and pet.bladder >= 100.0, "five hours on, it needs to go")
	pet.set_needs({"belly": 90.0, "energy": 95.0, "fun": 80.0, "bladder": 0.0})
	check(await _until(func() -> bool: return main.droppings() == 1, 1500), "and goes off and leaves a dropping")
	var dropping: Mess = main.messes.back()
	check(dropping.position.distance_to(main.nest_pos) > 0.8, "well away from its nest")
	check(main.comfort_of(pet) < clean - 5.0, "which spoils the place for it")
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 6.0)
	pet.position = Den.in_room(dropping.position + Vector3(-1.6 if dropping.position.x > 0.0 else 1.6, 0, 0), 0.4)
	await _frames(2)
	await _broom(pet, dropping, clean)
	pet._enter(Cryptlin.State.IDLE, 0.5)
	pet.bladder = 100.0
	check(await _until(func() -> bool: return main.messes.size() == 1 and main.messes[0].kind == Mess.Kind.PUDDLE, 1500), "it pees too, and leaves a puddle")
	main.messes[0].made -= Mess.LASTS[Mess.Kind.PUDDLE]
	await _frames(3)
	check(main.messes.is_empty(), "which dries up by itself in an hour")
	await _until(func() -> bool: return _settled(pet), 600)
	pet.set_needs({"belly": 100.0, "energy": 95.0, "digest": 100.0, "bowel": 0.0, "bladder": 0.0})
	await _come_back_after(6.0 * 3600.0)
	pet = main.who().pet
	check(main.droppings() == 1, "left alone for six hours after a meal, there is a dropping waiting")
	await _restart()
	pet = main.who().pet
	check(main.droppings() == 1, "and it is still there next time")
	for m in main.messes.duplicate():
		main.clear_mess(m)

	# A grown one left to itself may take a fancy to its nest, and stops dead if it is seen at it
	await _until(func() -> bool: return _settled(pet), 900)
	pet.set_needs({"belly": 90.0, "energy": 95.0, "fun": 80.0, "bowel": 0.0, "bladder": 0.0})
	main.nest_pos = Vector3(-0.8, 0, 0.6)
	main.move_nest(main.nest_pos)
	pet._enter(Cryptlin.State.FOND)
	check(await _until(func() -> bool: return pet.state == Cryptlin.State.FOND and pet.step == 1, 900) and pet.position.distance_to(main.nest_pos) < 0.4, "a grown one gets over-fond of its nest")
	await _frames(20)
	await _tap(_screen(pet.body_centre()))
	check(pet.state == Cryptlin.State.FOND and pet.step == 2 and pet.feeling == Cryptlin.Feeling.SCARED, "a tap and it stops dead, mortified")
	await _until(func() -> bool: return _settled(pet), 600)
	pet.age = 0.0
	pet.fond_cooldown = 0.0
	pet._enter(Cryptlin.State.FOND)
	check(pet.state != Cryptlin.State.FOND and not pet._fancies(), "a baby never does")
	pet.age = Cryptlin.GROW_AGE
	pet.grow = pet.adult_size

	# Odds and ends it gets up to
	for doing: int in [Cryptlin.State.SCRATCH, Cryptlin.State.STRETCH, Cryptlin.State.DIG, Cryptlin.State.SPIN, Cryptlin.State.GAZE]:
		pet._enter(doing)
		await _frames(40)
		check(pet.state == doing, "it can %s" % Cryptlin.State.keys()[doing].to_lower())
		check(await _until(func() -> bool: return pet.state != doing, 600), "  and stops again")
	check(main.messes.size() == 1 and main.messes[0].kind == Mess.Kind.HEAP and main.comfort_of(pet) > clean - 0.1, "digging leaves a heap of earth, which is no mess")
	main.messes[0].made -= Mess.LASTS[Mess.Kind.HEAP]
	await _frames(3)

	# The scanner
	await _until(func() -> bool: return _settled(pet), 900)
	await _tap(_on_shelf("scanner"))
	check(main.scanning and pet.xrayed and main.scanner.visible, "a tap on the scanner points it at the cryptlin")
	var screen_size := main.get_viewport().get_visible_rect().size
	var gun := main.screen_of(main.scanner.to_global(Vector3(0, Items.BORE, 0)))
	var mouth := main.screen_of(main.scanner.to_global(Items.MUZZLE))
	var aimed_at := main.screen_of(pet.global_position + Vector3(0, pet.tall() * 0.5, 0))
	check(gun.y > screen_size.y * 0.5 and gun.y < main.shelf.position.y and absf(gun.x - screen_size.x * 0.5) > screen_size.x * 0.2, "  from a lower corner of the view, above the shelf")
	check((mouth - gun).normalized().dot((aimed_at - gun).normalized()) > 0.95 and mouth.distance_to(aimed_at) > minf(screen_size.x, screen_size.y) * 0.15, "  aimed at it, and well clear of it")
	check(main.scan_ray.visible, "  with its light on it")
	check(pet.state == Cryptlin.State.SCANNED, "which holds still for it")
	pet.belly = 10.0
	await _frames(5)
	var low: float = pet.stomach_fill.scale.y
	pet.belly = 90.0
	await _frames(5)
	check(pet.stomach_fill.scale.y > low * 3.0, "its stomach shows how full it is")
	await _tap(_screen(Vector3(-1.5, 0, 1.0)))
	check(not main.scanning and not pet.xrayed and pet.skin.is_empty() and not main.scanner.visible and not main.scan_ray.visible, "a tap anywhere puts the scanner down")

	# Handling: a finger left on it picks it up, a flick pushes it, too much poking annoys it
	await _until(func() -> bool: return _settled(pet), 900)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	pet.position = Vector3(0.3, 0, 0.4)
	pet.velocity = Vector3.ZERO
	await _frames(2)
	var hold := _screen(pet.body_centre())
	_touch(hold, true)
	await _frames(45)
	check(pet.state == Cryptlin.State.HELD and pet.lift > 0.3, "a finger left on it picks it up")
	_drag(hold + Vector2(120, 0), Vector2(120, 0))
	await _frames(30)
	check(pet.position.x > 0.6, "and carries it about")
	_touch(hold + Vector2(120, 0), false)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.HELD and pet.lift == 0.0, 300), "and sets it down again")
	await _until(func() -> bool: return _settled(pet), 600)
	pet._enter(Cryptlin.State.IDLE, 3.0)
	pet.position = Vector3(0.0, 0, 0.4)
	pet.velocity = Vector3.ZERO
	await _frames(2)
	hold = _screen(pet.body_centre())
	_touch(hold, true)
	for i in 6:
		_drag(hold + Vector2(25 * (i + 1), 0), Vector2(25, 0))
		await _frames(1)
	_touch(hold + Vector2(150, 0), false)
	await _frames(3)
	check(pet.state == Cryptlin.State.SHOVED and pet.velocity.x > 0.5, "a flick pushes it")
	await _until(func() -> bool: return _settled(pet), 600)
	for i in 4:
		pet.boop()
		await _frames(8)
	check(pet.feeling == Cryptlin.Feeling.GRUMPY, "poked four times, it is grumpy")

	# What is out in the room is off the wheel, and toys wear out
	await _in_and_out(pet)
	await _toys()
	pet = main.who().pet

	# The notebook
	await _tap(_on_shelf("notebook"))
	check(main.notebook.visible and main.notebook.heading.text == "Smoke", "a tap on the notebook opens it at the cryptlin's page")
	check(main.notebook.said().contains(Snack.PLURALS[pet.fav_food]) and main.notebook.said().contains(pet.nature_name()), "which says what has been found out")
	main.use("bone")
	check(main.snacks.is_empty(), "nothing on the shelf answers while it is open")
	var turned := {}
	for i in main.notebook.pages() - 1:
		main.notebook.turn(1)
		turned[main.notebook.heading.text] = true
		check(main.notebook.body.text.length() > 60, "page %d: %s" % [i + 2, main.notebook.heading.text])
	check(Notebook.TITLES.all(func(title: String) -> bool: return turned.has(title)) and main.notebook.said(main.notebook.chapters() - 3).contains("broom") and main.notebook.said(main.notebook.chapters() - 3).contains("Toys do not last"), "every chapter comes round, and the one on the wheel has the broom and toys wearing out in it")
	await _pages()
	main.notebook.close()

	# The room is kept
	main.place_decor(Decor.Kind.SKULL, Vector3(1.0, 0, -1.0))
	main.set_nest(1)
	main.set_lamp(Den.Lamp.LOW)
	var nest_at := main.nest_pos
	main.save_game()
	await _restart()
	check(main.floor_style == main.who().pet.fav_ground and main.nest_style == 1 and main.lamp_mode == Den.Lamp.LOW, "the floor, the nest and the lamp are kept")
	check(main.decor_of(Decor.Kind.SKULL) != null and main.nest_pos.distance_to(nest_at) < 0.01, "and where things stand")
	check(main.who().known.get("food", false) and main.who().known.get("ground", false) and main.who().name == "Smoke", "and what you know of it")

	# Played inside a site with a shop: only what comes free and what was bought
	main.embedded = true
	main.stock = {"fish": 2, "cave": -1}
	main._sync()
	check(main.shelf.ids.has("fish") and main.shelf.ids.has("cave") and main.shelf.ids.has("bone") and not main.shelf.ids.has("berries"), "with a shop, the shelf holds what is free and what was bought")
	main.who().pet._enter(Cryptlin.State.IDLE, 3.0)
	main.who().pet.belly = 30.0
	main.feed(Snack.Kind.FISH)
	check(main.left_of("fish") == 1 and main.shelf.counts.get("fish") == 1, "and food bought gets used up")
	main.feed(Snack.Kind.BERRIES)
	check(main.snacks.size() == 1, "and what was not bought cannot be used")
	main.dev.visible = true
	main._sync()
	check(main.shelf.ids.size() == _all_but_in_use() and main.owns("berries") and main.left_of("fish") == -1, "with the test panel open everything is on the row without end, shop or no shop")
	main.feed(Snack.Kind.FISH)
	main.dev.visible = false
	main._sync()
	check(main.left_of("fish") == 1 and not main.owns("berries"), "and what is used meanwhile is not taken from what was bought")
	main.embedded = false
	main._clear_toys()
	main._sync()

	# A new egg
	main.set_lamp(Den.Lamp.BRIGHT)
	main.who().pet._enter(Cryptlin.State.IDLE, 3.0)
	main.ask_let_go(main.who())
	check(main.ask.visible, "asking for a new egg asks first")
	main._answer(false)
	await _frames(5)
	check(not main.ask.visible and main.who().pet != null and not main.who().leaving, "saying no keeps it")
	main.ask_let_go(main.who())
	main._answer(true)
	check(main.who().leaving and main.who().pet.state == Cryptlin.State.LEAVE, "saying yes sends it off")
	check(await _until(func() -> bool: return main.who().egg != null, 1200), "and a new egg comes")
	check(main.who().pet == null and main.ball == null and main.who().kind != kind, "holding a different kind (%s)" % main.who().egg.title())
	await _tap(_on_shelf("scanner"))
	check(main.scanning, "the scanner works on an egg too")
	main.stop_scan()

	# More than one: the egg on the shelf drops another in
	var first := main.who()
	await _tap(_on_shelf("egg"))
	check(main.residents.size() == 2 and main.residents[1].egg != null, "a tap on the egg on the shelf drops another egg in (%s)" % main.residents[1].egg.title())
	check(main.residents[1].kind != first.kind and main.residents[1].id != first.id, "of a different kind, with a number of its own")
	await _until(func() -> bool: return main.residents[0].egg.landed and main.residents[1].egg.landed, 400)
	check(main.residents[0].egg.position.distance_to(main.residents[1].egg.position) > 0.5, "clear of the first")
	await _tap(_on_shelf("notebook"))
	check(main.notebook.chapters() == Notebook.TITLES.size() + 2 and main.notebook.heading.text == "An egg", "the notebook has a page for each")
	main.notebook.close()
	for r in main.residents:
		r.egg.warmth = 100.0
	check(await _until(func() -> bool: return main.pets().size() == 2, 400), "both hatch")
	var one: Cryptlin = main.residents[0].pet
	var two: Cryptlin = main.residents[1].pet
	check(one.me.name != "" and two.me.name != "" and one.me == main.residents[0] and two.me.born > 0.0, "each with a name and a birthday of its own")
	main.open_namer(two.me)
	main.name_edit.text = "Second"
	main._name_done()
	check(two.me.name == "Second" and one.me.name != "Second", "the card names the one it was opened for")
	await _until(func() -> bool: return _settled(one) and _settled(two), 900)

	# Food is for whoever gets there, and neither stands in the other
	one.fight_cooldown = 9999.0
	two.fight_cooldown = 9999.0
	var both_eat := 0
	while both_eat == one.yuck_food or both_eat == two.yuck_food:
		both_eat += 1
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 25.0, "energy": 90.0, "fun": 80.0, "bowel": 0.0, "bladder": 0.0})
	var fed := 0
	while fed < 6 and (one.belly <= 30.0 or two.belly <= 30.0):
		fed += 1
		main.feed(both_eat)
		main.feed(both_eat)
		await _until(func() -> bool: return main.snacks.is_empty(), 2400)
	check(one.belly > 30.0 and two.belly > 30.0, "food dropped in feeds them both in the end (%.0f, %.0f)" % [one.belly, two.belly])
	await _until(func() -> bool: return _settled(one) and _settled(two), 900)
	for p: Cryptlin in [one, two]:
		p._enter(Cryptlin.State.IDLE, 6.0)
		p.position = Vector3(0.2, 0, 0.5)
	await _frames(120)
	check(one.position.distance_to(two.position) > 0.2, "put on the same spot, they push apart (%.2f)" % one.position.distance_to(two.position))

	# What is known is known of each, and the shelf shows it for the one last touched
	one.me.known = {}
	two.me.known = {}
	main.learned(one, "food")
	await _tap(_screen(two.body_centre()))
	check(main.who() == two.me and main.shelf.marks.is_empty() and not two.me.known.has("food"), "a tap on one makes it the one in question: nothing is known of it yet")
	await _until(func() -> bool: return _settled(two), 600)
	one.position = Vector3(-1.0, 0, 0.6)
	two.position = Vector3(1.0, 0, 0.6)
	for p: Cryptlin in [one, two]:
		p._enter(Cryptlin.State.IDLE, 6.0)
	await _frames(3)
	await _slide(_on_shelf("scanner"), _screen(one.body_centre()), 16, _on_shelf("scanner") - Vector2(0, 160))
	check(main.scanning and main.scanned == one.me and one.xrayed and not two.xrayed, "the scanner dragged up onto one of them scans that one")
	check(main.shelf.marks.get(Items.id_of("food", one.fav_food)) == "heart", "and the shelf shows what is known of it")
	main.stop_scan()
	main.chosen = two.me
	main.start_scan()
	check(main.scanned == two.me, "tapped, it goes to the one last touched")
	main.stop_scan()
	main.chosen = null
	one.position = Vector3(0.1, 0, 0.2)
	two.position = Vector3(1.6, 0, 1.0)
	main.start_scan()
	check(main.scanned == one.me and main.scan_side < 0.0, "or else to the one nearest the middle, held on the left")
	main.stop_scan()
	one.position = Vector3(-1.6, 0, 1.0)
	main.start_scan(one.me)
	check(main.scan_side > 0.0 and main.screen_of(main.scanner.global_position).x > main.screen_of(one.body_centre()).x, "and on the right for one that is over on the left")
	main.stop_scan()

	# One room, and each its own idea of it
	await _until(func() -> bool: return _settled(one) and _settled(two), 900)
	for m in main.messes.duplicate():
		main.clear_mess(m)
	var thing_one: int = one.like_decor[0]
	for d in main.decors.duplicate():
		main.remove_decor(d)
	var home_one := main.comfort_of(one)
	var home_two := main.comfort_of(two)
	main.place_decor(thing_one, Vector3(-1.4, 0, -1.0))
	check(main.comfort_of(one) > home_one + 10.0 and (main.comfort_of(two) > home_two + 10.0) == (thing_one in two.like_decor), "what one likes having about is not for that reason to the other's liking")
	main.remove_decor(main.decor_of(thing_one))

	# Saved and restored, and time away is lived through by each
	for m in main.messes.duplicate():
		main.clear_mess(m)
	one.set_needs({"belly": 41.0, "digest": 0.0, "bowel": 0.0, "bladder": 0.0})
	two.set_needs({"belly": 77.0, "digest": 0.0, "bowel": 0.0, "bladder": 0.0})
	var names: Array[String] = [one.me.name, two.me.name]
	var seeds: Array[int] = [one.look_seed, two.look_seed]
	await _restart()
	check(main.residents.size() == 2 and main.pets().size() == 2, "both are there next time")
	one = main.residents[0].pet
	two = main.residents[1].pet
	check(one.me.name == names[0] and two.me.name == names[1] and one.look_seed == seeds[0] and two.look_seed == seeds[1], "each who it was")
	check(absf(one.belly - 41.0) < 1.0 and absf(two.belly - 77.0) < 1.0 and one.me.known.get("food", false) and not two.me.known.has("food"), "as full as it was left, with what was known of it")
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 100.0, "energy": 90.0, "digest": 100.0, "bowel": 0.0, "bladder": 0.0})
	await _come_back_after(6.0 * 3600.0)
	one = main.residents[0].pet
	two = main.residents[1].pet
	check(one.belly < 75.0 and two.belly < 75.0, "six hours away and both are hungrier (%.0f, %.0f)" % [one.belly, two.belly])
	check(main.droppings() == 2, "and each has left a dropping")
	for m in main.messes.duplicate():
		main.clear_mess(m)

	# Getting on: what each thinks of the other, and what they get up to together
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 80.0, "energy": 90.0, "fun": 50.0, "age": Cryptlin.GROW_AGE, "bowel": 0.0, "bladder": 0.0})
		p.grow = p.adult_size
		p.fight_cooldown = 0.0
		p.me.regard = {}
		p._enter(Cryptlin.State.IDLE, 30.0)
	one.position = Vector3(-0.9, 0, 0.5)
	two.position = Vector3(0.9, 0, 0.5)
	check(is_equal_approx(main.regard(one, two), 50.0 + one.suits(two)) and is_equal_approx(one.suits(two), two.suits(one)), "to begin with they think of each other as their natures suit (%.0f)" % main.regard(one, two))
	main.warm(one, two, 60.0 - main.regard(one, two))
	main.warm(two, one, 60.0 - main.regard(two, one))
	one.meet(Cryptlin.State.SNIFF, two)
	check(await _until(func() -> bool: return one.state == Cryptlin.State.SNIFF and one.step == 1, 600) and one.position.distance_to(two.position) < 1.3, "one goes over to the other and sniffs at it")
	check(await _until(func() -> bool: return one.state != Cryptlin.State.SNIFF, 300) and main.regard(one, two) > 60.0 and main.regard(two, one) > 60.0, "and they think the better of each other for it")
	two.position = Vector3(1.2, 0, 0.8)
	two.target = Vector3(-1.2, 0, -0.6)
	two._enter(Cryptlin.State.WANDER)
	one.meet(Cryptlin.State.FOLLOW, two)
	await _frames(150)
	check(one.state == Cryptlin.State.FOLLOW and one.position.distance_to(two.position) < 1.7, "one trails round after the other")
	for p: Cryptlin in [one, two]:
		p._enter(Cryptlin.State.IDLE, 30.0)
		p.fun = 40.0
	var liking := main.standing(one, two)
	one.meet(Cryptlin.State.TAG, two)
	check(one.state == Cryptlin.State.TAG and two.state == Cryptlin.State.FLEE, "a game of chase: one runs and the other runs after it")
	check(await _until(func() -> bool: return not one.state in [Cryptlin.State.TAG, Cryptlin.State.FLEE] and not two.state in [Cryptlin.State.TAG, Cryptlin.State.FLEE], 2400), "which ends")
	check(one.fun > 40.0 and two.fun > 40.0 and main.standing(one, two) > liking, "with both the better amused and the better friends (%.0f)" % main.standing(one, two))
	# Asleep in the one nest: a heap if they get on, side by side if not
	main.move_nest(Vector3(0, 0, 0.2))
	main.warm(one, two, 80.0 - main.regard(one, two))
	main.warm(two, one, 80.0 - main.regard(two, one))
	for p: Cryptlin in [one, two]:
		p.energy = 30.0
		p.position = main.nest_pos + Vector3(0.05 if p == one else -0.05, 0, 0)
		p.velocity = Vector3.ZERO
		p._enter(Cryptlin.State.SLEEP)
	await _frames(120)
	var heaped := one.position.distance_to(two.position)
	main.warm(one, two, -60.0)
	main.warm(two, one, -60.0)
	await _frames(120)
	check(heaped > 0.05 and heaped < one.position.distance_to(two.position) - 0.1, "two that get on sleep in a heap, and two that do not lie apart (%.2f, %.2f)" % [heaped, one.position.distance_to(two.position)])
	main.warm(one, two, 30.0)
	main.warm(two, one, 30.0)
	liking = main.standing(one, two)
	main.set_lamp(Den.Lamp.OFF)
	main.pass_time(4.0 * 3600.0)
	check(one.state == Cryptlin.State.SLEEP and two.state == Cryptlin.State.SLEEP and main.standing(one, two) > liking + 1.0, "a night in the one nest brings them round to each other (%.0f, from %.0f)" % [main.standing(one, two), liking])
	main.set_lamp(Den.Lamp.BRIGHT)

	# Falling out. Two that are fed, at home and on good terms all but never fight
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 90.0, "energy": 90.0, "fun": 60.0, "health": 100.0, "bowel": 0.0, "bladder": 0.0})
		p.comfort = 70.0
		p._enter(Cryptlin.State.IDLE, 30.0)
		p.flash_time = 0.0
	one.position = Vector3(-0.3, 0, 0.5)
	two.position = Vector3(0.3, 0, 0.5)
	main.warm(one, two, 70.0 - main.regard(one, two))
	main.warm(two, one, 70.0 - main.regard(two, one))
	await _frames(3)
	check(one.temper(two) < 0.05 and not one.squabble(two, 0.5), "two that are fed, at home and on good terms have next to no fight in them (%.2f)" % one.temper(two))
	# An ill-matched hungry pair is another matter
	main.warm(one, two, -100.0)
	main.warm(two, one, -100.0)
	main.warm(one, two, 20.0)
	main.warm(two, one, 20.0)
	one.belly = 10.0
	two.belly = 10.0
	check(one.temper(two) > 0.9, "two that are hungry and cannot stand each other are spoiling for one (%.2f)" % one.temper(two))
	check(one.squabble(two, 1.0) and main.scuffle != null and one.state == Cryptlin.State.SCUFFLE and two.state == Cryptlin.State.SCUFFLE and not one.visible and not two.visible, "and come to blows: a ball of dust with the pair of them in it")
	check(await _until(func() -> bool: return main.scuffle == null, 400) and one.visible and two.visible, "which is soon over")
	var loser := one if one.health < two.health else two
	var winner := two if loser == one else one
	check(is_equal_approx(loser.health, 100.0 - Cryptlin.FIGHT_HURT) and winner.health == 100.0 and loser.state == Cryptlin.State.COWED, "the loser backs off a little the worse for it (%.0f)" % loser.health)
	check(is_equal_approx(main.regard(one, two), 20.0 - Den.FIGHT_SOURS) and is_equal_approx(main.regard(two, one), 20.0 - Den.FIGHT_SOURS), "and each thinks the less of the other")
	check(not one.squabble(two, 1.0), "they do not go straight back to it")
	for round in 3:
		await _until(func() -> bool: return _settled(one) and _settled(two), 900)
		for p: Cryptlin in [one, two]:
			p.health = minf(p.health, Cryptlin.FIGHT_FLOOR + 3.0)
			p.fight_cooldown = 0.0
			p.belly = 10.0
		one.squabble(two, 1.0)
		await _until(func() -> bool: return main.scuffle == null, 400)
	check(is_equal_approx(minf(one.health, two.health), Cryptlin.FIGHT_FLOOR), "fight after fight never takes one below the floor (%.0f, %.0f)" % [one.health, two.health])
	# A fight is had out on dry floor, pool or no pool
	await _until(func() -> bool: return _settled(one) and _settled(two), 900)
	main.place_decor(Decor.Kind.POOL, Den.middle(Den.Shore.BACK))
	one.position = Den.at_shore(0.0, 0.9)
	two.position = Den.at_shore(0.4, 0.7)
	main.start_fight(one, two)
	check(main.scuffle != null and Den.wade(main.scuffle.position) <= -0.299, "two that come to blows with water under them have it out on the dry floor")
	main.end_fight(true)
	check(Den.wade(one.position) < 0.0 and Den.wade(two.position) < 0.0, "and are both left there")
	main.remove_decor(main.decor_of(Decor.Kind.POOL))
	# The keeper can break it up: a tap, food dropped on it, the lamp swung over it
	for way in 3:
		await _until(func() -> bool: return _settled(one) and _settled(two), 900)
		for p: Cryptlin in [one, two]:
			p.health = 80.0
			p.fight_cooldown = 0.0
			p.belly = 10.0
			p.position = Vector3(-0.3 if p == one else 0.3, 0, 0.6)
		one.squabble(two, 1.0)
		await _frames(20)
		match way:
			0:
				await _tap(_screen(main.scuffle.position + Vector3(0, 0.35, 0)))
			1:
				main.feed(Snack.Kind.BONE, main.scuffle.position + Vector3(0, 1.5, 0))
				await _until(func() -> bool: return main.scuffle == null, 100)
			2:
				main.light_goal = main.scuffle.position
				main.light_point = main.scuffle.position
				main.light_dragging = true
				await _frames(3)
				main.light_dragging = false
		check(main.scuffle == null and main.scuffle_left > 0.5 and one.health == 80.0 and two.health == 80.0 and one.visible and two.visible, "%s breaks it up, and nobody is hurt" % ["a tap on the scuffle", "food dropped on it", "the lamp swung over it"][way])
		main._clear_toys()
	# A grown one never hurts a baby
	await _until(func() -> bool: return _settled(one) and _settled(two), 900)
	two.age = 0.0
	for p: Cryptlin in [one, two]:
		p.fight_cooldown = 0.0
	one.squabble(two, 1.0)
	check(main.scuffle == null and two.state == Cryptlin.State.SHOVED and two.health == 80.0 and one.health == 80.0, "a grown one does not fight a baby: it cuffs it away, and the baby is not hurt")
	two.age = Cryptlin.GROW_AGE
	# Left to themselves, the hungry pair fall out of their own accord
	for round in 8:
		if main.scuffle != null:
			break
		await _until(func() -> bool: return _settled(one) and _settled(two), 900)
		for p: Cryptlin in [one, two]:
			p.fight_cooldown = 0.0
			p.belly = 10.0
			p._enter(Cryptlin.State.IDLE, 4.0)
			p.position = Vector3(-0.3 if p == one else 0.3, 0, 0.6)
		if round % 2 == 1:
			main.feed(Snack.Kind.BONE, Vector3(0, 2.0, 0.6))
		await _until(func() -> bool: return main.scuffle != null, 400)
	check(main.scuffle != null, "left to themselves, a hungry pair that do not get on fall out: over being crowded, or over food")
	await _until(func() -> bool: return main.scuffle == null, 400)
	main._clear_toys()
	var worse := minf(one.health, two.health)
	var thinks := main.regard(one, two)
	await _restart()
	one = main.residents[0].pet
	two = main.residents[1].pet
	check(is_equal_approx(minf(one.health, two.health), worse) and is_equal_approx(main.regard(one, two), thinks), "health and what they think of each other are kept")
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 80.0, "health": 100.0})
		p.fight_cooldown = 9999.0

	# Health: days of an empty belly wear it away, and it mends fed and rested
	one.set_needs({"belly": 0.0, "health": 100.0, "energy": 90.0})
	one._wear(24.0 * 3600.0, false, 1.0, false)
	check(is_equal_approx(one.health, 100.0 - 2400.0 / Cryptlin.STARVE_HOURS) and one.health > 70.0, "a whole day of an empty belly costs it some of its health, and nothing like its life (%.0f)" % one.health)
	one.belly = 90.0
	one._wear(6.0 * 3600.0, true, 1.0, true)
	check(is_equal_approx(one.health, 100.0 - 2400.0 / Cryptlin.STARVE_HOURS + 600.0 / Cryptlin.MEND_HOURS), "fed and asleep, it mends (%.0f)" % one.health)
	one.set_needs({"belly": 60.0, "health": 30.0, "energy": 90.0})
	one.flash_time = 0.0
	one._enter(Cryptlin.State.IDLE, 5.0)
	await _frames(5)
	check(one.feeling == Cryptlin.Feeling.POORLY and one.faces[Cryptlin.Feeling.POORLY] != null, "a poorly one shows it")
	main.start_scan(one.me)
	await _frames(3)
	check(main.scanning and main._word(one.health, ["failing", "poorly", "off colour", "well", "in fine fettle"]) == "poorly", "and the scanner has a note of it")
	main.stop_scan()
	# The same wearing away whether the game is open or shut
	one.set_needs({"belly": 0.0, "health": 10.0, "energy": 90.0})
	two.set_needs({"belly": 0.0, "health": 10.0, "energy": 90.0})
	one._wear(9.5 * 3600.0, false, 1.0, false)
	two.pass_time(9.5 * 3600.0, false)
	check(one.health > 0.0 and absf(one.health - two.health) < 0.001, "an empty belly costs the same by the clock, with the game open or shut (%.3f, %.3f)" % [one.health, two.health])
	for m in main.messes.duplicate():
		main.clear_mess(m)
	for p: Cryptlin in [one, two]:
		p.set_needs({"belly": 80.0, "health": 100.0, "energy": 90.0, "bowel": 0.0, "bladder": 0.0})
		p._enter(Cryptlin.State.IDLE, 2.0)

	# The room holds four and no more
	await _tap(_on_shelf("egg"))
	await _tap(_on_shelf("egg"))
	check(main.residents.size() == Den.MAX_RESIDENTS, "two more eggs make four")
	await _tap(_on_shelf("egg"))
	check(main.residents.size() == Den.MAX_RESIDENTS, "and the room refuses a fifth")
	await _tap(_on_shelf("notebook"))
	check(main.notebook.chapters() == Notebook.TITLES.size() + 4, "the notebook has a page for each of the four")
	main.notebook.close()

	# Letting one go, from its page in the notebook: no egg comes in its place
	main.chosen = two.me
	main.notebook.open()
	check(main.notebook.resident() == two.me and main.notebook.let_go.visible, "its page has the means of letting it go")
	main.notebook.let_go.pressed.emit()
	check(main.ask.visible and not main.notebook.visible, "which asks first")
	main._answer(true)
	check(await _until(func() -> bool: return main.residents.size() == 3, 1200) and not main.parting in main.residents, "saying yes sends that one off, and the rest stay")

	# Dying. One left with an empty belly for days dies: here, while the keeper was away
	for r in main.residents:
		if r.egg != null:
			r.egg.warmth = 100.0
	check(await _until(func() -> bool: return main.pets().size() == 3, 400), "the two eggs hatch, which makes three")
	await _frames(30)
	var third: Cryptlin = main.residents[1].pet
	var fourth: Cryptlin = main.residents[2].pet
	var late := third.me.name
	one.set_needs({"belly": 100.0, "health": 100.0, "energy": 90.0})
	fourth.set_needs({"belly": 100.0, "health": 100.0, "energy": 90.0})
	third.set_needs({"belly": 0.0, "health": 2.0, "energy": 90.0})
	third._wear(1.0 * 3600.0, false, 1.0, false)
	check(third.health > 0.0, "with an hour less than it takes, it is still alive")
	await _come_back_after(3.0 * 3600.0)
	one = main.residents[0].pet
	third = main.residents[1].pet
	fourth = main.residents[2].pet
	check(third.health == 0.0 and third.state == Cryptlin.State.DYING and third.me.leaving and not third in main.pets(), "left hungry past the end of its health, it is found lying still")
	check(one.health > 90.0 and fourth.health > 90.0, "the others, fed, are none the worse")
	var lay := third.position
	check(await _until(func() -> bool: return main.departed.size() == 1, 400) and main.residents.size() == 2, "and then it is gone")
	var marker := main.decor_of(Decor.Kind.MARKER)
	check(marker != null and marker.position.distance_to(Vector3(lay.x, 0, lay.z)) < 0.3 and marker.whose == main.departed[0].id, "a marker of its own stands where it lay")
	check(is_instance_valid(third) and not third.skin.is_empty() and await _until(func() -> bool: return third.lift > 1.0, 600), "a pale ghost of it drifts up")
	var ghost := third.get_instance_id()
	check(await _until(func() -> bool: return not is_instance_id_valid(ghost), 1200), "and out through the ceiling")
	main.notebook.open()
	main.notebook.open_at(2)
	check(main.notebook.chapters() == Notebook.TITLES.size() + 3 and main.notebook.heading.text == late + ", gone" and main.notebook.said().contains("It lived") and not main.notebook.let_go.visible, "its page stays in the notebook, marked as gone")
	main.notebook.close()
	check(main.toast.text.findn("gone") < 0 and main.toast.text.findn(late) < 0, "nothing is written on the screen about it")
	# And here in front of the keeper, by the same wearing away
	late = fourth.me.name
	fourth.set_needs({"belly": 0.0, "health": 2.0, "energy": 90.0})
	fourth._wear(1.9 * 3600.0, false, 1.0, false)
	await _frames(5)
	check(fourth.health > 0.0 and fourth.state != Cryptlin.State.DYING, "the last of its health lasts as long with the game open")
	fourth._wear(0.1 * 3600.0, false, 1.0, false)
	check(await _until(func() -> bool: return fourth.state == Cryptlin.State.DYING, 10), "and then it lies down and goes still")
	await _tap(_screen(fourth.position + Vector3(0, 0.2, 0)))
	check(fourth.state == Cryptlin.State.DYING, "past poking")
	check(await _until(func() -> bool: return main.departed.size() == 2, 400) and main.residents.size() == 1 and main.departed[1].name == late and main.departed[1].lived > 0.0, "and is gone, with how long it lived written down")
	ghost = fourth.get_instance_id()
	await _until(func() -> bool: return not is_instance_id_valid(ghost), 1200)
	# The marker is a thing like any other in the room, and never on sale
	marker = main.decor_of(Decor.Kind.MARKER)
	one.position = Vector3(1.6, 0, -1.4)
	one._enter(Cryptlin.State.IDLE, 30.0)
	marker.position = Vector3(-1.0, 0, 0.6)
	await _frames(2)
	await _slide(_screen(marker.position + Vector3(0, 0.15, 0)), _screen(Vector3(0.6, 0, 1.0)))
	check(marker.position.x > 0.2, "its marker can be dragged about")
	check(not main.shelf.ids.has("marker"), "there is none on the row of things while they all stand in the room")
	await _slide(_screen(marker.position + Vector3(0, 0.15, 0)), _on_shelf("bone"))
	check(main.markers_away.size() == 1 and main.shelf.ids.has("marker") and main.shelf.counts.get("marker") == 1, "or put away, when it is on the row")
	main.embedded = true
	main._sync()
	check(main.shelf.ids.has("marker") and main.left_of("marker") == 0, "inside a page with a shop too: it is kept, not bought")
	main.embedded = false
	main._sync()
	await _tap(_on_shelf("marker"))
	check(main.markers_away.is_empty() and main.decors.filter(func(d: Decor) -> bool: return d.kind == Decor.Kind.MARKER).size() == 2 and not main.shelf.ids.has("marker"), "and brought out again")
	await _restart()
	one = main.residents[0].pet
	check(main.departed.size() == 2 and main.departed[1].name == late and main.decors.filter(func(d: Decor) -> bool: return d.kind == Decor.Kind.MARKER and d.whose > 0).size() == 2, "the markers and the pages are kept")

	# Pairing off: two grown ones that think well of each other and want for nothing
	main.new_egg().egg.warmth = 100.0
	check(await _until(func() -> bool: return main.pets().size() == 2, 400), "another hatches, to keep the one that is left company")
	await _frames(40)
	var mate: Cryptlin = main.residents[1].pet
	# (a room that suits them both: whatever each has is what it likes, and water for a water kind)
	if (one.needs_water() or mate.needs_water()) and main.decor_of(Decor.Kind.POOL) == null:
		main.place_decor(Decor.Kind.POOL, Den.middle(Den.Shore.BACK))
	for m in main.messes.duplicate():
		main.clear_mess(m)
	_content(one, mate)
	check(one.comfort >= 55.0 and mate.comfort >= 55.0 and main.would_pair(one, mate) and main.would_pair(mate, one), "a happy grown pair would pair off")
	# The hard limits. A baby is never any part of it, whichever of the two it is
	mate.age = 0.0
	check(not main.would_pair(one, mate) and not main.would_pair(mate, one), "never with a baby")
	one.meet(Cryptlin.State.PAIR, mate)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  not if the grown one goes to it")
	mate.meet(Cryptlin.State.PAIR, one)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  nor if it goes to the grown one")
	mate.partner = one
	mate._enter(Cryptlin.State.PAIR)
	one.partner = mate
	one._enter(Cryptlin.State.PAIR)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  nor by being put straight into it")
	one.age = 0.0
	one.meet(Cryptlin.State.PAIR, mate)
	check(not main.would_pair(one, mate) and one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  nor two babies")
	main.pass_time(40.0 * 3600.0)
	check(one.me.expecting.is_empty() and mate.me.expecting.is_empty() and one.me.paired == 0.0, "  nor while nobody is looking")
	# It takes both: one that is willing and one that is not do not pair
	_content(one, mate)
	main.warm(mate, one, -50.0)
	check(main.regard(one, mate) >= Den.PAIR_REGARD and not main.would_pair(one, mate) and not main.would_pair(mate, one), "never unless each thinks well of the other: one willing is not enough")
	one.meet(Cryptlin.State.PAIR, mate)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  the willing one cannot start it")
	mate.meet(Cryptlin.State.PAIR, one)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  and the other does not")
	main.pass_time(3600.0)
	check(one.me.expecting.is_empty() and mate.me.expecting.is_empty(), "  nor while nobody is looking")
	# Never close kin: a parent and its young, or two with a parent in common
	_content(one, mate)
	mate.me.parents = [one.me.id, 9001]
	check(main.kin(one.me, mate.me) and not main.would_pair(one, mate) and not main.would_pair(mate, one), "never a parent with its own young")
	one.meet(Cryptlin.State.PAIR, mate)
	mate.meet(Cryptlin.State.PAIR, one)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  whichever goes to which")
	mate.me.parents = [9001, 9002]
	one.me.parents = [9003, 9001]
	check(main.kin(one.me, mate.me) and not main.would_pair(one, mate), "nor two with a parent in common")
	one.meet(Cryptlin.State.PAIR, mate)
	check(one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, "  who do not")
	main.pass_time(3600.0)
	check(one.me.expecting.is_empty() and mate.me.expecting.is_empty(), "  nor while nobody is looking")
	mate.me.parents = []
	one.me.parents = []
	# Nor one that is hungry or poorly
	_content(one, mate)
	mate.belly = 30.0
	check(not main.would_pair(one, mate), "nor when one of them is hungry")
	_content(one, mate)
	one.health = 50.0
	check(not main.would_pair(one, mate), "nor when one of them is poorly")
	# A pair that would: out in the open, and mortified to be caught at it
	_content(one, mate)
	one.meet(Cryptlin.State.PAIR, mate)
	check(one.state == Cryptlin.State.PAIR and mate.state == Cryptlin.State.PAIR and mate.waiting and not one.waiting, "a pair that would: one goes over to the other")
	# (how far up it gets goes by how tall the other is, and some are very low)
	check(await _until(func() -> bool: return one.step == 1 and mate.step == 1 and one.lift > 0.02, 900) and one.feeling == Cryptlin.Feeling.LOVING, "and clambers up on it, all hearts")
	await _tap(_screen(mate.body_centre()))
	check(one.state == Cryptlin.State.PAIR and one.step == 2 and mate.step == 2 and one.feeling == Cryptlin.Feeling.SCARED and mate.feeling == Cryptlin.Feeling.SCARED and one.lift == 0.0, "a tap and they both stop dead, mortified")
	check(await _until(func() -> bool: return one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, 400) and one.me.expecting.is_empty() and mate.me.expecting.is_empty() and one.me.paired == 0.0, "and nothing comes of it")
	for way in 3:
		_content(one, mate)
		await _frames(2)
		one.meet(Cryptlin.State.PAIR, mate)
		await _until(func() -> bool: return one.step == 1, 900)
		await _frames(20)
		match way:
			0: main.call_all(Vector3(0, 0, 1.2))
			1: main.set_lamp(Den.Lamp.LOW if main.lamp_mode != Den.Lamp.LOW else Den.Lamp.BRIGHT)
			2: main.start_scan(mate.me)
		check(one.step == 2 and mate.step == 2 and one.state == Cryptlin.State.PAIR, "%s stops them too" % ["calling them", "changing the lamp", "the scanner"][way])
		main.stop_scan()
		await _until(func() -> bool: return _settled(one) and _settled(mate), 900)
	# Left to it, an egg is on the way, and is laid in the nest some hours later
	_content(one, mate)
	await _frames(2)
	one.meet(Cryptlin.State.PAIR, mate)
	check(await _until(func() -> bool: return one.state != Cryptlin.State.PAIR and mate.state != Cryptlin.State.PAIR, 1500), "left to it, they are soon done")
	var layer := one if not one.me.expecting.is_empty() else mate
	check(one.me.expecting.is_empty() != mate.me.expecting.is_empty() and one.me.paired > 0.0 and mate.me.paired > 0.0, "and one of them has an egg on the way")
	check(is_equal_approx(float(layer.me.expecting["due"]) - layer.me.paired, Den.EGG_HOURS * 3600.0) and main.residents.size() == 2, "due in %d hours, and not before" % int(Den.EGG_HOURS))
	check(not main.would_pair(one, mate), "they do not pair again for days")
	await _restart()
	one = main.residents[0].pet
	mate = main.residents[1].pet
	layer = one if not one.me.expecting.is_empty() else mate
	check(not layer.me.expecting.is_empty() and main.residents.size() == 2, "the egg on the way is kept in the save")
	# (the clock is put back for the test by moving what the save holds: the egg is due by the
	# clock on the wall, so that is moved too)
	layer.me.expecting["due"] = float(layer.me.expecting["due"]) - Den.EGG_HOURS * 3600.0 - 60.0
	await _come_back_after(Den.EGG_HOURS * 3600.0 + 60.0)
	one = main.residents[0].pet
	mate = main.residents[1].pet
	check(main.residents.size() == 3 and main.residents[2].egg != null and one.me.expecting.is_empty() and mate.me.expecting.is_empty(), "when the hours have gone by there is an egg")
	var young := main.residents[2]
	check(young.egg.position.distance_to(main.nest_pos) < 0.4, "in the nest")
	check(young.kind in [one.kind, mate.kind] and young.parents == [one.me.id, mate.me.id] and young.id != one.me.id and young.id != mate.me.id, "of the kind of one of its parents, with both of them written down")
	main.chosen = young
	main.notebook.open()
	check(main.notebook.said().contains(one.me.name) and main.notebook.said().contains(mate.me.name), "and named on its page in the notebook")
	main.notebook.close()
	# One asleep by an egg keeps it warm
	var brooded := young.egg.warmth
	main.set_lamp(Den.Lamp.OFF)
	one.position = main.nest_pos + Vector3(0.3, 0, 0)
	one._enter(Cryptlin.State.SLEEP)
	await _frames(120)
	check(young.egg.warmth > brooded + 1.0, "one asleep beside the egg broods it, lamp or no lamp")
	main.set_lamp(Den.Lamp.BRIGHT)
	young.egg.warmth = 100.0
	check(await _until(func() -> bool: return young.pet != null, 400), "it hatches")
	var child := young.pet
	check(child.kind in [one.kind, mate.kind] and child.is_baby(), "into a baby of a parent's kind (%s)" % child.kind_name())
	check(child.fur_colour.to_html(false) in [one.fur_colour.to_html(false), mate.fur_colour.to_html(false)], "in the coat of one of them")
	check(child.nature in [one.nature, mate.nature] and child.nature != child.nature2, "with a nature from one of them (%s)" % child.nature_name())
	var coated := one if child.fur_colour.to_html(false) == one.fur_colour.to_html(false) else mate
	var other := mate if coated == one else one
	# (but for any its own kind's coat does not take: see Cryptlin.SHAPES)
	check(child.marks == coated.marks or Cryptlin.SHAPES[child.kind].has("marks"), "the markings that go with that coat")
	check(is_equal_approx(float(child.shape["head"]), float(other.shape["head"])), "and the head of the other, for its kind")
	check(main.notebook._notes(child).contains("Its parents are %s and %s" % [one.me.name, mate.me.name]), "and its page records its parents")
	# Grown, it is still their young, and the room has its limit
	child.set_needs({"belly": 90.0, "energy": 90.0, "health": 100.0, "age": Cryptlin.GROW_AGE})
	child.fav_ground = main.floor_style
	child.fav_lamp = main.lamp_mode
	child.hate_decor = Decor.Kind.DISH
	child.comfort = 90.0
	_content(one, mate)
	main.warm(child, one, 95.0 - main.regard(child, one))
	main.warm(one, child, 95.0 - main.regard(one, child))
	check(not child.is_baby() and main.regard(one, child) >= Den.PAIR_REGARD and not main.would_pair(one, child) and not main.would_pair(child, mate), "grown up and fond of them, it is still their young: never")
	child.meet(Cryptlin.State.PAIR, one)
	check(child.state != Cryptlin.State.PAIR and one.state != Cryptlin.State.PAIR, "  whoever starts it")
	# With nobody looking, a happy pair gets round to it in a day or so; a full room has no egg
	main.new_egg()
	check(main.residents.size() == Den.MAX_RESIDENTS, "the room is full")
	one.me.paired = 0.0
	mate.me.paired = 0.0
	for day in 6:
		if one.me.paired > 0.0:
			break
		_content(one, mate)
		main.pass_time(24.0 * 3600.0)
	# (if the egg is still on the way, its time comes)
	for r in main.residents:
		if not r.expecting.is_empty():
			r.expecting["due"] = 0.0
	main._lay_due()
	check(one.me.expecting.is_empty() and mate.me.expecting.is_empty() and one.me.paired > 0.0 and main.residents.size() == Den.MAX_RESIDENTS, "with nobody looking a happy pair gets round to it, but a full room gets no egg")
	check(child.me.paired == 0.0 and child.me.expecting.is_empty(), "and their young had no part in it")
	await _restart()
	check(main.residents[2].parents.size() == 2 and main.residents[2].fur != "" and main.residents[2].nature >= 0 and main.residents[0].paired > 0.0, "parentage and what was inherited are kept in the save")

	# A save from when there was only ever one
	main.queue_free()
	await _frames(3)
	var old := FileAccess.open(save, FileAccess.WRITE)
	old.store_string(JSON.stringify({"v": 2, "name": "Old", "kind": Cryptlin.KINDS[kind]["title"], "seed": 7, "hatched": true, "born": Time.get_unix_time_from_system() - 5000.0, "needs": {"belly": 52.0, "fun": 50.0, "energy": 90.0, "love": 30.0, "age": 5000.0}, "known": {"toy": true}, "floor": 2, "time": Time.get_unix_time_from_system()}))
	old.close()
	main = _start()
	await _frames(5)
	check(main.residents.size() == 1 and main.who().name == "Old" and main.who().pet != null and main.who().pet.kind == kind and main.who().look_seed == 7, "a save from when there was only one loads as a room with that one in it")
	check(absf(main.who().pet.belly - 52.0) < 1.0 and main.who().known.get("toy", false) and main.who().pet.is_baby() and main.floor_style == 2, "as it was")
	main.play_ball(Ball.Kind.BALL)
	check(main.toybox.is_empty() and main.scuffs.is_empty() and main.broken.is_empty() and main.ball != null and main.ball.wear == 0.0 and main.ball.stage() == 0, "a save from before toys wore out loads with none out, and the one that comes out is as good as new")
	main._clear_toys()
	await _restart()
	check(main.residents.size() == 1 and main.who().name == "Old" and main.who().id > 0, "and is saved again as one of a list")
	main.queue_free()
	await _frames(3)
	old = FileAccess.open(save, FileAccess.WRITE)
	old.store_string(JSON.stringify({"v": 2, "name": "", "kind": Cryptlin.KINDS[kind]["title"], "seed": 7, "hatched": false, "warmth": 40.0, "needs": {}, "known": {}, "time": Time.get_unix_time_from_system()}))
	old.close()
	main = _start()
	await _frames(5)
	check(main.residents.size() == 1 and main.who().egg != null and main.who().kind == kind and main.who().egg.warmth > 39.0, "an old save of an egg loads as that egg")

	# Inside a host page eggs are stock, and a room is never given one for nothing: it stands
	# empty until the keeper lays one of their own, which the wheel holds out to them
	main.dev_show(kind)
	await _frames(10)
	main.embedded = true
	main.stock = {}
	main._sync()
	check(not main.shelf.ids.has("egg"), "inside a host page, there are no eggs on the wheel until one is given")
	main.use("egg")
	check(main.residents.size() == 1, "and none to lay")
	main.ask_let_go(main.who())
	main._answer(true)
	check(await _until(func() -> bool: return main.residents.is_empty(), 1200), "the last one let go leaves the room empty")
	await _frames(120)
	main.use("egg")
	main.notebook.open()
	main.notebook.close()
	check(main.residents.is_empty() and main.who() == null and main.shelf.beckon == "", "and empty it stays, with no egg in stock")
	main.stock = {"egg": 1}
	main._sync()
	var middle := root.get_final_transform() * (main.shelf.global_position + Vector2(main.shelf.size.x * 0.5, 0))
	check(main.shelf.ids.has("egg") and main.shelf.counts.get("egg") == 1 and main.shelf.beckon == "egg" and absf(_on_shelf("egg").x - middle.x) < 4.0, "an egg in stock is at the middle of the wheel, asking to be picked")
	await _tap(_on_shelf("egg"))
	check(main.residents.size() == 1 and main.who().egg != null and main.left_of("egg") == 0 and not main.shelf.ids.has("egg") and main.shelf.beckon == "", "a tap lays it, and the stock goes to none")
	main.use("egg")
	check(main.residents.size() == 1, "after which there are no more")
	main.queue_free()
	await _frames(3)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save))
	main = load("res://main.tscn").instantiate()
	main.save_path = save
	main.ask_names = false
	main.embedded = true
	root.add_child(main)
	await _frames(30)
	check(main.residents.is_empty(), "a new game inside a host page starts with an empty room")
	main.embedded = false
	main._sync()

	# The test panel: five taps in the corner open it, and it can put any kind in the room
	var corner_tap := root.get_final_transform() * Vector2(40, 40)
	for i in 5:
		await _tap(corner_tap)
	check(main.dev.visible, "five taps in the corner open the test panel")
	for k in Cryptlin.KINDS.size():
		main.dev_show(k)
		await _frames(20)
		check(main.who().pet != null and main.who().pet.kind == k and main.who().egg == null and not main.who().pet.is_baby(), "the panel shows a %s" % main.who().pet.kind_name())
		main.start_scan()
		await _frames(3)
		check(main.who().pet.xrayed and main.who().pet.inside_at("brain").y > main.who().pet.inside_at("stomach").y, "  with its insides in the right order")
		main.stop_scan()
	main._dev_egg()
	await _frames(20)
	check(main.who().pet == null and main.who().egg != null, "and its egg")
	main._dev_egg()
	await _frames(170)
	check(main.who().pet != null and main.who().egg == null, "which hatches when told to")

	# Its knack, with another of them in the room to work it on
	main.dev_toggle()
	main.dev_show(kind)
	var beside := main.new_egg((kind + 5) % Cryptlin.KINDS.size())
	beside.egg.warmth = 100.0
	check(await _until(func() -> bool: return main.pets().size() == 2, 900), "one of another kind hatches beside it")
	await _until(func() -> bool: return _settled(main.residents[0].pet) and _settled(main.residents[1].pet), 600)
	await _knack(main.residents[0].pet, main.residents[1].pet)
	if kind == Cryptlin.Kind.KONGAMATO:
		await _skimmer(main.residents[0].pet)
	print("smoke: %d failure(s)" % failures)
	quit(failures)
