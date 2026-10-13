// Where the pool lies, for the floor (which is cut away over it) and the water (which is darker
// the further out it is). `shore` is Den.Shore: 0 for no pool, 1 for one over the back of the
// room, 2 the left of it and 3 the right. The line is the one Den.wade() works to: the two have
// to be changed together.

uniform int shore = 0;

// How far out from the water's edge a place on the floor is: above zero in the water, below it
// on dry floor
float wade(vec2 at) {
	if (shore == 0) {
		return -100.0;
	}
	float along = shore == 1 ? at.x : at.y;
	float across = shore == 1 ? at.y : (shore == 2 ? at.x : -at.x);
	float edge = (shore == 1 ? 0.2 : -0.3) + sin(along * 1.3 + 0.7 + float(shore) * 1.9) * 0.2 + sin(along * 3.1 + 2.1) * 0.1 + sin(along * 6.7 + 4.0) * 0.04;
	return edge - across;
}
