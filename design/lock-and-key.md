# Lost Keep — Lock-and-Key Registry (draft v0.1)

Companion to `ability-atlas.md` and `world-and-regions.md`. Every coloured
bar on the macro map ends up as one row in this file. Positions are given
relative to the macro map mockup (`docs/art-production/lostkeep-attach/G-macro-map.jpg`)
until the map exists as a grid. Then each lock gets a room ID.

**Hard** = must hold against the best-skill player without the key.
**Soft** = skill, knowledge or attrition may pass it early, and that is
treated as a reward.

---

## 1. How keys are obtained (three sources)

| Source | What it feels like | Rules |
|---|---|---|
| **Boss (Keeper)** | The apex of a region's loop: a mechanical exam | The boss tests the verb the region taught; the key it guards opens the next tier. The arena doors seal, so a **sandbox escape** follows at once |
| **Ancestral Shrine / Relic Pedestal** | Exploration pays off: found, not given | Always deep, behind a climb, puzzle or secret; never on the obvious path. The shrine room *is* the first safe test of the ability |
| **Mentor / Hub Pact** | Narrative: someone you saved gives back | Earned by a rescue or quest, granted at the Refuge or on the spot. Proves the rescue loop feeds progression, not just shops |

### The eight movement keys by source

| # | Ability | Source | Giver / place | Sandbox escape (immediate validation) |
|---|---|---|---|---|
| 1 | Ironbark Ward | **Shrine/Pedestal** | The captain's shield on the Ironbark Reliquary pedestal, in the Lost Keep's flooded armory | The armory's floor collapses: bash through three bark-plate floors to drop out, while Carapax scouts fire shots you must parry |
| 2 | Emberwick | **Boss** | The Cinder Warden, a Blight-twisted Dusk-Drifter guardian of the forge | Silk flood: the forge's exit is wrapped shut; burn a chain of silk to escape before the spiders arrive |
| 3 | Barkgrip | **Hub Pact** | The Ironbark smith, rescued from a Hearth-Plains cocoon; forged at the Refuge anvil | The Refuge well: a smooth chimney under the camp, climbed out to the camp roof |
| 4 | Wing-Cloak | **Boss** | The Carapax Prototype guarding the first vat. Smashing the vat returns Anima, and Kleo's wings wake | The vat hall floods with Blight mist; glide across the collapsing vat gantry |
| 5 | Deep-Glow Breath | **Hub Pact** | Sora, freed in the Deep-Glow Caverns, teaches it beside the glow-pool | The cave mouth seals; the only way out is down through the pool and along a lit underwater tunnel |
| 6 | Memory-Meld | **Hub Pact** (story) | Vesper, freed in the High-Spire; the forbidden meld (**the Reveal**) | The Scriptorium burns in the present; walk out through its past, where the floors still stand |
| 7 | Thorn-Line | **Shrine** | Morvath's Trial: a wordless exploration puzzle in the Observatory, no fight | The Observatory dome opens; swing out across the Thorn Knots of the outer ring |
| 8 | Anima Siphon | **Boss** | A Vexari Shepherd at the Sovereign Spire | The Spire lift loses power; siphon Anima from Blight crystals to run it back up |

Mix: 3 bosses, 2 shrines, 3 pacts. No two consecutive abilities come from
the same kind of source.

---

## 2. The three types of key

### A. Systemic / movement keys (ability gates)
The eight abilities above. They're permanent verbs, each a spatial key
**and** a combat/traversal verb (see the atlas). They make up most gates.

### B. Hard / literal keys (item gates)
Used sparingly. Each one is a physical object with a story reason, opens a
small number of doors, and is shown before it's found.

