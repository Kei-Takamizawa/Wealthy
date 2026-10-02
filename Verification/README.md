# Verification

Run from the repository root on a Mac with Xcode installed. Pure rule checks, native Mac measurements, unsigned iOS builds, and real-device interaction validate different parts of the app.

## Receipt parsing and photographed samples

```sh
python3 Verification/verify_receipt_ocr.py
```

This runs 79 text, coordinate, date, and category fixtures, then type-checks the Apple Vision scanner against the iOS Simulator SDK. It does not measure photographed-receipt accuracy.

The [15-image development evaluation](ReceiptImageOCR/RESULTS.md) reports native Mac Vision results and actual Apple Foundation Models category calls separately. It includes the sample scope, fixed manual labels, denominator exclusions, selected-row CER, and reproducible commands. Receipt images, raw OCR, and manual transcriptions stay outside Git.

## Financial backup and receipt images

```sh
sh Verification/verify_backup.sh
```

The 91 checks use the actual finance models in an in-memory SwiftData container, synthetic PNGs, and temporary files. They cover record/image round trips, deduplicated size calculation, records-only export, legacy files without chat import, malformed archives, invalid images and filenames, and rollback after an injected commit failure. They do not operate the iOS file exporter or prove image display on a phone.

## Reply language, message expiration, and ticker projection

```sh
xcrun swiftc -module-cache-path /private/tmp/wealthy-language-cache \
  Wealthy/Wealthy/ReplyLanguagePolicy.swift Verification/ReplyLanguage/main.swift \
  -o /private/tmp/wealthy-language-checks
/private/tmp/wealthy-language-checks

xcrun swiftc -module-cache-path /private/tmp/wealthy-retention-cache \
  Wealthy/Wealthy/ChatRetentionPolicy.swift Verification/ChatRetention/main.swift \
  -o /private/tmp/wealthy-retention-checks
/private/tmp/wealthy-retention-checks

xcrun swiftc -module-cache-path /private/tmp/wealthy-projection-cache \
  Wealthy/Wealthy/AITickerProjection.swift Verification/ChatRetention/TickerProjection/main.swift \
  -o /private/tmp/wealthy-projection-checks
/private/tmp/wealthy-projection-checks
```

The 55 language checks cover language decisions and instructions, quoted dialogue, imperative responses, and code/quotation exclusions. Four expiration checks cover both sides of the 24-hour boundary, including the exact boundary and future timestamps. Four projection checks cover center/edge scale, blur, fade, symmetry, and a zero-width viewport. These are deterministic policy checks, not model-quality or iOS interaction measurements.

## Money-tip facts and actual generation

```sh
xcrun swiftc -module-cache-path /private/tmp/wealthy-money-tip-cache \
  Wealthy/Wealthy/MoneyTipContext.swift Verification/MoneyTip/main.swift \
  -o /private/tmp/wealthy-money-tip-checks
/private/tmp/wealthy-money-tip-checks
```

The 204 checks across 13 fixtures test situation selection, bounded factual actions, fallback humor, and Codable round trips. Wallet balances are not substituted for unrecorded income. The model writes a short playful opening; the app appends a situation-appropriate action derived from the records. Invalid or unavailable generation uses the local fallback opening.

To measure the actual on-device service with six synthetic financial scenarios in English and Japanese:

```sh
xcrun swiftc -parse-as-library -module-cache-path /private/tmp/wealthy-ticker-model-cache \
  Wealthy/Wealthy/LocalLLMService.swift Wealthy/Wealthy/ReplyLanguagePolicy.swift \
  Wealthy/Wealthy/ReceiptCategoryPolicy.swift Wealthy/Wealthy/MoneyTipContext.swift \
  Wealthy/Wealthy/FinancialDataSummary.swift Wealthy/Wealthy/LanguageManager.swift \
  Wealthy/Wealthy/Item.swift Verification/TickerAdvice/Evaluate.swift \
  -o /private/tmp/wealthy-ticker-model-evaluation
/private/tmp/wealthy-ticker-model-evaluation /private/tmp/wealthy-ticker-model-results.json
```

Apple Intelligence must be enabled and ready on the Mac. This test accesses no app database. Its output identifies fallback use rather than counting fallback text as model generation. The [native generation results](TickerAdvice/RESULTS.md) separate actual generation from fallback use. Humor quality requires human review and is not a numeric accuracy score.

## App builds

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

An unsigned build checks compilation. It does not establish device installation, iOS model inference, or successful interaction.

## Device interaction checks

On an Apple Intelligence-capable iPhone or iPad:

1. On a clean install, select each language in the initial popup. Relaunch and confirm the choice persists without showing the popup again. Check the popup also appears when Apple Intelligence is unavailable.
2. In both display languages, ask Japanese and English questions and check the reply language. Disable Apple Intelligence, check the explanatory screen, then enable it and return to the app.
3. Scan receipts with and without printed dates. Review uncertain totals, confirm the image is saved, and check that a needed new category appears in Settings.
4. Export records with and without receipt images. Confirm the size popup and restore both files into disposable test data. Check images can be opened after image-inclusive restore and chat never reappears.
5. Check chat at, before, and after 24 hours, including app suspension and resume. Expired messages must be absent from display and AI context after resume.
6. Request money tips after changing income, spending, and assets. Check the moving ticker in light/dark system appearance, with Reduce Motion and VoiceOver, and when a new sentence replaces an active one.

These end-to-end iPhone/iPad interactions remain unverified in the development environment. Mac component rendering and animation checks do not substitute for phone screenshots or device interaction.
