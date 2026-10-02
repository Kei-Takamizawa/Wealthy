#!/usr/bin/env python3
"""Run receipt-parser fixtures and type-check the Vision scanner with the iOS SDK."""

from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PARSER = ROOT / 'Wealthy/Wealthy/ReceiptTextParser.swift'
SCANNER = ROOT / 'Wealthy/Wealthy/ReceiptScanner.swift'
FIXTURES = ROOT / 'Verification/ReceiptOCR/main.swift'


def run(arguments, label):
    result = subprocess.run(arguments, cwd=ROOT, capture_output=True, text=True)
    if result.stdout:
        print(result.stdout, end='')
    if result.stderr:
        print(result.stderr, end='', file=sys.stderr)
    if result.returncode:
        raise RuntimeError(f'{label} failed (exit {result.returncode})')
    print(f'PASS: {label}')
    return result.stdout.strip()


def main():
    with tempfile.TemporaryDirectory(prefix='wealthy-receipt-ocr-') as directory:
        temporary = Path(directory)
        executable = temporary / 'receipt-parser-regression'
        cache = temporary / 'module-cache'
        run(['xcrun', 'swiftc', '-module-cache-path', str(cache), str(PARSER),
             str(FIXTURES), '-o', str(executable)], 'receipt fixture compilation')
        run([str(executable)], 'receipt parser regression')
        sdk = run(['xcrun', '--sdk', 'iphonesimulator', '--show-sdk-path'], 'iOS SDK lookup')
        run(['xcrun', 'swiftc', '-sdk', sdk, '-target', 'arm64-apple-ios26.0-simulator',
             '-module-cache-path', str(cache), '-typecheck', str(SCANNER), str(PARSER)],
            'Vision scanner and parser type checking')


if __name__ == '__main__':
    try:
        main()
    except RuntimeError as error:
        print(f'FAIL: {error}', file=sys.stderr)
        sys.exit(1)
