"""How calm is the camera? Reads the per-frame log of a scripted tour.

  drift      frames the view moved while Kleo stood still (the camera moving on its own)
  reversals  times the view changed horizontal direction (swaying)
  sway       px the view travelled beyond what Kleo travelled
  wobble     frames where Kleo's place on screen shifted while both moved (shimmer)

Usage: python3 tools/camera_report.py game/tests/out/tour/camera.csv [...]
"""
import sys


def report(path):
    rows = [list(map(float, l.split(","))) for l in open(path) if l.strip()]
    drift = reversals = wobble = 0
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
    n = len(rows)
    print(f"{path}: {n} frames")
    print(f"  drift (view moves, Kleo still): {drift} frames ({100 * drift / n:.0f}%)")
    print(f"  direction reversals of the view: {reversals}")
    print(f"  view travel {view_path:.0f} px vs Kleo travel {kleo_path:.0f} px (sway {max(0.0, view_path - kleo_path):.0f} px)")
    print(f"  wobble: {wobble} frames")


if __name__ == "__main__":
    for p in sys.argv[1:]:
        report(p)
