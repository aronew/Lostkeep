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
- **Platforms are rare, strategic and subtle.** Build with a mixture of
  large masses of floor (storeys of floor), large floating islands and
  platforms. What is ruled out is filling a room with dozens of platforms to
  cover space (the creative lead: "don't put 50 platforms in a room to get to
  fill in space"), not platforms themselves; the character mockups
  (`docs/mockups/character/`) show the mix.
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
- **Run it:** open `game/project.godot` in Godot 4.7.2 (the main scene is
  IB-03, the Ruin Gardens; then IB-04, the Gate Road; then IB-01, the Lantern
  Clearing, whose hall door leads into IB-05, the Shrine Hall, and on into
  IB-02, the Old Crypt). Renderer: GL Compatibility. `godot` is on the path in
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
    practice posts, room exits (`room_exit.gd`), false walls (`secret_cover.gd`).
  - `scripts/core/`: the `Game` autoload (input, hit-stop, fades, debug, room
    changes, flags) and the camera.
  - `scripts/fx/fx.gd`: dust, arcs, sparks.
  - `shaders/`: terrain fill, water, fog, vignette, hit flash.
- **A room is built from a plan,** in tiles: rock rectangles, then spaces
  carved out, then masses put back, materials, the skin's skip regions, props,
  lights, machines. `game/tools/room_builder.gd` is the shared base (the
  tileset, materials, back walls, terrain, and helpers: `_door`, `_lift`,
  `_water`, `_breakable`, `_light`, `_fog`, `_edge_shades`); each room has its
  own builder on top of it, holding its plan and its dressing:
  `build_test_room.gd` (IB-01), `build_ib02.gd` (IB-02), and `build_ib03.gd`
  and `build_ib04.gd` (the surface rooms, on `surface_builder.gd`), and
  `build_ib05.gd` (the Shrine Hall), `build_ib06.gd` (the Undercroft) and
  `build_ib07.gd` (the Pit Shaft). Each saves an
  ordinary scene:
  `godot --headless --path game --script res://tools/build_ib02.gd`.
  Re-running it overwrites the scene, so make lasting changes in the plan, or
  edit the scene by hand and stop rebuilding. A new room is a new builder that
  extends `room_builder.gd`: copy `build_ib02.gd`.
- **Rooms join at doors.** `_door(name, rect, side, target_scene, target_door)`
  makes a marker under `Doors` (where Kleo arrives, facing in) and a `RoomExit`
  strip at the room's edge. Walking into the strip calls `Game.go_to`, which
  fades, changes the scene and places her at the named door. Neighbouring rooms
  share one world grid: a door's rows in one room are its rows in the other,
  offset by the rooms' positions (each spec gives its room's origin).
- **What a room remembers** goes in `Game.flags` (a freed lift, a woken shrine,
  a found secret): give the machine a `flag` name and it restores itself when
  the room is entered again. F5 clears them. There is no save file yet.
- **Secrets:** a false wall (`_false_wall(name, hide, face_x, rows, faces, flag)`
  in `room_builder.gd`, script `secret_cover.gd`) has no collision: Kleo walks
  straight through, and once she is inside it fades for good (`flag`). It
  carries a copy of the rock layer with the hidden room filled in and a second
  terrain skin that paints it, clipped to the wall round the room, so from
  outside the room's own stone, bands and dark run on unbroken (the creative
  lead: "something that looks like a wall but has no collision ... a fake black
  silhouette wall too"). Always give it a tell (`_draught`: motes drifting into
  the stone; moss) and a reward. Secrets so far: IB-02's vault, IB-05 behind
  the hall's west wall (off its ledge), IB-06 behind L2's and L4's west walls,
  IB-07 at the foot of the west wall. `mode=secrets` walks into every one.
- **Resin, the currency** (a stand-in name and sprite, `tools/make_resin.py`;
  the creative lead asked for currency to reward curiosity): beads that hang
  and bob, drift to Kleo when she is near, and add to `Game.currency`, shown by
  the counter at the top left (it appears with the first bead). Placed with
  `_pickup(parent, pos, value, flag)` or `_resin_cache(parent, x0, x1, floor_y,
  count, flag)`; each bead's flag keeps it taken. F5 clears the count with the
  flags. To be spent at the Refuge (not built). 24 beads so far, all in secrets.
