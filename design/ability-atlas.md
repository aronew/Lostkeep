# Lost Keep — Ability Atlas (draft v0.1)

> Progression first: every room in the game is written with these verbs, so
> this document comes before any region or room. All numbers are
> **PROVISIONAL** until the movement feel is locked in-engine; when they
> change, every gate must be re-checked.

## 0. Movement envelope (provisional, in tiles)

| Symbol | Meaning | Proposed |
| --- | --- | --- |
| *tile* | Grid unit | 16 px (pixel-art scale of the mockups) |
| *B* | Kleo's body height | 2 tiles (ponytail has no collision) |
| *J* | Standing jump rise | ~3.5 — clears a 3-tile block, never a 4 |
| *Jr* | Running jump gap | ~6 |
| *Wd* | Ironbark Ward bash-dash | 3 (ground only, no air use) |
| *Gl* | Glide | ~3 tiles across per 1 tile fallen |
| *T* | Thorn-Line reach | 7 (to a Thorn Knot only) |

Every gate below must stay **shut** for a generous (best-skill) player
without its ability and **open** for a cautious player with it.

## 1. Schedule at a glance

| # | Ability | Verb | Found ≈ | From | Region (tentative) |
|---|---|---|---|---|---|
| 0 | Base kit | run, jump, slash, light | 0:00 | — | Ironbark Hollow |
| 1 | **Ironbark Ward** | parry / bash | 0:50 | Captain's shield, Lost Keep gatehouse | Ironbark Hollow |
| 2 | **Emberwick** | burn | 1:40 | Prism-shard shrine | Silkfall Ossuary |
| 3 | **Barkgrip** | cling / wall-jump | 2:30 | Ironbark smith (rescued) | Drowned Aqueducts |
| 4 | **Wing-Cloak** | glide | 3:30 | Wings wake when the first vat is broken | High-Spire Scriptorium |
| 5 | **Deep-Glow Breath** | swim / dive | 4:30 | Sora, freed | Deep-Glow Caverns |
| 6 | **Memory-Meld** | remember (phase into the past) | 5:30 | Vesper, freed; the Reveal | Vat Undercroft |
| 7 | **Thorn-Line** | grapple / pull | 6:30 | Morvath | Morvath's Observatory |
| 8 | **Anima Siphon** | drain / power | 7:30 | Stolen from a Vexari Shepherd | The Spire |

There's a new verb roughly every 50–60 min and no stat-only droughts. Each
region except the last plants visible locks for at least two later
abilities.

---

## 2. Entries

### 0 · Base kit: run, jump, slash, Lantern
- **Lantern (light):** a soft radius that shows footholds in dark rooms, makes
  web-spiders retreat, and pulses near hidden cocoons (the rescue targets).
- **Rescue verb (always on):** interact with a cocoon you can open to free a
  Lirien, who returns to the hub.
- **Gate look it establishes:** *silver silk walls and sealed cocoons* (seen
  from minute 5 and opened by Emberwick). This is the first "I'll come back".

### 1 · Ironbark Ward (parry + bash-dash)
- **Verb:** parry; bash.
- **Numbers:** parry window ~8 frames; bash-dash 3 tiles on the ground with
  0.6 s cooldown; breaks **bark-plate** and **Carapax plating**; a parried shot
  returns at 1.5× speed.
- **Vocabulary (≥4):**
  1. Break cracked bark-plate walls and floors (gate).
  2. Parry a projectile into a **crystal switch** you can't reach.
  3. Bash counterweights and pendulums to start machines.
  4. Bash-dash through crumbling floor tiles to drop into secrets.
  5. Parry the hazard a turret fires back into its own shell.
- **Gate look:** a pale plate scored with a rune-shaped crack.
- **Combat:** the core defensive verb. It cracks armored Carapax open,
  staggers skeleton spearmen (mockup 5), and parries spit from
  web-spiders.
- **Combines with:** Emberwick (a parried ember ignites a far brazier);
  Glide (parry mid-air to refresh the glide); Thorn-Line (pull a shield off,
  then bash).
- **Trivialises:** nothing in traversal. Parry-cheese risk on early
  bosses, so tune boss patterns with unparryable tells.
- **Bypass:** **Hard.** Plates have collision until broken.
- **Found:** the Lost Keep gatehouse armory, where her missing captain's
  shield hangs. The want: three plated walls in Ironbark Hollow beforehand.
- **Stage 5 idea:** parry a falling cocoon's swing to send it across a gap
  as a bridge.

### 2 · Emberwick (Lantern ignite)
- **Verb:** burn.
- **Numbers:** a 4-tile flame cone; draws on the teal (Anima) bar; burns
  silk in 0.5 s; lights braziers; fire spreads along connected silk.
