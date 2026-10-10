class_name Sfx
extends Node
## Every sound is synthesised at start-up (no audio files): little voiced chirps for the cryptlin
## and a few thumps and clicks for its things.

const RATE := 22050

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var purr_player: AudioStreamPlayer
var next := 0
var muted := false:
	set(value):
		muted = value
		AudioServer.set_bus_mute(0, muted)


func _ready() -> void:
	sounds["chirp"] = _voice(0.13, PackedFloat32Array([760.0, 1250.0]), 0.5)
	sounds["coo"] = _voice(0.32, PackedFloat32Array([520.0, 840.0, 640.0]), 0.5, 0.03)
	sounds["squeak"] = _voice(0.1, PackedFloat32Array([1150.0, 1900.0]), 0.45)
	sounds["whimper"] = _voice(0.42, PackedFloat32Array([720.0, 610.0, 430.0]), 0.4, 0.05)
	sounds["yawn"] = _voice(0.7, PackedFloat32Array([420.0, 640.0, 330.0]), 0.4, 0.02)
	sounds["grumble"] = _voice(0.3, PackedFloat32Array([210.0, 170.0, 190.0]), 0.5, 0.06, 0.15)
	sounds["chomp"] = _voice(0.09, PackedFloat32Array([230.0, 110.0]), 0.7, 0.0, 0.7)
	sounds["thud"] = _voice(0.11, PackedFloat32Array([120.0, 55.0]), 0.8, 0.0, 0.45)
	sounds["boing"] = _voice(0.15, PackedFloat32Array([340.0, 180.0]), 0.6)
	sounds["snore"] = _voice(0.9, PackedFloat32Array([75.0, 95.0, 70.0]), 0.3, 0.0, 0.35)
	sounds["click"] = _voice(0.035, PackedFloat32Array([1700.0, 700.0]), 0.45, 0.0, 0.5)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	purr_player = AudioStreamPlayer.new()
	purr_player.stream = _purr()
	purr_player.volume_db = -9.0
	add_child(purr_player)


func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	var p := players[next]
	next = (next + 1) % players.size()
	p.stream = sounds[sound]
	p.pitch_scale = pitch * randf_range(0.94, 1.06)
	p.volume_db = volume_db
	p.play()


func purr(on: bool) -> void:
	if on and not purr_player.playing:
		purr_player.play()
	elif not on and purr_player.playing:
		purr_player.stop()


# A short voiced sweep through `freqs`, with optional vibrato (a fraction of the pitch) and breath noise
func _voice(dur: float, freqs: PackedFloat32Array, vol: float, vibrato := 0.0, noise := 0.0) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	var last := freqs.size() - 1
	for i in n:
		var u := float(i) / n
		var at := u * last
		var k := mini(int(at), last)
		var f := lerpf(freqs[k], freqs[mini(k + 1, last)], at - k)
		f *= 1.0 + sin(u * dur * TAU * 11.0) * vibrato
		phase += TAU * f / RATE
		var s := sin(phase) + 0.35 * sin(phase * 2.0) + 0.15 * sin(phase * 3.0)
		if noise > 0.0:
			s = lerpf(s, randf_range(-1.0, 1.0), noise)
		var env := minf(u / 0.08, 1.0) * minf((1.0 - u) / 0.3, 1.0)
		data.encode_s16(i * 2, int(clampf(s * env * vol * 0.6, -1.0, 1.0) * 32767.0))
	return _wav(data)


# One second that loops cleanly: a low hum pulsing 24 times a second
func _purr() -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(RATE * 2)
	for i in RATE:
		var t := float(i) / RATE
		var pulse := pow(0.5 + 0.5 * sin(TAU * 24.0 * t), 2.0)
		var s := (sin(TAU * 96.0 * t) + 0.4 * sin(TAU * 192.0 * t)) * pulse
		data.encode_s16(i * 2, int(s * 0.4 * 32767.0))
	var wav := _wav(data)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = RATE
	return wav


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
