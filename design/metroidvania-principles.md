# Metroidvania Principles (from the creative lead: read fully, follow always)

> These are the creative lead's own words, kept close to how they were
> written. They override any default habit. Every Claude working on Lost Keep
> must read this file in full before designing, building or generating
> anything.

---

## 1. Key Points (very important)

Metroidvanias are all about **exploration and curiosity**. It isn't just
platforms and finding the quickest way to the goal or ability. **Exploration
comes first.**

- **Don't create a ton of platforms to fill space.** Platforms are only used
  **strategically, sparingly and subtly**, so they look natural in the
  environment.
- **Large masses of floor and floating islands** look more natural in the
  environment than 50 tiny platforms. **Create multiple levels with floors,
  not platforms.**
- **Add black-box collision geometry** that the tiles get painted on, creating
  natural shadows.
- **Use parallax and vignette techniques** to create a beautiful environment.
  **Add a parallax camera to the scene.**
- The world should look **natural, real and lived in.**
- The game must look and feel **top-tier, triple-A**. Built in **Godot 4.7.2**.

---

## 2. Things to know and remember about Metroidvanias

A great Metroidvania isn't just a 2D platformer with a big map. It is a
tightly wound clockwork of **spatial memory, mechanical transformation and
controlled friction**. At its heart, the genre is defined by a single rule:
**progression keys are also permanent gameplay verbs.**

### Part 1: The four core pillars

Every standout title in the genre builds its identity by balancing four
foundational pillars. How a designer weights them determines whether the game
feels like an atmospheric labyrinth (Hollow Knight), a kinetic obstacle course
(Ori) or a precision combat gauntlet (Nine Sols).

#### 1. An interconnected, non-linear world (spatial architecture)
Instead of isolated, sequential stages, the world exists as a single cohesive
ecosystem or megastructure, where biomes connect through multiple entry
points, transit hubs and hidden passages.

- **Visual breadcrumbing (show the lock before the key):** in the first 30
  minutes, a good Metroidvania deliberately shows you ledges just out of
  reach, glowing barrier walls you cannot break, and shafts you cannot cross.
  These act as "mental bookmarks" that build anticipation and reward spatial
  awareness.
- **Shortcut folding (intra-zone loops):** as you push deeper into a dangerous
  sector and your healing resources dwindle, the level geometry loops back on
  itself. You kick down a bridge, hack a security door or power an elevator
  that connects directly back to your last save point. Mastering a zone
  physically compresses the time it takes to cross it.

#### 2. Utility-gated progression ("keys that are verbs")
In a traditional adventure game, a brass key opens a brass door and serves no
other purpose. In a Metroidvania, the "key" is a permanent upgrade to the
player's moveset, such as an air dash, double jump, grapple, wall climb or
omni-directional parry.

- **Dual-purpose utility:** every major progression upgrade must work both as
  a **spatial key** (it lets you cross a specific environmental gate) and as a
  **combat/traversal verb** (it changes how you fight enemies and move through
  every room in the game).
- **Soft gates vs hard gates:** hard gates physically require an item in your
  inventory (for example, a charged strike to shatter a reinforced wall). Soft
  gates rely on player knowledge, skill or harsh environmental attrition (for
  example, pogo-bouncing off an enemy's head or parrying a projectile mid-air
  to reach a high ledge early).

#### 3. Expressive traversal and kinetic mastery
Because the genre requires players to revisit earlier sectors, moving from
point A to point B must evolve over the course of the campaign.

- **The friction-to-flow curve:** a corridor that takes 45 seconds of
  cautious jumping and methodical fighting in Act 1 should take 6 seconds of
  chained air-dashes, wall-kicks and grapple vaults in Act 3.
- **Re-contextualised geometry:** old rooms aren't just highways you walk back
  through. New movement abilities let you treat the upper ceilings and hazard
  pits of early zones as high-speed express lanes, turning backtracking into a
  tangible power fantasy.

#### 4. Reactive combat and mechanical gatekeepers
Enemies and bosses are not just health bars blocking a hallway. They are
living skill checks, designed to test your mastery of the game's core
mechanics.

- **Enemies as spatial modifiers:** basic enemies set the rhythm of a room.
  They force you to manage spacing, parry timings, aerial positioning or crowd
  control while you navigate platforming hazards.
- **Bosses as mechanical exams:** major bosses sit at the apex of a biome's
  loop. They either demand mastery of the ability you just found in that
  sector, or guard the transformative upgrade needed to crack open the next
  tier of the world map.

#### How genre benchmarks weight the four pillars

