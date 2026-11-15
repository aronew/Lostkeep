# Room IB-02: The Old Crypt

> The second room, built after IB-01 was approved. Scene:
> `game/scenes/rooms/ironbark_02_old_crypt.tscn`, built by
> `game/tools/build_ib02.gd`. Review images: `docs/rooms/ironbark_02/`.

## What the mockups gave it

The creative lead's twenty labyrinth mockups share one shape: stacked galleries
on either side of a tall central well, joined at their ends, with pockets off
the sides. This room takes that shape and keeps to the principles where the
mockups and the principles pull apart:

| From the mockups | How it is built here |
| --- | --- |
| A central well with galleries opening onto it at every level | The Root Well, 21 tiles wide and the room's full height, with four strata of masonry gallery on its east side and a gallery and a cave on its west |
| Floating islands in the well | Three islands (one large, two small), placed art on flat collision: the only way across |
| Ladders at the ends of the galleries | None. The way down is a drop, the way back up is a machine (the hoist): the principles' rule for a long climb |
| Rows of small platforms up the shaft | None. Islands are 11% of the standing room; everything else is floor |
| Built stone beside raw cave | East: the guard's masonry (the crypt kit). West: a gallery, then a root cave that has broken into it |
| A flooded lowest level | The cistern: the well's water runs east into a drowned gallery |

## Reskin (the creative lead: "reskin the Old Crypt with the same stone")

