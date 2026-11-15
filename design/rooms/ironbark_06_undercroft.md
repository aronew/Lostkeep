# Room IB-06: The Undercroft

> **Status: second blockout, awaiting the creative lead's review.** Scene:
> `game/scenes/rooms/ironbark_06_undercroft.tscn`, built by
> `game/tools/build_ib06.gd`. Review images: `docs/rooms/ironbark_06/`
> (`blockout_map.png`; `both_vs_mockups.png`, beside the mockup).

## The brief

The next room on the main line, under the Lantern Clearing, through the Shrine
Hall's lower East door. The first blockout (three long switchback corridors and
a root chamber) was rejected: "the undercroft room is poorly designed". This
one is laid out after the creative lead's middle vertical-level mockup
(`docs/mockups/undercroft/vertical_levels.webp`): rooms stacked down both
sides of a tall void, a broken arch across it, a basin at the bottom.

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-06. West (top): IB-05's lower East door. West (bottom), behind a bark plate (the Ward): IB-07, the Pit Shaft. East (bottom): on toward the Keep's foundations (not built) |
| **World grid** | Origin at IB-01's (0, 40). Its West door (rows 12 to 15) is IB-05's lower East door (rows 22 to 25); its lower West door (rows 60 to 64) is IB-07's East door (rows 36 to 40; IB-07's origin is (-44, 64)) |
| **Size** | 44 × 72 tiles (704 × 1152 px): 1.1 screens wide, 3.2 tall |
| **Idea** | The guard's cellar rooms stacked down both sides of a void under the clearing; the way down crosses the void from side to side, room by room; a lift folds the bottom back to the top |
| **Spaces** | The void (9 wide, the room's full height, open far above). West: L1 the storeroom (floor 16), L2 a lantern room (25), L3 the long arcade (39), L4 a lantern room (53), L5 the bottom-left room (65). East: R1 the arcade (18), R2 a lantern room (28), R3 an arcade (39), R4 a cellar (53), R5 the bottom-right room (65). The root arch across the void (46). The basin (68) and its sump. An alcove high in the void's east wall (5). The lift's shaft beside the east rooms |
| **Lips** | Each room's floor runs out into the void as a lip; a step in the void at row 28. Every gap she is meant to drop through is 2 tiles wide: she runs straight over a 1-tile gap (found walking it) |
| **Lines** | **Main:** the West door → L1 → a short jump across to R1 → off its lip onto the step → across to R2 → off its lip onto R3's → across to L3 → off L3's lip onto the root arch → east into R4 → off its west side to the basin → up into R5 → the East door. **Side:** L2 from the step; L4 off the arch's west end; L5 from the basin over the sump. **The fold:** the cellar lift, R5 up to R1 (freed from below at its winch), then the short jump back to L1 by the door |
| **Locks seen here** | **Barkgrip:** the alcove high in the void's east wall. **Deep-Glow Breath:** the sump in the basin. **Ironbark Ward (W1c):** the bark plate in L5's west door: the Pit Shaft stays shut until the Ward's slam |
| **Encounters, rewards** | None yet. Each lantern room is shaped for one (a lore beat, a pot cache, a health shard) |
| **Next pass** | The mockup's outlines are rounded and crumbling, its rooms have arcades and lanterns: shape the room walls that way when the layout is approved |

## Validation

`python3 tools/check_room.py ib06`: longest floor 24 tiles; 94% in runs of 8+;
no small steps, staircases or thin rock; the Barkgrip alcove holds; both exits
reached; 100% of the floor reached with the base kit; no traps.

Walked in the engine (`tests/playtest.gd room=ib06`): the main line down every
crossing to the East door (`mode=tour`); the winch, the lift up to R1 and the
jump back to L1; L2, L4, L5; the plated door holds; the sump returns her to
safe ground (`mode=upper`); IB-05's lower East door in and out (`mode=doors`).
