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
