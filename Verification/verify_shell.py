#!/usr/bin/env python3
"""Check catalog interpolation, bundled subsets and isolation from legacy model resources."""
from pathlib import Path
import hashlib
import json
import re
from fontTools.ttLib import TTFont
root = Path(__file__).resolve().parents[1]
app = root / 'Wealthy/Wealthy'
strings = json.loads((app/'Localizable.xcstrings').read_text())['strings']
for key,row in strings.items():
    assert set(row['localizations']) == {'en','ja','es','ko'}, key
    formats = [sorted((int(position) if position else index, kind) for index, (position, kind) in enumerate(re.findall(r'%(?:(\d+)\$)?([d@sf])', v['stringUnit']['value']), start=1)) for v in row['localizations'].values()]
    assert all(value == formats[0] for value in formats), key
for source in app.glob('*.swift'):
    text = source.read_text()
    assert not any(word in text for word in ['import SwiftData','@Model','@Query','modelContainer(', 'default.store']), source
    for key in re.findall(r'\.t\("([^"\\]+)"\)', text): assert key in strings, (source,key)
# Ignore Swift strings and comments when locating calls and argument labels.
swift_ignored = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"""[\s\S]*?"""|"(?:\\.|[^"\\])*"')
for source in (root/'Wealthy').rglob('*.swift'):
    text = source.read_text()
    code = swift_ignored.sub(lambda match: ' ' * len(match.group()), text)
    for call in re.finditer(r'\.\s*custom\s*\(', code):
        depth, end, relative = 1, call.end(), False
        while end < len(code) and depth:
            if depth == 1 and (end == 0 or not (code[end - 1].isalnum() or code[end - 1] == '_')) and re.match(r'relativeTo\s*:', code[end:]): relative = True
            if code[end] == '(': depth += 1
            elif code[end] == ')': depth -= 1
            end += 1
        assert depth == 0 and relative, f'{source}:{text.count(chr(10), 0, call.start()) + 1}: custom font must specify relativeTo:'
manifest = json.loads((root/'Verification/font_manifest.json').read_text())
for item in manifest['fonts']:
    path = app/'Fonts'/item['file']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['subsetSHA256']
    font = TTFont(path)
    assert font['name'].getDebugName(6) == path.stem
    if 'PoorStory' in path.name: assert all(i in font.getBestCmap() for i in range(0xac00,0xd7a4))
    if 'PatrickHand' in path.name: assert all(ord(c) in font.getBestCmap() for c in 'áéíóúüñÁÉÍÓÚÜÑ¿¡')
print(f'PASS: {len(strings)} keys x 4 languages, placeholder parity, new-target isolation, custom font relativeTo, 4 subset hashes and Hangul/Spanish coverage')
