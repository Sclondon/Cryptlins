extends SceneTree
## Smoke test: the egg and hatching, feeding, the ball, petting, calling, the lamp, sleep, a save/load
## round trip and sending it off for a new egg.
## godot --headless --fixed-fps 60 --path . -s tests/smoke.gd [-- --kind=0..3]
## (touches are sent as window pixels, like a real finger)

const SAVE := "user://smoke_test.json"

var main: Crypt
var failures := 0
var kind := 0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--kind="):
			kind = int(arg.trim_prefix("--kind="))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	main = _start()
	_run.call_deferred()


func _start() -> Crypt:
	var m: Crypt = load("res://main.tscn").instantiate()
	m.save_path = SAVE
	m.first_kind = kind
	root.add_child(m)
	return m


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


func _run() -> void:
	# The egg
	await _frames(5)
	check(main.egg != null and main.pet == null, "a new game starts with an egg (%s)" % main.egg.title())
	check(main.feed_button.disabled and main.ball_button.disabled and main.egg_button.disabled, "nothing to feed or play with yet")
	check(await _until(func() -> bool: return main.egg.landed, 300), "the egg drops into the light")
	var warm := main.egg.warmth
	await _frames(90)
	check(main.egg.warmth > warm, "the lamp warms it (%.1f)" % main.egg.warmth)
	main.toggle_lamp()
	await _frames(20)
	warm = main.egg.warmth
	await _frames(60)
	check(is_equal_approx(main.egg.warmth, warm), "but not when it is out")
	main.toggle_lamp()
	warm = main.egg.warmth
	var at := _screen(main.egg.centre())
	_touch(at, true)
	await _frames(2)
	_touch(at, false)
	await _frames(2)
	check(main.egg.warmth > warm + 2.0, "a tap warms it a little")
	main.egg.warmth = 40.0
	main.save_game()
	main.queue_free()
	await _frames(3)
	main = _start()
	await _frames(5)
	check(main.egg != null and main.pet_kind == kind and main.egg.warmth > 39.0, "a saved egg is still there, as warm")
	check(main.egg.stage == 1, "and as cracked")
	at = _screen(main.egg.centre())
	_touch(at, true)
	var most := 0
	for i in 1500:
		if main.pet != null:
			break
		most = maxi(most, main.egg.stage)
		_drag(at + Vector2(sin(i * 0.5) * 6.0, 0), Vector2(3, 0))
		await _frames(1)
	_touch(at, false)
	check(most == 2, "rubbing it cracks it further")
	check(main.pet != null and main.egg == null, "and then it hatches")
	var pet := main.pet
	await _frames(30)
	check(pet.kind == kind, "what was in the egg is a %s" % pet.kind_name())
	check(pet.legs.size() == 2 and pet.eyes.size() >= 1, "a cryptlin is built")
	check(main.pet_name != "", "it has a name (%s)" % main.pet_name)
	check(not main.feed_button.disabled and not main.egg_button.disabled, "now it can be fed")
	await _until(func() -> bool: return pet.state in Cryptlin.INTERRUPTIBLE and not pet.airborne, 600)

	# Feeding
	pet.belly = 30.0
	pet.energy = 90.0
	main.feed()
	check(main.snacks.size() == 1, "feeding drops a snack")
	check(await _until(func() -> bool: return main.snacks.is_empty(), 1500), "it finds the snack and eats it")
	check(pet.belly > 55.0, "eating fills its belly (%.0f)" % pet.belly)

	# The ball
	pet.fun = 20.0
	main.play_ball()
	check(main.ball != null, "the ball is thrown in")
	check(await _until(func() -> bool: return pet.kicks_total > 0, 1500), "it chases the ball and kicks it")
	check(pet.fun > 25.0, "playing is fun (%.0f)" % pet.fun)
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.CHASE_BALL, 2400), "it tires of the ball in the end")

	# Picking the ball up and throwing it
	await _until(func() -> bool: return main.ball.speed() < 0.3 and main.ball.position.y < 0.2, 900)
	main.ball.vel = Vector3.ZERO
	main.ball.position = Vector3(-0.8, Ball.R, 0.8)  # where a finger can get at it, not behind the buttons
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
	await _until(func() -> bool: return pet.state in Cryptlin.INTERRUPTIBLE and pet.ball_cooldown > 0.0, 2400)
	main.ball.vel = Vector3.ZERO
	main.ball.position = Vector3(3.2, Ball.R, -3.0)  # out of the way of the finger
	pet.position = Vector3(0.3, 0, 0.4)  # and the cryptlin out from behind the buttons
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
	await _until(func() -> bool: return pet.state in Cryptlin.INTERRUPTIBLE and not pet.airborne, 600)
	at = _screen(pet.body_centre())
	_touch(at, true)
	await _frames(2)
	_touch(at, false)
	await _frames(2)
	check(pet.state == Cryptlin.State.STARTLED, "a tap makes it jump")

	# Calling it over, and moving the lamp
	await _until(func() -> bool: return pet.state in Cryptlin.INTERRUPTIBLE, 600)
	var spot := Vector3(1.2, 0, 1.0) if pet.position.x < 0.0 else Vector3(-1.2, 0, 1.0)
	_touch(_screen(spot), true)
	await _frames(2)
	_touch(_screen(spot), false)
	await _frames(2)
	check(pet.state == Cryptlin.State.COME, "a tap on the floor calls it")
	check(await _until(func() -> bool: return pet.position.distance_to(spot) < 0.5, 600), "and it comes")
	var far := Vector3(-1.6, 0, 0.6) if pet.position.x > 0.0 else Vector3(1.6, 0, 0.6)
	_touch(_screen(far), true)
	await _frames(30)
	check(main.light_dragging, "a finger held on the floor takes the lamp")
	check(await _until(func() -> bool: return main.light_point.distance_to(far) < 0.4, 120), "the light follows it")
	check(await _until(func() -> bool: return pet.state == Cryptlin.State.CHASE_LIGHT, 60), "and the cryptlin chases the light")
	_touch(_screen(far), false)
	await _frames(5)
	check(not main.light_dragging, "letting go lets the lamp swing back")

	# Lamp off: bed
	pet.energy = 40.0
	main.toggle_lamp()
	check(not main.light_on, "the lamp goes out")
	check(await _until(func() -> bool: return pet.state == Cryptlin.State.SLEEP, 1800), "in the dark it goes to its nest and sleeps")
	var rested := pet.energy
	await _frames(120)
	check(pet.energy > rested, "sleep restores it")
	pet.energy = 70.0
	main.toggle_lamp()
	check(await _until(func() -> bool: return pet.state != Cryptlin.State.SLEEP, 300), "the lamp coming on wakes it")

	# Save, then a second visit
	pet.belly = 64.0
	main.save_game()
	var name := main.pet_name
	var seed_was := main.pet_seed
	main.queue_free()
	await _frames(3)
	main = _start()
	await _frames(5)
	check(main.pet_name == name and main.pet_seed == seed_was and main.pet != null and main.pet.kind == kind, "the same cryptlin is there next time")
	check(absf(main.pet.belly - 64.0) < 2.0, "as full as it was left (%.0f)" % main.pet.belly)

	# A new egg
	main.play_ball()
	main.ask_new_egg()
	check(main.ask.visible, "asking for a new egg asks first")
	main._answer(false)
	await _frames(5)
	check(not main.ask.visible and main.pet != null and not main.leaving, "saying no keeps it")
	main.ask_new_egg()
	main._answer(true)
	check(main.leaving and main.pet.state == Cryptlin.State.LEAVE, "saying yes sends it off")
	check(await _until(func() -> bool: return main.egg != null, 1200), "and a new egg comes")
	check(main.pet == null and main.ball == null and main.pet_kind != kind, "holding a different kind (%s)" % main.egg.title())

	print("smoke: %d failure(s)" % failures)
	quit(failures)
