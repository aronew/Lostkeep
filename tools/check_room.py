"""Measure a room's blockout against the rules, and walk it with a movement model.

Reads the collision cells exported by `playtest mode=map` (cells.json) and the
room's annotations below. Prints the rules met or broken. Numbers are tiles.

Usage: python3 tools/check_room.py [ib01|ib02|ib03]
"""
import json
import sys
from collections import deque

# Kleo's measured envelope (tests/playtest.gd mode=measure), cautious model.
JUMP_UP = 3       # standing jump clears 3 tiles (rises 3.37)
LEDGE_UP = 5      # a ledge up to 5.25 tiles can be caught
GAP = 5           # running jump clears 6.27 tiles; cautious 5
BODY = 2          # tiles of headroom she needs

# Each room's annotations (tiles). A standing spot is the cell Kleo's feet are
# in: the row above the floor.
#   spawn  where she starts
#   lift   pairs of spots a lift links, both ways
#   water  x, y, w, h: falling in returns her to safe ground
#   gated  places that must stay shut with the base kit
#   seals  cells that are solid until something opens them (silk, a plated
#          door, a jammed lift's deck)
#   exits  spots that must be reached
ROOMS = {
    "ib01": {
        "cells": "game/tests/out/map/cells.json",
        "spawn": (14, 23),
        "lift": [((24, 23), (24, 36)), ((25, 23), (25, 36)), ((26, 23), (26, 36)), ((27, 23), (27, 36))],
        "water": (95, 31, 25, 6),
        "gated": {
            "far bank (Wing-Cloak, G1)": (113, 20, 25, 8),
            "sealed pocket (Emberwick, E1)": (88, 32, 3, 5),
        },
        "seals": [(86, 32, 2, 5)],
        "exits": {"west upper (to the Guard Post)": (0, 23), "west lower (to the Old Crypt)": (0, 36)},
    },
    "ib02": {
        "cells": "game/tests/out/ib02/map/cells.json",
        "spawn": (109, 9),
        "lift": [((x, 9), (x, 27)) for x in range(96, 100)],
        "water": (41, 33, 49, 4),
        "gated": {"west gallery past the plated door (Ironbark Ward, W2)": (0, 11, 16, 5)},
        # The plated door, and the hoist's deck jammed at its head.
        "seals": [(16, 11, 2, 5), (96, 10, 4, 1)],
        "exits": {"east upper (to the Lantern Clearing)": (111, 9), "east lower (to the Undercroft)": (111, 27)},
    },
    "ib03": {
        "cells": "game/tests/out/ib03/map/cells.json",
        "spawn": (14, 24),
        "lift": [],
        "water": (76, 37, 4, 2),
        "gated": {"far island past the branch (Wing-Cloak)": (97, 10, 10, 8)},
        # The well's lid (Ironbark Ward).
        "seals": [(47, 33, 8, 1)],
        "exits": {"east (to the Lantern Clearing)": (111, 36), "west (the forest road)": (0, 24)},
    },
}
ROOM = ROOMS[sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] in ROOMS else "ib01"]
SPAWN, LIFT, WATER = ROOM["spawn"], ROOM["lift"], ROOM["water"]
GATED, SEALS, EXITS = ROOM["gated"], ROOM["seals"], ROOM["exits"]


def load(path):
    d = json.load(open(path))
    rx, ry, rw, rh = d["room"]
    solid = {(c[0], c[1]) for c in d["cells"]}
    for x0, y0, w, h in SEALS:
        for x in range(x0, x0 + w):
            for y in range(y0, y0 + h):
                solid.add((x, y))
    return (rx, ry, rw, rh), solid


def in_rect(p, r):
    return r[0] <= p[0] < r[0] + r[2] and r[1] <= p[1] < r[1] + r[3]


