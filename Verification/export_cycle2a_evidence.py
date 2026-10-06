#!/usr/bin/env python3
"""Create small comparison sheets from exported XCTest attachments, excluding videos."""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw

parser = argparse.ArgumentParser()
parser.add_argument('attachments', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
shots = {}
for test in json.loads((args.attachments / 'manifest.json').read_text()):
    for attachment in test['attachments']:
        name = attachment['suggestedHumanReadableName'].split('_0_')[0]
        file = args.attachments / attachment['exportedFileName']
        if file.suffix == '.png': shots[name] = file
screens = ['home', 'voice', 'info', 'info-child', 'goals', 'goals-unset', 'edit', 'tax', 'child-setup', 'child-detail', 'settings', 'result', 'month-result', 'no-ai']
for language in ['en', 'ja', 'es', 'ko']:
    sheet = Image.new('RGB', (len(screens) * 160, 1095), '#eee8dc')
    draw = ImageDraw.Draw(sheet)
    for row, variant in enumerate(['light', 'dark', 'ax3']):
        for col, screen in enumerate(screens):
            name = f'matrix-{language}-{variant}-{screen}'
            draw.text((col * 160 + 3, row * 365 + 2), f'{variant}: {screen}', fill='black')
            if name in shots:
                with Image.open(shots[name]) as original:
                    thumb = original.convert('RGB'); thumb.thumbnail((160, 345))
                    sheet.paste(thumb, (col * 160, row * 365 + 20))
    sheet.save(args.output / f'comparison-{language}.jpg', quality=88)
for name in ['matrix-en-light-home', 'matrix-en-light-info', 'matrix-en-light-edit', 'matrix-en-light-tax', 'matrix-en-light-child-setup', 'matrix-en-light-child-detail', 'matrix-es-ax3-goals', 'matrix-ja-dark-home', 'matrix-ko-light-voice', 'matrix-en-light-result', 'result---few', 'result---over', 'font-licenses', 'child-tax', 'matrix-en-light-info-child', 'matrix-en-light-goals-unset', 'matrix-es-ax3-home', 'matrix-ko-ax3-edit', 'normal-new-store-onboarding', 'income-entry', 'child-support-defaults', 'no-spend-empty-day', 'matrix-ko-ax3-month-result', 'existing-child-setup']:
    if name in shots:
        with Image.open(shots[name]) as original:
            original.save(args.output / f'{name}.png')
(args.output / 'capture_inventory.json').write_text(json.dumps(sorted(shots), indent=2) + '\n')
print(f'{len(shots)} screenshots inventoried; contact sheets and selected full-resolution evidence saved.')
