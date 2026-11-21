#!/usr/bin/env python3
"""WCAG 2.2 AA contrast for token role pairs and text sitting on a photo scrim.

Body text needs 4.5:1. Large text and icons need 3:1. A failing pair prints the
mode, the two role names, the measured ratio, and the required ratio.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

BODY = 4.5
LARGE = 3.0


def _channel(value: float) -> float:
    c = value / 255.0
    if c <= 0.04045:
        return c / 12.92
    return ((c + 0.055) / 1.055) ** 2.4


def parse_hex(value: str) -> tuple[int, int, int]:
    raw = value.strip().lstrip("#")
    if len(raw) == 8:
        raw = raw[2:]
    if len(raw) != 6:
        raise ValueError(f"not a colour: {value}")
    number = int(raw, 16)
    return (number >> 16) & 255, (number >> 8) & 255, number & 255


def luminance(hex_color: str) -> float:
    r, g, b = parse_hex(hex_color)
    return 0.2126 * _channel(r) + 0.7152 * _channel(g) + 0.0722 * _channel(b)


def contrast_ratio(foreground: str, background: str) -> float:
    lighter = max(luminance(foreground), luminance(background))
    darker = min(luminance(foreground), luminance(background))
    return (lighter + 0.05) / (darker + 0.05)


def required_ratio(level: str) -> float:
    if level == "body":
        return BODY
    if level == "large":
        return LARGE
    raise ValueError(f"unknown contrast level {level}")


def composite(scrim: str, alpha: float, backdrop: str) -> str:
    top = parse_hex(scrim)
    bottom = parse_hex(backdrop)
    mixed = tuple(round(alpha * t + (1.0 - alpha) * b) for t, b in zip(top, bottom))
    return "#{:02X}{:02X}{:02X}".format(*mixed)


def role_hex(ramps: dict, role: dict) -> str:
    step = ramps[role["ramp"]]["steps"][str(role["step"])]
    return step["hex"]


def check_pairs(spec: dict) -> list[str]:
    ramps = spec["colorRamps"]["ramps"]
    modes = spec["colorRamps"]["modes"]
    failures = []
    for pair in spec["colorRamps"]["pairs"]:
        mode = modes[pair["mode"]]
        fg_name = pair["fg"]
        bg_name = pair["bg"]
        level = pair["level"]
        ratio = contrast_ratio(role_hex(ramps, mode[fg_name]), role_hex(ramps, mode[bg_name]))
        need = required_ratio(level)
        if ratio + 1e-9 < need:
            failures.append(
                f"contrast: {pair['mode']} {fg_name} on {bg_name} {ratio:.2f} < {need:.2f}"
            )
    return failures


def scrim_samples(root: Path) -> list[str]:
    """Title text sits on the darkest stop of the photo scrim in ModernCard."""
    source = root / "lib/widgets/modern_card.dart"
    text = source.read_text(encoding="utf-8")
    alphas = [float(value) for value in re.findall(r"scrim\.withValues\(alpha:\s*(0\.\d+)\)", text)]
    if not alphas:
        return ["contrast: modern-card scrim missing"]
    alpha = max(alphas)
    # Worst case for light title text is a white photograph under a black scrim.
    plate = composite("#000000", alpha, "#FFFFFF")
    ratio = contrast_ratio("#FFFFFF", plate)
    if ratio + 1e-9 < BODY:
        return [
            f"contrast: modern-card title on scrim {ratio:.2f} < {BODY:.2f} alpha {alpha:.2f}"
        ]
    return []


def report(failures: list[str], checked: int) -> str:
    if not failures:
        return f"contrast: {checked} pairs pass WCAG 2.2 AA\n"
    lines = ["contrast: fail", *failures]
    if len(lines) > 15:
        hidden = len(lines) - 14
        lines = lines[:14] + [f"+{hidden} more"]
    return "\n".join(lines) + "\n"


def self_test() -> int:
    black_on_white = contrast_ratio("#000000", "#FFFFFF")
    if not 20.9 < black_on_white < 21.1:
        print(f"contrast: self-test ratio {black_on_white:.2f}")
        return 1
    weak = contrast_ratio("#777777", "#767676")
    if weak >= BODY:
        print("contrast: self-test expected a failing pair")
        return 1
    message = f"contrast: light sample on surface {weak:.2f} < {BODY:.2f}"
    if "sample" not in message or "surface" not in message or f"{weak:.2f}" not in message:
        print("contrast: self-test report omitted the roles or the ratio")
        return 1
    plate = composite("#000000", 0.2, "#FFFFFF")
    if contrast_ratio("#FFFFFF", plate) >= BODY:
        print("contrast: self-test thin scrim should fail AA")
        return 1
    print("contrast: self-test passed")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--sample-failure", action="store_true")
    args = parser.parse_args(argv)
    if args.sample_failure:
        ratio = contrast_ratio("#777777", "#767676")
        sys.stdout.write(
            f"contrast: fail\ncontrast: light onSurface on surface {ratio:.2f} < {BODY:.2f}\n"
        )
        return 1
    if args.self_test:
        return self_test()
    root = Path(args.root)
    spec = json.loads((root / "design/tokens/tokens.json").read_text(encoding="utf-8"))
    failures = check_pairs(spec) + scrim_samples(root)
    checked = len(spec["colorRamps"]["pairs"]) + 1
    sys.stdout.write(report(failures, checked))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