All its masonry is now the Shrine Hall's (SH1 and SH2, `_use_shrine_stone()` in
`room_builder.gd`): floors, ceilings, walls and corners, and the false wall over
the vault, which draws SH2's wall band so it still reads as unbroken wall. The
galleries no longer have a plum masonry back wall: they open onto SH8's misty
hall behind, as the Shrine Hall does. It is brighter and bluer
(CanvasModulate 0.8, 0.82, 0.96). The Root Well and the root cave keep their
raw earth and their islands (IB4, IB5), by design: a natural cavern broken
into the crypt. Collision unchanged.

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-02. East upper and lower: IB-05, the Shrine Hall (the Old Crypt's first section). West: the Refuge road (behind the plated door). Above: the Guard Post's well (out of reach) |
| **World grid** | West of IB-05 (the Shrine Hall): its origin is at IB-01's (-170, 28). Its East doors (rows 5 to 9, 23 to 27) are IB-05's West doors (rows 3 to 7, 21 to 25) |
| **Idea** | The guard's burial galleries, stacked beside a root-choked well that has broken through them; the way on is down, and the hoist brings you back |
| **Purpose** | The first labyrinth: reading a tall space, committing to drops, a loop that crosses itself. Establishes a landmark (the moonlit well). Shows four locks before their keys. Hides the game's first secret and teaches its tell. Folds a shortcut back to the door. Tells part of the story (a hideout, a cocoon hung out of reach) |
| **Size** | 112 × 40 tiles (1792 × 640 px): 2.8 screens wide, 1.8 tall |
| **Spaces** | The well's mouth (8 wide, rising out of the room) over the well cavern (21 × 33). East: E1 the vestibule (50 × 5), E2 the niche walk (27 × 5) with a collapse at its east end, E3 the long gallery (50 × 5), the hoist's shaft (4 × 13, E1 to E3), the flooded gallery (28 × 5). West: W1 the west gallery (41 × 5 with its door), a collapse in its floor, the root cave (27 × 7), the vault (11 × 5) behind the cave's west wall |
| **Masses** | The grave island (15 wide, top row 17); two low islands (6 and 5 wide, top row 28); the fallen rock in the cave (6 × 2) |
| **Exits** | East upper door (rows 5 to 9); East lower door (rows 23 to 27); West door (rows 11 to 15, gated); the well's mouth above (gated) |
| **Lines** | **Main:** East door → west along E1, over the jammed hoist → off the balcony onto the grave island (a 7-tile drop, one way) → E2 → the collapse → E3 → the winch → the lower East door. **Upper (optional):** grave island → W1 → the plated door (shut) → the collapse → the cave. **Lower:** E3's west balcony → the low islands → the cave. The upper and lower lines meet in the cave, so the room is one loop that crosses itself at the well |
| **Shortcut** | The bier hoist: jammed at its head in E1, a few steps inside the door. The winch at its foot in E3 frees it; after that it is the way back up, and it stays freed when the room is left |
| **Locks seen here** | **W2** the plated door across W1 (Ironbark Ward): the way west. **E2** a cocoon hung over the gap by W1's mouth, on a strand no blade reaches (Emberwick). **Deep-Glow Breath:** the cistern, and a glint deep in the flooded gallery. **Barkgrip:** the well's mouth, far above any jump, with moonlight coming down it. **Anima Siphon:** an empty Prism socket in the vault |
| **Secret** | The vault. From the cave its wall is unbroken masonry; the opening is 4 tiles up (a ledge catch). Tells: masonry standing in a raw cave, moss on it where the air moves, and a draught of motes drifting into the stone. Kleo climbing through fades the false wall for good |
| **Encounters** | None yet (no enemies exist). E3 and the cave are shaped for them: long sight lines, room for the combo |
| **Placed pieces** | 19 breakable pots, barrels and crates. The hoist's crossbeam is a one-way perch, as in IB-01 |
| **Landmark and story** | Moonlight falling down the well onto a single grave on a floating island. A cold fire, a half-eaten meal and a pair of boots in the cave: someone from the guard hid here, and is gone. A guard's helmet in the vault. The cocoon |
| **Later reads** | Ward opens the plated door (the Refuge road). Emberwick cuts the cocoon down (a rescue). Barkgrip climbs the well to the Guard Post and the cave wall to W1. Breath dives the flooded gallery for the glint. Wing-Cloak glides from E1 straight to W1. Siphon wakes the socket |

## Validation (measured, not judged by eye)

`python3 tools/check_room.py ib02` on the exported collision:

- Floors: longest run 50 tiles (rule ≥ 20); 90% in runs of 8+ (rule ≥ 60%).
- Small steps: 2, both sides of the fallen rock (rule ≤ 2). Staircases: 0.
  Masses thinner than 2 tiles: 0.
- The gate holds with the base kit: the west gallery past the plated door.
- Both East doors are reached; 100% of the ungated floor is reached with the
  base kit; no traps (every reached spot leads back to the East door).

Walked in the engine with real physics (`tests/playtest.gd room=ib02`):

- **Main line** (`mode=tour`): door → balcony → grave island → E2 → the
  collapse → E3 → the winch frees the hoist → the hoist up to E1 → out the
  East door into IB-01. Completed.
- **Upper line and loop** (`mode=west`): island → W1 → the plated door holds →
  the collapse into the cave → the ledge catch through the false wall into the
  vault (the cover fades) → the low islands → E3 → into the cistern and back
  to safe ground. Completed.
- **Doors** (`mode=doors`): IB-01's hall door into IB-02 and back; Kleo arrives
  standing just inside each door, facing in. Completed.

Camera (`tools/camera_report.py`): slide 0 and wobble 0 on both lines; the
view eases to a stop over 96 px at the room's edge.

Not yet checked: enemies (none yet); the lower East door and the West door
(their rooms are not built, so they end in darkness); the generous model on
the plated door (it is solid collision, so it holds).

## Art it is built from, and art it wants

Built from what exists: the crypt kit (CR1 to CR3), the earth kit (IB5, IB6),
IB4's and IB5's islands, the guard's belongings, the graveyard stones, the
lanterns, the flora, the bark-plate, the silk cocoon and the Prism socket.

Stand-ins that want their own art (cards to add to Book 1):

| Wanted | Today |
| --- | --- |
| A backdrop for the well: deep cave wall, great roots descending, far masonry | The earth fill, dimmed, with moonlight and dust |
| Great hanging roots for the well's shoulders and the collapses | Small vines from the flora sheet |
| A stone bier and coffin niches for the galleries | Headstones from the graveyard sheet |
| The hoist as its own machine (a bier cradle on chains) | IB-01's rope lift |
| A cracked, mossy false-wall piece | The wall band itself, with a moss tuft |
