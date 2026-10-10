# Cryptlins

A spotlight in a dark crypt, and the little monster that lives in it. A virtual pet: it runs about, eats, plays,
sleeps and looks at you. Godot 4.7 (GL Compatibility), made for phones and the web.

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
| **?** | Shows the finger gestures (also shown the first time). **Sound** (M) mutes. |

Phone-first: on an upright phone the three buttons share the full width, touch targets on the cryptlin and the ball are generous, and nothing needs a keyboard or hover.

Left alone it wanders, sits and stares at you with its head on one side, slinks off into the dark to watch from there,
gets the zoomies, dances, and begs with a thought bubble when it is hungry or bored. Belly, Fun and Rest run down
over time (slowly while you are away, and never to nothing); it sleeps by itself when tired.

Each cryptlin is shaped by a seed kept in the save: fur and eye colour, ear length, build, horns, odd-sized eyes, and a name.

## How it works

- `scripts/cryptlin.gd`: the creature. Its body is spheres, capsules and cones under a few pivots; all animation is
  procedural (gait from speed, squash-and-stretch on a spring, head and pupils tracking a gaze point, blinks, ear
  twitches). States set pose goals and `_animate()` eases toward them. The brain is a small state machine: urgent things
  (food, a thrown ball, the moving light, tiredness) interrupt, otherwise it picks something by weighted chance.
- `scripts/main.gd` (`Crypt`): the room, lamp, HUD, touch input and save (`user://cryptlin.json`).
- The eyes are emissive and the room has almost no ambient light, so outside the beam the eyes are all that shows.
- `shaders/beam.gdshader`: the haze in the beam, worked out per pixel from how near the line of sight passes to the
  beam's axis. `shaders/floor.gdshader`: flagstones from world position. No textures or audio files anywhere:
  `scripts/sfx.gd` synthesises every sound at start-up.
- The floor is on render layer 2 so the soft fill light (which stops things in the beam going black underneath)
  doesn't light the floor outside it.

## Tests and builds

```
godot --headless --fixed-fps 60 --path . -s tests/smoke.gd            # feeding, ball, petting, calling, lamp, sleep, save/load
godot --path . -s tests/shots.gd -- --shots=C:/tmp/shots [--portrait] [--seed=N]   # screenshots of each doing
godot --headless --path . --export-release Web build/index.html
```
