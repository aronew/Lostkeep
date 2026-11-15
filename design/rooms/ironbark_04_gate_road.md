# Room IB-04: The Gate Road

> **Status: built with art, awaiting the creative lead's review.** Scene:
> `game/scenes/rooms/ironbark_04_gate_road.tscn`, built by
> `game/tools/build_ib04.gd` (on `surface_builder.gd`). Review images:
> `docs/rooms/ironbark_04/`.

## The brief (the creative lead's words)

After their mockup "Moonlit Ruin Gardens Above the Forest": *"then you wind
back down ... and then you get to the straight path, jump the water and then
head to the guard post."*

## The pool (the creative lead's call)

The first build had a four-tile brook: *"that little tiny water jump that looks
pointless"*. They asked for *"something a little bigger with little tiny
islands that you have to jump across"*, after a mockup of stone piers standing
in a pool. So the pool is 23 tiles wide with three small islands. This is a
deliberate exception to "no rows of small platforms": one short, readable run
of them, over water, where the jump is the lesson. They are spaced for her
measured jump (56 px of water, 48 px to land on): a first version with piers
64 px apart could not be hopped, because a full jump sails over the next one.

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-04. West (high): IB-03, the Ruin Gardens. East: IB-01, the Lantern Clearing (the guard's post) |
| **World grid** | Origin at IB-01's (-112, -13). Its East door (rows 32 to 36) is IB-01's west upper exit (rows 19 to 23); its West door (rows 11 to 15) is IB-03's East door |
| **Idea** | She comes out of the arch high on a hill and winds down its grave terraces, great islands hanging over them; then the straight road, the water, and home |
| **Purpose** | The other half of the movement lesson: stairs down, two drops, the island line for the curious, then four jumps across the pool by its small islands. Shows the first lock |
| **Size** | 112 × 40 tiles (1792 × 640 px): 2.8 screens wide, 1.8 tall |
| **Ground** | The west hill's six terraces (rows 16, 19, 22, 26, 29, 34); the road (row 37, 27 flat tiles); the pool (23 wide) |
| **Islands (painted)** | The bush chunk (3 wide, row 17); the great tree island (19 wide, row 16); the root-held island (16 wide, row 20); the far ruin island (9 wide, row 17) |
| **Placed collision** | Four flights of stairs; the pool's three small islands (old wall piers, 3 tiles wide, their tops one and two tiles above the road) |
| **Lines** | **Main:** the arch → two flights down → a drop → a flight → a drop → a flight → the road → the pool, hopped by its three islands → the East door. **Islands (optional):** from the second terrace to the bush chunk, the tree island, down to the root-held island; the far island stays out of reach, and a leap for it lands on the road. **Way back:** ledge catches of 5 and 4 tiles and the flights |
| **Locks seen here** | **Wing-Cloak:** the far ruin island, something glinting in its arch, 10 tiles past the root-held island and 3 higher |
| **Encounters** | None yet. The road (27 flat tiles) is where a chill enemy belongs |
| **Story** | A crystal shrine by the road; the timber gate over the water; the Great Ironbark's kin at the road's end |

## Validation

`python3 tools/check_room.py ib04`: longest floor 32 tiles; 93% in runs of 8+;
no small steps, staircases or thin rock; the far island holds; both doors
reached; 100% of the ungated floor reached; no traps.

Walked in the engine (`tests/playtest.gd room=ib04`): the main line
(`mode=tour`) down the hill, across the pool (all four jumps landed) and out into IB-01; the islands
(`mode=upper`), the leap for the far island (lands on the road), the way back
up the hill, and the water (returns her to safe ground); the doors
(`mode=doors`) with IB-01 and IB-03. All completed. Camera: slide 0, wobble 0.

## Rough edges

- The hill is one long descent east; the mockup's terraces fold back on
  themselves more tightly.
- The pool is two tiles deep (the room ends there), so the piers stand in
  shallow water; its banks are plain earth.
- The pool's piers are tinted SF11 pieces, two side by side per island.
- No enemies yet.
