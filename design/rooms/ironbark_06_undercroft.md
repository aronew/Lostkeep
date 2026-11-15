# Room IB-06: The Undercroft

> **Status: blockout, awaiting the creative lead's review** (no art placed:
> the terrain shows the CY stone because the skin paints every room). Scene:
> `game/scenes/rooms/ironbark_06_undercroft.tscn`, built by
> `game/tools/build_ib06.gd`. Review images: `docs/rooms/ironbark_06/`
> (`blockout_map.png`, the black-box map with the walked routes).

## The brief

The next room on the main line: under the Lantern Clearing, through the
Shrine Hall's lower East door (the creative lead: "start building the
Undercroft blockout"). It also takes the way down from the Shrine Hall's pit
(W1b), which is its own room, IB-07, the Pit Shaft.

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-06. West: IB-05's lower East door. West lower: IB-07, the Pit Shaft. East lower: on toward the Lost Keep (not built). High in the root chamber's east wall: a passage (Barkgrip) |
| **World grid** | Origin at IB-01's (0, 40): under the clearing. Its West door (rows 12 to 15) is IB-05's lower East door (rows 22 to 25); its lower West door (rows 32 to 36) is IB-07's East door (rows 8 to 12; IB-07's origin is (-44, 64)) |
| **Size** | 96 × 40 tiles (1536 × 640 px): 2.4 screens wide, 1.8 tall |
| **Idea** | The guard's cellars under the clearing, broken open by the Great Ironbark's roots: three floors stacked like a ploughed field (east, back west, east again), a tall root chamber at the turn, and a lift that folds the bottom back to the door you came in by |
| **Purpose** | The principles' switchback (pancake) stacking; the friction of a long way down, then the fold back up (the lift, from below); two locks seen before their keys |
| **Spaces** | F1, the storeroom gallery (46 × 5, floor row 16); the root chamber (30 × 22, floor row 26) with two root masses (8 wide, rows 22 and 19); F2, the root passage back west (36 × 5, floor row 26) ending in a collapse; F3, the cistern walk (96 × 5, floor row 37) with the sump (4 wide); the lift's shaft (F3 up to F1, beside the West door); the passage high in the chamber's east wall |
| **Lines** | **Main:** the West door → east along F1 → off its end into the root chamber → back west along F2 → down its collapse into F3 → east over the sump → the lower East door. **Ways back up:** the cellar lift (from F3: the winch frees it, it carries her to F1 by the West door); the root chamber's climb (floor → the low root mass → the high one → F1), each mass beside the next, never over it. **Side:** F3's west end, the lower West door into the Pit Shaft |
| **Locks seen here** | **Barkgrip:** a passage high in the root chamber's east wall, 17 tiles of sheer wall below it. **Deep-Glow Breath:** the sump in F3's floor, dark water going on down, a glint in it |
| **Shortcut** | The cellar lift: jammed at the top (its deck plugs F1's floor beside the West door); freed from below, it folds F3 back to the Shrine Hall's door |
| **Encounters** | None yet (F1 and F3 are long, flat and shaped for them) |
| **Art** | None yet. Ideas for it: roots of the Great Ironbark breaking through the masonry in the chamber; storeroom racks, barrels and sacks along F1; water seeping from the moat above along F3 |

## Validation

`python3 tools/check_room.py ib06`: longest floor 62 tiles; 99% in runs of
8+; no small steps, staircases or thin rock; the Barkgrip passage holds; all
three exits reached; 100% of the floor reached with the base kit; no traps.

Walked in the engine (`tests/playtest.gd room=ib06`): the main line
(`mode=tour`: F1, the chamber, F2, the collapse, F3, over the sump, to the
lower East door); the ways back (`mode=upper`: the winch and the lift from F3
to F1; the chamber's climb by both root masses to F1; falling in the sump
returns her to safe ground); the doors (`mode=doors`: IB-05's lower East door
into the Undercroft and back). The Pit Shaft's tour leaves by its East door
into the Undercroft's lower West door.