- **The terrain:** two TileMapLayers are the collision (tile atlas column 0 is
  earth, 1 is stone). `Solid` is the rock (floors, walls, ceilings); `Masses`
  holds the masses put back into the spaces (islands, shelves, capstones), so
  each is painted as an object of its own and the floor under it keeps its edge.
  `TerrainSkin` paints shallow bands along every exposed edge (tops, then
  walls, then undersides, then painted corners); each ends in the void along
  its own stones, and wall faces stand a few pixels proud of the collision. The
  inside of every mass is black. Only walking lines are straight. Earth's wall
  band and corners are cut from IB6 (painted into shadow); all crypt stone (floor, ceiling arcade,
  walls, corners, the arcade's open end, the back wall) from the crypt kit CR1
  to CR3, tinted toward the region's plum (`crypt_kit()`, `CRYPT_TINT`). Both by
  `tools/make_terrain.py`, which writes their anchors to
  `terrain/kit_anchors.json` for the builder. Stone walking edges get a pale lip so ledges read. In the
  editor, paint or erase tiles and the skin follows.
- **The foreground, in two value steps** (the creative lead: "2 layers of
  foreground, one not all the way silhouetted and one full silhouette"):
  `Foreground` (the mid step, scroll 1.15 to 1.2) is the room's own art
  darkened to about half value and tinted toward its mood, its form still
  showing (surface: P5's canopy and ferns; crypts: roots and ivy along the top,
  crystals, rubble and a broken pillar along the bottom); `ForegroundNear`
  (scroll 1.5) is sparse pure-black silhouettes in thin shapes (a branch,
  vines, grass; long roots, rubble, a great pillar). Never big blobs: a big
  black shape reads as a hole. Both frame the screen (scroll y 0): they slide
  sideways faster than the room but hold their height on screen, so a tall
  room has them on every floor and they never slide up or down when the
  camera changes floors. `_build_foreground()` in `surface_builder.gd`,
  `_crypt_foreground()` in `room_builder.gd`. IB-01 keeps its own. Comparison:
  `docs/rooms/foreground_two_steps.png`.
- **Shadow rule (the creative lead's, after Hollow Knight and Core Keeper):** a
  mass is the nearest thing to the camera, so it shadows to black toward its
  centre and only its edges get art. Every mass is black inside, piers
  included. Every edge piece is solid along its open edge (no gaps for the
  black box to show through), lit for a few pixels, then steps into the black:
  wall bands (`shadow_face`, 12 + 12 px), corners (`shadow_corner`), and floor
  and ceiling bands (`crust`, lit 8 px then stepping down) in
  `tools/make_terrain.py`.
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
  - **Other rooms:** add `room=ib02` (output goes to `tests/out/ib02/<mode>/`).
    IB-02's lines are `mode=tour` (main line, hoist, out the door) and
    `mode=west` (the upper line, the secret, the loop, the cistern);
    `mode=doors` walks IB-01 → IB-02 → IB-01. `stitch_map.py ib02` and
    `check_room.py ib02` take the room's name. A new room needs an entry in
    `ROOMS` in `tests/playtest.gd` and `tools/check_room.py` (its spawn, lift,
    water, gates and exits), its scripted lines, and its routes in
    `stitch_map.py`.
  - IB-03 and IB-04 (`room=ib03`, `room=ib04`): `mode=tour` (the main line
    and out the East door), `mode=upper` (the optional lines and the ways
    back) and `mode=doors` (IB-01, IB-04 and IB-03).
    `python3 tools/blockout_map.py ib03` draws a labelled black-box map with
    the walked routes, for blockout reviews (the in-game box view is too dark
    to read in a picture).
  - After any change to shared code (the builder, Kleo, the camera, `Game`),
    run IB-01's modes again as well: both rooms must keep passing.
- **Rules for every room:** base resolution 640×360, integer-scaled; a tile is
  16 px; Kleo's measured envelope is in `design/pillars.md`. Black box first;
  the parallax camera (`Parallax2D` sky 0.05, far 0.15, mid 0.35, ruins 0.72,
  playfield 1.0, foreground 1.2); `CanvasModulate`, `PointLight2D`
  lanterns, fog and the vignette. Glows are never baked into tiles.
- **Each room gets a spec** in `design/rooms/`, with its validation.

### Art pipeline
1. **Prompt books:** prompts live in `docs/art-production/*-prompt-book.html`
   (layout copied from the user's MetroidVania repo). Reference images are in
   `docs/art-production/lostkeep-attach/` (A to Z).
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
- **The Ironbark surface: two rooms built, awaiting the creative lead's
  review.** The game opens in **IB-03, the Ruin Gardens** (a climb: a hill of
  terraces, the great graveyard island, a log, the cliff's arch) and goes on
  through **IB-04, the Gate Road** (wind back down a hill under the islands,
  the road, then a long pool with two ways over it: six small islands to hop,
  or the big floating islands above) into IB-01, which the creative lead
  calls the guard post. Specs: `design/rooms/ironbark_03_ruin_gardens.md`,
  `ironbark_04_gate_road.md`; images in `docs/rooms/`.
  - **What the creative lead wants here** (their words and reviews):
    - The look of their "Moonlit" mockups (`docs/mockups/ironbark_surface/`):
      plum boulder terrain, **large floating islands**, IB-01's purple sky,
      moons and teal forest. They rejected the SF kit's bluer colours, SF9's
      twisted trunk, badly cut stairs, and a first IB-03 (bridge, hill, chapel)
      that "looks nothing like the mockup".
    - These rooms are "to learn movement, get the feel for the game, do some
      jumps, maybe a chill enemy or two".
  - **Their art for it** is in `art/source/ironbark/islands/` (seven painted
    islands and a cliff atlas, as generated at 8x), reduced 8:1 with nothing
    else done to `game/assets/environment/ironbark/island_*.png` and
    `cliffs_and_ruins.png`. The atlas holds two stair flights, two arch doors,
    a crystal shrine, a timber gate, a lantern post, two corner silhouettes and
    three terrace slabs (the slabs and the five-step flight are not used yet).
  - **How a surface room is built** (`game/tools/surface_builder.gd`, on
    `room_builder.gd`): `_surface_begin` / `_surface_finish` give IB-01's
    backdrops, darkness, moonlight, canopy and corner silhouettes. A painted
    island is `_island(kind, tile_x, row, tiles)` over a one-tile mass in the
    plan (also in SKIP; `_hide_island_tiles()` hides the tiles, the box view
    shows them). Stairs are `_flight(edge_x, foot_y, down_east)`: the
    eight-step painting over a slope, three tiles up in 68 px. `_log` is a
    one-way timber. The checker can't see non-tile collision: list logs and
    island tiles under `seals`, and each flight as a `lift` pair.
  - **Floating islands on a path sit at different heights** (the creative
    lead: "so it doesn't feel so straight"), and they like the big graveyard
    island: vary the levels around the big pieces, don't swap them for small ones.
  - **Small islands over water are allowed where the jump is the lesson**
    (the creative lead asked for them in IB-04's pool). Space them for her real
    jump, about 95 px long from a standing run-up: roughly 56 px of gap and
    48 px to land on. Closer than that and a full jump overshoots.
  - **The first enemy is in: the Mossback** (`scripts/world/mossback.gd`,
    placed with `_mossback(x, floor_y, left_x, right_x)`): the creative lead
    asked for "a chill enemy or two" that "take like 7 hits to kill". It walks
    between two x positions on a flat floor (no physics body), rests, never
    chases, shoves Kleo on contact (`kleo.hurt`, she has no health yet), and
    dies on the seventh sword hit (`hits_to_kill`). Two in each surface room.
    Its sprite is a stand-in from `tools/make_mossback.py`. Test:
    `room=ib03 mode=enemy` (run it with `--max-fps 60` too).
  - **Next for these rooms:** a generated Mossback sheet, pickups for the
    cave and the shrine island, and a tree of the surface's own (both rooms
    borrow IB-01's Great Ironbark). SF9 to SF13 are no longer used anywhere
    except a few tinted graves-and-ruins pieces; mockups R to W and the SF
    cards in Book 1 are superseded by the Moonlit mockups for this area.
- Regenerate G3 and the crown knots of S1, which are still red. Regenerate
  P2 and P5 taller, with transparent skies. (P3 v2, IB5 and K4 are in.)
- **The crypt kit is in** (CR1 to CR3, the generator's painted originals,
  tinted toward the region's plum: the creative lead's pick over the old crypt
  and the kit as painted). It replaces K1, K2, K4 and K5 in the crypts. Its
  arcade is 101 px from crown to pier foot, so in a five-tile crypt the piers
  stand on the floor and the crowns rise 21 px into the slab's shadow. Take art
  only as the generator made it, never pre-processed: a first export, rebuilt
  by another tool and snapped to the hex codes, was rejected.
- **IB6 and L6 are in.** IB6 gives earth its wall band and outer corners. L6 (the
  moat bank and the bridge's west end, one painting) is placed by its own
  anchors (`bridge_bank()` in `tools/make_terrain.py`): its walking line on row
  28, its first water arch at the moat (x 95), its piers run on down to the bed,
  and its bank goes into the black along its boulders. The bank (x 91-94) is
  earth again. The east span is still the old L4 sheet.
- Not yet used: IB6's inner corners and pillar top (the skin places outer
  corners only); IB5's two small islands; CR3's inner corners, its second outer corner and the arcade's end against a wall. Every
  stone ceiling hangs the crypt arcade, whose piers stand on a floor 80 px (five
  tiles) below, so crypt spaces are five tiles tall.
- Mirroring in the skin: a negative width draws the art flipped within
  [x, x + |width|]; a mirrored rect starts at its left end, not at the face.
- Kleo: approve the KL0 model sheet first, then the KL1 idle and KL2 run.
- **IB-01 is approved. IB-02, the Old Crypt, is built and awaits review**
  (`design/rooms/ironbark_02_old_crypt.md`, images in `docs/rooms/ironbark_02/`).
  It is the first labyrinth room: stacked galleries beside a central well,
  after the creative lead's labyrinth mockups (`docs/mockups/labyrinths/`).
  Those mockups guide the large shape of a sector (a well, strata, loops,
  pockets); where they show ladders or rows of small platforms, the principles
  win: drops, islands, and a machine for the long climb.
- **Two blockouts await the creative lead's review (second pass):** the first
  pass of both was rejected ("the undercroft room is poorly designed"; "make
  the vertical shaft one look just like my far left mockup"; "I shouldn't be
  able to get into that room until I get that slam"). Both now follow the
  creative lead's vertical-level mockups (`docs/mockups/undercroft/vertical_levels.webp`):
  **IB-06, the Undercroft** (`design/rooms/ironbark_06_undercroft.md`, origin
  (0, 40), 44 x 72), after the middle one: cellar rooms stacked down both sides
  of a tall void, crossed side to side on the way down, a root arch, a basin,
  a lift from the bottom-right room back to the top; and **IB-07, the Pit
  Shaft** (`ironbark_07_pit_shaft.md`, origin (-44, 64), 44 x 64), after the
  far-left one, mass by mass, entered only with the Ward: the cracked plate
  above (W1b) or the bark plate in the Undercroft's bottom-left room (W1c).
  **Floating platforms are painted pieces, never floor:** a floating ledge or
  plate is SH4's art (`_platform(parent, spec, tile_x, row, tiles, flip)` with
  `SH4_PLATE_A/B/C`, `SH4_BROKEN_LEDGE`, `SH4_WALL_LEDGE`, `SH4_ARCH_ISLAND` in
  `room_builder.gd`) over a one-tile mass that is also in SKIP and in the
  checker's `seals` (the creative lead: "why are the floating islands and
  platforms ... just floor tiles"). Floors that run out into a void (the
  Undercroft's lips, the Pit Shaft's walkway) stay terrain.
  **Every gap meant for dropping through is 2 tiles wide:** Kleo runs straight
  over a 1-tile gap (the checker thinks she can drop through one; she can't).
  Both: `room=ib06` / `room=ib07` with `mode=tour`, `upper`, `shots`, `map`
  (IB-06 also `doors`); `check_room.py` and `blockout_map.py` take their names.
  A tall shaft fails the checker's floor-run and small-step rules by design.
  `tools/world_map.py` draws every room on the world grid
  (`docs/maps/where_we_are.png`).
- **Rooms not built yet:** the Keep's foundations (east of the Undercroft's
  lower East door: next on the main line), the Refuge road (west of IB-02,
  behind the plated door: needs the Ward), the Guard Post above IB-02's well
  (the surface rooms lie over the crypt instead). All end in darkness today.
- **The Old Crypt's first section is built as IB-05, the Shrine Hall, and
  awaits review** (`design/rooms/ironbark_05_shrine_hall.md`, images in
  `docs/rooms/ironbark_05/`), after the creative lead's mockup
  `docs/mockups/old_crypt/old-crypt-first-section.jpg` ("exactly how I want
  that first section of the Old Crypt to look") and their kit OC1 to OC8
  (`art/source/ironbark/crypt_oc/`, reduced 8:1 / 4:1 with nothing else done
  by `tools/make_crypt_oc.py` to `game/assets/environment/ironbark/oc_*.png`
  and the `terrain/oc_*` bands). It sits between IB-01's hall door and IB-02,
  whose origin moved to IB-01's (-170, 28). Its pale masonry is a third terrain
  material. **IB-02 now uses the same SH stone** (the creative lead asked for
  it): `_use_shrine_stone()` and `_shrine_far()` in `room_builder.gd` give any
  room the SH masonry and the SH8 backdrop. IB-02's well is stone too; only its
  root cave stays earth. **Colour:** the backdrop is graded toward the mockup's
  dark slate (`SHRINE_FAR_TINT`), not SH8's brighter blue: the creative lead
  found it "so much bluer than the mockup". Compare against the mockup's
  measured background (about #373A55) before changing it. **Then the creative
  lead asked for moodier colour and more depth** (after a reference of a ruin
  hall in purple above and deep teal below, `docs/rooms/ironbark_05/depth_before_after.png`):
  `_shrine_far()` now builds six layers behind the playfield (SH8 far hall,
  teal mist, OC6 arcades twice at 0.32 and 0.58, mist, SH7 ruins in dark
  silhouette at 0.78) under a multiply grade (`Mood`, purple at the room's top,
  teal at its bottom: `MOOD_TOP`, `MOOD_BOTTOM`); `_crypt_foreground()` adds
  OC7's dark rock (the nearer pillars and roots, blown up from SH and P5 art,
  read as holes and were taken out until FG1 and FG2 arrive). The
  surface rooms got the same idea: `ForegroundNear` in `surface_builder.gd`,
  P5's ferns and a branch enlarged as silhouettes at 1.45.
  **The SH stone's inside is masonry, not void** (the creative lead: tiles
  "don't connect correctly" at the joins): `tools/make_crypt_sh.py` cuts the
  void off SH1 and SH2's bands along their blocks (pixels darker than 40 go
  clear) and makes `sh_fill.png` from SH1's lit blocks; the material fades it
  over 4 tiles. Thin slabs are solid stone and joins have no black notches;
  deep rock still goes dark. This departs from the earth's shadow rule on
  purpose: the crypt mockup fills its masses with blocks.
  **No straight seams inside a slab** (the creative lead: "a hard cut line, not
  blending into the shadow"): the floor band's lit bricks are broken off below,
  and the ceiling band's above, block by block (`ragged_top`/`ragged_bottom` in
  `make_crypt_sh.py`, shaded at the break); `sh_fill` is cut only from SH1's
  evenly lit courses (rows 13 to 28), never its cap row or darker tail; and the
  fill shader nudges each fade step per 8 x 4 block so steps follow the
  masonry. Check thin slabs (4 tiles) after any change to the stone.
  **Stone colour:** graded toward reference Y (the creative lead: "too bright";
  Y's stone "goes into the black ... at a slight darker color"):
  `STONE_GRADE` (0.82, 0.76, 0.74) multiplies the terrain, placed islands and
  props in both crypt rooms (`_grade_stone()`), so lit faces measure about
  (72, 70, 87) as in Y; `sh_fill` is darkened to Y's plum-grey masonry (about
  #2F283D) and fades over 5 tiles. Comparison: `docs/rooms/ironbark_05/stone_vs_reference_y.png`.
  **The crypt terrain is now the CY stone** (the creative lead's chunky brick
  after reference Y, about 11 x 5 px; they tried the finer brick in a scene and
  rejected it): CY1 (floor and ceiling), CY2 (wall, outer floor corner) and
  CY2b (outer ceiling corner), clean 8x exports in `art/source/ironbark/crypt_y/`,
  cut by `tools/make_crypt_cy.py` into `terrain/cy_*` (material `terrain_cy.tres`,
  `_use_crypt_y_stone()` in `room_builder.gd`, used by IB-02 and IB-05). The
  SH paragraphs above describe the stone it replaced; the SH islands, shrine
  and props stay. Its bands fade into the dark brick by brick themselves, so
  the inside of a mass is the void (fade 0, no masonry fill) and the terrain
  is not graded (`_grade_stone()` skips it; islands and props still are).
  **Thin slabs** (under 5 tiles): the wall band's and the corners' inward
  fades would paint dark alcoves over the bands' lit bricks, so a material's
  `thin_wall_depth` (12 for CY: the quoin column) limits walls and corners
  there to their face stones, and each corner to its band's share of the
  slab. Materials without it (earth, SH) draw as before.
  **Inner corners** (the creative lead: "these corners look weird", where a
  slab's ceiling met a wall below it and the wall's quoins ran on up into the
  slab): a material can carry painted `inner_under` (a ceiling running into a
  wall) and `inner_top` (a floor running into a wall rising from it), each
  painted with its wall on the left of the notch and mirrored for the other
  side. With them, walls stop at the line instead of running past it. CY's come
  from CY2b's and CY2's right cells, cut across the whole stone side so their
  own fades reach the dark (anchors (59, 48) and (64, 48)). They are placed
  only where the wall runs at least 3 tiles (`INNER_WALL`): on a one-tile step
  the inner floor corner's wall stood up into the air (the creative lead: "this
  looks a bit odd"), so steps keep the outer corner, wall foot and head.
  **Light along the edges, dark inside** (the creative lead circled a step and
  a pillar that "looks weird"): CY2's corners and wall fade into the dark
  faster than CY1's bands, and walls are drawn over floors, so with a
  `thin_wall_depth` material (CY) the skin draws only the face stones (a) for
  outer corners, always (their turn of quoins); (b) for walls within 3 tiles of
  a floor or ceiling line; (c) for short faces (steps under 3 tiles). The
  bands' lit bricks show there, and the wall's fade only below them. Beside a
  step down of one or two tiles, the lower floor's band runs on under the first
  3 tiles of the upper one (`_step_drop`), so both fade out at one depth.
  **CY4 and CY5** are kept in `art/source/ironbark/crypt_y/` but not used:
  CY5's ledges were tried in IB-05 and rejected ("just the ledges don't look
  good"; IB-05's plates, ledges and wall ledges stay SH4's), CY4's arcade and
  pier too ("look bad"). Kept for later: CY4's stairs and CY5's broken slab
  ends. Book 1 asks again: CY4b (the arcade and pier after Y's) and CY5's
  ledges (wedges of broken masonry, not flat bars).
  **Next for the crypts' look:** foreground
  depth in value steps, as in Y and Hollow Knight: the playfield (1.0), near
  rubble at about 70 % value (1.12), nearer rubble at about 45 % (1.25), then
  the black silhouette (1.4). FG5 is the rubble, painted at full value so the
  game darkens copies to each step; FG1 and FG2 are the silhouettes.
  **The fade rule** (the creative lead, pointing at broken slabs in a generated
  CY set): stone fades into the dark gradually, brick by brick, lavender grey
  to dusky plum to near-black plum to void, loose bricks at the edge; never a
  straight light/dark line, a flat black slab or a hard cut. It is `FADE_RULE`
  in Book 1 (in every CY card) and CY6 is a set of big masses built on it.
  Judge every new terrain sheet by it.
  - **Its layout follows the mockup piece by piece** (second layout, after the
    creative lead said the first "looks very different from the mockup"):
    `docs/rooms/ironbark_05/layout_vs_mockup.png`. **It now wears the creative
    lead's SH1 to SH8** (`art/source/ironbark/shrine_hall/`, brought in by
    `tools/make_crypt_sh.py` to `sh_*.png` and `terrain/sh_*`; material
    `terrain_sh.tres` made in `build_ib05.gd`). The OC kit is no longer used
    in IB-05 except OC7's foreground and OC8's bier and bones.
  - **Small ledges stand beside what they lead to, never over it:** a one-tile
    ledge above an island or floor she jumps from bumps her head (found in
    IB-05's first layout).
- **Art the Old Crypt wants** (older list) is in Book 1 as OC1 to OC8 (floor and ceiling,
  walls and corners, islands, ledges, far and mid backdrops, foreground, props),
  styled on mockups O, P and Q in `lostkeep-attach/`.
- **The detail pass** (the creative lead: "hanging things on ceilings", "so many
  90 degree corners", "the stone is a little too bright", "2 layers on the floor
  level"): `_room_detail()` in `room_builder.gd`, run by `_finish()` in any room
  whose foreground set `_detail_kind`, hangs SH flora roots and ivy under ceilings
  and corner ivy off floor ends (chosen by a cell hash, never in skip regions,
  secrets or the room's edge tiles), and stands darkened pieces along floors
  (`FloorMid`, the mid step). The floor's black near step waits for art (CH8):
  the blown-up placeholders read as spiky blobs. `CY_GRADE` darkens the CY
  terrain. Image: `docs/rooms/detail_pass.png`.
- **Character mockups** (`docs/mockups/character/`, ten of them; the creative
  lead: "they have so much character to the level"): no bare right angle. Slabs
  taper into hanging stone with moss off them, floors stand on columns, corbels
  and arches, edges step course by course, every top carries something, alcoves
  are rooms inside the room, and the room sits in a rounded cobble cave wound
  with roots. Book 1's CH1 to CH8 ask for those pieces (CH1 replaces the plates,
  lips and walkway the creative lead called weird). Their crimson roots are the
  Blight's colour, so the cards ask for dull roots. Their floating slabs are
  welcome: they sit in the mix with the large masses and islands.
- **Mood test** (the creative lead's moody fog reference,
  `docs/mockups/mood/moody_fog_reference.webp`: "maybe an idea for another
  place"): `tools/mood_test.gd` loads a built room and saves a copy sunk into a
  teal murk (`MURK` CanvasModulate, a haze over the backdrops, ground fog along
  every floor run behind and in front of Kleo, a low bank in the drops, a fog
  bank across the bottom of the view, warm lights up and cold ones down, a
  deeper vignette). `scenes/tests/mood_ib05.tscn` is IB-05 in it; pictures in
  `docs/rooms/mood_test/` (taken with `tests/mood_shot.gd`). Not applied to any
  room by the tool. The fog shader's `side_fade` softens a band's ends.
  **IB-05 now wears it as its own look** (the creative lead: "I like that look
  instead of so bright"; `docs/mockups/mood/shrine_hall_moody.webp`): a room
  sets `_mood = true` and `_finish()` calls `_moody()` in `room_builder.gd`
  (`MOOD_*` constants). Other rooms can switch it on once IB-05 is approved.
  Don't run `mood_test.gd` on IB-05: it would double the fog.
- IB-02 has no enemies yet; its long gallery and cave are shaped for them (the
  Mossback is a surface creature).
- Polish noted in the first room: corner caps where tops meet walls; the sky's
  three moons are large (consider regenerating P1 with smaller moons).
- **Textures that tile** are cut with a minimum-error seam
  (`tools/make_terrain.py`), never a dithered crossfade. Bands with a regular
  pattern (arches, carved panels) are cut at a whole number of repeats.
