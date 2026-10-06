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
    formats = [re.findall(r'%[d@sf]',v['stringUnit']['value']) for v in row['localizations'].values()]
    assert all(value == formats[0] for value in formats), key
for source in app.glob('*.swift'):
    text = source.read_text()
    assert not any(word in text for word in ['import SwiftData','@Model','@Query','modelContainer(', 'default.store']), source
    for key in re.findall(r'\.t\("([^"\\]+)"\)', text): assert key in strings, (source,key)
manifest = json.loads((root/'Verification/font_manifest.json').read_text())
for item in manifest['fonts']:
    path = app/'Fonts'/item['file']
    assert hashlib.sha256(path.read_bytes()).hexdigest() == item['subsetSHA256']
    font = TTFont(path)
    assert font['name'].getDebugName(6) == path.stem
    if 'PoorStory' in path.name: assert all(i in font.getBestCmap() for i in range(0xac00,0xd7a4))
    if 'PatrickHand' in path.name: assert all(ord(c) in font.getBestCmap() for c in 'áéíóúüñÁÉÍÓÚÜÑ¿¡')
print(f'PASS: {len(strings)} keys x 4 languages, placeholder parity, new-target isolation, 4 subset hashes and Hangul/Spanish coverage')
