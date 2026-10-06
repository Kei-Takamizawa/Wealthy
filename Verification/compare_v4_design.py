#!/usr/bin/env python3
"""Build compact v4 design-to-device comparisons from repository inputs.

By default this reads the curated source captures under
Verification/Cycle2aEvidence/compare/source. To refresh those from an XCTest
attachment export, pass --manifest and --capture-dir. The script never edits
design boards or application screenshots; it crops only the selected design
panel and lays it beside its matching device capture.
"""

from __future__ import annotations

import argparse
import json
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / "design" / "v4"
OUT = ROOT / "Verification" / "Cycle2aEvidence" / "compare"
DEFAULT_SOURCE = Path("/private/tmp/wealthy-v4-compare-source")
HEIGHT = 1_080
PANEL_WIDTH = 790
PAD = 24
HEADER = 76


@dataclass(frozen=True)
class Panel:
    board: str
    rect: tuple[float, float, float, float] = (0, 0, 1, 1)
    note: str = ""


# Crop rectangles are normalized [left, top, right, bottom] coordinates in
# the original board. Multi-screen boards are intentionally reduced to the
# one screen closest to the corresponding v4 destination.
PANELS: dict[str, dict[str, Panel]] = {
    "Home": {
        "light": Panel("ホーム マトリクス.png", (0.015, 0.025, 0.198, 0.96)),
        "dark": Panel("ホーム マトリクス.png", (0.205, 0.025, 0.389, 0.96)),
    },
    "Voice": {
        "light": Panel("声の画面 ライト.png", (0.006, 0.015, 0.171, 0.735), "Closest idle-state board panel."),
        "dark": Panel("声の画面 ダーク.png", (0.006, 0.015, 0.171, 0.735), "Closest idle-state board panel."),
    },
    "InfoHousehold": {
        "light": Panel("情報画面（家計タブ）ライト.png"),
        "dark": Panel("情報画面（家計タブ）ダーク.png"),
    },
    "InfoChild": {
        "light": Panel("情報画面（子ども枠タブ）ライト.png"),
        "dark": Panel("情報画面（子ども枠タブ）ダーク.png"),
    },
    "ChildSetup": {
        "light": Panel("子ども枠の設定と詳細.png", (0.005, 0.01, 0.222, 0.735)),
        "dark": Panel("子ども枠の設定と詳細.png", (0.222, 0.01, 0.429, 0.735)),
    },
    "ChildDetail": {
        "light": Panel("子ども枠の設定と詳細.png", (0.597, 0.01, 0.795, 0.735)),
        "dark": Panel("子ども枠の設定と詳細.png", (0.795, 0.01, 0.998, 0.735)),
    },
    "Goals": {
        "light": Panel("目標の設定 ライト.png"),
        "dark": Panel("目標の設定.png", (0.20, 0.005, 0.40, 0.74)),
    },
    "GoalsUnset": {
        "light": Panel("目標の設定.png", (0.65, 0.005, 0.82, 0.74)),
        "dark": Panel("目標の設定.png", (0.82, 0.005, 0.998, 0.74)),
    },
    "Edit": {
        "light": Panel("記録の追加・編集.png", (0.005, 0.005, 0.171, 0.77)),
        "dark": Panel("記録の追加・編集.png", (0.171, 0.005, 0.341, 0.77)),
    },
    "Tax": {
        "light": Panel("消費税.png", (0.0, 0.005, 0.328, 0.965)),
        "dark": Panel("消費税.png", (0.337, 0.005, 0.657, 0.965)),
    },
    "Settings": {
        "light": Panel("カテゴリ・設定・復元.png", (0.34, 0.005, 0.535, 0.75)),
        "dark": Panel("カテゴリ・設定・復元.png", (0.535, 0.005, 0.73, 0.75)),
    },
    "EmptyDay": {
        "light": Panel("何も記録がない日・Apple Intelligence 非対応.png", (0.0, 0.005, 0.202, 0.64)),
        "dark": Panel("何も記録がない日・Apple Intelligence 非対応.png", (0.202, 0.005, 0.405, 0.64)),
    },
    "NoAI": {
        "light": Panel("何も記録がない日・Apple Intelligence 非対応.png", (0.615, 0.005, 0.808, 0.64)),
        "dark": Panel("何も記録がない日・Apple Intelligence 非対応.png", (0.81, 0.005, 0.998, 0.64)),
    },
    "OnboardLanguage": {
        "light": Panel("はじめての設定.png", (0.0, 0.005, 0.169, 0.665)),
    },
    "OnboardCurrency": {
        "light": Panel("はじめての設定.png", (0.169, 0.005, 0.337, 0.665)),
    },
    "OnboardTarget": {
        "light": Panel("はじめての設定.png", (0.337, 0.005, 0.505, 0.665)),
        "dark": Panel("はじめての設定.png", (0.67, 0.005, 0.837, 0.665)),
    },
    "OnboardChild": {
        "light": Panel("はじめての設定.png", (0.505, 0.005, 0.67, 0.665)),
    },
}

