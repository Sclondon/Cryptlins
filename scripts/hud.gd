extends Control
## The cryptlin's name and how it is doing, drawn small in a corner. Before it hatches: how warm the egg is.

const ROWS: Array[String] = ["Belly", "Fun", "Rest", "Bond"]

var pet: Cryptlin
var egg: Egg
var title := ""


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	if pet == null and egg == null:
		return
	draw_string(font, Vector2(0, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.93, 0.9, 0.8, 0.9))
	if pet == null:
		_bar(font, 0, "Warm", egg.warmth / 100.0, Color(0.5, 0.6, 0.9).lerp(Color(1.0, 0.6, 0.2), egg.warmth / 100.0))
		return
	var values: Array[float] = [pet.belly, pet.fun, pet.energy, pet.love]
	for i in ROWS.size():
		var v := values[i] / 100.0
		_bar(font, i, ROWS[i], v, Color(0.95, 0.4, 0.55) if i == 3 else Color(0.9, 0.3, 0.2).lerp(Color(0.55, 0.85, 0.4), smoothstep(0.15, 0.6, v)))


func _bar(font: Font, row: int, label: String, v: float, c: Color) -> void:
	var y := 40.0 + row * 22.0
	draw_string(font, Vector2(0, y + 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.8, 0.78, 0.72, 0.7))
	draw_rect(Rect2(52, y, 130, 10), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(52, y, 130 * clampf(v, 0.0, 1.0), 10), Color(c, 0.85))
