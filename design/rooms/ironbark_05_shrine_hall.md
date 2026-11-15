# Room IB-05: The Shrine Hall (the Old Crypt's first section)

> **Status: built with the creative lead's crypt kit, awaiting review.** Scene:
> `game/scenes/rooms/ironbark_05_shrine_hall.tscn`, built by
> `game/tools/build_ib05.gd`. Review images: `docs/rooms/ironbark_05/`.

## The brief

The creative lead's mockup `docs/mockups/old_crypt/old-crypt-first-section.jpg`:
*"this mock up is exactly how I want that first section of the Old Crypt to
look"*, then their kit for it, OC1 to OC8 (`art/source/ironbark/crypt_oc/`).

It is a new room between IB-01 and IB-02: the hall door of the Lantern
Clearing now opens into it, and IB-02 (the galleries and the Root Well) lies
on beyond its two west doors. IB-02 keeps its plum crypt kit for now.

## Spec

| Field | Content |
| --- | --- |
| **Identity** | Ironbark Guard, IB-05. East (upper): IB-01's hall door. West (upper and lower): IB-02's two East doors. East (lower): the Undercroft (not built) |
| **World grid** | Origin at IB-01's (-56, 27). Its East door (rows 5 to 9) is IB-01's hall door (rows 32 to 36); its West doors (rows 5 to 9, 23 to 27) are IB-02's East doors. IB-02's origin is now at IB-01's (-168, 27) |
| **Idea** | A tall hall of pale masonry under the clearing: a gallery of burial niches along its top, the hooded statue's island floating in the middle air between two braziers, smaller ruins on islands, the dead on their biers below |
| **Purpose** | The first sight of the crypts, as a landmark you see from the door and come back to. The main line is short (along the gallery, one jump over its break); the hall below is for the curious |
| **Size** | 56 × 36 tiles (896 × 576 px): 1.4 screens wide, 1.6 tall |
| **Ground** | The gallery (row 10, door to door, broken for 5 tiles over the shrine); the lower floor (row 28) with a 4-wide pit |
| **Islands and ledges (painted, OC3 and OC4)** | The shrine island (15 wide, row 20) with the hooded statue; the arch island (6, row 22); the niche island (5, row 19); a balcony on the east wall (4, row 16); three small ledges, each beside the island it leads to, never over one (row 15 under the break, row 24 by the west wall, row 25 by the pit) |
| **Lines** | **Main:** East door → west along the gallery → jump its break → West door (into IB-02). **The hall:** drop through the break onto the shrine; down to the floor; over the pit; up by the ledge, the arch island and the niche island to the balcony. **Back up:** the west ledge, the shrine island, the ledge under the break, then jump up through the break and catch the gallery's lip |
| **Locks seen here** | None new. The lower East door leads on to the Undercroft (not built) |
| **Encounters** | None yet |
| **Art (all the creative lead's, OC1 to OC8)** | Masonry floor and ceiling bands and wall strips (OC1, OC2) on the terrain skin, with OC2's outer corner; the islands and ledges (OC3, OC4); the distant well (OC5) and middle arcades (OC6) as parallax; the hooded statue, braziers, candles, niches, biers, bones, mushrooms, roots (OC8); OC7's dark stone along the bottom and top as foreground |

## Validation

`python3 tools/check_room.py ib05`: longest floor 32 tiles; 83% in runs of 8+;
no small steps, staircases or thin rock; all four doors reached; 100% of the
floor reached with the base kit; no traps.

Walked in the engine (`tests/playtest.gd room=ib05`): the main line
(`mode=tour`) and out the West door into IB-02; the hall (`mode=upper`): onto
the shrine, the floor, over the pit, every island to the balcony, all four
steps back up to the gallery, and out the lower West door into IB-02; the
doors (`mode=doors`) from IB-01 and both of IB-02's East doors. All completed.
Camera: slide 0, wobble 0. IB-01 and IB-02 still pass with the new doors.

## Rough edges

- Against the mockup: no lit doorways with torches, no purple crystal
  clusters (only mushrooms), no arcades standing on the upper gallery; the
  gallery is one straight floor where the mockup's steps up and down.
- Only one of OC2's corners is used (the outer top corner); ceilings and the
  slab's underside corners are plain band ends.
- The pots are the guard's belongings from the old kit.
- The last step back up (from the ledge through the break to the gallery)
  needs a jump straight up and a push toward the lip at the top: a knowledge
  move, not obvious.
