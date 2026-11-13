# Ironbark Book 1: review of the first generated set

All 25 sheets are here unchanged (`*.png`), with the generator's own QA
(`generator_QA.csv`). Game-ready versions are in
`game/assets/environment/ironbark/`, made by `tools/process_art.py`.
That script reduces each sheet to true pixel scale, snaps it to a palette and
makes its alpha hard.

The generator's IDs differ from the book: S1–S5 = L1–L5 (landmarks),
D1–D4 = PR1–PR4 (props), G1–G4 = GT1–GT4 (gates).

| Status | Sheets |
|---|---|
| Usable now | IB1, IB2, IB4, K1, K2, K3, P1, P4, S2, S4, S5, D1–D4, G1, G2 |
| Fixed in processing | S3, G4 (the purple Prism recoloured to icy blue) |
| Regenerate | G3 (red knot: it must be pale bark with an amber eye), S1 (its crown knots are red: same fix) |
| Regenerate taller | P3, P2, P5: delivered at 3:1, so they are only 256 px tall in game against a 360 px screen. P3 also has an opaque sky band that shows a hard top edge |
| Check | IB3: the corner pieces are usable, but the wall face is not a straight edge. IB2: a visible seam where the band repeats every 384 px |
