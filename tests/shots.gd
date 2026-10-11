extends SceneTree
## Screenshots of the cryptlin at its various doings.
## godot --path . -s tests/shots.gd -- --shots=<dir> [--portrait] [--seed=N] [--kind=0..3] [--egg]
## With --egg: the egg of that kind, cracking and hatching, and then the new-egg question.

const SAVE := "user://shots_test.json"

var main: Crypt
var out := "user://shots"
var portrait := false
var look := 0
var kind := 0
var egg_only := false


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			out = arg.trim_prefix("--shots=")
		if arg.begins_with("--seed="):
			look = int(arg.trim_prefix("--seed="))
		if arg.begins_with("--kind="):
			kind = int(arg.trim_prefix("--kind="))
		if arg == "--egg":
			egg_only = true
		if arg == "--portrait":
			portrait = true
	DirAccess.make_dir_recursive_absolute(out)
	DisplayServer.window_set_size(Vector2i(540, 1170) if portrait else Vector2i(1280, 720))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if not egg_only:
		var f := FileAccess.open(SAVE, FileAccess.WRITE)
		f.store_string(JSON.stringify({"name": "Seed %d" % look, "kind": kind, "seed": maxi(look, 1), "hatched": true, "needs": {}, "time": Time.get_unix_time_from_system()}))
		f.close()
	main = load("res://main.tscn").instantiate()
	main.save_path = SAVE
	main.first_kind = kind
	root.add_child(main)
	if egg_only:
		_run_egg.call_deferred()
	else:
		_run.call_deferred()


func _snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/k%d_%s%s.png" % [out, kind, name, "_p" if portrait else ""])


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _until(done: Callable, seconds: float) -> void:
	var left := seconds
	while left > 0.0 and not done.call():
		await process_frame
		left -= 1.0 / 60.0


func _run_egg() -> void:
	await _wait(0.4)
	await _snap("e0_drop")
	await _until(func() -> bool: return main.egg.landed, 4.0)
	await _wait(1.0)
	await _snap("e1_egg")
	main.egg.warmth = 33.5
	await _wait(1.2)
	await _snap("e2_crack")
	main.egg.warmth = 67.5
	await _wait(1.2)
	await _snap("e3_peek")
	main.toggle_lamp()
	await _wait(1.0)
	await _snap("e4_dark")
	main.toggle_lamp()
	main.egg.warmth = 99.9
	await _until(func() -> bool: return main.pet != null, 6.0)
	await _wait(0.12)
	await _snap("e5_hatch")
	await _wait(1.6)
	await _snap("e6_hatched")
	main.ask_new_egg()
	await _wait(0.3)
	await _snap("e7_ask")
	main._answer(true)
	await _wait(1.0)
	await _snap("e8_wave")
	quit()


func _run() -> void:
	var pet := main.pet
	pet.set_needs({"belly": 60.0, "fun": 60.0, "energy": 90.0, "love": 40.0})
	pet.position = Vector3(0.2, 0, 0.6)
	pet.yaw = 0.3
	pet._enter(Cryptlin.State.STARE)
	await _wait(1.6)
	await _snap("1_stare")
	pet.position = Vector3(-0.9, 0, 0.2)
	pet.target = Vector3(1.3, 0, 0.9)
	pet._enter(Cryptlin.State.WANDER)
	await _wait(1.0)
	await _snap("2_walk")
	pet.belly = 30.0
	main.feed()
	await _until(func() -> bool: return pet.state == Cryptlin.State.EAT, 8.0)
	await _wait(0.6)
	await _snap("3_eat")
	await _until(func() -> bool: return main.snacks.is_empty(), 4.0)
	main.play_ball()
	await _until(func() -> bool: return pet.kicks_total > 0, 10.0)
	await _wait(0.25)
	await _snap("4_ball")
	main.ball.vel = Vector3.ZERO
	pet.belly = 10.0
	pet.beg_cooldown = 0.0
	pet.ball_cooldown = 30.0
	pet._enter(Cryptlin.State.BEG)
	await _until(func() -> bool: return pet.step == 1, 6.0)
	await _wait(1.0)
	await _snap("5_beg")
	pet.belly = 80.0
	pet.stroke()
	for i in 50:
		pet.stroke()
		await process_frame
	await _snap("6_petted")
	pet._enter(Cryptlin.State.LURK)
	await _until(func() -> bool: return pet.step == 1, 9.0)
	await _wait(1.0)
	await _snap("7_lurk")
	pet.position = main.nest_pos
	pet._enter(Cryptlin.State.SLEEP)
	await _wait(2.0)
	await _snap("8_sleep")
	main.toggle_lamp()
	pet.energy = 100.0
	pet.position = Vector3(0.6, 0, 1.2)
	pet._enter(Cryptlin.State.STARE)
	await _wait(1.5)
	await _snap("9_dark")
	quit()
