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
| **Spaces and masses** | Terrace (west, top 24) over the west hall (stone, 8 tall); clearing (top 28, 4 thick) over the crypt (stone, 5 tall); the drop (4 wide) into the crypt; the lift shaft; a floating island (top 21) and the root shelf (top 17) above the clearing; the moat; the bridge's two spans with an 11-tile gap; the far bank |
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
  shelf (a ledge catch and the handstand climb) → the long drop (a hard landing)
  → a heavy blow (the knockback slide). Completed.

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
| A foreground silhouette layer for depth | Three `Parallax2D` layers at scroll 1.3 (held on screen vertically): fern and grass clumps along the bottom, moss and vines from the top, and two tree trunks. Flat near-void shapes with a 1 px moonlit rim (`shaders/silhouette.gdshader`), made by `tools/make_silhouettes.py` |
