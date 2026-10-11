# Cryptlins

A spotlight in a dark crypt, and the little monster that lives in it. A virtual pet: it hatches from an egg, runs
about, eats, plays, sleeps and looks at you. Godot 4.7 (GL Compatibility), made for phones and the web, and drawn
like a PlayStation game.

It starts as an egg in the lamplight. The lamp warms it slowly (about a minute and a half), a rubbing finger warms
it fast (about ten seconds), and a tap makes it knock back. It cracks twice on the way, an eye looks out of the
second crack, and then it hatches. The shell says what is inside:

| Egg | Hatches a | Which is |
| --- | --- | --- |
| Mossy, warty | **gremlin** | The all-rounder: big ears, a tail, fangs. |
| Purple with an eye marking | **bogle** | Squat, one-eyed, horned. Slow, greedy, deep-voiced; stares a lot and likes to dance. |
| Pale and faintly glowing | **spook** | Floats, no legs, hollow eyes. Eats little, lurks in the dark, and glows enough to be seen there. |
| Dark with two points | **flit** | A small bat. Fast, squeaky, hops high on beating wings, gets the zoomies, tires quickly. |

**New egg** asks first, then the cryptlin waves and walks off into the dark and an egg of a different kind drops in.

| You | It |
| --- | --- |
| **Feed** (or F) | A bone, toadstool or candy corn drops into the light. It runs over and eats it in three bites. |
| **Ball** (or B) | Throws a ball in (or tosses the one that's there). It chases and kicks it, and fetches it back out of the dark. Pick the ball up with a finger and it jumps for it; let go to throw. |
| **Lamp** (or L) | Puts the lamp out. All you can see are its eyes; before long it goes to its nest and sleeps. |
| Tap the floor | Calls it over. |
| Hold or drag on the floor | Swings the lamp. It chases the pool of light and pounces on it. |
| Rub it | It purrs. Builds the bond. |
| Tap it | It jumps (and wakes, grumbling, if it was asleep). |
| Move the mouse | It watches the pointer. Otherwise it watches you. |
| **?** | Shows the finger gestures (also shown for a new egg and a new hatchling). **Sound** (M) mutes. |

Phone-first: on an upright phone the three buttons share the full width, touch targets on the cryptlin and the ball are generous, and nothing needs a keyboard or hover.

Left alone it wanders, sits and stares at you with its head on one side, slinks off into the dark to watch from there,
gets the zoomies, dances, and begs with a thought bubble when it is hungry or bored. Belly, Fun and Rest run down
over time (slowly while you are away, and never to nothing); it sleeps by itself when tired.

Each cryptlin is shaped by its kind and a seed, both kept in the save: fur and eye colour, ear length, build, horns,
odd-sized eyes, and a name.

## How it works

- `scripts/cryptlin.gd`: the creature. `KINDS` holds what sets the four kinds apart in behaviour and there is one
  `_build_<kind>()` for each body; they all fill the same rig (two leg pivots, two arms, ears, eyes, mouth, tail), so
  the brain and the animation are shared. Its body is spheres, capsules and cones under a few pivots; all animation is
  procedural (gait from speed, squash-and-stretch on a spring, head and pupils tracking a gaze point, blinks, ear
  twitches). States set pose goals and `_animate()` eases toward them. The brain is a small state machine: urgent things
  (food, a thrown ball, the moving light, tiredness) interrupt, otherwise it picks something by weighted chance.
- `scripts/egg.gd`: the egg, its warmth, cracks and hatching.
- `scripts/main.gd` (`Crypt`): the room, lamp, HUD, touch input and save (`user://cryptlin.json`). `pet` is null
  while there is an egg.
- The PlayStation look: the crypt is drawn into a SubViewport 240 pixels on its short side and blown up with hard
  pixels by `shaders/ps1_screen.gdshader`, which also cuts it to 15-bit colour with the console's dither pattern.
  Every solid thing uses `shaders/ps1.gdshader` (through `scripts/ps1.gd`), which snaps corners to whole pixels and
  maps textures without perspective; meshes are low-poly; the floor pattern is cut into coarse texels. The buttons
  and text are drawn sharp on top. Because the crypt is drawn smaller than the screen, touches go through
  `Crypt._in_view()` before any camera ray, and `Crypt.screen_of()` goes the other way.
- The eyes are emissive and the room has almost no ambient light, so outside the beam the eyes are all that shows.
- `shaders/beam.gdshader`: the haze in the beam, worked out per pixel from how near the line of sight passes to the
  beam's axis. `shaders/floor.gdshader`: flagstones from world position. No textures or audio files anywhere:
  `scripts/sfx.gd` synthesises every sound at start-up.
- The floor is on render layer 2 so the soft fill light (which stops things in the beam going black underneath)
  doesn't light the floor outside it.

## Tests and builds

```
godot --headless --fixed-fps 60 --path . -s tests/smoke.gd [-- --kind=0..3]   # egg, hatching, feeding, ball, petting, calling, lamp, sleep, save/load, new egg
godot --path . -s tests/shots.gd -- --shots=C:/tmp/shots [--portrait] [--seed=N] [--kind=0..3] [--egg]   # screenshots of each doing, or of the egg hatching
godot --headless --path . --export-release Web build/index.html
```
