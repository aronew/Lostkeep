# Kleo Book 2: review of the first generated set

All 28 sheets are here unchanged, with the generator's QA (`generator_QA.csv`,
`generator_README.txt`). Game-ready strips are in `game/assets/characters/kleo/`,
made by `tools/process_sprites.py`. Each is a horizontal strip of 64 × 64 frames:
the anchor is at x 32, y 56, Kleo is 28 px tall, and all strips share one palette.

The generator kept the approved chibi reference (a big head, short legs, solid
vertical-rectangle eyes). That reference is now canon, and the book and
CLAUDE.md are updated to match it.

| Status | Sheets |
|---|---|
| Good base | idle, run, start/stop/turn, combo 1–4, directional strikes, Ward, Spark, Lance, Emberwick, swim, wing-cloak, death, heal/rest, rescue, all FX |
| Weak against the brief | ledge (the hang and pull-up don't read against a ledge); wall (no clear contact with a wall); damage (the heavy knockback is mild); idle (almost static: needs more breathing and ponytail life) |
| To push for the AAA bar | the combo needs stronger anticipation holds, bigger smears and more forward lunge; the finisher spin is the best of the set |

Next: load the strips into Godot and judge them in the test room at game
speed, with hit-stop and FX, before regenerating anything.

## Round 2 (revised sheets)

The eight redo sheets replace their first versions, which are kept in `v1/`.
`generator_QA_v2.csv` is the generator's report.

- **Idle** sways clearly now. **Long idle:** only the yawn (frames 1–8) is
  used; the sap-gum bubble was cut by the creative lead because it grew too big.
- **Ledge:** grab, hang, a handstand on the edge, and a roll onto her feet.
  The key-green ledge is removed in processing. Hanging frames are pinned by
  her hands at y 6; frames on the ledge top are pinned to the anchor.
- **Wall:** she grips the key-green wall (removed in processing).
- **Combo hits 1–3:** big crescent smears, deep lunges and held wind-ups.
- **Knockback:** launched off her feet, then skids back with a hand down.

Processing now scales every sheet by the area of Kleo's hair, which stays
steady across poses, so all 24 animations match in size.
