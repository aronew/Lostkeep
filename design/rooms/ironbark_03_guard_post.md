# Room IB-03: The Guard Post (the game's opening room)

> **Status: built with art, awaiting the creative lead's review.** Composed like
> their surface mockups R, S and T from their set pieces SF9 to SF13. Scene:
> `game/scenes/rooms/ironbark_03_guard_post.tscn`, built by
> `game/tools/build_ib03.gd`. Review images: `docs/rooms/ironbark_03/`
> (`room_art.png` the whole room, `room_blockout.png` the labelled black box
> with both walked routes). It is the project's main scene: the game opens here.

## History

The first blockout started Kleo on the hilltop and led down. The creative lead's
notes: *"make it look just like my mockups"* and *"it can go high and then drop
down"*. So the room now starts low under the great tree, as in the mockups,
climbs to the chapel on the hill, and drops down the far side to the road.

Their review of that build: it *"looks nothing like the mockup"*, the new kit's
colours are worse than the first area's (*"purple skies and that palette looks
a lot better"*), and the twisted tree *"looks like shit"*. Changed since:

- **Palette:** IB-01's backdrops (the purple sky and moons, far forest, nearer
  trees), its darkness and moonlight shafts, and its canopy foreground. SF13's
  blue backdrops are no longer used. The SF9 to SF12 pieces that remain are
  tinted toward the Ironbark kit's plum (`SF_TINT`).
- **Tree:** SF9's twisted trunk and its repeated leaf rows are gone. The start
  stands under the Great Ironbark painting from IB-01 (a stand-in: the same
  landmark twice; a new tree wants its own card). The second tree and its
  branch are replaced by the Ironbark kit's long island.
- **Layout:** unchanged, and still open. The mockups are one dense screen; this
  room spreads the same pieces over 2.8 screens.

## What the mockups gave it, and where the principles shaped it

| From the mockups | How it is built here |
| --- | --- |
| A great tree on one side, a lantern, the hero starting under it | The start: the Great Ironbark with its lantern, two mossy wall blocks beside it |
| Branches as walkways across the upper air | One great branch (SF9) from the tree. It is one-way: she jumps up through it and drops back down |
| Floating ruin islands in the middle air | The ruin island, the grave island (SF12) and the long island (the Ironbark kit's): the upper line |
| A pool at the lowest point with a broken bridge | The pool, and SF11's bridge as two broken ends with a four-tile gap: the room's one required jump |
| A chapel on a hill, climbed by stair terraces | The guard's chapel (SF10) on the hilltop, four terraces up, each joined by a flight of SF10's stairs |
| Stairs | Painted steps over a slope she runs up: no one-tile stair collision, no jump needed |
| Stumps and small blocks in the water as stepping stones | Two fallen blocks, dimmed and behind her: scenery, not a way across. No rows of small platforms anywhere |
| The sky, far ruins and nearer trees | IB-01's backdrops (the creative lead's preferred palette), not SF13's |

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-03. East: IB-01's terrace (the way on). West: the forest road (proposed; not built) |
| **World grid** | West of IB-01 and 5 tiles higher: its origin is at IB-01's (-112, -5). Its East door (rows 24 to 28) is IB-01's west upper exit (rows 19 to 23). It lies over the Old Crypt (IB-02) |
| **Idea** | Kleo comes home to her post at dusk: under the great tree, over the broken bridge, up the hill to the chapel. Nobody is there. The road east drops away below |
| **Purpose** | The story's start. Teaches run, stairs, one jump (the bridge's gap), and, for the curious, jumping up through a branch and island hopping. Shows two locks in the first minute. Ends with a look down the road she must take |
| **Size** | 112 × 32 tiles (1792 × 512 px): 2.8 screens wide, 1.4 tall |
| **Ground** | The start (row 24, 24 long) with the root ledge on it; the pool's banks (row 27); the pool (16 wide); the hill's terraces (rows 24, 21, 18, each 9 long); the hilltop (row 15, 10 long); the far side's two shelves (rows 19 and 24); the road (row 29) |
| **Placed collision** | Seven flights of stairs (slopes); the bridge's two decks (row 25); the two branches (rows 19 and 18, one-way); the root ledge |
| **Islands** | The ruin island (11 wide, row 18); the grave island (7 wide, row 17); the far island (4 wide, row 9) |
| **Exits** | East door (rows 24 to 28); West door (rows 19 to 23, leads nowhere yet) |
| **Lines** | **Main:** the tree → stairs down to the bank → the bridge and its gap → four flights up the hill → the chapel → down the far side's shelves → the East door. About 30 seconds. **Upper (optional):** the wall blocks → up through the great branch → the ruin island → the grave island → the long island → down to the hill's second terrace: an express lane over the pool |
| **Way back** | From the road, the far side's shelves are ledge catches of 5, 5 and 4 tiles: the room is not one-way |
| **Locks seen here** | **Deep-Glow Breath:** a glint deep in the pool under the bridge's gap. **Wing-Cloak:** the far island over the road, a glint on it, out of reach from the hilltop |
| **Encounters** | None. The opening room is safe |
| **Story** | The chapel's windows are lit and nobody is home. Graves on the terraces. More to place: the watch fire, a meal left, the thorn knots in the tree (Thorn-Line) |
| **Later reads** | Breath: the pool (and under it the Old Crypt's Root Well). Wing-Cloak: the far island, and a glide from the chapel deep into IB-01 |

## Validation (measured, not judged by eye)

`python3 tools/check_room.py ib03` on the exported collision, with the placed
collision annotated:

- Floors: **longest run 15 tiles (rule ≥ 20): fails.** The start is 24 tiles but
  the wall blocks stand on it; the mockups' terraces are short by nature. 75%
  of floor is in runs of 8+ (rule ≥ 60%).
- Small steps: 0. Staircases: 0. Masses thinner than 2 tiles: 0.
- The gate holds with the base kit: the far island.
- Both doors are reached; 100% of the ungated floor is reached with the base
  kit; no traps.

Walked in the engine with real physics (`tests/playtest.gd room=ib03`):

- **Main line** (`mode=tour`): stairs to the bank → onto the bridge → jumped
  the gap → four flights to the chapel → down the far side → out the East door
  into IB-01. Completed.
- **Upper line** (`mode=upper`): wall blocks → up through the great branch → ruin
  island → grave island → long island → the second terrace. Then the way back
  from the road up all three shelves, and a walk off the bridge into the pool
  (returned to safe ground). Completed.
- **Doors** (`mode=doors`): IB-01's terrace into the Guard Post and back.
  Completed.

Camera (`tools/camera_report.py`): slide 0 and wobble 0 on both lines; the view
eases to a stop over 96 px at the room's edge.

## Known rough edges

- The start's tree is IB-01's Great Ironbark again, a stand-in.
- The branch's painted top undulates a few pixels around the flat walking line.
- The surface pieces are tinted, not repainted, toward the Ironbark palette.
- The pool is only as wide as the bridge, and its sides are plain earth.
- The far side's shelves and the hill's east face are bare.
- The terrain's grass and earth edges are IB-01's kit (SF1 to SF8 are not
  generated yet); SF10's painted terrace blocks, SF11's waterfalls and most of
  its stumps are not used.
- No watch fire or other story props yet (the tree's own thorn knots show the
  Thorn-Line lock).