RESULT_PANELS = {
    "WeekAchieved": {"light": Panel("週の結果.png", (0.017, 0.025, 0.328, 0.975)), "dark": Panel("結果 ダーク.png", (0.0, 0.025, 0.334, 0.975))},
    "WeekOver": {"light": Panel("週の結果.png", (0.338, 0.025, 0.655, 0.975)), "dark": Panel("結果 ダーク.png", (0.334, 0.025, 0.666, 0.975))},
    "WeekFew": {"light": Panel("週の結果.png", (0.667, 0.025, 0.985, 0.975)), "dark": Panel("結果 ダーク.png", (0.666, 0.025, 0.999, 0.975))},
    "MonthAchieved": {"light": Panel("月の結果.png", (0.017, 0.025, 0.328, 0.975))},
    "MonthOver": {"light": Panel("月の結果.png", (0.338, 0.025, 0.655, 0.975))},
    "MonthFew": {"light": Panel("月の結果.png", (0.667, 0.025, 0.985, 0.975)), "dark": Panel("結果 ダーク.png", (0.666, 0.025, 0.999, 0.975))},
}

# Try specific 2a.1 state captures first, then earlier saved results. A single
# mode is never substituted for the other. Missing state screenshots stay
# visibly unavailable in INDEX.md.
CAPTURE_ALIASES: dict[str, dict[str, tuple[str, ...]]] = {}
for screen in PANELS:
    capture_id = {
        "InfoHousehold": "info",
        "InfoChild": "info-child",
        "ChildSetup": "child-setup",
        "ChildDetail": "child-detail",
        "GoalsUnset": "goals-unset",
        "EmptyDay": "empty-home",
        "OnboardLanguage": "onboarding-language",
        "OnboardCurrency": "onboarding-currency",
        "OnboardTarget": "onboarding-target",
        "OnboardChild": "onboarding-child",
    }.get(screen, screen.lower().replace("onboard", "onboarding-"))
    if screen.startswith("Onboard"):
        step = {"OnboardLanguage": "language", "OnboardCurrency": "currency", "OnboardTarget": "target", "OnboardChild": "child"}[screen]
        CAPTURE_ALIASES[screen] = {
            "light": (f"onboarding-{step}-ja", f"onboarding-{step}-en"),
            "dark": (f"onboarding-{step}-ja---dark", f"onboarding-{step}-en---dark"),
        }
    elif screen == "EmptyDay":
        CAPTURE_ALIASES[screen] = {
            "light": ("empty-home-ja", "empty-home-en"),
            "dark": ("empty-home-ja---dark", "empty-home-en---dark"),
        }
    else:
        CAPTURE_ALIASES[screen] = {
            mode: (f"matrix-ja-{mode}-{capture_id}", f"matrix-en-{mode}-{capture_id}")
            for mode in ("light", "dark")
        }
for screen in RESULT_PANELS:
    period = "week" if screen.startswith("Week") else "month"
    state = screen.removeprefix("Week").removeprefix("Month").lower()
    CAPTURE_ALIASES[screen] = {
        mode: (
            f"{period}-result-{state}-{mode}",
            f"result-{period}-{state}-{mode}",
            f"{period}-{state}-result-{mode}",
            *((f"matrix-ja-{mode}-result", f"matrix-en-{mode}-result") if screen == "WeekAchieved" else ()),
            *(("result---over",) if screen == "WeekOver" and mode == "light" else ()),
            *(("result---few",) if screen == "WeekFew" and mode == "light" else ()),
            *((f"matrix-ja-{mode}-month-result", f"matrix-en-{mode}-month-result") if screen == "MonthFew" else ()),
        )
        for mode in ("light", "dark")
    }
