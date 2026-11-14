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
| Regenerate taller | P3, P2, P5: delivered at 3:1, so they are only 256 px tall in game against a 360 px screen. P3's canopy runs off its top edge, so its trees have no crowns (hidden by haze in game for now; P3 v2 in Book 1 asks for whole crowns on a 16:9 canvas). P5 is replaced for now by silhouettes built from the flora sheets (`tools/make_silhouettes.py`) |
| Check | IB2: a visible seam where the band repeats every 384 px |
| Replace | IB3: its wall band grows ferns, mushrooms and moss ledges out of the rock, which reads as clutter on short faces, and its face is not straight. No longer used: the earth wall is made from IB2's soil. Regenerate as IB5 (Book 1) |
| In (third set) | K5 (`K5.png`): the crypt arcade at K4's scale, three arches per strip; it replaces K2's arcade band |
| In (second set) | IB5 (`IB5.png`): face band, four corners and two small islands; used: the face band and the outer top and ceiling corners. K4 (`K4.png`, variant `K4-alt.png`): face band (its straight inner edge is crusted in processing), outer top corner; the arch ends are about twice the K2 arcade's scale, so they wait. P3 v2 (`P3.png`, variant `P3-alt.png`; the first version is `P3-v1.png`): whole crowns, now the mid layer |