- **Vocabulary:**
  1. Burn silk walls (the gate from minute 5).
  2. Cut the strand of a **hanging cocoon**: it drops and becomes a platform,
     or is opened to rescue someone.
  3. Burn a web **lattice** so the floor drops away (descent routes).
  4. Light braziers that open shrine doors and make **heat updrafts** (dormant
     until Wing-Cloak, a planted combo).
  5. A chain reaction: light one strand and it burns through a web network,
     opening a room-wide route.
- **Gate look:** silver silk sheets with glowing eggs at the corners
  (mockup 3).
- **Combat:** ignites webs mid-fight. In the **Spider Matriarch** arena, the
  ceiling webs she climbs to can be burned away, which forces her down to the
  floor.
- **Combines with:** Ward (parried embers); Glide (updraft columns); Deep-Glow
  (can't burn underwater, so silk below the waterline is a later puzzle).
- **Trivialises:** Lantern-only dark rooms (they're brighter now). Design
  them knowing this.
- **Bypass:** **Hard** for silk walls. **Soft** for some cocoon drops
  (a skilled player can slash a strand from a precise jump).
- **Found:** the Prism-shard shrine (mockup 5) deep in Silkfall Ossuary. The
  ability arrives inside the problem it solves: the rest of the Ossuary is
  built for fire.
- **Story:** the cocoons hold the **missing Lirien**. The Matriarch is a
  Vexari-bred collector that harvests them for the vats. Killing her frees the
  great cocoon (mockup 3's skull nest), and the first big rescue, **the
  merchant**, opens the hub shop.
- **Stage 5 idea:** burn a cocoon's strand while a spider rides it down, which
  turns an enemy into an elevator.

### 3 · Barkgrip (wall cling + wall-jump)
- **Verb:** cling; climb.
- **Numbers:** cling slides at 1 tile/s on stone and holds still on wood or
  root. A wall-jump gains ~2.5 tiles of height away from the wall. Can't cling
  to silk, slime, or Prism crystal.
- **Vocabulary:** vertical shafts become roads; wall-jump between two pillars;
  cling to dodge ground shockwaves in arenas; reach high secrets; chimney
  climbs mixed with Ward-broken plates.
- **Gate look:** a tall, smooth shaft with a ledge visible above *J*.
- **Combat:** wall perches, and plunging attacks off a wall.
- **Combines with:** Emberwick (burn silk off a wall to make it grippable);
  Glide (wall-jump → glide = long diagonal travel).
- **Trivialises:** vertical drops and lift puzzles. Every elevator after this
  needs a second job.
- **Bypass:** **Soft.** Pogo-slashing off spiders can reach some ledges, and
  that's treated as a reward.
- **Found:** made by the **Ironbark smith** you rescue in the Aqueducts.
  Your first ability *made by your own people*, the hub paying off.

### 4 · Wing-Cloak (glide)
- **Verb:** glide; ride wind.
- **Numbers:** hold jump to glide (~3:1). Updrafts lift Kleo 1 tile per
  0.3 s. Blight mist cancels the glide.
- **Vocabulary:** wide chasms; heat updrafts from lit braziers (planted in
  ability 2); falling-water and steam vents in the Aqueducts; glide under
  descending crushers; long aerial secrets.
- **Gate look:** a gap beyond *Jr* with a **torn banner fluttering** over it,
  which shows wind or the possibility of flight.
- **Combat:** hover over ground attacks; glide-slash.
- **Combines with:** Emberwick (fire = lift); Barkgrip; Thorn-Line (swing →
  glide).
- **Trivialises:** many early pits and drop puzzles. Protect key early
  rooms with low ceilings.
- **Bypass:** **Hard** on chasms (gap > the generous *Jr* + 2).
- **Story:** Lirien wings are dormant because the Vexari siphon Anima from
  everyone. When Kleo breaks her first vat, a pulse of returned Anima wakes
  her cloak. This is the first hint of what the vats are.

### 5 · Deep-Glow Breath (swim + dive)
- **Verb:** dive; swim.
- **Numbers:** free swim with no air timer in clear water. **Blackwater**
  (Blight-tainted) still hurts. A dive-dash of 4 tiles underwater.
- **Vocabulary:** flooded aqueduct passages (mockups 1–2 already show them);
  underwater secrets beneath the hub; current puzzles; raise or lower water
  with sluice machines to change whole rooms; underwater fights with the
  axolotl-like creatures.
- **Gate look:** deep water with **no glow**. Before this ability, Kleo
  bobs to the surface and can't go under.
- **Combat:** underwater combat, plus surface-ambush lunges.
- **Combines with:** Emberwick (no fire below, so you must surface to burn);
  Memory-Meld (the old water level in the past).
- **Trivialises:** surface lily-pad hopping.
- **Bypass:** **Hard.**
- **Found:** **Sora** is freed in the Deep-Glow Caverns and teaches it. The
  second ally.

### 6 · Memory-Meld (step into the past)
- **Verb:** remember.
- **Numbers:** hold for up to 3 s to shift the room to how it looked
  **before the fall**. Echo platforms gain collision and present-day walls
  lose it. Draws on the Anima bar. Cooldown 1 s.
- **Vocabulary:** echo bridges over chasms; walls that didn't exist yet;
  past water levels; **ghost wisps** (mockup 2) are echoes of missing
  Lirien who guide you to hidden cocoons; read memories at crime scenes
  (lore).
- **Gate look:** a **faint teal outline** of broken architecture, flickering.
- **Combat:** phase through an attack (a short i-frame window), and see a
  Vexari's tethered Orun half.
- **Combines with:** everything. This is the late-game puzzle verb (state
  puzzles: shift mid-glide, or swap the water level mid-swim).
- **Trivialises:** some silk and plate gates (they didn't exist in the past).
  Decide per gate which era it exists in.
- **Bypass:** **Hard.**
- **Story / Reveal:** freeing **Vesper** triggers the forbidden memory-meld.
  Kleo sees the harvesting chambers, and the "Shepherds of the Prism" are
  exposed. Sets up the whole second half.

### 7 · Thorn-Line (grapple)
- **Verb:** grapple; pull.
- **Numbers:** fires at a Thorn Knot within 7 tiles and pulls Kleo there.
  It can also pull light objects and shields toward her.
- **Vocabulary:** swinging across Thorn Knot chains; pull a cocoon down from
  out of reach; rip shields off Carapax; drag a counterweight or bridge;
  yank a spider off a wall.
- **Gate look:** a **red thorn knot with one closed eye** (the red vines in
  mockup 5 are its early, dormant form).
- **Combat:** a gap-closer, a shield-stripper, and a pull on small enemies.
- **Combines with:** Glide (swing-release-glide), Ward (strip then bash),
  Meld (anchors that exist only in the past).
- **Bypass:** **Hard.**
- **Found:** from **Morvath**, who tests Kleo in her Observatory. The red
  roots from minute 1 are her watching.

### 8 · Anima Siphon (drain + power)
- **Verb:** drain; give.
- **Numbers:** a 3-tile tether. Draining heals and fills the Anima bar.
  Giving powers Oru'Vex machinery.
- **Vocabulary:** power dead Spire lifts and doors; drain Blight crystals
  (the purple growths in mockup 5) to clear Blightwater and Blight mist;
  restore withered hub plants; drain enemies to heal.
- **Gate look:** a **dark Prism crystal socket** (present from region 1).
- **Combat:** a sustain/drain tether.
- **Moral weight:** it's Vexari tech. Overuse leaves visible corruption on
  Kleo and changes the ending, mirroring the Vexari's own fall.
- **Bypass:** **Hard.**
- **Found:** taken from the first Vexari Shepherd she defeats in the Spire.

---

## 3. Gate looks (keep these for the whole game)

| Ability | Look |
|---|---|
| Ironbark Ward | Pale plate with a rune-shaped crack |
| Emberwick | Silver silk sheet / sealed cocoon |
| Barkgrip | Smooth shaft, a lip visible above jump height |
| Wing-Cloak | Chasm with a fluttering torn banner |
| Deep-Glow | Dark, unlit deep water |
| Memory-Meld | Flickering teal outline of a past structure |
| Thorn-Line | Red thorn knot with a closed eye |
| Anima Siphon | Empty dark-Prism socket |

## 4. Rescue tie-in (hub services)

Abilities and rescues are linked: some abilities come *from* rescued
people (Barkgrip from the smith, Breath from Sora, Meld from Vesper). Most
cocoons are optional, and each fills a stall in the hub (merchant,
map-maker, smith, healer, lore-keeper, cartographer of secrets). The number
rescued could affect the ending.

## 5. Open items

- [ ] Confirm the engine and lock the movement numbers in a test room.
- [ ] Macro map: place three locks per ability on two routes before each key.
- [ ] Decide which era (present or past) every gate exists in, for Meld.
- [ ] Decide whether Anima Siphon's corruption is a real branch or flavor.
- [ ] Spider Matriarch: a 2-phase spec (ceiling phase, burned → floor phase).