CAPTURE_ALIASES.update({
    "Voice": {m: (f"matrix-ja-{m}-voice", f"matrix-en-{m}-voice") for m in ("light", "dark")},
    "Home": {m: (f"matrix-ja-{m}-home", f"matrix-en-{m}-home") for m in ("light", "dark")},
    "NoAI": {m: (f"matrix-ja-{m}-no-ai", f"matrix-en-{m}-no-ai") for m in ("light", "dark")},
    "Tax": {m: (f"matrix-ja-{m}-tax", f"matrix-en-{m}-tax") for m in ("light", "dark")},
    "Edit": {m: (f"matrix-ja-{m}-edit", f"matrix-en-{m}-edit") for m in ("light", "dark")},
    "Goals": {m: (f"matrix-ja-{m}-goals", f"matrix-en-{m}-goals") for m in ("light", "dark")},
    "Settings": {m: (f"matrix-ja-{m}-settings", f"matrix-en-{m}-settings") for m in ("light", "dark")},
})


def find_capture(manifest_path: Path, capture_dir: Path, aliases: tuple[str, ...]) -> Path | None:
    manifest = json.loads(manifest_path.read_text())
    matches: list[tuple[float, float, float, Path]] = []
    for record in manifest:
        for attachment in record.get("attachments", []):
            suggested = attachment.get("suggestedHumanReadableName", "")
            for rank, alias in enumerate(aliases):
                if suggested.startswith(alias + "_") or suggested.startswith(alias + "---") or suggested.startswith(alias + "--"):
                    mode_specific = any(token in alias for token in ("-light", "-dark", "---dark"))
                    dark_capture = "---dark" in suggested or "--dark" in suggested or "-dark-" in suggested
                    if mode_specific and alias.endswith("light") and dark_capture:
                        continue
                    if "---dark" in alias and not dark_capture:
                        continue
                    if alias.startswith(("empty-home-", "onboarding-")) and not alias.endswith("---dark") and dark_capture:
                        continue
                    if alias.startswith("result---") and mode_specific is False and dark_capture:
                        continue
                    path = capture_dir / attachment.get("exportedFileName", "")
                    if path.is_file():
                        # Prefer the plain matrix capture over AX3 and reduce-motion variants.
                        penalty = 2.0 if "ax3" in suggested else 0.0
                        penalty += 2.0 if "reduce-motion" in suggested else 0.0
                        matches.append((rank * 10 + penalty, -float(attachment.get("timestamp", 0)), float(len(suggested)), path))
    return min(matches, default=(0, 0, 0, None))[3]


def crop_board(panel: Panel) -> Image.Image:
    image = Image.open(DESIGN / panel.board).convert("RGB")
    width, height = image.size
    left, top, right, bottom = panel.rect
    rect = (round(left * width), round(top * height), round(right * width), round(bottom * height))
    return image.crop(rect)


def save_source_inputs(manifest_path: Path, capture_dir: Path, source_dir: Path) -> dict[str, str]:
    source_dir.mkdir(parents=True, exist_ok=True)
    for stale in source_dir.glob("*.jpg"):
        stale.unlink()
    resolved: dict[str, str] = {}
    pairs = [(screen, mode, panel) for screen, modes in PANELS.items() for mode, panel in modes.items()]
    pairs += [(screen, mode, panel) for screen, modes in RESULT_PANELS.items() for mode, panel in modes.items()]
    for screen, mode, _ in pairs:
        src = find_capture(manifest_path, capture_dir, CAPTURE_ALIASES[screen][mode])
        if src is None:
            continue
        dest = source_dir / f"{screen}-{mode}.jpg"
        im = Image.open(src).convert("RGB")
        im.save(dest, "JPEG", quality=92, optimize=True)
        resolved[f"{screen}-{mode}"] = dest.name
    return resolved


