# Room IB-03: The Ruin Gardens (the game's opening room)

> **Status: built with art, awaiting the creative lead's review.** Scene:
> `game/scenes/rooms/ironbark_03_ruin_gardens.tscn`, built by
> `game/tools/build_ib03.gd` (on `surface_builder.gd`). Review images:
> `docs/rooms/ironbark_03/`. It is the project's main scene.

## The brief (the creative lead's words)

After their mockup "Moonlit Forest Ruins and Floating Islands"
(`docs/mockups/ironbark_surface/`): *"more terrain like these mockups, the ones
with the large floating islands are what I like. These areas are mostly to
learn movement, get the feel for the game, do some jumps, maybe a chill enemy
or two."* This room is the climb; IB-04 winds back down.

An earlier IB-03 (a bridge, a hill and a chapel from the SF kit) was rejected
and removed: wrong colours, a twisted tree, badly cut stairs, and a layout
unlike the mockups.

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-03. East (high): IB-04, the Gate Road. West: the forest road (not built) |
| **World grid** | Origin at IB-01's (-205, -13). Its East door (rows 11 to 15) is IB-04's West door |
| **Idea** | The old burial gardens at dusk: a hill of terraces, a great island of graves hanging in the moonlight, a cliff with an arch at its top |
| **Purpose** | Learn to move with nothing at stake: run, stairs, a jump up, two island hops, a long walk across the great island, a log, more stairs. Fall anywhere and you land in the garden, with a way back up |
| **Size** | 93 × 40 tiles (1488 × 640 px): 2.3 screens wide, 1.8 tall |
| **Ground** | The road (row 37); the west hill's three terraces (rows 34, 31, 28); the garden under the islands (row 37, 22 long); a shelf at each cliff foot (row 33); the east cliff (rows 22, 19, 16) with a cave in its foot |
| **Islands (painted)** | The stepping chunk (5 wide, row 25); the great graveyard island (27 wide, row 22); the crystal-shrine island over the garden (11 wide, row 31) |
| **Placed collision** | Four flights of stairs; the log from the great island to the cliff (one-way) |
| **Lines** | **Main:** the road → a flight → a three-tile jump up → a flight → the stepping chunk → the great island → the log → the cliff's two flights → the arch (East door). **Garden (optional, and where a fall lands):** back up to the hill by two ledge catches (4 and 5 tiles); the cliff's shelf, its cave, and the crystal-shrine island |
| **Locks seen here** | None yet. The opening is about movement |
| **Encounters** | None yet: no enemies exist. The garden (22 flat tiles) and the great island (27) are where the first chill enemy or two belong |
| **Story** | Graves everywhere, lanterns lit, nobody tending them |

## Validation

`python3 tools/check_room.py ib03`: longest floor 31 tiles; 84% in runs of 8+;
no small steps, staircases or thin rock; both doors reached; 100% of the floor
reached with the base kit; no traps. (The painted islands are one tile of
collision under thick paintings; they are listed as placed collision.)

Walked in the engine (`tests/playtest.gd room=ib03`): the main line
(`mode=tour`) to the arch and out into IB-04; the garden (`mode=upper`): both
ledge catches back up to the hill, the shelf and cave, the low island. All
completed. Camera: slide 0, wobble 0.

## Rough edges

- The islands are placed as painted, on one tile of collision: their grass
  lines are near-straight, not ruled.
- The start's tree is IB-01's Great Ironbark, mostly out of frame.
- The hill, the garden and the cliff are terrain-kit boulders with a few
  graves: thinner dressing than the mockup.
- No enemies; no pickups in the cave or on the shrine island yet.