| Key | Found | Opens | Type | Why it exists |
|---|---|---|---|---|
| **Warden's Seal-Ring** | The Keep's fallen warden (Ironbark boss) | The Lost Keep's inner keep doors (2) → the Ironbark shortcut lift to the Refuge | Hard | Turns the opening region's loop into a shortcut |
| **Granary Key** | A Rootling elder's house (Hearth-Plains, behind silk) | The sealed granary, which holds Rootling survivors and a health shard | Soft (a Ward-breakable back wall exists late) | Rootling warmth; teaches "the people are hidden, not gone" |
| **Foundry Sigil-Plates** ×3 | Three Carapax overseers in the Foundry | The Foundry's central furnace door | Hard | A meso loop that sends you across the whole Foundry |
| **Vat Seals** ×3 | One each in the Foundry, the Spire and the Deep-Glow (the Alchemist's labs) | The Anima Vats core, to the Alchemist | Hard | Ties three late regions to the vats |
| **Voice Sigils** ×7 | Given by each Kindred Voice once convinced (story gates) | The Sovereign Prism, only once all seven are united | Hard (story) | The Manufactured Divide undone, as an object |
| **Tether-Shard** | Hidden in Orun Sanctum | The Orun choice in the final fights | Optional | The true ending |
| **Lift Crank** ×n | Various | Dead lifts that become shortcuts | Soft | Shortcut folding, with "every machine has a lever" |

### C. Knowledge keys (information gates)
Nothing goes into the inventory; the *player* learns something. They're
always hinted in-world and never needed on the critical path without a
fallback.

| Knowledge | Where it's learned | What it opens |
|---|---|---|
| **The Rootling harvest song** (a 4-note lantern pattern) | Sung by Rootlings at the Refuge kitchen once three are rescued | Rootling root-doors across the west: flash the Lantern in the song's rhythm |
| **The Triad Eclipse mural** | A shrine mural in Ironbark showing the three moons in a sequence | Moon-dial doors in the High-Spire and the Spire: set the dials to the eclipse |
| **Vexari glyphs** | Vesper teaches the cipher after the Reveal | Spire inscriptions that point to hidden rooms and false walls |
| **Morvath's star chart** | The Observatory ceiling | The order of Thorn Knots in a late secret |
| **Draft and moss tells** | Taught once, early: moss grows where air flows | False walls everywhere: the game's secret language |
| **Tide timing** | Tide-Weaver fishermen's chant | Tidal passages that are open only at low water |
| **Memory echoes** | Ghost wisps (Memory-Meld) replay where a missing person hid something | Cocoon caches, hidden rescues |

---

## 3. Lock registry, by ability

The rule for every ability: its lock is **met at least three times, on at
least two routes, before the key**, and **no route reaches the key without
passing a lock**. Returns must pay off (a room, a shortcut, an upgrade, a
rescue or a truth).

### 1 · Ironbark Ward: bronze bar, cracked-shield icon
| ID | Region | Where (map) | Hard/Soft | Seen before key? | Return pays |
|---|---|---|---|---|---|
| W1 | Ironbark | The first descent, under the great tree: a cracked plate floor | Hard | ✔ min ~5 | A shortcut back to the start lantern |
| W2 | Ironbark **IB-02** | The Old Crypt: a plated door across the west gallery (upper line) | Hard | ✔ | The Refuge road, a health shard and a warden's journal |
| W3 | Ironbark | The keep wall beside the bridge (lower route) | Hard | ✔ | The route to the armory, where the key is |
| W1b | Ironbark **IB-05** | The Shrine Hall: the pit in the lower floor has a cracked bark-plate floor, motes rising through the cracks and a faint light below | Hard | ✔ | A shaft down into the Undercroft, stepping down on wall ledges that take turns on each wall: a shortcut into its depths, and the way back up |
| W4 | Refuge | A plated hatch under the camp | Hard | — | The Refuge cellar: the map-maker rescue |
| W5 | Dusk-Drifter | Carapax-plated shutters | Hard | — | The critical path into the forge |

### 2 · Emberwick: orange-red bar, flame icon
| ID | Region | Where | H/S | Before key? | Return pays |
|---|---|---|---|---|---|
| E1 | Ironbark | A silk-wrapped side tunnel near the graveyard, with a cocoon visible behind it | Hard | ✔ min ~5, the first want | The first rescue (a Rootling child) |
| E2 | Ironbark **IB-02** | The Old Crypt: a cocoon hung over the gap by the west gallery's mouth (the strand can't be cut) | Soft | ✔ | A rescue |
| E3 | Refuge | Silk over the east gate | Hard | ✔ | The route to the Hearth-Plains |
| E4 | Dusk-Drifter | Webbed vents in the forge's upper halls | Hard | ✔ | A forge loop back to the save |
| E5 | Hearth-Plains | The whole region (silk farms) | Hard | — | The critical path |

