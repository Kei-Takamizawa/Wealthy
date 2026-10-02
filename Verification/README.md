# Verification

Run these checks from the repository root on a Mac with Xcode installed.

## Receipt parser

`python3 Verification/verify_receipt_ocr.py`

This compiles and runs 42 text-and-coordinate fixtures, then type-checks the Apple Vision scanner against the iOS Simulator SDK. It does not measure recognition accuracy on photographed receipts.

## Reply language

Compile the actual language policy together with its fixtures:

```sh
xcrun swiftc -module-cache-path /tmp/wealthy-language-cache Wealthy/Wealthy/ReplyLanguagePolicy.swift Verification/ReplyLanguage/main.swift -o /tmp/wealthy-language-checks
/tmp/wealthy-language-checks
```

The 49 checks cover Japanese input with an English fallback, English input with a Japanese fallback, short messages, other languages, ambiguous numeric input, and output-language checks that distinguish prose from code and quotations. They test language decisions and response instructions, not generated model answers.

## App builds

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
```

An unsigned build checks compilation; it does not establish device installation or successful model inference.

## Device tests

On an Apple Intelligence-capable iPhone or iPad:

1. Set the display language to English. Ask a Japanese question, then an English question, and check each reply's language.
2. Repeat with Japanese display language and a conversation containing earlier replies in the other language.
3. Disable Apple Intelligence, reopen the app, and check the explanatory screen. Enable it, finish model preparation, and verify that returning to the app or pressing Check Again restores access.
4. Scan photographed receipts and compare the saved details against the images, including unclear totals that require manual entry.

Real-device responses, language compliance, receipt recognition accuracy, and app interaction remain unverified in the current development environment.
