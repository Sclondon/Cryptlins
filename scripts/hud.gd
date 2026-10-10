extends Control
## The cryptlin's name and how it is doing, drawn small in a corner.

const ROWS: Array[String] = ["Belly", "Fun", "Rest", "Bond"]

var pet: Cryptlin
var title := ""


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if pet == null:
		return
	var font := get_theme_default_font()
	draw_string(font, Vector2(0, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.93, 0.9, 0.8, 0.9))
	var values: Array[float] = [pet.belly, pet.fun, pet.energy, pet.love]
	for i in ROWS.size():
		var y := 40.0 + i * 22.0
		draw_string(font, Vector2(0, y + 12), ROWS[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.8, 0.78, 0.72, 0.7))
		draw_rect(Rect2(52, y, 130, 10), Color(1, 1, 1, 0.1))
		var v := values[i] / 100.0
		var c := Color(0.95, 0.4, 0.55) if i == 3 else Color(0.9, 0.3, 0.2).lerp(Color(0.55, 0.85, 0.4), smoothstep(0.15, 0.6, v))
		draw_rect(Rect2(52, y, 130 * v, 10), Color(c, 0.85))
