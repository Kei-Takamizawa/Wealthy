#!/usr/bin/env python3
"""Compare PRIVATE manually frozen receipt labels with native Vision measurements.

The truth JSON is prepared from the images before OCR. Inputs/outputs should be
outside the repository; do not publish customer receipt text or source images.
CER covers two selected, visible rows per image, not the complete receipt.
Width and whitespace differences are ignored; no OCR digit corrections are made.
Each selected row is aligned to the closest entire OCR row by edit distance.
"""
import argparse
import json
from pathlib import Path
import unicodedata


def normalized(text):
    return ''.join(unicodedata.normalize('NFKC', text).split())


def distance(a, b):
    row = list(range(len(b) + 1))
    for i, ac in enumerate(a, 1):
        following = [i]
        for j, bc in enumerate(b, 1):
            following.append(min(following[-1] + 1, row[j] + 1, row[j-1] + (ac != bc)))
        row = following
    return row[-1]


# Evaluate purchase purpose, permitting the app's broader existing categories.
# Mixed grocery/nonfood receipts are reviewed separately in the report.
SEMANTIC_LABELS = {
    '食費': {'食費', 'Food', 'Groceries'},
    'カフェ': {'食費', 'カフェ', 'Food', 'Cafe'},
    '外食': {'食費', '外食', 'Food', 'Dining', 'Restaurants'},
    '書籍': {'書籍', '趣味', 'Books', 'Hobbies'},
    '住居・DIY': {'住居・DIY', '住居', 'Home & DIY', 'DIY', 'Home'},
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('truth', type=Path)
    parser.add_argument('vision', type=Path)
    parser.add_argument('--model', type=Path, help='Actual app-service output, including sanitization and any hybrid category rules')
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    truth = json.loads(args.truth.read_text())
    vision = {item['file']: item for item in json.loads(args.vision.read_text())}
    model = {item['file']: item for item in json.loads(args.model.read_text()) if 'file' in item} if args.model else {}
    baseline = {item['file']: item for item in json.loads(args.baseline.read_text())} if args.baseline else {}
    rows = []
    errors = characters = selected = 0
    for label in truth:
        measurement = vision[label['file']]
        assert not measurement.get('error'), f"Vision failed: {label['file']}"
        expected = label.get('totalJPY')
        amount_correct = measurement['amount'] == (expected or 0)
        observed_rows = [normalized(value) for value in measurement['rows']]
        for target in label['lines']:
            target = normalized(target)
            errors += min((distance(target, candidate) for candidate in observed_rows), default=len(target))
            characters += len(target)
            selected += 1
        accepted = SEMANTIC_LABELS.get(label['category'], set())
        model_value = model.get(label['file'], {})
        fields = model_value.get('fields', {})
        rows.append({
            'file': label['file'],
            'readableJPY': expected is not None,
            'amountCorrect': amount_correct,
            'amount': measurement['amount'],
            'expectedJPY': expected,
            'baselineAmountCorrect': baseline.get(label['file'], {}).get('amount') == (expected or 0),
            'dateCorrect': measurement.get('printedDate') == label['date'],
            'printedDate': measurement.get('printedDate'),
            'expectedDate': label['date'],
            'categoryEvaluable': label['category'] is not None,
            'ruleCategoryCorrect': measurement['category'] in accepted,
            'ruleCategory': measurement['category'],
            'modelCategoryCorrect': fields.get('category') in accepted,
            'modelCategory': fields.get('category'),
            'modelError': model_value.get('error'),
            'storeSubstringCorrect': normalized(label['store']).casefold() in normalized(measurement['title']).casefold(),
            'notes': label['note'],
        })
    readable = [r for r in rows if r['readableJPY']]
    labeled = [r for r in rows if r['categoryEvaluable']]
    summary = {
        'images': len(rows),
        'readableJPY': len(readable),
        'readableJPYCorrect': sum(r['amountCorrect'] for r in readable),
        'baselineReadableJPYCorrect': sum(r['baselineAmountCorrect'] for r in readable),
        'allAmountCorrectOrConservativelyRejected': sum(r['amountCorrect'] for r in rows),
        'printedDates': sum(label['date'] is not None for label in truth),
        'printedDatesCorrect': sum(r['dateCorrect'] for r in rows if r['expectedDate'] is not None),
        'allDateOrAbsentCorrect': sum(r['dateCorrect'] for r in rows),
        'categoryEvaluable': len(labeled),
        'ruleCategoryCorrect': sum(r['ruleCategoryCorrect'] for r in labeled),
        'modelCategoryCorrect': sum(r['modelCategoryCorrect'] for r in labeled),
        'storeSubstringCorrect': sum(r['storeSubstringCorrect'] for r in rows),
        'selectedVisibleRows': selected,
        'selectedRowCharacters': characters,
        'selectedRowEditErrors': errors,
        'selectedRowCER': errors / characters,
        'OCRsecondsTotal': sum(r['seconds'] for r in vision.values()),
        'modelSecondsTotal': sum(r['seconds'] for r in model.values()),
    }
    args.output.write_text(json.dumps({'summary': summary, 'rows': rows}, ensure_ascii=False, indent=2))
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
