extends SceneTree
## A picture of every item on the shelf, for the shop that sells them (the station's ticket
## counter): one square PNG each, named by item id, on nothing.
## godot --path . -s tests/icons.gd -- --out=<dir> [--size=96]

var out := "user://icons"
var size := 96


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		if arg.begins_with("--size="):
			size = int(arg.trim_prefix("--size="))
	DirAccess.make_dir_recursive_absolute(out)
	_run.call_deferred()


func _run() -> void:
	# The same little scene the shelf is drawn in, one thing at a time
	var view := SubViewport.new()
	view.own_world_3d = true
	view.transparent_bg = true
	view.size = Vector2i(size, size)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.85)
	env.ambient_light_energy = 0.5
	var camera := Camera3D.new()
	camera.environment = env
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.98
	view.add_child(camera)
	camera.position = Vector3(0, 1.22, 3.0)
	camera.rotation = Vector3(-0.3, 0, 0)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 1.3
	view.add_child(sun)
	sun.look_at_from_position(Vector3(-2, 4, 5), Vector3.ZERO)
	for item in Items.LIST:
		if item["id"] in Items.KEPT:
			continue
		var id: String = item["id"]
		var model := Items.model(id)
		model.rotation.y = 0.45
		view.add_child(model)
		await process_frame
		await RenderingServer.frame_post_draw
		view.get_texture().get_image().save_png("%s/%s.png" % [out, id])
		model.queue_free()
		await process_frame
	print("icons: %d written to %s" % [Items.LIST.size() - Items.KEPT.size(), out])
	quit()
