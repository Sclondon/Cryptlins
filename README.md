# Cryptlins

A spotlight in a dark room, and the little monster that lives in it. A virtual pet: it hatches from an egg, runs
about, eats, plays, sleeps and looks at you. Godot 4.7 (GL Compatibility), made for phones and the web, and drawn
like a PlayStation game.

It starts as an egg in the lamplight. The lamp warms it slowly (about a minute and a half), a rubbing finger warms
it fast (about ten seconds), and a tap makes it knock back. It cracks twice on the way, an eye looks out of the
second crack, and then it hatches. The shell says what is inside:

| Egg | Hatches a | Which is |
| --- | --- | --- |
| Mossy, warty | **gremlin** | The all-rounder: big ears, a tail, fangs. |
| Hairy | **squatchling** | A young sasquatch: a shaggy mound of hair with two tall eyes, on big feet and no arms yet. Slow, heavy, deep-voiced, hungry and shy. |
| Speckled | **cockatrice** | A rooster with a serpent's tail. Struts, flaps, crows high, and stares more than anything else does. |
| Wound in silk | **mothman** | Dark and furry with great red eyes, feathered feelers and eyed wings. Fast, squeaky, gets the zoomies, tires quickly. |
| Spiny | **chupacabra** | Lean and hunched, spines down its back, fangs. Quick, very hungry, lurks. |
| Slimy | **Loveland frogman** | A frog that stands up. Jumps highest of all, croaks, loves to dance. |
| Cold and wet | **Loch Ness monster** | A hump, four flippers and a long neck. Slow on land, shy, rarely tired. |
| Stone | **slide-rock bolter** | A whale of the high slopes: mostly mouth, with a hooked tail. Lumbering and always starving, until it gets the zoomies. |
| Antlered | **wendigo** | A deer's skull on a thin dark body with long arms. Never full, keeps to the dark, stares. |

It hatches a **baby**: small, big-headed and squeaky. After about seven minutes awake it grows up, to a size of its
own (0.8 to 1.3 times the usual).

Each cryptlin also has a **nature** (greedy, playful, shy, sleepy, cuddly, bold, grumpy or restless) that bends its
needs and habits and decides how it takes being picked up or pushed, a **favourite food**, a food it **won't eat**,
and a **favourite toy**. Its kind leans it one way or another; the rest is its own. You find these out by trying
things, and the menu keeps a note of what you have learned. How it is **feeling** (content, happy, excited, loving,
hungry, bored, sleepy, grumpy, scared, sad or disgusted) shows in its eyes, ears and the hang of its head, and is
written under its name.

The buttons carry symbols, not words:

| You | It |
| --- | --- |
| **Bone** (or F) | Opens the food tray: bone, toadstool, candy corn, fish, beetle, berries. It runs over and eats what you drop, loves its favourite, and spits out the one it can't stand. |
| **Ball** (or B) | Opens the toy tray: a bouncy ball, a heavy stone, a ringing bell, a floaty orb that glows in the dark. It chases and kicks the toy and fetches it back; it plays longest with its favourite. Pick the toy up with a finger and it jumps for it; let go to throw. |
| **Lamp** (or L) | Puts the lamp out. All you can see are its eyes; before long it goes to its nest and sleeps. |
| **Footprint** | The menu: who it is and what you know of its tastes, the floor (flagstones, floorboards, moss, checkers), the nest (rags, twigs, cushion, box), a new egg, and sound. |
| **?** | Shows what a finger can do. |
| Tap the floor | Calls it over. |
| Hold or drag on the floor | Swings the lamp. It chases the pool of light and pounces on it. |
| Rub it | It purrs. Builds the bond. |
| Tap it | A poke: it jumps (and wakes, grumbling, if it was asleep). Poke it four times running and it has had enough. |
| Hold a finger on it | Picks it up. Drag to carry it; let go to set it down. Some like it, some don't. |
| Flick it | Pushes it skidding across the floor. |
| Move the mouse | It watches the pointer. Otherwise it watches you. |

