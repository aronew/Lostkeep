# Lost Keep

A 2D side-view **Metroidvania** in **Godot 4.7.2**, in premium pixel art. The
bar is top-tier, AAA presentation: the world must look natural, real and
lived in, and every animation must feel amazing, never basic or generic.

The hero is **Kleo of the Ironbark Guard**. One by one her people have gone
missing.

## ⚠ Read first, every time: `design/metroidvania-principles.md`

These are the creative lead's own words and the most important file in the
repo. Read it **in full** before designing, building or generating anything.
It has three parts, and all three are binding:

1. **The key points.** Exploration and curiosity come first. Platforms are
   rare, strategic and subtle. Build with large floor masses, floating islands
   and multiple floors, never dozens of tiny platforms. Black-box collision
   with tiles painted on it gives natural shadows. Use parallax, a parallax
   camera and a vignette. The world must look natural, real and lived in, at a
   top-tier AAA level.
2. **What to know about Metroidvanias.**
   - Progression keys are permanent verbs.
   - The four pillars: an interconnected world (show the lock before the key,
     fold shortcuts back to saves); keys that are verbs (dual-purpose, with
     deliberate hard and soft gates); a friction-to-flow traversal curve; and
     enemies and bosses as mechanical exams.
   - The three nested loops: micro (15–60 s), meso (20–45 min) and macro
     (1–3 h), including the sandbox escape after every new ability.
3. **World layout.** An ant-farm grid where gravity is the compass, and each
   biome touches three or four neighbours above and below. Some sectors use
   switchback, pancake-stacked floors.

When a request conflicts with these principles, follow the principles and say
so.

## Read before working

| File | What it holds |
|---|---|
| `design/metroidvania-principles.md` | **The creative lead's principles: read first, in full** |
| `design/pillars.md` | The non-negotiables and how a room is built in Godot |
| `design/ability-atlas.md` | Every ability and spell: numbers, uses, gate looks, where found |
| `design/lock-and-key.md` | Every lock, key source, item key, knowledge key and shortcut |
| `design/world-and-regions.md` | Lore, peoples, Kindreds, regions, critical path, colour language, gate legend |
| `docs/art-production/*-prompt-book.html` | Copy-ready image prompts (Book 1 Ironbark, Book 2 Kleo) |
| `art/source/ironbark/REVIEW.md` | The state of the first generated art set |
| `design/rooms/` | One spec per built room, with its validation |

The design docs are canon. If you change a decision, update the doc in the
same commit.

---

## The lore

### The world
- **Vaelora**, a world with **three moons**. Their alignment, the **Triad
  Eclipse**, frames its history.
- **The Sovereign Prism** is Vaelora's living crystalline heart and life
  source: the bond between its people and the natural order.

### The mythic past
- **The Oru'Vex**, radiant extradimensional architects, descended during a
  Triad Eclipse and raised the **Spire of the Sovereign Prism** around it.
- **The Schism of Light:** seeking perfection, they tried to burn away their
  flaws in the Prism's core. It fractured, and each of them was cleaved into
  two tethered beings: the rapacious, avian-mantis **Vexari** and the stoic,
  six-limbed **Orun**.
- **Morvath the World-Root**, the thorny, one-eyed embodiment of Vaelora's
  crust and stars, retreated to her **Observatory** and entrusted the world
  to the **Lirien**.

