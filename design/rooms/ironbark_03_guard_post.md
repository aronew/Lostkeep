# Room IB-03: The Guard Post (the game's opening room)

> **Status: blockout, awaiting the creative lead's approval.** Collision, doors,
> the brook and the well's lid only: no props, lights, backdrops or set pieces
> yet (SF9 to SF13 wait for approval). Scene:
> `game/scenes/rooms/ironbark_03_guard_post.tscn`, built by
> `game/tools/build_ib03.gd`. Review images: `docs/rooms/ironbark_03/`
> (`room_blockout.png` is the labelled black-box map).

## What mockups R, S and T gave it, and where the principles won

| From the mockups | How it is built here |
| --- | --- |
| A building on a hill, climbed by terraces: the high point | The guardhouse's hill is the west half of the room. Kleo **starts on top** and the terraces lead down and east: gravity is the compass from the first step |
| Stair terraces of grass and stone | Three long terraces (14 to 24 tiles), four tiles apiece: floors, not stairs. Down is a walk off an edge; back up is a ledge catch |
| A great tree whose branches are walkways | One great branch, 34 tiles long, across the upper air: a floor in the sky, not a row of perches |
| Floating ruin islands in the middle air | Two: one beside the hilltop (the way onto the branch), one past the branch's end, out of reach (a Wing-Cloak lock) |
| Three heights read at once | The branch line (row 21), the terrace line (rows 25, 29, 33), the ground line (row 37) |
| A pool at the lowest point, a broken bridge, stepping stumps | Only a brook across the yard with its footbridge down: one four-tile jump. **The pool, the bridge and the falls are kept for the Keep approach** (the moat is there); this room sits on top of the Old Crypt with three tiles of ground to spare. No stumps: they are small platforms |
| Rows of small floating blocks | None. Everything walkable is a floor of 10 tiles or more |

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-03. East: IB-01's terrace (the way on). West: the forest road (proposed; not built). Below: the Old Crypt, IB-02, down the well (lidded) |
| **World grid** | West of IB-01 and 13 tiles higher: its origin is at IB-01's (-112, -13). Its East door (rows 32 to 36) is IB-01's west upper exit (rows 19 to 23). Its well (x 47 to 54) is the mouth of IB-02's Root Well |
| **Idea** | The guard's post on its hill, empty; three terraces step down to the yard and the road east, under a great branch that crosses the whole sky |
| **Purpose** | The story's start: Kleo at her post, and nobody else. Teaches run, walking off an edge, one jump (the brook), and, for the curious, the ledge catch and a running jump. Shows three locks in the first minute. Sets the compass: down and east |
| **Size** | 112 × 40 tiles (1792 × 640 px): 2.8 screens wide, 1.8 tall |
| **Ground** | The hill's back (a cliff, x 0 to 5) with the road cut through it; the hilltop (row 25, 24 long); the upper terrace (row 29, 14 long); the well terrace (row 33, 16 long, the well in it); the yard and the road (row 37, 52 long) with the brook (4 wide) |
| **Masses** | The ruin island (14 wide, top row 22); the great branch (34 wide, top row 21); the far island (10 wide, top row 18) |
| **Exits** | East door (rows 32 to 36); West door (rows 20 to 24, leads nowhere yet); the well (sealed) |
| **Lines** | **Main:** the guardhouse → down the terraces → over the well's lid → the yard → the brook → the East door. About 25 seconds. **Upper (optional):** the hilltop's brink → the ruin island (3 across, 3 up) → the great branch (4 across, 1 up) → its far end, the lookout → a 16-tile drop to the yard |
| **Shortcut** | None of its own. Later: the Ward breaks the well's lid, a straight drop into the Old Crypt; Barkgrip climbs back up it |
| **Locks seen here** | **Ironbark Ward:** the well's bark-plate lid, walked over on the main line. **Wing-Cloak:** the far island, 12 tiles past the branch's end. **Thorn-Line:** thorn knots high in the great tree, over the branch (placed with the art) |
| **Encounters** | None. The opening room is safe |
| **Story (placed with the art)** | The guardhouse dark, its door open. The watch fire cold. The lookout at the branch's end: the first sight of the Lost Keep, far to the east |
| **Later reads** | Ward: the well. Wing-Cloak: the far island, and from the branch a glide deep into IB-01. Thorn-Line: the tree's crown. Barkgrip: up the well from the crypt |

## Validation (measured, not judged by eye)

`python3 tools/check_room.py ib03` on the exported collision:

- Floors: longest run 34 tiles (rule ≥ 20); 100% in runs of 8+ (rule ≥ 60%).
- Small steps: 0. Staircases: 0. Masses thinner than 2 tiles: 0.
- The gate holds with the base kit: the far island.
- Both doors are reached; 100% of the ungated floor is reached with the base
  kit; no traps.

Walked in the engine with real physics (`tests/playtest.gd room=ib03`):

- **Main line** (`mode=tour`): hilltop → upper terrace → well terrace (the lid
  holds) → yard → jumped the brook → out the East door into IB-01, standing on
  its terrace. Completed.
- **Upper line** (`mode=upper`): back up a terrace by a ledge catch → the ruin
  island → the great branch → a leap for the far island from the branch's end
  falls short and lands in the yard → into the brook, returned to safe ground.
  Completed.
- **Doors** (`mode=doors`): IB-01's terrace into the Guard Post and back; Kleo
  arrives standing just inside each door, facing in. Completed.

Camera (`tools/camera_report.py`): slide 0 and wobble 0 on both lines; the view
eases to a stop over 96 px at the room's edge.

IB-01 (all modes) and IB-02 (tour, west, doors, checker) pass unchanged.

## Open questions for the creative lead

1. **Start high or start low?** The mockups put the chapel on the hill as a goal
   to climb to. Here Kleo starts at the top and comes down, because she is
   leaving her post and gravity is the compass. The alternative (start in the
   yard, climb to the post, come back) is a longer opening.
2. **The west door.** Is the forest walk west of the post? It is only a road cut
   in the cliff today.
3. **The upper half of the room is empty sky.** The great tree's trunk, canopy
   and the guardhouse fill it in the art pass, but if it should hold more to
   find (a second branch, a tree-hollow room), say so before the art.
4. **Where the game opens.** The project's main scene is still IB-01. It moves
   here once this room has art.
