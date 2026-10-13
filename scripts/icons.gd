class_name Icons
extends RefCounted
## The symbols on the buttons and beside the bars, drawn with shapes so the game needs no image
## files. paint() draws one, centred on a point, to fit a circle of the given radius.

const BONE := Color(0.93, 0.9, 0.8)
const AMBER := Color(1.0, 0.76, 0.28)
const MOSS := Color(0.07, 0.1, 0.08)
const DARK := Color(0.05, 0.05, 0.06)


static func paint(ci: CanvasItem, symbol: String, c: Vector2, r: float, tint := Color.WHITE) -> void:
	var bone := BONE * tint
	var amber := AMBER * tint
	var dark := DARK * tint
	var w := maxf(r * 0.16, 2.0)
	match symbol:
		"bone":
			var along := Vector2(0.7, -0.7)
			var across := Vector2(0.7, 0.7)
			ci.draw_line(c - along * r * 0.75, c + along * r * 0.75, bone, r * 0.3)
			for end: float in [-1.0, 1.0]:
				for side: float in [-1.0, 1.0]:
					ci.draw_circle(c + (along * 0.85 * end + across * 0.24 * side) * r, r * 0.26, bone)
		"toadstool":
			oval(ci, c + Vector2(0, 0.45) * r, r * 0.22, r * 0.5, bone)
			var cap := PackedVector2Array()
			for i in 13:
				var t := PI + PI * i / 12.0
				cap.append(c + Vector2(cos(t) * 0.95, sin(t) * 0.8 + 0.1) * r)
			ci.draw_colored_polygon(cap, Color(0.8, 0.2, 0.25) * tint)
			for dot: Vector2 in [Vector2(-0.45, -0.25), Vector2(0.1, -0.45), Vector2(0.5, -0.15)]:
				ci.draw_circle(c + dot * r, r * 0.13, bone)
		"candy":
			var tip := c + Vector2(0, -0.95) * r
			var bands: Array[Color] = [Color(0.97, 0.95, 0.9), Color(1.0, 0.55, 0.1), Color(1.0, 0.85, 0.2)]
			for i in 3:
				var top := i / 3.0
				var bottom := (i + 1) / 3.0
				ci.draw_colored_polygon(PackedVector2Array([
					tip + Vector2(-0.7 * top, 1.85 * top) * r, tip + Vector2(0.7 * top, 1.85 * top) * r,
					tip + Vector2(0.7 * bottom, 1.85 * bottom) * r, tip + Vector2(-0.7 * bottom, 1.85 * bottom) * r,
				]) if i > 0 else PackedVector2Array([tip, tip + Vector2(0.7 * bottom, 1.85 * bottom) * r, tip + Vector2(-0.7 * bottom, 1.85 * bottom) * r]), bands[i] * tint)
		"fish":
			oval(ci, c + Vector2(0.15, 0) * r, r * 0.75, r * 0.42, Color(0.5, 0.68, 0.8) * tint)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.45, 0) * r, c + Vector2(-1.0, -0.45) * r, c + Vector2(-1.0, 0.45) * r]), Color(0.36, 0.5, 0.62) * tint)
			ci.draw_circle(c + Vector2(0.55, -0.1) * r, r * 0.09, dark)
		"beetle":
			for i in 3:
				var y := (i - 1) * 0.42
				ci.draw_line(c + Vector2(-0.95, y + 0.15) * r, c + Vector2(0.95, y + 0.15) * r, dark.lerp(bone, 0.35), w * 0.7)
			oval(ci, c + Vector2(0, 0.12) * r, r * 0.55, r * 0.72, Color(0.16, 0.46, 0.34) * tint)
			ci.draw_circle(c + Vector2(0, -0.68) * r, r * 0.26, dark.lerp(bone, 0.2))
			ci.draw_line(c + Vector2(0, -0.4) * r, c + Vector2(0, 0.8) * r, dark, w * 0.6)
		"berries":
			for berry: Vector2 in [Vector2(-0.4, 0.35), Vector2(0.4, 0.35), Vector2(0, -0.2)]:
				ci.draw_circle(c + berry * r, r * 0.42, Color(0.6, 0.14, 0.42) * tint)
				ci.draw_circle(c + (berry + Vector2(-0.12, -0.12)) * r, r * 0.1, Color(0.85, 0.5, 0.7) * tint)
			oval(ci, c + Vector2(0.35, -0.72) * r, r * 0.34, r * 0.14, Color(0.3, 0.6, 0.25) * tint)
		"ball":
			ci.draw_circle(c, r * 0.9, Color(0.95, 0.5, 0.12) * tint)
			oval(ci, c, r * 0.32, r * 0.9, Color(0.42, 0.2, 0.58) * tint)
			ci.draw_arc(c, r * 0.9, 0, TAU, 24, bone, w * 0.6)
		"stone":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-0.9, 0.3) * r, c + Vector2(-0.6, -0.5) * r, c + Vector2(0.1, -0.8) * r, c + Vector2(0.8, -0.35) * r,
				c + Vector2(0.95, 0.35) * r, c + Vector2(0.3, 0.75) * r, c + Vector2(-0.5, 0.7) * r,
			]), Color(0.5, 0.5, 0.54) * tint)
			ci.draw_line(c + Vector2(-0.3, -0.2) * r, c + Vector2(0.2, 0.1) * r, Color(0.3, 0.3, 0.34) * tint, w * 0.6)
		"bell":
			ci.draw_arc(c + Vector2(0, -0.85) * r, r * 0.18, 0, TAU, 12, amber, w * 0.6)
			ci.draw_circle(c + Vector2(0, 0.08) * r, r * 0.78, Color(0.8, 0.6, 0.2) * tint)
			ci.draw_line(c + Vector2(-0.5, 0.25) * r, c + Vector2(0.5, 0.25) * r, dark, w * 0.8)
			ci.draw_circle(c + Vector2(0, 0.25) * r, r * 0.14, dark)
		"glow":
			ci.draw_circle(c, r * 0.95, Color(0.5, 1.0, 0.65, 0.22) * tint)
			ci.draw_circle(c, r * 0.6, Color(0.6, 1.0, 0.7) * tint)
			ci.draw_circle(c + Vector2(-0.18, -0.18) * r, r * 0.18, Color(0.92, 1.0, 0.9) * tint)
		"lamp_on", "lamp_off":
			var lit := symbol == "lamp_on"
			if lit:
				for i in 5:
					var t := PI * 0.15 + PI * 0.7 * i / 4.0
					ci.draw_line(c + Vector2(cos(t), sin(t)) * r * 0.55 + Vector2(0, 0.05) * r, c + Vector2(cos(t), sin(t)) * r * 1.0 + Vector2(0, 0.05) * r, amber, w * 0.7)
				ci.draw_circle(c + Vector2(0, 0.08) * r, r * 0.3, amber)
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-0.3, -0.85) * r, c + Vector2(0.3, -0.85) * r, c + Vector2(0.75, 0.0) * r, c + Vector2(-0.75, 0.0) * r,
			]), bone if lit else bone.darkened(0.45))
			ci.draw_line(c + Vector2(0, -1.0) * r, c + Vector2(0, -0.85) * r, bone, w)
			if not lit:
				ci.draw_arc(c + Vector2(0, 0.08) * r, r * 0.26, 0, PI, 10, bone.darkened(0.45), w * 0.6)
		"menu":
			# A footprint
			oval(ci, c + Vector2(0, 0.3) * r, r * 0.5, r * 0.68, bone)
			var toes: Array[Vector2] = [Vector2(-0.62, -0.42), Vector2(-0.32, -0.72), Vector2(0.05, -0.82), Vector2(0.4, -0.7), Vector2(0.68, -0.4)]
			for i in toes.size():
				ci.draw_circle(c + toes[i] * r, r * (0.2 - i * 0.012), bone)
		"help":
			var font := ThemeDB.fallback_font
			var size := int(r * 2.0)
			ci.draw_string(font, c + Vector2(-r, r * 0.7), "?", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, size, bone)
		"sound_on", "sound_off":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-0.9, -0.28) * r, c + Vector2(-0.5, -0.28) * r, c + Vector2(0.0, -0.75) * r,
				c + Vector2(0.0, 0.75) * r, c + Vector2(-0.5, 0.28) * r, c + Vector2(-0.9, 0.28) * r,
			]), bone)
			if symbol == "sound_on":
				ci.draw_arc(c, r * 0.5, -0.8, 0.8, 8, bone, w * 0.7)
				ci.draw_arc(c, r * 0.9, -0.8, 0.8, 10, bone, w * 0.7)
			else:
				ci.draw_line(c + Vector2(0.3, -0.35) * r, c + Vector2(0.95, 0.35) * r, amber, w)
				ci.draw_line(c + Vector2(0.95, -0.35) * r, c + Vector2(0.3, 0.35) * r, amber, w)
		"egg":
			oval(ci, c + Vector2(0, 0.08) * r, r * 0.66, r * 0.9, bone)
			ci.draw_polyline(PackedVector2Array([
				c + Vector2(-0.62, 0.0) * r, c + Vector2(-0.3, 0.25) * r, c + Vector2(-0.05, -0.05) * r,
				c + Vector2(0.25, 0.25) * r, c + Vector2(0.62, 0.0) * r,
			]), dark, w * 0.7)
		"heart":
			heart(ci, c, r, Color(1.0, 0.45, 0.6) * tint)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-0.7, 0.05) * r, c + Vector2(-0.2, 0.6) * r, c + Vector2(0.8, -0.6) * r]), bone, w * 1.3)
		"cross":
			ci.draw_line(c + Vector2(-0.65, -0.65) * r, c + Vector2(0.65, 0.65) * r, amber, w * 1.2)
			ci.draw_line(c + Vector2(0.65, -0.65) * r, c + Vector2(-0.65, 0.65) * r, amber, w * 1.2)
		"left", "right":
			var way := -1.0 if symbol == "left" else 1.0
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0.7 * way, 0) * r, c + Vector2(-0.5 * way, -0.75) * r, c + Vector2(-0.5 * way, 0.75) * r]), bone)
		"dice":
			ci.draw_rect(Rect2(c - Vector2(0.8, 0.8) * r, Vector2(1.6, 1.6) * r), bone)
			for pip: Vector2 in [Vector2(-0.42, -0.42), Vector2(0.42, 0.42), Vector2(0, 0), Vector2(-0.42, 0.42), Vector2(0.42, -0.42)]:
				ci.draw_circle(c + pip * r, r * 0.15, dark)
		"ticket":
			# A railway ticket: a card with a bite out of each end and a line where it tears
			ci.draw_rect(Rect2(c + Vector2(-0.95, -0.55) * r, Vector2(1.9, 1.1) * r), amber)
			for end: float in [-1.0, 1.0]:
				ci.draw_circle(c + Vector2(0.95 * end, 0) * r, r * 0.2, Icons.MOSS * tint)
			for i in 4:
				ci.draw_rect(Rect2(c + Vector2(0.3, -0.45 + i * 0.26) * r, Vector2(0.09, 0.13) * r), dark)
			ci.draw_rect(Rect2(c + Vector2(-0.65, -0.28) * r, Vector2(0.7, 0.16) * r), dark)
			ci.draw_rect(Rect2(c + Vector2(-0.65, 0.08) * r, Vector2(0.45, 0.14) * r), dark)
		"pencil":
			ci.draw_line(c + Vector2(-0.55, 0.55) * r, c + Vector2(0.65, -0.65) * r, amber, r * 0.34)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.95, 0.95) * r, c + Vector2(-0.72, 0.42) * r, c + Vector2(-0.42, 0.72) * r]), bone)
		"moon":
			var shape := PackedVector2Array()
			for i in 13:
				var t := -PI * 0.5 + PI * i / 12.0
				shape.append(c + Vector2(cos(t) * 0.9 - 0.2, sin(t) * 0.9) * r)
			for i in 13:
				var t := PI * 0.5 - PI * i / 12.0
				shape.append(c + Vector2(cos(t) * 0.45 - 0.2, sin(t) * 0.9) * r)
			ci.draw_colored_polygon(shape, bone)


static func oval(ci: CanvasItem, c: Vector2, rx: float, ry: float, colour: Color) -> void:
	var shape := PackedVector2Array()
	for i in 20:
		var t := TAU * i / 20.0
		shape.append(c + Vector2(cos(t) * rx, sin(t) * ry))
	ci.draw_colored_polygon(shape, colour)


static func heart(ci: CanvasItem, c: Vector2, r: float, colour: Color) -> void:
	ci.draw_circle(c + Vector2(-0.42, -0.25) * r, r * 0.48, colour)
	ci.draw_circle(c + Vector2(0.42, -0.25) * r, r * 0.48, colour)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-0.86, -0.02) * r, c + Vector2(0.86, -0.02) * r, c + Vector2(0, 0.95) * r]), colour)
