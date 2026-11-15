# Room IB-04: The Gate Road

> **Status: built with art, awaiting the creative lead's review.** Scene:
> `game/scenes/rooms/ironbark_04_gate_road.tscn`, built by
> `game/tools/build_ib04.gd` (on `surface_builder.gd`). Review images:
> `docs/rooms/ironbark_04/`.

## The brief (the creative lead's words)

After their mockup "Moonlit Ruin Gardens Above the Forest": *"then you wind
back down ... and then you get to the straight path, jump the water and then
head to the guard post."*

## The pool (the creative lead's calls)

1. The first build had a four-tile brook: *"that little tiny water jump that
   looks pointless"*. They asked for *"something a little bigger with little
   tiny islands that you have to jump across"*, after a mockup of stone piers
   standing in a pool.
2. Then: *"make the water section longer like in the mockup ... the water with
   a possible jump across the little island steps and up above the bigger
   islands that are floating in the air too, making 2 paths."*

So the pool is 42 tiles long (more than a screen) and has two ways over it:

- **Low path:** six small islands (old wall piers, 3 tiles wide, their tops one
  and two tiles above the road): seven jumps. A deliberate exception to "no
  rows of small platforms": one readable run of them, over water, where the
  jump is the lesson. They are spaced for her measured jump (about 55 px of
  water, 48 px to land on); a first version with piers 64 px apart could not be
  hopped, because a full jump sails over the next one.
- **High path:** the floating islands above the water. It starts on the hill
  (the second terrace), crosses the bush chunk, the tree island and the
  root-held island, then goes out over the pool.
3. Then: *"make the bigger islands above the water at different heights so you
   don't just jump straight across in a line."* So over the pool every island
   is at its own level: the ruin island (two up), the crystal-shrine island
   (three down), a bush chunk (three up), a second ruin island (three down),
   the headstone chunk (four down), then the far bank. The headstone chunk
   sits right over the bank, so a full jump that overshoots it lands on the
   bank, not in the water (a first version ended on a three-tile chunk over
   open water, and a full jump sailed past it).

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-04. West (high): IB-03, the Ruin Gardens. East: IB-01, the Lantern Clearing (the guard's post) |
| **World grid** | Origin at IB-01's (-128, -13). Its East door (rows 32 to 36) is IB-01's west upper exit (rows 19 to 23); its West door (rows 11 to 15) is IB-03's East door (IB-03's origin is at IB-01's (-221, -13)) |
| **Idea** | She comes out of the arch high on a hill and winds down its grave terraces, great islands hanging over them; then the road, the long pool, and home |
| **Purpose** | The other half of the movement lesson: stairs down, two drops, then a choice of two ways over the water. Shows the first lock |
| **Size** | 128 × 40 tiles (2048 × 640 px): 3.2 screens wide, 1.8 tall |
| **Ground** | The west hill's six terraces (rows 16, 19, 22, 26, 29, 34); the road (row 37, 24 flat tiles); the pool (42 long); the far bank (8) |
| **Islands (painted)** | The bush chunk (3 wide, row 17); the tree island (19, row 16); the root-held island (16, row 20); over the pool, the ruin island (9, row 18), the crystal-shrine island (11, row 21), a bush chunk (3, row 18), a second ruin island (9, row 21, mirrored), the headstone chunk (5, row 25); a far bush chunk (3, row 14) |
| **Placed collision** | Four flights of stairs; the pool's six small islands |
| **Lines** | **Low:** the arch → two flights down → a drop → a flight → a drop → a flight → the road → the pool by its six islands → the East door. **High:** from the second terrace along the islands, out over the pool, down to the far bank. **Way back:** ledge catches of 5 and 4 tiles and the flights |
| **Locks seen here** | **Wing-Cloak:** a far chunk high over the road's end, something glinting on it, out of reach from every island |
| **Encounters** | None yet. The road (24 flat tiles) is where a chill enemy belongs |
| **Story** | A crystal shrine by the road; the timber gate before the water; lanterns on both banks |

## Validation

`python3 tools/check_room.py ib04`: longest floor 28 tiles; 86% in runs of 8+;
no small steps, staircases or thin rock; the far chunk holds; both doors
reached; 100% of the ungated floor reached; no traps.

Walked in the engine (`tests/playtest.gd room=ib04`): the low path
(`mode=tour`): down the hill, across the pool (all seven jumps landed) and out
into IB-01. The high path (`mode=upper`): every island, up and down, to the far bank (the test's full last jump lands on the bank); then
the way back up the hill, and a walk into the water (returns her to safe
ground). The doors (`mode=doors`) with IB-01 and IB-03. All completed. Camera:
slide 0, wobble 0.

## Rough edges

- The hill is one long descent east; the mockup's terraces fold back on
  themselves more tightly.
- The pool is two tiles deep (the room ends there), so the piers stand in
  shallow water; its banks are plain earth. No waterfall or ruins around it.
- The ruin island appears twice over the pool (once mirrored), and the bush
  chunk three times in the room: seven island paintings are stretched thin.
- The pool's piers are tinted SF11 pieces, two side by side per island.
- No enemies yet.
