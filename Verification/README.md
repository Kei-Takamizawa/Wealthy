# Verification

Run from the repository root on a Mac with Xcode installed. Pure rule checks, native Mac measurements, unsigned iOS builds, and real-device interaction validate different parts of the app.

## Receipt parsing and photographed samples

```sh
python3 Verification/verify_receipt_ocr.py
```

This runs 91 text, coordinate, date, and category fixtures, then type-checks the Apple Vision scanner against the iOS Simulator SDK. It does not measure photographed-receipt accuracy.

The [15-image development evaluation](ReceiptImageOCR/RESULTS.md) separates native Mac and physical-iPhone measurements. It includes the sample scope, fixed manual labels, denominator exclusions, selected-row CER, and reproducible commands. Receipt images, raw OCR, and manual transcriptions stay outside Git.

## Financial backup and receipt images

```sh
sh Verification/verify_backup.sh
```

The 114 checks use the actual finance models in an in-memory SwiftData container, synthetic PNGs, and temporary files. They cover record/image round trips, deduplicated size calculation, records-only export, legacy files without chat import, malformed archives, invalid images and filenames, and rollback after an injected commit failure. Schema 4 preserves each record’s currency, point cards and payment/provisional-wallet metadata, and accepts schema 1–3 archives with legacy amounts treated as JPY. The checks do not operate the iOS file exporter or prove image display on a phone.

## Display languages and local bookkeeping

```sh
sh Verification/verify_localization.sh
sh Verification/verify_payments.sh
sh Verification/verify_migration.sh
```

The 6,634 localization assertions cover all 196 catalog keys in 11 languages, formatting placeholders, persisted choices, English fallback, Arabic direction, and category aliases. They establish catalog completeness, not native-speaker translation review or device layout.

The 96 payment and ledger checks use synthetic OCR text and actual in-memory SwiftData. They check 24 payment identifiers, absence of payment evidence, advertising and transaction-ID exclusions, ambiguous methods/points redemption, negative provisional wallets, one-time debits, income signs, edited/deleted entries, separate points, and unfinished edits remaining outside autosave. They do not measure payment-method recognition on photographs or access bank accounts.

Eleven migration checks open a persisted Mac SwiftData store created with the earlier `c0120a0` finance schema, preserve its records and balances, validate new defaults, and write a point card. This is not an installed iOS app-upgrade test.

## Currency precision and preferences

```sh
sh Verification/verify_currency.sh
```

The 40 checks cover exact integer/minor-unit round trips for JPY, USD and KWD in English, French and Arabic locales, the integer bounds, Decimal totals larger than a single record can store, and persistence of one or multiple enabled currencies and the active currency. The app supports 155 currency codes. These checks do not establish foreign-receipt OCR or exchange-rate conversion; neither is provided.

## Reply language, message expiration, and ticker projection

```sh
sh Verification/verify_policies.sh
```

The 65 language checks cover language decisions and instructions across the display languages, quoted dialogue, imperative responses, and code/quotation exclusions. Four expiration checks cover both sides of the 24-hour boundary, including the exact boundary and future timestamps. Four projection checks cover center/edge scale, blur, fade, symmetry, and a zero-width viewport. These are deterministic policy checks, not model-quality or iOS interaction measurements.

## Money-tip facts and actual generation

```sh
sh Verification/verify_money_tip.sh
```

The 1,524 checks across 17 fixtures and 11 languages test situation selection, bounded factual actions, fallback humor, and Codable round trips. Wallet balances are not substituted for unrecorded income. The model writes a short playful opening; the app appends a situation-appropriate action derived from the records. Invalid or unavailable generation uses the local fallback opening.

To measure the actual on-device service with three synthetic financial scenarios in each of the 11 display languages:

```sh
sh Verification/verify_ticker_model.sh /private/tmp/wealthy-ticker-model-results.json
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

## Physical-device automation

The shipping project is kept separate from the test project. Generate a temporary Xcode project with a dedicated `com.harrison.Wealthy.DeviceTest` application ID:

```sh
python3 Verification/prepare_device_tests.py /private/tmp/wealthy-device-verification
xcodebuild -project /private/tmp/wealthy-device-verification/Wealthy.xcodeproj \
  -scheme Wealthy -destination 'id=YOUR_IPHONE_UDID' \
  -derivedDataPath /private/tmp/wealthy-device-build -allowProvisioningUpdates \
  -resultBundlePath /private/tmp/wealthy-device-results.xcresult test
