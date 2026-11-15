# Room IB-07: The Pit Shaft

> **Status: second blockout, awaiting the creative lead's review.** Scene:
> `game/scenes/rooms/ironbark_07_pit_shaft.tscn`, built by
> `game/tools/build_ib07.gd`. Review images: `docs/rooms/ironbark_07/`
> (`blockout_map.png`; `../ironbark_06/both_vs_mockups.png`, beside the mockup).

## The brief

The creative lead asked whether the Shrine Hall's pit would go on down, chose a
Ward lock for it (the cracked bark plate, W1b), and gave references for a thin
vertical level, "especially the one on the far left"
(`docs/mockups/undercroft/vertical_levels.webp`). The first blockout (a plain
shaft with eight ledges) was rejected: "make the vertical shaft one look just
like my far left mockup", and "I shouldn't be able to get into that room until
I get that slam". Now it follows the mockup's masses, and both ways in are the
Ward's: the plate from above, and a bark plate on the Undercroft's side.

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-07. Top: the Shrine Hall's cracked plate (W1b). East: the Undercroft's plated door (W1c). East (bottom): on to the deep (not built) |
| **World grid** | Origin at IB-01's (-44, 64): under the Shrine Hall, whose pit (world x -29 to -26) is over the cave opening at the top (x 15 to 18 here). Its East door (rows 36 to 40) is IB-06's lower West door (rows 60 to 64) |
| **Size** | 44 × 64 tiles (704 × 1024 px): 1.1 screens wide, 2.8 tall |
| **The mockup, piece by piece** | The cave opening at the top (the pit); the walkway across the chasm, with a gap to drop through; the left and right masses under it; the building over the arched-door room down the left, its floor (row 28) and the wall under it; the tall wall on the right; the zig-zag mass down the middle, the landing on top (row 28), a ledge off its west side (36), its foot; a ledge low in the west cave (50); the niche on the mass's east side (41) and the passage out beside it; the lantern room low on the right; the stepped bottom floor (58, 60) |
| **Lines** | **In, with the Ward:** drop through the plate onto the walkway → through its gap onto the landing → across to the arched-door room and back → down the west cave by its two ledges to the bottom → east, up the three ledges on the right (54, 50, 46) to the niche → the passage → the East door into the Undercroft. Or off the walkway's east end, down beside the tall wall onto the passage. **On:** the lantern room's door, east to the deep |
| **The upper half is a descent** | The walkway, the chasm, the landing, the arched-door room and the west cave are reached only by dropping from the plate; the climb on the right brings her back to the way out |
| **Checker** | Its floor-run and small-step rules are written for horizontal rooms and fail here by design (a tall shaft has no long floors); coverage and traps pass |

## Validation

`python3 tools/check_room.py ib07`: the plate-only parts hold (the checker
starts at the East door); both exits reached; 100% of the rest reached; no
traps. Walked in the engine (`tests/playtest.gd room=ib07`): from the walkway
down through every part and the climb out to the East door into the
Undercroft (`mode=tour`); off the walkway's east end to the passage
(`mode=upper`).