### 3 · Barkgrip: moss-green bar, claw icon
| ID | Region | Where | H/S | Before key? | Return pays |
|---|---|---|---|---|---|
| B1 | Ironbark | The keep's tall well-shaft, a lip visible above jump height | Hard | ✔ | The keep's battlements: a lore room and a wing upgrade hint |
| B1b | Ironbark **IB-02** | The Old Crypt: the Root Well's mouth, far above any jump, moonlight coming down it. Also the cave's wall up to the west gallery | Hard | ✔ | The Guard Post from below; a way back up the loop |
| B1c | Ironbark **IB-06** | The Undercroft: a passage high in the root chamber's east wall, 17 tiles of sheer wall below it | Hard | ✔ | A way on under the moat toward the Keep's walls |
| B2 | Dusk-Drifter | The ash chimneys | Hard | ✔ | A secret forge and a charm |
| B3 | Hearth-Plains | The silo tower beside the Silk Mother arena | Hard | ✔ | A bypass shortcut |
| B4 | Refuge | The camp's chimney under the well | Hard | (it's the sandbox) | — |
| B5 | Carapax Foundry | Smooth furnace stacks | Hard | — | The critical path |

### 4 · Wing-Cloak: sky-white bar, feather icon
| ID | Region | Where | H/S | Before key? | Return pays |
|---|---|---|---|---|---|
| G1 | Ironbark | The broken arch bridge with its centre fallen, a torn banner over the gap | Hard | ✔ | The far bank: an express lane over the graveyard |
| G1b | Ironbark **IB-04** | The Gate Road: a far chunk high over the road's end, something glinting on it, out of reach from every island | Hard | ✔ | A relic |
| G2 | Hearth-Plains | The wind-mill gorge | Hard | ✔ | Rootling village outskirts: a rescue |
| G3 | Dusk-Drifter | Heat updrafts from braziers lit with Emberwick, with nothing to ride them yet | Hard | ✔ (a planted combo) | A sky route over the forge |
| G4 | Fen-Stalker | The swamp's canopy chasm | Hard | — | The critical path west |

### 5 · Deep-Glow Breath: teal bar, droplet icon
| ID | Region | Where | H/S | Before key? | Return pays |
|---|---|---|---|---|---|
| D1 | Ironbark **IB-01** | The moat under the keep bridge: dark water, a glint below | Hard | ✔ | A sunken reliquary: a lore room |
| D1b | Ironbark **IB-02** | The Old Crypt: the cistern and its flooded gallery, a glint deep inside | Hard | ✔ | A drowned burial: a relic |
| D1c | Ironbark **IB-06** | The Undercroft: the sump in the cistern walk's floor, dark water going on down, a glint in it | Hard | ✔ | A flooded way down under the clearing |
| D2 | Refuge | The flooded undercroft under the camp | Hard | ✔ | The undercroft shortcut to the Vats |
| D3 | Fen-Stalker | Deep fen pools | Hard | ✔ | Mire-Kin rescues |
| D4 | Tide-Weaver | The whole region | Hard | — | Return region |

### 6 · Memory-Meld: pale-violet bar, spiral-eye icon
| ID | Region | Where | H/S | Before key? | Return pays |
|---|---|---|---|---|---|
| M1 | Ironbark | The Lantern shows a flickering teal outline of a fallen walkway in the keep hall | Hard | ✔ | A past-era room: the night the guard vanished (a lore beat) |
| M2 | Hearth-Plains | A Rootling home burned out; its past is intact | Hard | ✔ | A hidden cocoon |
| M3 | Deep-Glow | An echo bridge over an abyss | Hard | ✔ | A deep secret |
| M4 | Foundry | Walls that didn't exist before the Vexari | Hard | ✔ | A bypass |
| M5 | High-Spire | Critical path after the Reveal | Hard | — | — |

### 7 · Thorn-Line: copper bar, thorn-knot icon
| ID | Region | Where | H/S | Before key? | Return pays |
|---|---|---|---|---|---|
| T1 | Ironbark | Closed-eyed bark knots on the great tree's crown (Morvath watching from minute 1) | Hard | ✔ | The tree's crown: a vista of the Spire and a Voice beat |
| T2 | Hearth-Plains | Knots over the silk-farm ravine | Hard | ✔ | A secret |
| T3 | Fen-Stalker | Knot chains across the bog | Hard | ✔ | The Observatory back door, a loop |
| T4 | Tide-Weaver | Knots over the tide gate | Hard | ✔ | A Tide-Weaver rescue |
| T5 | Sovereign Spire | Critical path | Hard | — | — |

