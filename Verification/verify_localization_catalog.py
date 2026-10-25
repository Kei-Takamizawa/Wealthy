#!/usr/bin/env python3
"""Verify the shipping app catalog, independently of the archived app checks."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
catalog = json.loads((root / 'Wealthy/Wealthy/Localizable.xcstrings').read_text())
assert catalog['sourceLanguage'] == 'en'
languages = {'en', 'ja', 'es', 'ko'}
for key, row in catalog['strings'].items():
    assert set(row['localizations']) == languages, (key, 'unexpected or missing language')
    signatures = []
    for language, translation in row['localizations'].items():
        unit = translation['stringUnit']
        assert unit['state'] == 'translated' and unit['value'].strip(), (key, language)
        signatures.append(sorted(re.findall(r'%(?:\d+\$)?[d@sf]', unit['value'])))
    assert all(value == signatures[0] for value in signatures), (key, 'placeholder mismatch')
for directory in [root / 'LegacyApp', root / 'Wealthy/Wealthy']:
    assert {p.stem for p in directory.glob('*.lproj')} <= languages, directory
print(f"PASS: shipping app {len(catalog['strings'])} keys x 4 languages; zero missing keys; English base; placeholder parity")
