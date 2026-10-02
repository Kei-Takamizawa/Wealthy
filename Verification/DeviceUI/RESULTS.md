# Physical-device verification — October 2–3, 2026

Tested on an **iPhone 16 Pro Max running iOS 27.2**, with Apple Intelligence enabled, using Xcode 27.0. Tests used a separately signed app with its own data container. No real bank account or personal financial record was used. Device identifiers, signer details, receipt images, raw OCR and result bundles are not published.

## Executed checks

| Test case | Observed result |
| --- | --- |
| Bookkeeping, points and backup dialog | Passed: a 1,200-yen expense created Cash at −1,200; setting the current balance to 5,000, cancelling an expense edit and then saving its 700-yen replacement produced the expected balances. Point-card registration and cancelling a points edit preserved 900 points. The receipt-image size/choice dialog, Calendar and Analysis opened. |
| Actual chat replies | Passed: in English UI, a Japanese spending question received a Japanese answer containing the recorded 700 yen; a subsequent English question received an English answer with the same recorded amount. Generated wording varied between runs. |
| Initial language choices | Passed: all 11 choices opened the app. A normal relaunch retained the last choice, Portuguese, without showing onboarding. |
| Language changes in Settings | Passed: English, Hindi, Arabic and Japanese were selected from Settings in the same session. A normal relaunch retained Japanese without showing onboarding. |
| iOS SwiftData ledger | Passed: one-time debit, discarded edits remaining outside autosave, saved amount changes, one persisted entry, and reversal on delete. |
| Image/points backup | Passed: schema-4 backup and restore preserved the balance, point card and exact synthetic PNG bytes; the restored image decoded on iOS under a fresh filename. Chat was absent from the exported archive. |
| Multiple currencies and onboarding | Passed: language selection preceded the currency popup; one JPY choice and multiple JPY/USD choices worked, while an empty selection could not be saved. The choice and USD default survived normal relaunches without either popup. A USD 12.34 expense created a separate wallet at −12.34; adding USD 100.00 produced 87.66 while JPY Cash stayed at 5,500. Settings, per-currency Analysis, and Calendar were checked. |
| Currency ledger and backup | Passed: JPY, USD and KWD amounts stayed separate through iOS ledger operations and schema-4 backup/restore. USD two-decimal and KWD three-decimal input values were preserved. |
| Large historical totals | Passed: valid expenses totalling Int.max + 1 produced the expected Int.min wallet balance; bar and pie chart totals used Decimal without an integer overflow. |
| Actual mixed-currency chat | Passed after language-recovery changes: Japanese then English questions returned JPY 700 and USD 12.34 separately, through the real Apple model service. Localized currency names or ISO codes were accepted. No template fallback was used. |
| Receipt-image measurement | Completed all 15 supplied images using the shipping scanner and real Apple model service. Accuracy is reported separately below. |

The six original cases passed together with zero failures, skips or runtime warnings. The Settings case and four additional currency/aggregate/chat cases also passed: **11 unique cases passed across the October 2–3 runs**. They were not all executed in one final run. The first currency run found a search UI problem and a fixture with an unintended legacy wallet name; the UI and fixture were corrected before rerunning. The mixed-language chat exposed a rejected English turn; chat now excludes clearly conflicting earlier assistant prose and can retry from authoritative facts in a fresh session. A successful receipt-measurement test establishes completion, not perfect extraction. See the [15-image evaluation](../ReceiptImageOCR/RESULTS.md).

The initial-choice case intentionally launches the test app with an argument reproducing first launch, then terminates it between languages. Those visible exits are test operations. Normal app launches have no override: the first selection is remembered, and users can change it later in Settings. The available device crash-log listing contained **zero Wealthy reports** when checked; this is not a guarantee that every future workflow is crash-free.

## Fixes checked on the phone

- Removed color inversion from the expense date picker and matched its system appearance to the dark editor; the date became readable.
- Made payment-method and date input groups use the editor's full width.
- Expanded the initial language popup and allowed longer Home button labels to wrap to two lines. English, Hindi, Arabic and Japanese screenshots were reviewed after the button change.
- Kept currency confirmation and cancellation accessible while searching, above the keyboard.
- Validated positive deposits through the ledger and used Decimal for historical totals to prevent integer-overflow crashes.
- Added conservative food evidence for an explicit reduced-tax-rate subtotal when item names are unclear. Newspaper/subscription and mixed standard-tax evidence suppress that inference. The final photographed-receipt category result is a development-set measurement, not model-only accuracy.

The device reported model support for English, Japanese, Simplified Chinese, Spanish, French, Korean and Portuguese. Hindi, Arabic, Indonesian and Russian were unsupported by its installed model. All 11 interface languages remain selectable; AI support is queried from Apple's API rather than inferred from interface availability.

## Build checks and limits

The final source compiled in **Release** for both generic iOS Simulator and the physical iPhone. The normally signed app is version **0.1.1**, build **2**. The disposable test app and runner are removed after testing; test records are not copied into the normal app.

Not verified: a live camera capture session, iOS Files export/import interactions, a real installed-app data migration, live financial-service authorization/synchronization, a full 24-hour suspension cycle, VoiceOver, Reduce Motion on this phone, alternate hardware/OS versions, every screen in every language, or native-speaker translation review. Core backup tests verify the archive and iOS image data separately from the file-picker UI. Mac animation and policy results are documented separately and do not establish those untested phone workflows.
