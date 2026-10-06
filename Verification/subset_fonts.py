#!/usr/bin/env python3
"""Reproduce the bundled OFL subsets; needs fontTools and pdfplumber, not app dependencies."""
from pathlib import Path
import hashlib
import json
import urllib.request
from io import BytesIO
import argparse
from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'Wealthy/Wealthy/Fonts'
ITEMS = [
 ('kleeone','KleeOne-Regular','bf4063f030cc2ae6adf0a11424a1888e5c0eb4438f1f6d02f52294af868e9b3a'),
 ('kleeone','KleeOne-SemiBold','b031ec426c23ca1143ef1f7d58bee7a79efe119ed654152f121c922202b303fd'),
 ('poorstory','PoorStory-Regular','831ab87f7b5463f9cd83ac249bf386816f3a478f1d226427c88cac907adb7ee2'),
 ('patrickhand','PatrickHand-Regular','0f173b3e6cb6d1af25babf7f0057c5ac4ee11f9992b0469bb817e967ef4ad0fc')]
JOYO_URL = 'https://www.bunka.go.jp/kokugo_nihongo/sisaku/joho/joho/kijun/naikaku/pdf/joyokanjihyo_20101130.pdf'
parser = argparse.ArgumentParser()
parser.add_argument('--joyo-file', type=Path, help='Previously extracted primary forms from the official PDF')
args = parser.parse_args()
joyo = set()
if args.joyo_file:
    joyo = set(map(ord, args.joyo_file.read_text()))
else:
    import pdfplumber
    with pdfplumber.open(BytesIO(urllib.request.urlopen(JOYO_URL).read())) as pdf:
        for page in pdf.pages[10:161]:
            for word in page.extract_words():
                if 17.8 < word['height'] < 19.1 and 95 < word['x0'] < 120:
                    char = next((c for c in word['text'] if '\u3400' <= c <= '\u9fff' or '\U00020000' <= c <= '\U0002ffff'), None)
                    if char: joyo.add(ord(char))
# Retain first-column variants from the official PDF rather than pruning the extracted forms.
assert len(joyo) >= 2136, len(joyo)
latin = set(range(0x20,0x250)) | set(range(0x2000,0x2070)) | {0x20a9,0x20ac,0xffe5}
manifest = []
DEST.mkdir(parents=True, exist_ok=True)
for folder, name, sha in ITEMS:
    url = 'https://raw.githubusercontent.com/google/fonts/main/ofl/' + folder + '/' + name + '.ttf'
    data = urllib.request.urlopen(url).read()
    assert hashlib.sha256(data).hexdigest() == sha
    font = TTFont(BytesIO(data)); chars = latin.copy()
    if folder == 'kleeone': chars |= joyo | set(range(0x3000,0x3100)) | set(range(0xff00,0xffef))
    if folder == 'poorstory': chars |= set(range(0xac00,0xd7a4)) | set(range(0x1100,0x1200)) | set(range(0x3130,0x3190))
    options = subset.Options(); options.name_IDs = ['*']; options.name_legacy = True; options.name_languages = ['*']
    sub = subset.Subsetter(options=options); sub.populate(unicodes=chars); sub.subset(font)
    family = 'Wealthy' + name.split('-')[0]; style = name.split('-')[1]
    for record in font['name'].names:
        values = {1:family,3:family+'-'+style,4:family+' '+style,6:family+'-'+style,16:family}
        if record.nameID in values: record.string = values[record.nameID].encode(record.getEncoding())
    destination = DEST / (family+'-'+style+'.ttf'); font.save(destination)
    license_data = urllib.request.urlopen('https://raw.githubusercontent.com/google/fonts/main/ofl/'+folder+'/OFL.txt').read()
    (DEST / (name.split('-')[0]+'-OFL.txt')).write_bytes(license_data)
    manifest.append({'source':url,'sourceSHA256':sha,'file':destination.name,'bytes':destination.stat().st_size,'subsetSHA256':hashlib.sha256(destination.read_bytes()).hexdigest()})
(ROOT / 'Verification/font_manifest.json').write_text(json.dumps({'joyoSource':JOYO_URL,'extractedJoyoForms':len(joyo),'fonts':manifest},indent=2)+'\n')
print('PASS: 4 source hashes verified; total subset bytes:',sum(i['bytes'] for i in manifest))
