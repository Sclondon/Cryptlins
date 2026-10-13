class_name Resident
extends RefCounted
## One of those that live in the room: an egg, or the cryptlin that came out of it, and what the
## save keeps of it. Den holds a list of them, the eldest first.

# A number of its own, never used twice in one room
var id := 0
var name := ""
var kind := 0
var look_seed := 1
var hatched := false
# When it hatched (unix time)
var born := 0.0
# How warm its egg is, and where on the floor the egg lies
var warmth := 0.0
var at := Vector3.INF
# Its needs as last saved (see Cryptlin.get_needs), and what has been found out about its tastes
var needs := {}
var known := {}
# What it thinks of each of the others, 0 to 100, by their numbers (see Den.regard)
var regard := {}
# Whichever of the two it is in the room just now
var pet: Cryptlin
var egg: Egg
# Sent off into the dark, and on its way out
var leaving := false


# The thing itself in the room, egg or cryptlin
func body() -> Node3D:
	if egg != null:
		return egg
	return pet


# What the save keeps of it
func to_save() -> Dictionary:
	var spot := at if body() == null else body().position
	return {
		"id": id,
		"name": name,
		"kind": Cryptlin.KINDS[kind]["title"],
		"seed": look_seed,
		"hatched": hatched,
		"born": born,
		"warmth": egg.warmth if egg != null else 0.0,
		"needs": pet.get_needs() if pet != null else needs,
		"known": known,
		"regard": regard,
		"at": [spot.x, spot.z] if spot != Vector3.INF else [],
	}


static func from_save(d: Dictionary) -> Resident:
	var r := Resident.new()
	r.id = int(d.get("id", 0))
	r.name = str(d.get("name", ""))
	r.kind = Cryptlin.kind_of(d.get("kind", 0))
	r.look_seed = int(d.get("seed", 1))
	r.hatched = bool(d.get("hatched", true))
	r.born = float(d.get("born", 0.0))
	r.warmth = clampf(float(d.get("warmth", 0.0)), 0.0, 99.0)
	if d.get("needs") is Dictionary:
		r.needs = d["needs"]
	if d.get("known") is Dictionary:
		r.known = d["known"]
	if d.get("regard") is Dictionary:
		r.regard = d["regard"]
	if d.get("at") is Array and d["at"].size() == 2:
		r.at = Vector3(float(d["at"][0]), 0, float(d["at"][1]))
	return r
