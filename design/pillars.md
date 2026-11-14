# Lost Keep — Design Pillars & Production Rules

> Before anything else, read `design/metroidvania-principles.md` in full.

Read this before designing any room, region or asset. It holds the user's
non-negotiables.

## Target
- **Engine:** Godot **4.7.2**.
- **Bar:** top-tier, AAA presentation. The world must look natural, real
  and lived in.
- **Art:** pixel art matching the mockups in
  `docs/art-production/lostkeep-attach/`.

## Exploration first
- A Metroidvania is about **exploration and curiosity**, not the quickest
  path to the goal or the next ability.
- **Platforms are rare, strategic and subtle.** Never fill space with
  platforms. Prefer **large masses of floor**, **multiple storeys made of
  floors**, and **floating islands** that read as natural landforms over
  dozens of small ledges.
- Progression keys are permanent **verbs** (`ability-atlas.md`).

## The four pillars
1. **An interconnected world:** show the lock before the key (visual
   breadcrumbs in the first 30 minutes); shortcut folds back to saves.
2. **Utility-gated progression:** every key is both a spatial key and a
   combat/traversal verb. Hard and soft gates are chosen deliberately.
3. **Expressive traversal:** the friction-to-flow curve. A 45-second Act 1
   corridor becomes a 6-second Act 3 sprint; old ceilings and pits become
   express lanes.
4. **Reactive combat:** enemies shape the space; bosses are mechanical
   exams at the apex of a region's loop.

## The three nested loops
- **Micro (15–60 s):** read the room → act → manage attrition.
- **Meso (20–45 min):** anchor at a save → push and spot locks → fold the
  shortcut → clear the apex.
- **Macro (1–3 h):** hit friction → funnel to the viable route → survive and
  acquire the verb → **sandbox escape** → re-contextualise the world.

## World layout
- An **ant-farm / beehive** grid: gravity is the compass. Strata stack
  Crown → Hearth → Under → Deep → Core (`lock-and-key.md` §6).
- **Switchback (pancake) layering** in some sectors (the Foundry, the
  Spire): stacked horizontal floors that loop back on the same axis.

## How a room is built in Godot
1. **Black-box collision first.** Solid geometry is drawn as black masses
   (`TileMapLayer` "Solid", colour `#0B0812`). It's the skeleton: flat floors
   and ceilings, height from separate masses, few platforms.
2. **Tiles are painted on the black box, and the masses go into shadow.** The
   creative lead's reference is Hollow Knight and Core Keeper: a mass of
   ground is the nearest thing to the camera, so it shadows to black toward its
   centre and **only its edges get art**. Every edge (walking tops, wall faces,
   undersides, corners) is solid along its open edge, lit for a few pixels, then
   steps down into the void colour `#0B0812`; the inside of every mass, piers
   included, is that void. Only walking lines are perfectly straight; faces and
   undersides are organic and stand a few pixels proud of the collision. One
   material per face, never several bands stacked in one space.
3. **Parallax camera:** `Camera2D` plus `Parallax2D` layers, at roughly
   sky 0.05 · far 0.15 · mid 0.35 · back wall 0.7 · **playfield 1.0** ·
   foreground 1.2. The foreground is foreground art (P5) along the room's top
   and bottom edges, close to the camera: it scrolls faster sideways but stays
   in the world vertically, so it never slides when the camera rises or falls,
   and it never stands among the props on a walking line.
4. **Atmosphere:** a screen vignette (a `CanvasLayer` shader), depth fog per
   layer, light shafts, particles, and `PointLight2D` for lanterns
   (`CanvasModulate` darkens the scene). Glows are lights or additive
   sprites, never baked into tiles.
5. **Art comes after the blockout is approved** (the
   `metroidvania-level-design` workflow).

## Technical numbers (measured in Godot)
- Base resolution **640×360**, integer-scaled ×3 to 1080p and ×6 to 4K.
- Tile **16 px**. Kleo is about **28 px** tall (≈1.75 tiles); her collision
  box is 10 × 26 px.
- Asset masters are painted at **×8** (one art pixel = an 8×8 block), then
  reduced with nearest-neighbour and quantised to the palette.

### Kleo's movement envelope
Measured by `tests/playtest.gd mode=measure`. Every gate is designed against
these numbers; if any change, re-run the measure and the room checker.

| Move | Measured | Design rule |
| --- | --- | --- |
| Standing jump (held) | 54 px = **3.37 tiles** | Clears a 3-tile mass, never a 4 |
| Tapped jump | 10 px = 0.65 tiles | |
| Running jump | 100 px = **6.27 tiles** | Gaps up to 5 for the cautious player; gates need 8+ |
| Ledge catch | up to 84 px = **5.25 tiles** above the floor | 4–5 tile walls need a ledge catch; 6+ are gated |
| Ledge catch across | 4 tiles of gap at 4 tiles up | |
| Run speed | 140 px/s = 8.75 tiles/s | |
| Hard landing | falls over 120 px (7.5 tiles) | |
