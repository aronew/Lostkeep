# IB-08 · The Keep's foundations (the outpost)

| | |
|---|---|
| **Identity** | Ironbark Guard, IB-08. West: the Undercroft's lower East door (IB-06). East (lower): on toward the Keep (not built) |
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
- **The building:** a stand-in (CH6's arcade recess and an SH doorway) until
  OP1, the outpost in pixel art, arrives.
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
