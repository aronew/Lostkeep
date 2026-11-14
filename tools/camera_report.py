"""How calm is the camera? Reads the per-frame log of a scripted tour.

  drift       frames the view moved while Kleo stood still (the camera moving on its own)
  reversals   times the view changed horizontal direction (swaying)
  slide       frames the view moved faster than Kleo while she ran steadily (the
              whole world sliding past her, as a look-ahead does); should be 0
  ease        frames the view moved slower than her while it eased into motion
  edge brake  at the room's edges, how far Kleo runs while the camera slows from
              her speed to a stop (or speeds up from a stop to her speed): a hard
              stop is a few px, an eased one well over 50
  wobble      frames where Kleo's place on screen shifted while both moved (shimmer)

Usage: python3 tools/camera_report.py game/tests/out/tour/camera.csv [...]
"""
import sys


AVG = 6  # frames: averaging removes the camera's whole-pixel rounding (2, 2, 3 px...)
EDGE = 160  # px from the view's limits: the zone where the room's edge is felt


def report(path):
    room_w = None
    rows = []
    for line in open(path):
        if line.startswith("#room"):
            room_w = float(line.split(",")[1])
        elif line.strip():
            rows.append(list(map(float, line.split(","))))
    drift = reversals = wobble = slide = ease = 0
    view_path = kleo_path = 0.0
    last_dir = 0
    for a, b in zip(rows, rows[1:]):
        kdx, kdy = b[0] - a[0], b[1] - a[1]
        vdx, vdy = b[2] - a[2], b[3] - a[3]
        kmove = abs(kdx) + abs(kdy)
        vmove = abs(vdx) + abs(vdy)
        view_path += vmove
        kleo_path += kmove
        if kmove < 0.05 and vmove >= 0.5:
            drift += 1
        d = (vdx > 0.3) - (vdx < -0.3)
        if d and last_dir and d != last_dir:
            reversals += 1
        if d:
            last_dir = d
        sx_a, sx_b = a[0] - a[2], b[0] - b[2]
        if kmove > 0.05 and vmove > 0.05 and abs(round(sx_b) - round(sx_a)) >= 1 and abs(kdx) < 0.05:
            wobble += 1
    # Speeds averaged over AVG frames.
    kv = [(rows[i + AVG][0] - rows[i][0]) / AVG for i in range(len(rows) - AVG)]
    vv = [(rows[i + AVG][2] - rows[i][2]) / AVG for i in range(len(rows) - AVG)]
    ky = [abs(rows[i + AVG][1] - rows[i][1]) for i in range(len(rows) - AVG)]
    for i in range(len(kv) - 1):
        steady = abs(kv[i + 1] - kv[i]) < 0.05 and ky[i] < 0.5
        centre = rows[i + AVG // 2][2]
        near_edge = room_w is not None and (centre < 320 + EDGE or centre > room_w - 320 - EDGE)
        if steady and abs(kv[i]) > 1.5 and not near_edge:
            if abs(vv[i]) > abs(kv[i]) + 0.25:
                slide += 1
            elif abs(vv[i]) < abs(kv[i]) - 0.25:
                ease += 1
    # Edge braking: per frame, the view's speed as a share of Kleo's (unrounded
    # positions are not logged, so use the 6-frame averages). Find each stretch
    # where she runs steadily near an edge and the share crosses from >= 0.85 to
    # <= 0.15, or back; the braking distance is how far she ran meanwhile.
    brakes = []
    start = None
    for i in range(len(kv)):
        centre = rows[i + AVG // 2][2]
        near_edge = room_w is not None and (centre < 320 + EDGE + 200 or centre > room_w - 320 - EDGE - 200)
        if abs(kv[i]) < 1.5 or not near_edge:
            start = None
            continue
        share = vv[i] / kv[i]
        if share >= 0.85 or share <= 0.15:
            if start is not None and (share >= 0.85) != start[1]:
                # Only stops at the room's edge: the "still" end of the stretch has
                # the view within 12 px of its limit (not the dead zone's start).
                still = rows[i][2] if share <= 0.15 else rows[start[0]][2]
                if room_w is not None and (still < 320 + 12 or still > room_w - 320 - 12):
                    brakes.append(abs(rows[i][0] - rows[start[0]][0]))
            start = (i, share >= 0.85)
    n = len(rows)
    print(f"{path}: {n} frames")
    print(f"  drift (view moves, Kleo still): {drift} frames ({100 * drift / max(n, 1):.0f}%)")
    print(f"  direction reversals of the view: {reversals}")
    print(f"  slide (view faster than Kleo while she runs): {slide} frames")
    print(f"  ease (view slower while it starts to follow): {ease} frames")
    if brakes:
        print(f"  edge brake: {len(brakes)} times, shortest {min(brakes):.0f} px of Kleo's running")
    else:
        print("  edge brake: none in this run")
    print(f"  view travel {view_path:.0f} px vs Kleo travel {kleo_path:.0f} px")
    print(f"  wobble: {wobble} frames")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        report(p)