### The peoples
- **Lirien:** graceful, wing-cloaked mortals in **seven Kindreds**. All share
  one ancestry and the ability to **meld memories**. Their wings lie dormant
  (the Vexari's harvesting drains them).
- **Rootlings:** small, round, cheerful humanoids who farm, cook, sing and
  dance in close-knit villages. They are the most innocent people in Vaelora,
  which is why their harvesting must land as horror. **Kleo never kills a
  Rootling.**
- **Vexari:** decaying lords who rule from the Spire as the revered
  "Shepherds of the Prism".
- **Orun:** the Vexari's tethered other halves. Each Vexari is linked to one.

### The Seven Kindreds
| Kindred | People | Region / role |
|---|---|---|
| High-Spire | Aetheri | Scholars. Their **High Voice** leads all the Voices and is manipulated by the Vexari. Vesper's people |
| Ironbark | Vanguard | Martial guardians. **Kleo's people**; home of the Lost Keep |
| Deep-Glow | Lumen | Cave-dwellers who make their own light. Sora's people |
| Tide-Weaver | Nautil | Water folk |
| Fen-Stalker | Mire-Kin | Swamp hunters of the Thornveil forest, scorned as "primitive" |
| Hearth-Plains | Loam-Born | Farmers and silk-growers, neighbours of the Rootlings |
| Dusk-Drifter | Ash-Walker | Wanderers of the ash wastes, masters of fire |

Each Kindred is governed by a **Voice** (a Sovereign Matriarch), and all
answer to the **High Voice**. **The Manufactured Divide:** the Vexari stoke
pride and prejudice between the Kindreds so they never unite or notice their
villagers vanishing.

### The crime: Anima and the Blight-Tide
1. **The Alchemist**, a Vexari, experimented on the Prism and discovered
   **essence extraction**.
2. The Vexari harvest **Anima** (pure resonant life-force) from captive Lirien
   and Rootlings in subterranean **vats** and consume it to stay young.
3. The abuse destabilises the Prism, and the **Blight-Tide** seeps out of it:
   plants twist, animals mutate, creatures are infected, Lirien included.
4. The Vexari try to **weaponise** the Blight, and it becomes a threat to
   everyone, the Vexari too.
5. They build the **Carapax**, shell-forged automatons, to purge rebellion.

### The story
- People keep disappearing from the Ironbark Guard's post. Kleo goes looking.
- The missing are in **cocoons**, in **vats**, or turned by the Blight. Most
  can be **rescued**: each rescue sends someone to **the Refuge** (the hub),
  where they open a service and the Kindreds slowly learn to live together.
- **Sora** (Deep-Glow) and **Vesper** (High-Spire) are among the missing.
  Freeing Vesper triggers the forbidden **memory-meld**, **the Reveal**: the
  "Shepherds" are harvesters. The survivors then rename the hub the
  **Memory-Meld Refuge**.
- Uniting the seven Voices opens the way to the **Sovereign Prism**, where the
  Vexari hold the Prism chained over a bottomless well.
- **The Lost Keep** is the Ironbark Guard's fortress: the first place lost,
  the last place taken back.

### Named characters and bosses
- **Kleo:** young Lirien of the Ironbark Guard, in **short chibi proportions**:
  a big rounded head about half her height, short legs, and plain solid dark
  vertical-rectangle eyes. Navy hair in a long high ponytail, a small brown
  leather jerkin with bronze fastenings, a teal neck accent and a gold collar
  clasp, a short dark cloak lined in red (her folded, dormant wings), a short
  silver sword in her right hand, and a brass lantern at her left hip. She casts
  **teal Anima magic**. Later she wears a wide-brimmed hat and long coat.
- **Sora, Vesper:** allies freed mid-game. **Morvath:** mentor, tests Kleo.
- **Bosses so far:**
  - **The Keep's fallen warden** (an armoured giant on a throne): Ironbark.
  - **The Cinder Warden:** Dusk-Drifter.
  - **The Silk Mother:** Hearth-Plains. Their great silk-spinner, twisted by
    the Blight; she cocoons villagers to "protect" them. **Never call her the
    Spider Matriarch**, even though older mockups do.
  - **The Carapax Prototype:** Carapax Foundry.
  - **The Thornveil Reaper:** Fen-Stalker. A skeleton fused into a tree,
    burning with stolen Anima.
  - **A Vexari Shepherd:** the Sovereign Spire.
  - **The Alchemist:** the Anima Vats.

---

## The game

### Abilities, in order (details in `design/ability-atlas.md`)
| ≈ Time | Ability | Verb | Source |
|---|---|---|---|
| 0:00 | Base kit: run, jump, ledge grab, **4-hit sword combo**, Lantern | | |
| 0:50 | Ironbark Ward | parry, bash | Relic pedestal |
| 1:15 | Anima Spark (spell, orb) | shoot | Shrine |
| 1:40 | Emberwick | burn | Boss |
| 2:30 | Barkgrip | wall cling and jump | Hub pact (the rescued smith) |
| 3:30 | Wing-Cloak | glide | Boss |
| 4:30 | Deep-Glow Breath | swim, dive | Pact (Sora) |
| 5:30 | Memory-Meld | step into the past | Pact (Vesper): the Reveal |
| 6:30 | Thorn-Line | grapple | Shrine (Morvath's Trial) |
| 7:30 | Anima Siphon + Anima Lance (beam) | drain, channel | Boss |

**The four-hit combo:**
1. Swipe left.
2. Swipe right.
3. Overhead.
4. A spinning leap that ends in a slashing slam.

She steps forward with every hit.

### Regions (critical path ≈ 9 h; strata from top to bottom)
1. Ironbark Guard.
2. The Refuge.
3. Dusk-Drifter.
4. Hearth-Plains.
5. Carapax Foundry.
6. Fen-Stalker (Thornveil).
7. Deep-Glow Caverns.
8. Tide-Weaver (optional).
9. High-Spire.
10. Morvath's Observatory.
11. Sovereign Spire.
12. Anima Vats.
13. Orun Sanctum (optional).
14. Sovereign Prism.

### Colour language (canon, never break it)
| Thing | Colour |
|---|---|
| Sovereign Prism and its shards | Icy blue `#9FE6F5` / `#3A7FB0` |
| The Blight (reserved for it alone) | Crimson tendrils `#8E1E3A` / `#C2385A`; magenta veins on the map |
| Anima: Kleo's magic, life-force, vats | Teal `#3FE0C8` |
| Morvath's thorn knots | Pale bark `#B8A58A` with an amber-gold eye; copper on the map. **Never red** |
| Warm safety: lanterns, saves, the Refuge | Amber `#F2B04A` |
| Void: the inside of every solid mass | `#0B0812` |

---

## How to work on it

### Design rules (from `design/pillars.md`)
- **Exploration and curiosity come first.** A Metroidvania is not a race to
  the next ability.
- **Platforms are rare, strategic and subtle.** Build with large masses of
  floor, storeys of floor and natural floating islands, never rows of small
  ledges.
- **Progression keys are permanent verbs.** Show each lock at least three
  times, on at least two routes, before its key. Every region except the last
  plants locks for at least two later abilities.
- Follow the three loops (micro, meso, macro), fold shortcuts back to saves,
  and give every new ability a **sandbox escape** right after it is found.
- The world is an **ant-farm grid**: gravity is the compass. Some sectors use
  switchback, pancake-stacked floors.
- Work **progression first, blockout first, art last.** Get one room approved
  before applying a method widely.
- The `metroidvania-level-design` skill holds the detailed method; use it.

### The Godot project (`game/`)
- **Run it:** open `game/project.godot` in Godot 4.7.2 (the main scene is the
  Ironbark test room). Renderer: GL Compatibility. `godot` is on the path in
  cloud sessions (the environment's setup script installs it to `/opt/godot/`).
- **Controls:** move A/D or arrows; jump Space/Z/K; attack **left click** or X/J;
  interact E/C or up; gamepad too. **Right click** (or V/L, gamepad B) is the
  `spell` action, reserved for Kleo's Anima spells: it does nothing until they
  are built. **Debug:** F1 black-box view, F2 overlay, F3 slow motion,
  F5 restart, H a heavy hit.
- **Layout:**
  - `scripts/player/kleo.gd`: the controller and its tuning.
  - `scripts/world/terrain_skin.gd`: paints art onto the black-box tiles.
  - `scripts/world/`: the room, back walls, the lift, the shrine, the moat,
    practice posts.
  - `scripts/core/`: the `Game` autoload (input, hit-stop, fades, debug) and
    the camera.
  - `scripts/fx/fx.gd`: dust, arcs, sparks.
  - `shaders/`: terrain fill, water, fog, vignette, hit flash.
- **A room is built from a plan.** `game/tools/build_test_room.gd` holds it, in
  tiles: rock rectangles, then spaces carved out, then masses put back,
  materials, the skin's skip regions, props, lights, machines. It saves an
  ordinary scene:
  `godot --headless --path game --script res://tools/build_test_room.gd`.
  Re-running it overwrites the scene, so make lasting changes in the plan, or
  edit the scene by hand and stop rebuilding.
- **The terrain:** two TileMapLayers are the collision (tile atlas column 0 is
  earth, 1 is stone). `Solid` is the rock (floors, walls, ceilings); `Masses`
  holds the masses put back into the spaces (islands, shelves, capstones), so
  each is painted as an object of its own and the floor under it keeps its edge.
  `TerrainSkin` paints shallow bands along every exposed edge (tops, then
  walls, then undersides, then painted corners); each ends in the void along
  its own stones, and wall faces stand a few pixels proud of the collision. The
  inside of every mass is black. Only walking lines are straight. The wall
  bands and corners are cut from the IB5 and K4 kits by `tools/make_terrain.py`,
  which writes their anchors to `terrain/kit_anchors.json` for the builder. Stone walking edges get a pale lip so ledges read. In the
  editor, paint or erase tiles and the skin follows.
- **The foreground:** `Foreground` is a `Parallax2D` at scroll (1.2, 1.0): P5's
  canopy along the room's top edge and its fern tops along the bottom, unlit.
  It sits in the world vertically, so it never slides when the camera rises or
  falls, and it never stands on a walking line among the props.
- **Shadow rule (the creative lead's):** every mass is black inside, piers
  included. Every edge piece is solid along its open edge (no gaps for the
  black box to show through), lit for 12 px, then steps into the black over
  12 px like a shadow: wall bands (`shadow_face`) and corners (`shadow_corner`)
  in `tools/make_terrain.py`, like the floor and ceiling bands.
- **Placed pieces:** one-way platforms are on physics layer 7 (`one_way`); Kleo
  drops through with down + jump. Pots, barrels and crates are `Breakable`
  (one sword hit breaks them into tumbling pieces). Anything Kleo's sword can
  hit has an Area2D on layer 3 whose parent has `take_hit(hit) -> bool`.
- **The camera** (`camera_rig.gd`) never moves on its own and never moves faster
  than Kleo: a small window she moves in (the camera eases into following her),
  **no look-ahead** (a camera that runs ahead slides the whole world past her,
  which the creative lead found nauseating), a fixed height that ignores jumps,
  an eased approach to the room's edges instead of a hard stop, physics-tick
  updates in whole pixels. The room's west and east edges fade into darkness
  (passages leading on). `python3 tools/camera_report.py <camera.csv>` measures
  it: keep `slide` at 0, `wobble` at 0, `edge brake` above 50 px.
- **Hit-stop** (`Game.hitstop`) ends on the real clock, checked every frame, and
  is capped at 0.12 s. Never end a time-scale change from a timer: timers count
  smoothed frame time, so they can finish early and leave the game stuck slow.
  Props pass a lighter `hit_weight`.
- **Test it** (use a virtual display in the cloud):
  - `xvfb-run -a godot --path game --fixed-fps 60 --audio-driver Dummy res://tests/playtest.tscn -- mode=X`
  - `mode=measure`: Kleo's jump, gap and ledge numbers.
  - `mode=shots`: screenshots, with art and as the black box.
  - `mode=tour` and `mode=upper`: the main and upper lines played by script.
  - `mode=props`: breaking props (the game must be back to full speed after),
    the crossbeam and dropping through it.
  - `mode=hitstop`: overlapping hit-stops for 3 s; the game must always recover.
  - `mode=edge`: runs to the room's west edge on both floors and back.
  - Run `props` and `hitstop` **without** `--fixed-fps` (use `--max-fps 60`):
    timing bugs only show with real frame times. `tests/framelog.tscn` logs
    every frame's real time and game speed for profiling.
  - `mode=map`: the whole room plus its collision cells.
  - Then `python3 tools/stitch_map.py` makes the map images and the walked
    routes.
  - Then `python3 tools/check_room.py` checks the blockout rules: floors,
    steps, mass thickness, gates, exits, coverage and traps.
- **Rules for every room:** base resolution 640×360, integer-scaled; a tile is
  16 px; Kleo's measured envelope is in `design/pillars.md`. Black box first;
  the parallax camera (`Parallax2D` sky 0.05, far 0.15, mid 0.35, ruins 0.72,
  playfield 1.0, foreground 1.2); `CanvasModulate`, `PointLight2D`
  lanterns, fog and the vignette. Glows are never baked into tiles.
- **Each room gets a spec** in `design/rooms/`, with its validation.

### Art pipeline
1. **Prompt books:** prompts live in `docs/art-production/*-prompt-book.html`
   (layout copied from the user's MetroidVania repo). Reference images are in
   `docs/art-production/lostkeep-attach/` (A–N).
2. **The user generates sheets.** Unchanged originals go in
   `art/source/<region>/`.
3. **Processing:** `python3 tools/process_art.py <src> <out>` reduces each
   sheet to true pixel scale, snaps the palette and hardens the alpha. Output
   goes to `game/assets/...`. `tools/recolor_prism.py` fixes sheets made with
   the old purple Prism.
4. **Generator IDs vs book IDs:** the user's generator renames IDs. S1–S5 are
   L1–L5, D1–D4 are PR1–PR4, and G1–G4 are GT1–GT4.
5. **Kleo's sprites:** `python3 tools/process_sprites.py art/source/kleo
   game/assets/characters/kleo` makes 64 × 64 frame strips (anchor at x 32,
   y 56; Kleo 28 px tall; one shared palette).
6. **Judge art in the game,** not on its own.

### Open items
- Regenerate G3 and the crown knots of S1, which are still red. Regenerate
  P2 and P5 taller, with transparent skies. (P3 v2, IB5 and K4 are in.)
- **Art requested (Book 1):** the **crypt kit** CR1 to CR3 (back wall; floor
  and arcade; walls, corners and the arcade's two ends), one set in mockup A's
  muted style that replaces K1, K2, K4 and K5 in the crypts (the creative lead:
  the crypt's pieces are mismatched; keep the silk and cocoon). IB6 (earth
  edges and corners drawn into shadow). L6 (the moat bank and bridge end as one
  set piece on the collision: bank at tiles 93-94, span 95-101, walking line
  row 28, water line row 31).
- Not yet used from the kits: IB5's inner corners and its two small islands,
  K4's second arch end and its last corner. **K5** (the crypt arcade at K4's
  scale) is in as `stone_under`: every stone ceiling hangs a colonnade whose
  piers stand on a floor 80 px (five tiles) below, so crypt spaces are five
  tiles tall.
- Mirroring in the skin: a negative width draws the art flipped within
  [x, x + |width|]; a mirrored rect starts at its left end, not at the face.
- Kleo: approve the KL0 model sheet first, then the KL1 idle and KL2 run.
- **The first room awaits approval** (`design/rooms/ironbark_01_lantern_clearing.md`,
  images in `docs/rooms/ironbark_01/`). Don't build more rooms until it is approved.
- Polish noted in the first room: corner caps where tops meet walls; the sky's
  three moons are large (consider regenerating P1 with smaller moons).
- **Textures that tile** are cut with a minimum-error seam
  (`tools/make_terrain.py`), never a dithered crossfade. Bands with a regular
  pattern (arches, carved panels) are cut at a whole number of repeats.
