# Lost Keep

A 2D side-view **Metroidvania** in **Godot 4.7.2**, in premium pixel art. The
bar is top-tier, AAA presentation: the world must look natural, real and
lived in, and every animation must feel amazing, never basic or generic.

The hero is **Kleo of the Ironbark Guard**. One by one her people have gone
missing.

## Read before working

| File | What it holds |
|---|---|
| `design/pillars.md` | The non-negotiables and how a room is built in Godot |
| `design/ability-atlas.md` | Every ability and spell: numbers, uses, gate looks, where found |
| `design/lock-and-key.md` | Every lock, key source, item key, knowledge key and shortcut |
| `design/world-and-regions.md` | Lore, peoples, Kindreds, regions, critical path, colour language, gate legend |
| `docs/art-production/*-prompt-book.html` | Copy-ready image prompts (Book 1 Ironbark, Book 2 Kleo) |
| `art/source/ironbark/REVIEW.md` | The state of the first generated art set |

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
- **Kleo:** young Lirien of the Ironbark Guard. Navy hair in a long high
  ponytail, brown leather jerkin, short dark cloak lined in red (her folded,
  dormant wings), a short sword, a brass lantern at her hip. She casts **teal
  Anima magic**. Later she wears a wide-brimmed hat and long coat.
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

### Building rooms in Godot 4.7.2
- `godot` is on the path (the cloud environment's setup script installs it to
  `/opt/godot/`), so run the project headless to test and screenshot it.
- Base resolution is **640×360**, integer-scaled. A tile is **16 px**. Kleo
  is about **28 px** tall.
- **Black-box collision first:** solid masses in `#0B0812` with flat floors and
  ceilings. Terrain tiles are painted onto them, and each mass's interior fades
  to the void so the box becomes the shadow.
- **Parallax camera:** `Camera2D` plus `Parallax2D` layers at sky 0.05, far
  0.15, mid 0.35, back wall 0.7, playfield 1.0 and foreground 1.3.
- **Light and atmosphere:** `CanvasModulate`, `PointLight2D` lanterns, a
  vignette shader, fog and particles. Glows are never baked into tiles.
- Kleo is an `AnimatedSprite2D` using `SpriteFrames`. The animation table is in
  the Kleo prompt book.

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
5. **Judge art in the game,** not on its own.

### Open items
- Regenerate G3 and the crown knots of S1, which are still red. Regenerate
  P2, P3 and P5 taller, with transparent skies.
- Kleo: approve the KL0 model sheet first, then the KL1 idle and KL2 run.
- Next build: the Godot project and the first Ironbark test room.