### 8 · Anima Siphon: prism-gold bar, socket icon
| ID | Region | Where | H/S | Before key? | Return pays |
|---|---|---|---|---|---|
| S1 | Ironbark **IB-01** | A dark Prism socket in the shrine (mockup 5) | Hard | ✔ | A pre-fall memory and a health shard |
| S1b | Ironbark **IB-02** | The Old Crypt: an empty Prism socket in the hidden vault | Hard | ✔ | The vault's inner door |
| S2 | Refuge | A dead Oru'Vex lift in the camp | Hard | ✔ | A lift to the Spire: a late fast route |
| S3 | Foundry | Dead machinery | Hard | ✔ | The Foundry loop closes |
| S4 | Deep-Glow / Tide-Weaver | Blight crystal clogs | Hard | ✔ | Blightwater drained from returning regions |
| S5 | Anima Vats | Critical path | Hard | — | — |

### Story gates: silver bar, Voice sigil
| ID | Where | Opens when |
|---|---|---|
| V1 | Refuge → High-Spire | Hearth-Plains + Dusk-Drifter Voices convinced (the High-Spire won't receive an Ironbark guard otherwise) |
| V2 | Sovereign Prism | All seven Voice Sigils united |

### The Blight: crimson tendrils, a state, not a key
Blight veins spread at **act 2** (after the Reveal) and **act 3** (after the
Siphon), re-routing earlier regions. Anima Siphon drains Blight crystals,
so the Blight is both a new lock and its own key.

---

## 4. Region view: what each region plants and receives

| Region | Locks it plants (later abilities) | Returns it receives |
|---|---|---|
| Ironbark Guard | Emberwick, Barkgrip, Glide, Breath, Meld, Thorn-Line, Siphon | Every ability (the opening is the richest region to revisit: the friction-to-flow showcase) |
| Refuge | Ward, Emberwick, Barkgrip, Breath, Siphon | Hub upgrades with each rescue |
| Dusk-Drifter | Barkgrip, Glide | Barkgrip, Glide, Siphon |
| Hearth-Plains | Glide, Meld, Thorn-Line | Glide, Meld, Thorn-Line |
| Carapax Foundry | Meld, Siphon | Meld, Siphon |
| Fen-Stalker | Breath, Thorn-Line | Breath, Thorn-Line |
| Deep-Glow | Meld, Siphon | Meld, Siphon |
| Tide-Weaver | Thorn-Line, Siphon | Thorn-Line, Siphon |
| High-Spire | Thorn-Line, Siphon | Thorn-Line, Siphon |
| Observatory | Siphon | Siphon |

Every region except the last plants at least two later abilities. ✔

---

## 5. Shortcut folds (meso loop, one or more per region)

| Region | Fold |
|---|---|
| Ironbark | The **Warden's Seal-Ring** opens the inner keep lift: the boss arena connects back to the first lantern save |
| Refuge | The undercroft hatch (Ward) drops into the start of the Vats route |
| Dusk-Drifter | Kick a slag bridge down from the far side, back to the forge save |
| Hearth-Plains | Burn the silo's silk bridge free, and it swings back to the village save |
| Foundry | The sigil-plate furnace door opens a cargo lift to the Refuge east gate |
| Fen-Stalker | Thorn-Line back door to the Observatory |
| Deep-Glow | Drain the cavern (sluice) to reveal a dry path back to the save |
| High-Spire | Moon-dial elevator (knowledge key) |

---

## 6. World layout: ant-farm strata

Gravity is the compass. The macro map already has the Spire at the top and
the Prism at the bottom; organise the regions into **strata** so that
descending means going deeper into the truth:

| Stratum | Regions | Feel |
|---|---|---|
| **Crown** (surface and sky) | Ironbark canopy, Morvath's Observatory, the Spire's peak, High-Spire | Open sky, the three moons, wind |
| **Hearth** (ground level) | Ironbark Guard, the Refuge, Hearth-Plains, Dusk-Drifter | Lived in: villages, forges, camps |
| **Under** | Fen-Stalker, Carapax Foundry, Tide-Weaver | Industry and rot, water |
| **Deep** | Deep-Glow Caverns, Anima Vats | Darkness, glow, horror |
| **Core** | Orun Sanctum, Sovereign Prism | The source |

- Each region touches three or four neighbours **above and below**, not just
  to the side.
- **Switchback (pancake) layering** suits the **Carapax Foundry** (assembly
  floors, left→right then right→left, joined by cargo lifts) and the
  **Sovereign Spire** (an ascending spiral of stacked halls).

## 7. Validation (to do once rooms exist)
- [ ] Every row above has a room ID.
- [ ] A walk with base moves reaches W1–W3, E1–E2, G1, D1, M1, T1 and S1
      inside Ironbark (the region shows 7 locks for later abilities).
- [ ] No route reaches any key without passing its lock first.
- [ ] Every hard gate holds against the generous player model.