**New egg** (in the menu) asks first, then the cryptlin waves and walks off into the dark and an egg of a different
kind drops in.
| **?** | Shows the finger gestures (also shown for a new egg and a new hatchling). **Sound** (M) mutes. |

Phone-first: on an upright phone the three buttons share the full width, touch targets on the cryptlin and the ball are generous, and nothing needs a keyboard or hover.

Left alone it wanders, sits and stares at you with its head on one side, slinks off into the dark to watch from there,
gets the zoomies, dances, and begs with a thought bubble when it is hungry or bored. Belly, Fun and Rest run down
over time (slowly while you are away, and never to nothing); it sleeps by itself when tired.

Each cryptlin is shaped by its kind and a seed, both kept in the save: fur and eye colour, ear length, build, horns,
odd-sized eyes, and a name.

## How it works

- `scripts/cryptlin.gd`: the creature. `KINDS` holds what sets the nine kinds apart in behaviour and there is one
  `_build_<kind>()` for each body; they all fill the same rig (two leg pivots, two arms, ears, eyes, mouth, tail), so
  the brain and the animation are shared. Its body is spheres, capsules and cones under a few pivots; all animation is
  procedural (gait from speed, squash-and-stretch on a spring, head and pupils tracking a gaze point, blinks, ear
  twitches). States set pose goals and `_animate()` eases toward them. The brain is a small state machine: urgent things
  (food, a thrown ball, the moving light, tiredness) interrupt, otherwise it picks something by weighted chance.
- `scripts/egg.gd`: the egg, its warmth, cracks and hatching.
- `scripts/main.gd` (`Den`): the room, lamp, HUD, touch input and save (`user://cryptlin.json`). `pet` is null
  while there is an egg.
- The PlayStation look: the room is drawn into a SubViewport 240 pixels on its short side and blown up with hard
  pixels by `shaders/ps1_screen.gdshader`, which also cuts it to 15-bit colour with the console's dither pattern.
  Every solid thing uses `shaders/ps1.gdshader` (through `scripts/ps1.gd`), which snaps corners to whole pixels and
  maps textures without perspective; meshes are low-poly; the floor pattern is cut into coarse texels. The buttons
  and text are drawn sharp on top. Because the room is drawn smaller than the screen, touches go through
  `Den._in_view()` before any camera ray, and `Den.screen_of()` goes the other way.
- The eyes are emissive and the room has almost no ambient light, so outside the beam the eyes are all that shows.
- `shaders/beam.gdshader`: the haze in the beam, worked out per pixel from how near the line of sight passes to the
  beam's axis. `shaders/floor.gdshader`: flagstones from world position. No textures or audio files anywhere:
  `scripts/sfx.gd` synthesises every sound at start-up.
- The floor is on render layer 2 so the soft fill light (which stops things in the beam going black underneath)
  doesn't light the floor outside it.

## Test panel

Five quick taps on the name in the top-left corner (or the ` key, or `?dev` on the address of the web build) open a
small panel on the left: **<** and **>** step through every kind, **Look** rolls a new colour, build and nature, **Egg**
swaps the cryptlin for its egg, which **Hatch** then hatches at once, and **Age** switches between baby and adult. While
it is open the menu shows the cryptlin's tastes without your having to find them out. The same five taps close it.

## Tests and builds

```
godot --headless --fixed-fps 60 --path . -s tests/smoke.gd [-- --kind=0..8]   # egg, hatching, feeding, ball, petting, calling, lamp, sleep, save/load, new egg
godot --path . -s tests/shots.gd -- --shots=C:/tmp/shots [--portrait] [--seed=N] [--kind=0..8] [--egg|--ui]   # screenshots of each doing, of the egg hatching, or of the trays, menu, floors and nests
godot --headless --path . --export-release Web build/index.html
```
