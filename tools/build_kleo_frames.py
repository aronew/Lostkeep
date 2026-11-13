"""Write Kleo's SpriteFrames resource from her 64 x 64 frame strips.

Each animation lists the strip, its frames (0-based), its speed, whether it
loops, and optional holds: {frame: duration multiplier}. Holds give the motion
weight: a wind-up that pauses, an impact that lands.

Usage: python3 tools/build_kleo_frames.py   (writes game/scenes/player/kleo_frames.tres)
"""
import os

STRIPS = "res://assets/characters/kleo/"
OUT = "game/scenes/player/kleo_frames.tres"

# name: (strip, first, last, fps, loop, holds)
ANIMS = [
    ("idle", "idle", 0, 11, 8, True, {}),
    ("idle_yawn", "idle_long", 0, 7, 9, False, {1: 1.6, 3: 2.2, 6: 1.4}),
    ("run", "run", 0, 11, 16, True, {}),
    ("run_start", "start_stop_turn", 0, 3, 18, False, {}),
    ("run_stop", "start_stop_turn", 4, 7, 16, False, {5: 1.3}),
    ("turn", "start_stop_turn", 8, 9, 20, False, {}),
    ("jump", "jump_rise", 0, 4, 18, False, {}),
    ("jump_apex", "jump_rise", 5, 7, 10, False, {}),
    ("fall", "fall_land", 0, 3, 12, True, {}),
    ("land", "fall_land", 4, 6, 20, False, {}),
    ("land_hard", "fall_land", 7, 11, 14, False, {7: 1.4, 8: 1.6}),
    ("ledge_grab", "ledge", 0, 1, 18, False, {}),
    ("ledge_hang", "ledge", 2, 4, 6, True, {}),
    ("ledge_climb", "ledge", 5, 15, 16, False, {9: 1.8, 10: 1.6}),
    ("attack_1", "combo_backhand", 0, 11, 24, False, {2: 1.6, 4: 1.3, 7: 1.4}),
    ("attack_2", "combo_forehand", 0, 11, 24, False, {2: 1.5, 3: 1.2, 6: 1.3}),
    ("attack_3", "combo_overhead", 0, 11, 22, False, {3: 1.4, 4: 1.5, 6: 1.8}),
    ("attack_4", "combo_finisher", 0, 15, 24, False, {5: 1.6, 6: 1.3, 12: 2.2, 13: 1.4}),
    ("attack_up", "directional_strikes", 0, 3, 22, False, {2: 1.4}),
    ("attack_air", "directional_strikes", 4, 7, 24, False, {5: 1.3}),
    ("attack_down", "directional_strikes", 8, 11, 22, False, {10: 1.3}),
    ("hurt", "damage", 0, 3, 18, False, {}),
    ("knockback", "damage", 4, 15, 16, False, {4: 1.4, 8: 1.2, 9: 1.2, 10: 1.2}),
    ("death", "death", 0, 15, 10, False, {0: 1.5, 15: 6.0}),
    ("heal", "heal_rest", 0, 5, 12, False, {3: 1.6}),
    ("rest", "heal_rest", 6, 9, 8, False, {9: 3.0}),
    ("rest_rise", "heal_rest", 10, 11, 10, False, {}),
    ("interact", "rescue_interact", 5, 7, 12, False, {6: 1.6}),
    ("rescue", "rescue_interact", 0, 4, 12, False, {3: 1.6}),
    # Abilities found later in the game.
    ("ward", "ironbark_ward", 0, 11, 22, False, {}),
    ("spark", "anima_spark_cast", 0, 11, 20, False, {}),
    ("lance", "anima_lance_channel", 0, 11, 14, False, {}),
    ("emberwick", "emberwick", 0, 7, 16, False, {}),
    ("wall", "wall", 0, 11, 12, False, {}),
    ("glide", "wing_cloak", 0, 11, 12, False, {}),
    ("swim", "underwater", 0, 11, 10, False, {}),
    ("thorn_line", "thorn_line", 0, 11, 16, False, {}),
    ("meld", "memory_siphon", 0, 7, 10, False, {}),
]


def main():
    strips = sorted({a[1] for a in ANIMS})
    ext = {s: f"{i + 1}_{s}" for i, s in enumerate(strips)}
    subs = []
    anims = []
    for name, strip, first, last, fps, loop, holds in ANIMS:
        frames = []
        for f in range(first, last + 1):
            sid = f"{strip}_{f}"
            if sid not in [s[0] for s in subs]:
                subs.append((sid, strip, f))
            dur = holds.get(f, 1.0)
            frames.append('{\n"duration": %.1f,\n"texture": SubResource("%s")\n}' % (dur, sid))
        anims.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}' % (
            ", ".join(frames), "true" if loop else "false", name, fps))
    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(strips) + len(subs) + 1} format=3]', ""]
    for s in strips:
        lines.append(f'[ext_resource type="Texture2D" path="{STRIPS}{s}.png" id="{ext[s]}"]')
    lines.append("")
    for sid, strip, f in subs:
        lines += [f'[sub_resource type="AtlasTexture" id="{sid}"]', f'atlas = ExtResource("{ext[strip]}")',
                  f"region = Rect2({f * 64}, 0, 64, 64)", ""]
    lines += ["[resource]", "animations = [" + ", ".join(anims) + "]", ""]
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as fh:
        fh.write("\n".join(lines))
    print(f"wrote {OUT}: {len(ANIMS)} animations, {len(subs)} frames")


if __name__ == "__main__":
    main()