def main(path):
    room, solid = load(path)
    rx, ry, rw, rh = room

    def blocked(x, y):
        return (x, y) in solid or not (rx <= x < rx + rw)  # open above and below the room

    def stand(x, y):
        return (not blocked(x, y) and not blocked(x, y - 1) and ((x, y + 1) in solid)
                and not in_rect((x, y), WATER))

    spots = {(x, y) for x in range(rx, rx + rw) for y in range(ry, ry + rh) if stand(x, y)}
    report = []

    # --- Floors: flat runs -----------------------------------------------------
    runs = []
    for y in range(ry, ry + rh):
        run = 0
        for x in range(rx, rx + rw + 1):
            if (x, y) in spots:
                run += 1
            else:
                if run:
                    runs.append(run)
                run = 0
    total = sum(runs)
    long8 = sum(r for r in runs if r >= 8)
    report.append(f"floors: longest run {max(runs)} tiles (rule: >= 20) {'OK' if max(runs) >= 20 else 'FAIL'}")
    report.append(f"floors: {100 * long8 / total:.0f}% in runs of 8+ (rule: >= 60%) {'OK' if long8 / total >= 0.6 else 'FAIL'}")

    # --- Steps: neighbouring floor heights 1-2 apart -------------------------
    steps = 0
    stairs = 0
    tops = {}
    for (x, y) in spots:
        tops.setdefault(x, []).append(y)
    for x in range(rx, rx + rw - 1):
        for y in tops.get(x, []):
            for dy in (1, 2, -1, -2):
                if (x + 1, y + dy) in spots and (x + 1, y) not in spots:
                    steps += 1
                    if (x + 2, y + 2 * dy) in spots and (x + 2, y + dy) not in spots:
                        stairs += 1
    report.append(f"small steps (1-2 tiles) in the floors: {steps} (rule: <= 2) {'OK' if steps <= 2 else 'FAIL'}")
    report.append(f"staircases: {stairs} (rule: none) {'OK' if stairs == 0 else 'FAIL'}")

    # --- Thin rock: every walkable top's mass at least 2 thick ------------------
    sealed = {(x, y) for x0, y0, w, h in SEALS for x in range(x0, x0 + w) for y in range(y0, y0 + h)}
    thin = sorted({(x, y + 1) for (x, y) in spots if (x, y + 2) not in solid and ry <= y + 2 < ry + rh} - sealed)
    report.append(f"masses thinner than 2 tiles under a floor: {len(thin)} {'OK' if not thin else 'FAIL ' + str(thin[:6])}")

    # --- Walk it: reachable standing spots with the base kit --------------------
    def fall(x, y):
        while ry <= y < ry + rh + 2:
            if in_rect((x, y), WATER):
                return None
            if (x, y) in spots:
                return (x, y)
            if blocked(x, y + 1) and (x, y + 1) not in solid:
                return None
            y += 1
        return None

    def clear_column(x, y_from, y_to):
        lo, hi = min(y_from, y_to), max(y_from, y_to)
        return all(not blocked(x, y) for y in range(lo - BODY + 1, hi + 1))

    def moves(p):
        x, y = p
        out = []
        for d in (-1, 1):
            if (x + d, y) in spots:
                out.append((x + d, y))
            # off an edge
            for dx in (1, 2):
                if not blocked(x + d * dx, y) and not blocked(x + d * dx, y - 1):
                    q = fall(x + d * dx, y)
                    if q:
                        out.append(q)
            # jumps: up to JUMP_UP, ledges up to LEDGE_UP, across gaps up to GAP
            for dx in range(1, GAP + 3):
                tx = x + d * dx
                # Up to a ledge catch above; down as far as a long drop with drift.
                for dy in range(-LEDGE_UP, 14):
                    q = (tx, y + dy)
                    if q not in spots:
                        continue
                    rise = -dy
                    gap = dx - 1  # open tiles crossed
                    if rise > LEDGE_UP:
                        continue
                    if rise > JUMP_UP and gap > 4:
                        continue  # a ledge catch: measured up to 4 tiles across at 4-5 up
                    if rise <= JUMP_UP and gap > GAP - (1 if rise > 1 else 0):
                        continue
                    # The body's path must be open: the start and landing columns up to
                    # the arc's top, and every column between across the arc's height.
                    # The arc's top: the higher standing row, plus a little air on low jumps.
                    # (A drop needs no more than a hop: air above only to clear a wide gap.)
                    air = max(0, 2 - rise) if rise >= 0 else (2 if gap > 2 else 0)
                    apex = min(y, y + dy) - air
                    if not (clear_column(x, y, apex) and clear_column(tx, y + dy, apex)):
                        continue
                    low = min(y, y + dy)
                    if not all(clear_column(x + d * i, low, apex) for i in range(1, dx)):
                        continue
                    out.append(q)
        for a, b in LIFT:
            if p == a:
                out.append(b)
            if p == b:
                out.append(a)
        return out

    seen = {SPAWN}
    queue = deque([SPAWN])
    while queue:
        p = queue.popleft()
        for q in moves(p):
            if q not in seen:
                seen.add(q)
                queue.append(q)

    for name, r in GATED.items():
        leak = [p for p in seen if in_rect(p, r)]
        report.append(f"gate holds: {name}: {'OK' if not leak else 'LEAK at ' + str(leak[:4])}")
    for name, p in EXITS.items():
        report.append(f"exit reached: {name}: {'OK' if p in seen else 'NOT REACHED'}")
    ungated = [p for p in spots if not any(in_rect(p, r) for r in GATED.values())]
    reached = [p for p in ungated if p in seen]
    report.append(f"coverage: {100 * len(reached) / len(ungated):.0f}% of ungated floor reached with the base kit")
    missing = sorted(set(ungated) - seen)
    if missing:
        report.append(f"  not reached: {missing[:12]}{' ...' if len(missing) > 12 else ''}")

    # --- Traps: every reached spot can get back to the spawn ----------------------
    rev = {}
    for p in seen:
        for q in moves(p):
            rev.setdefault(q, set()).add(p)
    back = {SPAWN}
    queue = deque([SPAWN])
    while queue:
        p = queue.popleft()
        for q in rev.get(p, ()):
            if q not in back:
                back.add(q)
                queue.append(q)
    traps = sorted(seen - back)
    report.append(f"traps (reached but no way back to the shrine): {len(traps)} {'OK' if not traps else str(traps[:8])}")
    print("\n".join(report))


if __name__ == "__main__":
    main(ROOM["cells"])
