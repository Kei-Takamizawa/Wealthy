#!/usr/bin/env python3
"""Evaluate a PRIVATE DeviceCore receipt attachment; never commit input/output JSON."""
import argparse
import json
from pathlib import Path

from evaluate_receipt_images import SEMANTIC_LABELS, distance, normalized

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('measurement', type=Path)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
data = json.loads(args.measurement.read_text())
receipts = data['receipts']
readable = [r for r in receipts if r['expected']['totalJPY'] is not None]
unconfirmed = [r for r in receipts if r['expected']['totalJPY'] is None]
dated = [r for r in receipts if r['expected']['date'] is not None]
undated = [r for r in receipts if r['expected']['date'] is None]
classified = [r for r in receipts if r['expected']['category'] is not None]
errors = characters = selected = 0
for receipt in receipts:
    observed = [normalized(row) for row in receipt['rawText'].splitlines()]
    for reference in receipt['expected']['lines']:
        reference = normalized(reference)
        errors += min((distance(reference, row) for row in observed), default=len(reference))
        characters += len(reference)
        selected += 1

def category_correct(receipt):
    category = receipt.get('model', {}).get('category', receipt.get('fallbackCategory'))
    return category in SEMANTIC_LABELS.get(receipt['expected']['category'], set())

summary = {
    'images': len(receipts),
    'readableJPY': len(readable),
    'readableJPYCorrect': sum(r['amount'] == r['expected']['totalJPY'] for r in readable),
    'unconfirmedTotals': len(unconfirmed),
    'unconfirmedTotalsSafelyRejected': sum(r['amount'] == 0 for r in unconfirmed),
    'printedDates': len(dated),
    'printedDatesCorrect': sum(r['dateWasPrinted'] and r['date'] == r['expected']['date'] for r in dated),
    'undatedImages': len(undated),
    'undatedCorrectlyDetected': sum(not r['dateWasPrinted'] for r in undated),
    'categoryEvaluable': len(classified),
    'hybridCategoryCorrect': sum(category_correct(r) for r in classified),
    'modelErrors': sum('modelError' in r for r in receipts),
    'selectedVisibleRows': selected,
    'selectedRowCharacters': characters,
    'selectedRowEditErrors': errors,
    'selectedRowCER': errors / characters if characters else None,
    'combinedOCRAndModelSeconds': sum(r['seconds'] for r in receipts),
    'supportedLocales': data['supportedLocales'],
}
args.output.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n')
print(json.dumps(summary, ensure_ascii=False, indent=2))
