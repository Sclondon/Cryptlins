extends Control
## The cryptlin's name and how it is doing, drawn small in a corner. Before it hatches: how warm the egg is.

# Belly, fun, rest and bond
const ROWS: Array[String] = ["bone", "ball", "moon", "heart"]

var pet: Cryptlin
var egg: Egg
var title := ""


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	if pet == null and egg == null:
		return
	draw_string(font, Vector2(0, 22), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Icons.AMBER)
	if pet == null:
		_bar(font, 0, "Warm", egg.warmth / 100.0, Color(0.5, 0.6, 0.9).lerp(Color(1.0, 0.6, 0.2), egg.warmth / 100.0))
		return
	var small := Color(0.8, 0.78, 0.72, 0.8)
	draw_string(font, Vector2(0, 42), "%s %s%s" % [pet.nature_name(), "baby " if pet.is_baby() else "", pet.kind_name()], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, small)
	draw_string(font, Vector2(0, 61), "feeling %s" % pet.feeling_name(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.95, 0.8, 0.45, 0.9))
	var values: Array[float] = [pet.belly, pet.fun, pet.energy, pet.love]
	for i in ROWS.size():
		var v := values[i] / 100.0
		_bar(font, i, ROWS[i], v, Color(0.95, 0.4, 0.55) if i == 3 else Color(0.9, 0.3, 0.2).lerp(Color(0.55, 0.85, 0.4), smoothstep(0.15, 0.6, v)))
func _bar(font: Font, row: int, label: String, v: float, c: Color) -> void:
	var y := (74.0 if pet != null else 40.0) + row * 24.0
	if label in ROWS:
		Icons.paint(self, label, Vector2(10, y + 6), 9.0)
	else:
		draw_string(font, Vector2(0, y + 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(Icons.BONE, 0.7))
	var left := 28.0 if label in ROWS else 52.0
	draw_rect(Rect2(left, y, 182.0 - left, 12), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(left, y, (182.0 - left) * clampf(v, 0.0, 1.0), 12), Color(c, 0.85))
	draw_rect(Rect2(left, y, 182.0 - left, 12), Color(Icons.BONE, 0.25), false, 1.0)
