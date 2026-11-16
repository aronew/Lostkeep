# IB-08 · The Keep's foundations (the outpost)

| | |
|---|---|
| **Identity** | Ironbark Guard, IB-08. West: the Undercroft's lower East door (IB-06). East (lower): on toward the Keep (not built). The outpost's doorway: IB-09, its interior |
| **World grid** | Origin at IB-01's (44, 88). Its West door (rows 12 to 16) is IB-06's lower East door (rows 60 to 64) |
| **Size** | 64 × 28 tiles (1024 × 448 px): 1.6 screens wide, 1.25 tall |
| **Idea** | The first rest since the clearing: a long straight walkway under a cave ceiling, the hooded stranger's outpost on it, then the walkway breaks off into the foundations' lower gallery and the way on east |
| **Mockups** | `docs/mockups/outpost/outpost.webp` (the building, painted: shape and mood only), `docs/mockups/outpost/hooded_stranger.webp` (the stranger, pixel art) |

## The outpost

The creative lead: "if we're getting currency by finding secrets and smashing
things maybe having an NPC and an outpost might be a good idea around this
point". Their choices:

- **The hooded stranger** (a wanderer, not a Guard; `scripts/world/stranger.gd`).
  Talk (interact) for a greeting, then a menu: up and down choose, interact or
  jump confirms, attack leaves. Keys are read on the physics tick, as Kleo's.
  - **A rumour: 5 Resin.** Five, told in order (`stranger_rumours` in
    `Game.flags`): secrets are shadow walls; smash pots and crates; bark plates
    break under a heavy shield blow (the captain's, in the armory under the
    Keep); the missing were carried down; the lantern is older than she thinks.
  - **The map of Ironbark: 60 Resin** ("the map should be expensive, you
    probably shouldn't be able to get it when you first get to the outpost").
    Sets `ironbark_map`; the map screen is not built yet.
  - The sprite is the creative lead's own pixel-art mockup, read at its 15.5 px
    grid (`tools/make_stranger.py`): 34 × 48 px, a head taller than Kleo.
    Animated frames: Book 1's OP2.
- **The save shrine**, as the clearing's ("save should be like the shrine you
  kneel at in the beginning"): the same Prism-shard shrine (`prism_shrine.gd`),
  flag `ib08_shrine`, at x 13 on the walkway.
- **The building:** OP1, the creative lead's pixel-art outpost (see below).
- **Resin from smashing:** every breakable now drops Resin (`resin`, 1 by
  default, in `breakable.gd`). Each drop is flagged by its room and place, so
  a pot that is back next visit doesn't pay again.

## The plan

- The passage in (rows 12 to 16) and the outpost cavern over the walkway
  (x 8 to 41, ceiling row 4, floor row 17).
- The lower gallery east of the walkway's broken end (x 42 to 63, ceiling
  row 9, floor row 24), the East door at its end (rows 19 to 23).
- The way back up: two CH1 slabs, [47, 21] and [43, 18]; the walkway is a
  tile above the second.
- **The lock before its key:** a cracked bark plate in the gallery's floor
  (x 52 to 54, W1d), four Resin glinting in the pit under it.
- **A secret** behind the gallery's west wall, under the walkway (x 36 to 41,
  rows 20 to 23): a false wall, motes drifting into it, six Resin.
- The crypts' look: `_mood`, `_ch_detail`, `_rim`.

## Validation

- `check_room.py ib08`: longest floor 42 tiles, 91 % in runs of 8+, no small
  steps, no thin masses, the plate holds, both exits reached, coverage 100 %,
  no traps.
- `room=ib08 mode=tour`: kneels at the shrine; talks to the stranger, buys a
  rumour for 5 Resin, says farewell and is released; off the walkway into the
  gallery; smashes the crate (Resin 7 → 9); back up by both slabs to the
  walkway; out to the East door.
- IB-01 `mode=props` (shared code changed): props break, the game is back to
  full speed, the crossbeam holds.
- Images: `docs/rooms/ironbark_08/outpost_shots.png` (in-game),
  `room_routes.png`.

## Inside the outpost (IB-09) and the light coming out of it

The creative lead: "I want it that you have to enter his outpost ... spooky
feeling in a way not all bright", and "there's light coming out of it sort of
like how Hollow Knight does it".

- **The doorway is an entry** (`_entry()` in `room_builder.gd`,
  `scripts/world/entry_door.gd`): interact to go in; coming back out, Kleo
  stands at the `OutpostDoor` marker on the walkway.
- **IB-09, the outpost inside** (`tools/build_ib09.gd`,
  `scenes/rooms/ironbark_09_outpost.tscn`): one screen, not on the world grid.
  Dim: the crypts' mood sunk darker (`mood_murk` (0.27, 0.27, 0.36)), lit only
  by a candelabra, two candles, a faint violet crystal and the stranger's
  amber eyes. Shelves of arches (CH6), jars, bones, a cobweb and chains (CH4),
  fog on the floor; no black near-layer roots (`detail_near = false`). The
  stranger stands behind his counter. Its west door leads back out.
- **The light coming out** (`_doorway_glow()` in `build_ib08.gd`): a pale glow in
  the doorway, a fan of light spilling out across the walkway, a pool on the
  stones, and a wide haze blooming round the building in the mist; all
  additive. OP1's leaf window gets the same when the building arrives.
- `mode=tour` now goes in, buys a rumour, comes back out at the doorway, then
  on as before: all true. Image: `docs/rooms/ironbark_08/outpost_outside_inside.png`.

## The stranger's frames (OP2)

The creative lead's OP2 sheet (`art/source/ironbark/outpost/hooded_stranger_frames.png`,
the generator's own): eight figures painted on a 7.75 px grid.
`tools/make_stranger_frames.py` reads each art pixel at its centre, hardens the
alpha, splits the figures and lines them up by their feet:
`stranger_frames.png`, 8 frames of 32 × 47. `stranger.gd` plays them: idle
(0 to 3, a slow breath, the blink on 2 every few seconds) and, while a
conversation is open, talk (4 to 7: the hand lifting, the eyes smiling). The
conversation box sits at the top of the screen so the scene stays in view, and
the detail pass keeps clear of his counter. Image:
`docs/rooms/ironbark_08/stranger_idle_talk.png`.

## The outpost building (OP1)

The creative lead's OP1 (`art/source/ironbark/outpost/outpost_building.png`,
the generator's own, painted at full resolution): `tools/make_outpost.py` crops
it to the building, reduces it 5:1 (box) and hardens the alpha, to
`outpost.png`, 278 × 184 px. It stands on the walkway with its golden doorway
on the entry (x 22.5), its base stones 3 px into the floor, on the root (not
graded, so the gold stays gold). The light spilling out (`_doorway_glow()`) is
gold to match the painted door; its leaf window has a faint teal light; the
detail pass keeps clear of its front (`detail_skip`). The save shrine moved to
x 11. `mode=tour` passes as before. Image: `docs/rooms/ironbark_08/outpost_in_game.png`.

**The white door** (the creative lead: "how about a white light at the door"):
their second OP1, the same building with a white doorway
(`outpost_building_white.png`; the gold one stays in the source folder), is
the one in the game, and the spilled light is white to match (`SPILL`).
Image: `docs/rooms/ironbark_08/outpost_white_door.png`.

The doorway light raised to the painted opening (the creative lead: "a little
higher ... its coming at lower middle"): then at about three quarters of its height
("not at the very top of the door"): the door glow at 44 px above the sill,
the light at 46, the fan from 48 px; `docs/rooms/ironbark_08/door_light.png`.
