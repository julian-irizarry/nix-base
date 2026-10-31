"""Pixel grids (rows of '#'/'.') -> braille frames. 2x4 pixels per cell."""
import json, sys

BITS = [[0x01, 0x08], [0x02, 0x10], [0x04, 0x20], [0x40, 0x80]]
W = 12  # pixels (6 cells)

def braille(rows):
    rows = [r.ljust(W, ".") for r in rows]
    out = ""
    for cx in range(0, W, 2):
        v = 0
        for y in range(4):
            for dx in range(2):
                if rows[y][cx + dx] == "#":
                    v |= BITS[y][dx]
        out += chr(0x2800 + v)
    return out

def place(art, x):
    return ["." * x + r for r in art]

# crab: 8x4, claws up at the corners, eyes are gaps, legs alternate
CRAB_A = ["#.####.#", "##.##.##", ".######.", "#.#..#.#"]
CRAB_B = ["#.####.#", "##.##.##", ".######.", ".#.##.#."]
CRAB_BLINK = ["#.####.#", "########", ".######.", "#.#..#.#"]
CRAB_WAVE = [".#.##.#.", "##.##.##", ".######.", "#.#..#.#"]  # claws lifted in
CRAB_WAVE2 = ["#.####.#", "##.##.##", ".######.", "#.#..#.#"]

# robot: 8x4, antenna, square head, two eyes
def robot(eyes, antenna=True, mouth=False):
    top = "...##..." if antenna else "........"
    return [top, "########", eyes, ".#....#." if not mouth else ".#.##.#."]
R_C = robot("#.##.#.#".replace("#.##.#.#", "##.##.##"))
R_L = robot("#.##.###")
R_R = robot("###.##.#")
R_OFF = robot("##.##.##", antenna=False)
R_SLEEP = robot("########", antenna=False)
R_HAPPY = robot("##.##.##", mouth=True)

def lane(frames_art, positions):
    return [braille(place(art, x)) for art, x in zip(frames_art, positions)]

ping = [0, 1, 2, 3, 4, 3, 2, 1]  # 8 steps across a 12px lane for an 8px crab
mid = 2

sprites = {
    "crab": {
        "interval_ms": 160,
        # Claude's coral, red when blocked, green when it cheers on done.
        "color": "#d97757",
        "colors": {"blocked": "#ff4d4d", "done": "#a6e3a1"},
        "working": lane([CRAB_A if i % 2 == 0 else CRAB_B for i in range(8)], ping),
        "done": lane([CRAB_WAVE, CRAB_WAVE2], [mid, mid]),
        "blocked": lane([CRAB_A, CRAB_A, CRAB_A, CRAB_A], [mid - 1, mid + 1, mid - 1, mid]),
        "idle": lane([CRAB_A] * 14 + [CRAB_BLINK], [mid] * 15),
    },
    "robot": {
        "interval_ms": 160,
        "working": lane([R_C, R_L, R_L, R_C, R_R, R_R, robot("##.##.##", antenna=False), R_C], [mid] * 8),
        "done": lane([R_HAPPY, R_HAPPY, robot("##.##.##", mouth=True, antenna=False)], [mid] * 3),
        "blocked": lane([R_C, R_C, R_C, R_C], [mid - 1, mid + 1, mid - 1, mid]),
        "idle": lane([R_OFF] * 14 + [R_SLEEP], [mid] * 15),
    },
}

if __name__ == "__main__":
    if sys.argv[1:] == ["toml"]:
        for name, s in sprites.items():
            print(f"[ui.sprites.{name}]")
            print(f"interval_ms = {s['interval_ms']}")
            if "color" in s:
                print(f"color = {json.dumps(s['color'])}")
            if "colors" in s:
                pairs = ", ".join(f"{k} = {json.dumps(v)}" for k, v in s["colors"].items())
                print(f"colors = {{ {pairs} }}")
            for state in ("working", "done", "blocked", "idle"):
                print(f"{state} = {json.dumps(s[state], ensure_ascii=False)}")
            print()
    else:
        for name, s in sprites.items():
            for state in ("working", "done", "blocked", "idle"):
                uniq = list(dict.fromkeys(s[state]))
                print(f"{name:6} {state:8} " + "  ".join(f"[{f}]" for f in uniq))
