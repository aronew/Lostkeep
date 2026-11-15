# Room IB-04: The Gate Road

> **Status: built with art, awaiting the creative lead's review.** Scene:
> `game/scenes/rooms/ironbark_04_gate_road.tscn`, built by
> `game/tools/build_ib04.gd` (on `surface_builder.gd`). Review images:
> `docs/rooms/ironbark_04/`.

## The brief (the creative lead's words)

After their mockup "Moonlit Ruin Gardens Above the Forest": *"then you wind
back down ... and then you get to the straight path, jump the water and then
head to the guard post."*

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-04. West (high): IB-03, the Ruin Gardens. East: IB-01, the Lantern Clearing (the guard's post) |
| **World grid** | Origin at IB-01's (-112, -13). Its East door (rows 32 to 36) is IB-01's west upper exit (rows 19 to 23); its West door (rows 11 to 15) is IB-03's East door |
| **Idea** | She comes out of the arch high on a hill and winds down its grave terraces, great islands hanging over them; then the straight road, the water, and home |
| **Purpose** | The other half of the movement lesson: stairs down, two drops, the island line for the curious, one jump over water. Shows the first lock |
| **Size** | 112 × 40 tiles (1792 × 640 px): 2.8 screens wide, 1.8 tall |
| **Ground** | The west hill's six terraces (rows 16, 19, 22, 26, 29, 34); the road (row 37, 38 flat tiles); the water (4 wide) |
| **Islands (painted)** | The bush chunk (3 wide, row 17); the great tree island (19 wide, row 16); the root-held island (16 wide, row 20); the far ruin island (9 wide, row 17) |
| **Placed collision** | Four flights of stairs |
| **Lines** | **Main:** the arch → two flights down → a drop → a flight → a drop → a flight → the road → the jump over the water → the East door. **Islands (optional):** from the second terrace to the bush chunk, the tree island, down to the root-held island; the far island stays out of reach, and a leap for it lands on the road. **Way back:** ledge catches of 5 and 4 tiles and the flights |
| **Locks seen here** | **Wing-Cloak:** the far ruin island, something glinting in its arch, 10 tiles past the root-held island and 3 higher |
| **Encounters** | None yet. The road (38 flat tiles) is where a chill enemy belongs |
| **Story** | A crystal shrine by the road; the timber gate over the water; the Great Ironbark's kin at the road's end |

## Validation

`python3 tools/check_room.py ib04`: longest floor 38 tiles; 97% in runs of 8+;
no small steps, staircases or thin rock; the far island holds; both doors
reached; 100% of the ungated floor reached; no traps.

Walked in the engine (`tests/playtest.gd room=ib04`): the main line
(`mode=tour`) down the hill, over the water and out into IB-01; the islands
(`mode=upper`), the leap for the far island (lands on the road), the way back
up the hill, and the water (returns her to safe ground); the doors
(`mode=doors`) with IB-01 and IB-03. All completed. Camera: slide 0, wobble 0.

## Rough edges

- The hill is one long descent east; the mockup's terraces fold back on
  themselves more tightly.
- The water is a plain four-tile brook under the timber gate.
- The road's end reuses IB-01's Great Ironbark, mirrored.
- No enemies yet.