def panel_image(image: Image.Image, max_width: int, height: int, background: str) -> Image.Image:
    fitted = ImageOps.contain(image, (max_width, height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", (max_width, height), background)
    canvas.paste(fitted, ((max_width - fitted.width) // 2, (height - fitted.height) // 2))
    return canvas


def render(screen: str, mode: str, panel: Panel, source_file: Path, notes: str = "") -> Path:
    dark = mode == "dark"
    bg = "#171719" if dark else "#F3EBDD"
    ink = "#F5F2EB" if dark else "#282722"
    canvas = Image.new("RGB", (PANEL_WIDTH * 2 + PAD * 3, HEADER + HEIGHT + PAD * 2), bg)
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 28)
        small = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 21)
    except OSError:
        font, small = ImageFont.load_default(), ImageFont.load_default()
    title = f"{screen} | {mode.title()}"
    draw.text((PAD, 8), title, font=font, fill=ink)
    draw.text((PAD, 46), "Design board", font=small, fill=ink)
    draw.text((PANEL_WIDTH + PAD * 2, 46), "Device screenshot", font=small, fill=ink)
    design_panel = panel_image(crop_board(panel), PANEL_WIDTH, HEIGHT, bg)
    device_panel = panel_image(Image.open(source_file).convert("RGB"), PANEL_WIDTH, HEIGHT, bg)
    canvas.paste(design_panel, (PAD, HEADER))
    canvas.paste(device_panel, (PANEL_WIDTH + PAD * 2, HEADER))
    output = OUT / f"compare-V4{screen}-{mode}.jpg"
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output, "JPEG", quality=80, optimize=True)
    if output.stat().st_size >= 2_000_000:
        raise RuntimeError(f"Comparison exceeds 2 MB: {output}")
    if max(canvas.size) > 2_400:
        raise RuntimeError(f"Comparison exceeds 2400 px: {output}")
    return output


def known_difference(screen: str, mode: str) -> str:
    notes = {
        "Home": "The remaining-allowance hero, seven-day states, month summary and bottom microphone were checked against this design; the island remains a standalone rounded illustration instead of a full-bleed background.",
        "Voice": "Board shows a voice-session mock; this cycle's page is an idle placeholder.",
        "InfoHousehold": "Board includes long overview sections; the device image shows the current scroll position.",
        "InfoChild": "Board includes more explanatory content; device values are synthetic test data.",
        "ChildSetup": "Board includes category targets; device capture reflects the current setup controls.",
        "ChildDetail": "Board contains longer detail sections; device capture is viewport-limited.",
        "Goals": "Board and device may differ in category list and month; values are synthetic.",
        "GoalsUnset": "Board's unset-target card is compared with the device's unset-month state.",
        "Edit": "Board shows additional receipt and recurring controls outside this cycle's scope.",
        "Tax": "Board uses sample Japanese entries; device values come from synthetic test fixtures.",
        "Settings": "Board includes destinations outside this cycle; the device shows the current settings page.",
        "EmptyDay": "Board copy is Japanese; the device capture uses the selected test locale.",
        "NoAI": "Board includes multiple unavailable/preparation cases; the device shows the selected no-AI state.",
        "OnboardLanguage": "Board copy is Japanese; the device capture uses the selected test locale.",
        "OnboardCurrency": "Board copy is Japanese; the device capture uses the selected test locale.",
        "OnboardTarget": "Board value is a static example; device value is synthetic test data.",
        "OnboardChild": "Board copy is Japanese; the device capture uses the selected test locale.",
        "WeekAchieved": "Board uses a Japanese sample week; the device state uses synthetic test entries.",
        "WeekOver": "Board uses a Japanese sample week; the device state uses synthetic test entries.",
        "WeekFew": "Board uses a Japanese sample week; the device state uses synthetic test entries.",
        "MonthAchieved": "Board copy uses a fixed day-count example; the device should show the Core 70% threshold.",
        "MonthOver": "Board uses a Japanese sample month; the device state uses synthetic test entries.",
        "MonthFew": "Board uses a fixed day-count example; the device should show the Core 70% threshold.",
    }
    return notes.get(screen, f"{mode.title()} design panel compared with a synthetic-data device capture.")


def write_index(rows: list[tuple[str, str, str, str, str]], missing_boards: list[str], capture_label: str, source_dir: Path) -> None:
    lines = [
        "# v4 design and device comparisons", "",
        f"Each available image places the selected design panel on the left and a synthetic-data XCTest device capture on the right. Both panels have the same displayed height. The captured implementation is `{capture_label}`. Output JPEG quality is 80; the longest edge is at most 2,400 px.", "",
        "Design panels are cropped from the local exported boards in `design/v4/`. Several exports are multi-screen canvases; crop boxes are explicitly recorded in `Verification/compare_v4_design.py`. A difference note describes visible known differences only; the images are review aids, not pixel-diff claims.", "",
        "| File | Screen / mode | Known difference or source note |", "|---|---|---|",
    ]
    for file_name, screen, mode, note, status in rows:
        lines.append(f"| {file_name} | {screen} / {mode} | {note or status} |")
    lines += ["", "## Missing mappings", ""]
    if missing_boards:
        lines.extend(f"- {item}" for item in missing_boards)
    else:
        lines.append("No missing board mappings were detected for the available screenshot/mode pairs.")
    lines += [
        "", "## Rebuild", "",
        f"From the repository root, run `python3 Verification/compare_v4_design.py --manifest PATH/manifest.json --capture-dir PATH --source-dir {source_dir}`. The manifest and capture folder come from an XCTest attachment export; aliases are configured in the script. Source captures are kept outside Git. Requires Pillow.", "",
        "Synthetic test fixtures only. No real financial records are included.", "",
    ]
    (OUT / "INDEX.md").write_text("\n".join(lines))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, help="XCTest attachment manifest JSON")
    parser.add_argument("--capture-dir", type=Path, help="Directory containing exported attachment PNGs")
    parser.add_argument("--source-dir", type=Path, default=DEFAULT_SOURCE, help="External folder for selected compressed source screenshots")
    parser.add_argument("--capture-label", default="PR #5 base 39ae7d5 (pre-fix)", help="Provenance label shown in INDEX.md")
    args = parser.parse_args()
    if bool(args.manifest) != bool(args.capture_dir):
        parser.error("--manifest and --capture-dir must be provided together")
    if args.manifest:
        sources = save_source_inputs(args.manifest, args.capture_dir, args.source_dir)
    else:
        sources = {}
    if args.source_dir.exists():
        sources.update({p.stem: p.name for p in args.source_dir.glob("*.jpg")})

    rows: list[tuple[str, str, str, str, str]] = []
    missing_boards: list[str] = []
    total = 0
    expected = {**PANELS, **RESULT_PANELS}
    for screen, modes in expected.items():
        for mode in ("light", "dark"):
            panel = modes.get(mode)
            if panel is None:
                missing_boards.append(f"{screen} {mode}: no local exported {mode} board panel was found.")
                continue
            key = f"{screen}-{mode}"
            source_name = sources.get(key)
            board_path = DESIGN / panel.board
            if not board_path.is_file():
                missing_boards.append(f"{screen} {mode}: missing local design board `{panel.board}`.")
                continue
            if not source_name or not (args.source_dir / source_name).is_file():
                missing_boards.append(f"{screen} {mode}: no device screenshot mapping found; expected a capture alias for `{key}`.")
                continue
            output = render(screen, mode, panel, args.source_dir / source_name)
            total += output.stat().st_size
            note = panel.note or known_difference(screen, mode)
            rows.append((output.name, screen, mode, note, ""))
    all_jpegs = list(OUT.glob("*.jpg")) + list(args.source_dir.glob("*.jpg"))
    total = sum(p.stat().st_size for p in all_jpegs)
    if any(p.stat().st_size >= 2_000_000 for p in all_jpegs):
        raise RuntimeError("A comparison/source JPEG exceeds 2 MB")
    if total >= 30_000_000:
        raise RuntimeError(f"Comparison images exceed the 30 MB total limit: {total:,} bytes")
    write_index(rows, missing_boards, args.capture_label, args.source_dir)
    print(f"Wrote {len(rows)} comparisons ({total:,} bytes); listed {len(missing_boards)} missing mappings in {OUT / 'INDEX.md'}")


if __name__ == "__main__":
    main()
