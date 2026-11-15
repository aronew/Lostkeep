# Room IB-07: The Pit Shaft

> **Status: blockout, awaiting the creative lead's review.** Scene:
> `game/scenes/rooms/ironbark_07_pit_shaft.tscn`, built by
> `game/tools/build_ib07.gd`. Review images: `docs/rooms/ironbark_07/`.

## The brief

The creative lead asked whether the Shrine Hall's pit would go on down ("it
looks like it should"), chose a Ward lock for it (option 2: the cracked bark
plate, W1b), and gave references for the way down: a narrow masonry shaft with
small ledges on alternating walls (`docs/mockups/undercroft/shaft_reference.webp`:
steps like these "don't read as weird"), and their vertical-level mockups,
"especially the one on the far left" (`docs/mockups/undercroft/vertical_levels.webp`).

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-07. East: the Undercroft's lower West door. Top: the underside of the Shrine Hall's cracked plate (W1b, out of reach) |
| **World grid** | Origin at IB-01's (-44, 64): under the Shrine Hall, whose pit (world x -29 to -26) is over the shaft (x 15 to 18 here). Its East door (rows 8 to 12) is IB-06's lower West door (rows 32 to 36) |
| **Size** | 44 × 41 tiles (704 × 656 px): 1.1 screens wide, 1.8 tall |
| **Idea** | A narrow masonry shaft dropping from the Shrine Hall's pit to the deep: small ledges taking turns across it, burial pockets opening off it on alternating sides, the deepest chamber at the bottom |
| **Spaces** | The shaft (6 wide, rows 1 to 33); the passage east to the Undercroft (floor row 13); a burial pocket off its west side (floor row 22); a longer pocket off its east side (floor row 31); the deep chamber (36 wide, floor row 39) |
| **The ledges** | Eight, 2 wide, every 4 or 5 rows, at rows 35 (west), 31 (east, the east pocket's lip), 27 (middle), 22 (west, the west pocket's lip), 18 (middle), 13 (east, the passage's lip), 9 (west) and 5 (east, under the plate). Each stands beside the one below, never over it, and each is within her ledge catch of the last: the climb back up is the way out |
| **Lines** | In from the Undercroft along the passage; down the shaft ledge by ledge to the deep chamber; the climb back up through both pockets; up the last two ledges under the plate (shut until the Ward); out the East door |
| **Locks seen here** | The Shrine Hall's cracked plate from below (Ironbark Ward, W1b): with the Ward it becomes the shortcut between the Shrine Hall and the deep |
| **Encounters, rewards** | None yet. The pockets and the deep chamber are shaped for a reward each (a relic, a health shard, a lore beat) |
| **Next pass** | The far-left mockup is richer than this blockout: irregular masses, a dark rock column in the middle, rooms with doors and lanterns stacked up both sides. Shape the walls around the shaft that way once the creative lead approves the climb |

## Validation

`python3 tools/check_room.py ib07`: longest floor 36 tiles; 91% in runs of 8+;
no small steps, staircases or thin rock; the exit reached; 100% of the floor
reached with the base kit; no traps.

Walked in the engine (`tests/playtest.gd room=ib07`): down the shaft ledge by
ledge to the deep chamber; the climb back up by all six ledges (35, 31, 27,
22, 18, 13) and through both pockets; out the East door into the Undercroft
(`mode=tour`). Up the last two ledges under the plate and back down
(`mode=upper`).