```

Use `xcrun devicectl list devices` to find the connected device. The generator inherits the project’s signing team; use `--team YOUR_TEAM_ID` to override it. iOS may require trusting the development signer under **Settings → General → VPN & Device Management**. The test app has its own records, receipt files and language preferences; the normal Wealthy app's container is not reset. Tests create synthetic records and screenshot attachments. To rerun the initial negative-wallet checks, use a fresh test-app container; remove only the dedicated DeviceTest app, never the normal app or its data.

The UI suite exercises negative provisional Cash, wallet editing, cancelling and saving expense edits, point-card registration/cancel, the backup size dialog, Calendar/Analysis, actual Japanese/English AI replies, all 11 initial language choices, and preference persistence. Its multi-currency cases cover language → currency onboarding, one/multiple choices, empty-selection prevention, persistent defaults, USD decimal expenses and income, independent JPY balances, and AI responses that keep JPY/USD spending separate. A separate settings case changes display languages without forcing onboarding and checks the saved choice after relaunch. Core tests exercise the real iOS SwiftData ledger, Decimal chart aggregates above the Int range, and schema-4 image/point/currency backup while excluding chat.

The initial-language case deliberately relaunches the separate test app with `-hasSelectedLanguage NO` to reproduce a fresh choice in each language. This override is a test launch argument, not normal app behavior. Normal relaunches retain the chosen language; the production app is never launched with this override.

Optionally pass `--receipt-images /path/to/private/images --receipt-truth /path/to/private/labels.json` to the generator for the image-measurement test. Inputs are copied only into the temporary project, given anonymous IDs, and never added to Git. The result bundle contains raw OCR and receipt data; keep it private. The measurement tests record recognition results without treating every completion as an accurate total or category.

## Device interaction checks

On an Apple Intelligence-capable iPhone or iPad:

1. On a clean install, select a language, then one or multiple currencies in the next popup. Relaunch and confirm both choices persist without showing either popup again. Change the enabled/default currencies in Settings. Record JPY, USD and a three-decimal currency and check that balances, history, analysis and backup preserve their units. Check the popup also appears when Apple Intelligence is unavailable.
2. In every display language, ask Japanese and English questions and check the reply language. Try a language the installed model reports as unsupported and check the explicit explanation. Disable Apple Intelligence, check the explanatory screen, then enable it and return to the app.
3. Scan receipts with and without printed dates and payment methods. Review uncertain totals, confirm the image is saved, and check that a needed category appears in Settings. Cancel a draft and an edited entry; balances must remain unchanged. Save, edit the amount/wallet, and delete an entry; each wallet must reflect exactly one change. Test points redemption and several matching wallets requiring review.
4. Register a provisional wallet with its earlier opening balance and edit another to its actual current balance. Register, edit, cancel and delete a point card. Export records with and without receipt images. Confirm the size popup and restore both files into disposable test data. Check points and images restore and chat never reappears.
5. Check chat at, before, and after 24 hours, including app suspension and resume. Expired messages must be absent from display and AI context after resume.
6. Request money tips after changing income, spending, and assets. Check the moving ticker in light/dark system appearance, with Reduce Motion and VoiceOver, and when a new sentence replaces an active one.

The [physical-device results](DeviceUI/RESULTS.md) identify the 11 completed iPhone cases and their limits. Items above that are outside those cases remain unverified. Mac component rendering and animation checks do not substitute for phone screenshots or device interaction.

## New ledger foundation (WealthyCore)

```sh
sh Verification/verify_core.sh
```

This runs the Swift Testing suite on the Mac, without a simulator. It covers the new ledger's derived balances, command validation, previews, undo, receipts, recurring entries, budgets, queries, and versioned backups. The performance case reports median query times for 10,000 synthetic entries across ten wallets; timing is informational and has no pass/fail threshold.

WealthyCore is linked to the app but no current screen uses it yet. Its separate store and receipt directory leave legacy records and images untouched. Package tests and unsigned builds do not establish physical-device behavior or CloudKit synchronization.
