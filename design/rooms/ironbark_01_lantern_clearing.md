# Room IB-01: The Lantern Clearing (the Ironbark test room)

> The first room built in Godot, for approval before the method is applied
> to more rooms. Scene: `game/scenes/rooms/ironbark_test_room.tscn`, built
> by `game/tools/build_test_room.gd`. Review images: `docs/rooms/ironbark_01/`.

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-01. West upper: the Guard Post (the story's start). West lower: the Old Crypt (the main way on). East: the Lost Keep's gate (gated) |
| **Idea** | Under the Great Ironbark, a mossy clearing runs east to the broken bridge, with the guard's crypt beneath it |
| **Purpose** | Establishes a landmark (the Great Ironbark, the save shrine); introduces running, jumping, the ledge catch and the combo (a training yard); shows five locks before their keys; folds a shortcut back to the save; gives breath |
| **Size** | 138 × 40 tiles (2208 × 640 px): 3.5 screens wide, 1.8 tall |
| **Spaces and masses** | Terrace (west, top 24) over the west hall (stone, 5 tall like the crypt it runs on into; the lift shaft drops 8 tiles from the terrace into it); clearing (top 28, 4 thick) over the crypt (stone, 5 tall); the drop (4 wide) into the crypt; the lift shaft; a floating island (top 21, 15 wide) and the root shelf (an island, top 17, 22 wide) above the clearing; the moat; the bridge's two spans with an 11-tile gap; the far bank |
| **Exits** | West upper at the terrace (height 24), west lower door from the hall (32–37), east across the gap (Wing-Cloak) |
| **Lines** | Main: terrace → clearing → the drop → the crypt west → the hall → the west door (a switchback). Upper (optional): terrace → island → ledge catch → root shelf pocket → drop to the clearing. Lower: the crypt |
| **Shortcut** | The guard's lift: jammed at the top, worked from below with the winch; it links the hall to the shrine |
| **Locks seen here** | W1 bark-plate floor (Ward), E1 silk seal and cocoon (Emberwick), G1 the broken bridge (Wing-Cloak), D1 the moat with a glint below (Breath), S1 the shrine's Prism socket (Siphon), T1 the tree's thorn knots (Thorn-Line) |
| **Encounters** | Two practice posts in the training yard (no enemies yet) |
| **Placed pieces** | The lift's crossbeam: a one-way perch 3 tiles above the terrace (drop through with down + jump). Thirteen breakable pots, barrels and crates in the hall, the crypt, the clearing and the root shelf |
| **Landmark and story** | The Great Ironbark and its lantern; the guard's graveyard with one fresh, empty grave; the training yard with a meal left half-eaten; the Lost Keep's gate across the gap |
| **Later reads** | Ward breaks W1 (a shortcut down into the crypt); Emberwick burns E1 (a rescue); Wing-Cloak crosses the gap to the Keep; Breath dives for the glint; Siphon wakes the socket; Thorn-Line reaches the tree's crown |

## Validation (measured, not judged by eye)

`python3 tools/check_room.py` on the exported collision:

- Floors: longest run 86 tiles (rule ≥ 20); 98% in runs of 8+ (rule ≥ 60%).
- Small steps: 0 (rule ≤ 2). Staircases: 0. Masses thinner than 2 tiles: 0.
- Gates hold with the base kit: the far bank (G1) and the sealed pocket (E1).
- Both west exits are reached; 100% of the ungated floor is reached with the
  base kit; no traps (every reached spot leads back to the shrine).

Walked in the engine with real physics (`tests/playtest.gd`):
- **Main line** (`mode=tour`): shrine → down the step → the four-hit combo on
  the practice posts → the drop (a hard landing) → west through the crypt →
  the winch → the lift up → rest at the shrine. Completed.
- **Upper line** (`mode=upper`): terrace → island (a running jump) → the root
  shelf (a ledge catch and the handstand climb) → off its east end at a run,
  down the collapse into the crypt (a hard landing) → a heavy blow (the
  knockback slide). Completed.

Camera on the main line (`tools/camera_report.py`): drift 1%, sway 0 px,
wobble 0 frames.

Not yet checked: enemies (none yet), the room's doors to its neighbours (they
are walls until those rooms exist), and the generous model on the gates (the
gap is 11 tiles against a 6.27-tile running jump, so it holds by a wide margin).

## Revision 2: the creative lead's first notes

| Note | Change |
| --- | --- |
| The gap between the floor and the crypt's corbels should be black, not stone | Every mass is now the void inside (`fade_tiles` 0). Only the edge bands are painted: grass and a shallow soil band that steps down to the void, then black, then the arches |
| Too much going on in the floor tiles: overlaps, several tiles in one space | A slab is one material from the grass down (stone starts at the crypt ceilings); the soil band is 12 px lit + 10 px fading instead of 40 px; walls are drawn after tops so a corner is one straight face; a column open on both sides gives each face half its width |
| The ledge in the hall looks out of place | The fallen capstone (a 4 × 3 stone mass skinned with floor tiles) is removed; the hall is one clean floor |
| The rock faces of the drop and the piers look odd | IB3's wall band (ferns and mushrooms growing from the rock) is replaced by the floor's own soil turned on its side, 20 px deep. Real art is requested as IB5 and K4 |
| Background tree tops are cut off | P3 was generated cropped through the canopy. A haze band on the mid layer lets the trees rise into mist; P3 v2 (taller, whole crowns) is requested |
| The edges are straight lines on the black | Every band now ends in the void along its own stones (`crust` in `tools/make_terrain.py`): a few rows always kept, then only the stones joined to them, each with a shaded underside. Wall faces stand up to 4 px proud of the collision in worn runs, and the straight outline beside them is gone. Only walking lines are straight. IB5 and K4 now ask for the same. Still boxy: the root shelf, a skinned slab; it should become placed island art like the floating island |
| A foreground layer for depth | First as flat silhouettes held on screen (they slid when the camera moved and the generated trunks looked wrong), now a `Parallax2D` at scroll (1.2, 1.0): eleven dark, unlit clumps of the flora sheet's ferns and grasses standing on the walking lines, roots sunk in the slab |
| New art: IB5, K4, P3 v2 | Wall faces are IB5's and K4's painted bands; outer top and ceiling corners are painted pieces placed by the skin and clipped to their mass. The mid layer is P3 v2 with whole crowns (the haze is gone) |
| Still something weird with the floor tiles under the graveyard step | Two causes. The hall's ceiling (row 28) met the crypt's (row 31) under the step, leaving a 3-tile face hanging under the floor and a 2-tile scrap of arcade beside it; the hall's high vault now ends at the lift shaft's wall, so one wall runs from the grass to the arcade. And every left-facing face and corner was drawn displaced into its mass: a negative width draws the art flipped within [x, x + width], not back across x (a bug since the first skin). Both fixed |
| The crypt arcade stopped mid-arch at walls | K4's arch end is its end piece: a full-height pier where the arcade meets a wall or the collapse, placed only where the floor lies within reach of it (so never hanging in the hall's taller vault) |
| One arcade, one scale (K5) | The crypt arcade is K5: round arches on piers that stand on the floor, at K4's scale, so the crypts read as one colonnade between K4's end arches. Kleo passes in front of it; the piers below the imposts are one value step darker so they sit back against the wall. The west hall is now 5 tiles tall like the crypt, so the colonnade stands on the floor everywhere |
| The root shelf looked like a floor piece | It is IB4's big island now (with its sapling), its collision widened from 15 to 22 tiles to match the island's flat top. Walking off its east end lands on the clearing; running off carries Kleo down the collapse into the crypt |