| Game | Primary pillar focus | World topology | Core gating philosophy |
|---|---|---|---|
| **Super Metroid** | Utility-gated exploration and sequence breaking | A deep, looping subterranean labyrinth with hidden destructible tiles | Arsenal and suit upgrades (Morph Ball bombs, Speed Booster, Grapple, Screw Attack) |
| **Hollow Knight** | Interconnected world and non-linear discovery | A sprawling organic web of caverns radiating from a central crossroads | Minimalist movement verbs (Dash, Mantis Claw, Double Jump) plus open boss order |
| **Nine Sols** | Reactive combat (parry and rhythm) and sector folding | Architectural hub-and-spoke transit sectors with Souls-style Root Node shortcuts | Combat-utility hybrids (Tai-Chi Kick, Charged Strike, Unbounded Counter) plus hacking |
| **Ori and the Will of the Wisps** | Expressive traversal and kinetic flow | Wide, flowing natural playgrounds built for continuous momentum | High-velocity momentum chaining (Bash projectile redirection, Burrow, Grapple) |

### Part 2: The core gameplay loop (three nested scales)

A Metroidvania doesn't run on a single flat loop. It runs on three nested
cycles, **micro, meso and macro**, that lock together to create the "just one
more room" compulsion.

#### 1. The micro loop (room to room, 15–60 seconds)
What your hands are doing every second:
- **Read the room:** enter a new screen and instantly parse the terrain
  geometry, hazards and enemy placements.
- **Execute combat and movement verbs:** engage enemies or platforming
  challenges with your current toolkit (parrying telegraphs, spacing attacks,
  vaulting hazards).
- **Manage attrition and harvest:** collect dropped currency and resources
  while weighing your remaining health and healing charges against the risk of
  pushing one room further.

#### 2. The meso loop (the sector circuit, 20–45 minutes)
How you conquer a single biome or district:
- **Anchor at a save node:** establish a safe baseline (bench, root node, save
  station) and bank resources.
- **Push the frontier and spot locks:** venture into uncharted hallways and
  vertical shafts, mentally logging blocked side paths for later.
- **Fold the shortcut:** survive a multi-room gauntlet until you loop back
  around and open a one-way door, bridge or elevator back to your save node,
  permanently banking your spatial progress.
- **Clear the biome apex:** defeat the sector's boss or clear its platforming
  trial to claim the zone's major reward.

#### 3. The macro loop (the progression cycle, 1–3 hours)
The engine that drives the whole campaign:
- **Explore and hit friction (the lock):** explore the open edges of the map
  until every available path is blocked by an insurmountable gate (a gap too
  wide, a sealed barrier, a vertical shaft).
- **Funnel to the viable route:** the map reveals the one remaining unexplored
  branch your current abilities can penetrate, pulling you into a new biome.
- **Survive the crucible and acquire the verb (the key):** deep inside that
  biome, you earn a transformative new movement or combat ability.
- **The sandbox escape (immediate validation):** right after you pick up the
  upgrade, the game locks the door behind you and presents a custom-built
  gauntlet that needs the new ability to escape. This teaches the mechanic
  under pressure before turning you loose.
- **World re-contextualisation (backtracking and opening):** with your new
  verb, you return to the wider world. Old rooms feel faster to cross, optional
  stat upgrades (health, attack power, charm slots) can now be claimed from old
  locks, and the critical path into the next major biome cracks wide open.

---

## 3. Knowledge for designing the world layout

Classic Metroidvanias (Super Metroid, Hollow Knight, Animal Well) use what
designers call a **vertical subterranean labyrinth**, often nicknamed an
**"ant-farm" or "beehive" grid**.

- In an ant-farm map, **gravity is the primary compass**: you start at the
  surface and descend deeper into stacked underground strata.
- **Every biome bleeds into three or four neighbours above and below it**, on a
  single unified grid.

Some sectors use **switchback layering**, also called **pancake stacking** or
**boustrophedon flow** (a term from architecture and classic 2D action games
meaning "turning like an ox ploughing a field"):

- **Stacked horizontal planes:** you fight from left to right across floor 1,
  ride a mechanical lift or climb a short staircase up one storey, then fight
  from right to left across floor 2.
- **Looping back on the same axis.**

---

## 4. How keys are obtained and what kinds exist

**Three sources of keys and abilities:**
1. **Bosses (keepers).**
2. **Ancestral shrines / relic pedestals** (exploration).
3. **Mentor / hub pacts** (narrative and quest unlocks).

**Three types of key in level design:**
1. **Systemic / movement keys** (ability gates).
2. **Hard / literal keys** (item gates).
3. **Knowledge keys** (information gates).

The full registry for Lost Keep is in `design/lock-and-key.md`.

---

## 5. Production order

1. **Environmental assets come before any world building.** Prompt books use
   the layout from the creative lead's MetroidVania repo; nothing else is taken
   from that repo.
2. Then the Godot 4.7.2 project, the black-box test room, and the world.
