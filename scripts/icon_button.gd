class_name IconButton
extends Button
## A button with a drawn symbol on it instead of words (see Icons), an optional small caption
## underneath, and an optional mark in the corner.

var symbol := "":
	set(value):
		symbol = value
		queue_redraw()
var caption := "":
	set(value):
		caption = value
		queue_redraw()
var mark := "":
	set(value):
		mark = value
		queue_redraw()


func _draw() -> void:
	var tint := Color(1, 1, 1, 0.28 if disabled else 1.0)
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.3
	if caption != "":
		c.y -= size.y * 0.1
		r = minf(size.x, size.y) * 0.25
		var font_size := 17
		draw_string(get_theme_default_font(), Vector2(0, size.y - 11), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Icons.BONE * Color(1, 1, 1, 0.85) * tint)
	Icons.paint(self, symbol, c, r, tint)
	if mark != "":
		Icons.paint(self, mark, Vector2(size.x - 22, 22), 11, tint)
