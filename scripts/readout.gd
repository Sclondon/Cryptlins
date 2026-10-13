class_name Readout
extends RefCounted
## The scanner's own lettering: a face of five dots by seven, capitals and figures only, painted
## as square dots so that it reads as an instrument's readout. There are no font files in the
## project; this is all of it.

# Each letter's seven rows from the top, five dots to a row
const GLYPHS := {
	"A": "01110 10001 10001 11111 10001 10001 10001", "B": "11110 10001 10001 11110 10001 10001 11110",
	"C": "01110 10001 10000 10000 10000 10001 01110", "D": "11110 10001 10001 10001 10001 10001 11110",
	"E": "11111 10000 10000 11110 10000 10000 11111", "F": "11111 10000 10000 11110 10000 10000 10000",
	"G": "01110 10001 10000 10111 10001 10001 01111", "H": "10001 10001 10001 11111 10001 10001 10001",
	"I": "01110 00100 00100 00100 00100 00100 01110", "J": "00111 00010 00010 00010 00010 10010 01100",
	"K": "10001 10010 10100 11000 10100 10010 10001", "L": "10000 10000 10000 10000 10000 10000 11111",
	"M": "10001 11011 10101 10101 10001 10001 10001", "N": "10001 11001 10101 10011 10001 10001 10001",
	"O": "01110 10001 10001 10001 10001 10001 01110", "P": "11110 10001 10001 11110 10000 10000 10000",
	"Q": "01110 10001 10001 10001 10101 10010 01101", "R": "11110 10001 10001 11110 10100 10010 10001",
	"S": "01111 10000 10000 01110 00001 00001 11110", "T": "11111 00100 00100 00100 00100 00100 00100",
	"U": "10001 10001 10001 10001 10001 10001 01110", "V": "10001 10001 10001 10001 10001 01010 00100",
	"W": "10001 10001 10001 10101 10101 11011 10001", "X": "10001 10001 01010 00100 01010 10001 10001",
	"Y": "10001 10001 01010 00100 00100 00100 00100", "Z": "11111 00001 00010 00100 01000 10000 11111",
	"0": "01110 10001 10011 10101 11001 10001 01110", "1": "00100 01100 00100 00100 00100 00100 01110",
	"2": "01110 10001 00001 00010 00100 01000 11111", "3": "11110 00001 00001 01110 00001 00001 11110",
	"4": "00010 00110 01010 10010 11111 00010 00010", "5": "11111 10000 11110 00001 00001 10001 01110",
	"6": "00110 01000 10000 11110 10001 10001 01110", "7": "11111 00001 00010 00100 01000 01000 01000",
	"8": "01110 10001 10001 01110 10001 10001 01110", "9": "01110 10001 10001 01111 00001 00010 01100",
	"-": "00000 00000 00000 11111 00000 00000 00000", ".": "00000 00000 00000 00000 00000 01100 01100",
}
# How many dots from the start of one letter to the start of the next, and how many a line is tall
const ADVANCE := 6
const TALL := 7


# How wide a line of it is, with dots `dot` across
static func width(text: String, dot: float) -> float:
	return maxf(text.length() * ADVANCE - 1, 0) * dot


# Paints a line of it with its top left corner at `at`, each dot `dot` across (a whole number of
# pixels keeps it crisp): first dark behind every dot, then the dots
static func paint(ci: CanvasItem, at: Vector2, text: String, dot: float, colour: Color) -> void:
	for layer in 2:
		var x := at.x
		for letter in text.to_upper():
			var rows: String = GLYPHS.get(letter, "")
			for i in rows.length():
				if rows[i] == "1":
					var square := Rect2(x + (i % 6) * dot, at.y + (i / 6) * dot, dot, dot)
					if layer == 0:
						ci.draw_rect(square.grow(dot * 0.75), Color(0, 0, 0, 0.85))
					else:
						ci.draw_rect(square, colour)
			x += ADVANCE * dot
