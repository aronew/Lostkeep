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
| **Spaces and masses** | Terrace (west, top 24) over the west hall (stone, 8 tall); clearing (top 28, 4 thick) over the crypt (stone, 5 tall); the drop (4 wide) into the crypt; the lift shaft; a 3-tall capstone in the hall; a floating island (top 21) and the root shelf (top 17) above the clearing; the moat; the bridge's two spans with an 11-tile gap; the far bank |
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

- Floors: longest run 64 tiles (rule ≥ 20); 96% in runs of 8+ (rule ≥ 60%).
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

Not yet checked: enemies (none yet), the room's doors to its neighbours (they
are walls until those rooms exist), and the generous model on the gates (the
gap is 11 tiles against a 6.27-tile running jump, so it holds by a wide margin).
