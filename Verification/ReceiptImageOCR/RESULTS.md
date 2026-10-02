# Receipt evaluation — 2026-10-02

These are development-set measurements on 15 supplied images, not a held-out accuracy benchmark. Labels were established by viewing the original images **before running OCR** and were kept fixed while improving the implementation. Source images, filenames, manual transcriptions and OCR output are intentionally excluded from this repository.

## Environment and method

- Native arm64 macOS 27.0.1 (26A434), Xcode's Swift 6.4 compiler.
- Apple Vision `VNRecognizeTextRequest`: `.accurate`, Japanese then English, language correction enabled, minimum text height zero, and the same receipt vocabulary as the iOS scanner. Original images and their EXIF orientation were used without image edits.
- The native harness uses the app's actual `ReceiptTextParser` and position-based row grouping. macOS Vision results do **not** establish identical iOS Vision results.
- The real `LocalLLMService.extractReceiptData` was compiled into a CLI and run with `SystemLanguageModel.default`; availability was `available`. Category measurements used the six default Japanese categories. This was local Mac inference, not iPhone/iPad inference or cloud inference. Apple's API describes this model as [the on-device foundation model](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel).
- Sandbox restrictions initially caused Vision to return `nilError` for every image. Measurements below are from the successful native execution, not those failed attempts.

## Results

| Measurement | Result | Scope |
| --- | ---: | --- |
| JPY total extracted correctly, before fixes | 4/10 (40.0%) | Ten images with a visible integer-JPY payment total |
| JPY total extracted correctly, final parser | 6/10 (60.0%) | Four remaining images require manual amount entry |
| Foreign-currency totals safely left unconfirmed | 4/4 | Dollar amounts are not converted into yen |
| Cropped total safely left unconfirmed | 1/1 | The visible subtotal is not treated as the missing total |
| Correct amount or appropriate refusal, all images | 11/15 (73.3%) | Includes the five safe refusals above; this is not the JPY extraction rate |
| Printed purchase date parsed correctly | 14/14 (100%) | Excludes one image without a printed date |
| Printed date or correctly detected date absence | 15/15 | Date absence triggers the supplied capture timestamp |
| Purpose classification, deterministic fallback | 12/14 (85.7%) | Excludes one mock receipt with meaningless item names |
| Purpose classification, Apple model before evidence override | 12/14 (85.7%) | Wrongly classified a drink purchase as transportation and a book purchase as food |
| Purpose classification, final hybrid service | 13/14 (92.9% on this development set) | Rules take precedence when a recognized purchase purpose is present; AI handles the remainder |
| Legacy store-name candidate contains the manual store label | 6/15 (40.0%) | Strict case-insensitive, width-normalized substring comparison; decorative logos and slogans are difficult |
| Selected-row character error rate | 46/410 (11.22%) | Two selected visible rows per image, 30 rows total; **not complete-receipt OCR accuracy** |

The printed-date sample contains duplicate purchase dates and advertising/return-expiry dates. The parser selected the purchase dates. The one undated image checks absence detection; the `capturedAt` value is supplied by the caller. These downloaded sample images do not validate recovery of an original photo's EXIF capture timestamp.

For the selected-row CER, full-width/half-width and whitespace differences were normalized. No digit guesses or spelling corrections were applied. Each fixed reference row was matched against the closest **whole OCR row** by Levenshtein distance; side-by-side receipts and rotated images can produce extra text in a row. CER is limited to these selected legible rows, including date/total/store fields, and does not quantify every item, hidden text or the whole page.

Category scoring compares purchase purpose, allowing the existing Food category to cover groceries, cafés and restaurant meals, and Hobbies to cover books. Two receipts contain mixed food and nonfood goods; the score uses their manually selected predominant purpose. The mock receipt has no defensible purpose label and is excluded from the classification denominator. Merchant names or keywords are heuristic evidence, so successful development-set classification must not be interpreted as guaranteed category accuracy on new stores or mixed purchases.

## Changes and remaining failure modes

The parser now excludes tax-only and pre-tax body totals, and avoids interpreting a footer's payment advertisement as an additional unreadable payment-total label. Those general fixes improved the visible JPY total result from 4/10 to 6/10. Foreign currency is explicitly rejected even when its currency marker appears to the left of TOTAL. No expected amount from the ground truth is imported into the parser, and missing digits are not invented.

The four unresolved JPY images have two incomplete total labels, one misrecognized total label, and one rotated layout whose bounding boxes combine unrelated rows. They remain amount zero/unconfirmed. A future general improvement could measure document cropping, perspective correction and deskewing on a separate evaluation set before enabling them. This change does not claim those image-processing techniques were implemented or validated.

Dates support Japanese numeric dates, Japanese eras with era boundaries, numeric English month/day/year dates, short years, and English month names. Impossible dates are rejected without Calendar rollover; valid future dates are retained. Short years use the explicit convention 00–69 → 2000–2069 and 70–99 → 1970–1999. Ambiguous numeric English dates currently use month/day/year, so other regional ordering needs review. An incidental CJK recognition error in otherwise English text does not change the numeric date ordering.

The model-only development run also returned unsafe numeric totals for foreign currency and some subtotals. The app therefore preserves the deterministic JPY amount and parsed/capture date instead of replacing them with generated values. Improving the generic category prompt alone left classification at 12/14; the final service combines explicit-purpose rules with AI. **The final 13/14 result belongs to the hybrid service, not to the model alone.** The remaining error is a confectionery purchase assigned to Other when the product text is unclear. The previous AI-only service assigned that image to Food, so the same-image reruns also show why one generated response cannot establish guaranteed behavior.

Three additional synthetic cases with no existing categories returned reusable categories for construction materials, prescription services and books (Japanese Home & DIY, Japanese Healthcare, and English Books): **3/3 purpose/name checks passed**. These check category proposals, not category persistence in SwiftData.

Native Vision processed the 15 final images in approximately 3.91 seconds in total. The final hybrid service completed its 15 receipt calls in approximately 30.55 seconds in total (2.04 seconds per receipt on average). Timing depends on device, OS, model preparation and warm caches and is not an iPhone performance promise.

## Reproduction

The harness accepts an image directory and a private output path:

```sh
xcrun swiftc -module-cache-path /tmp/wealthy-receipt-cache \
  Wealthy/Wealthy/ReceiptTextParser.swift \
  Wealthy/Wealthy/ReceiptCategoryPolicy.swift \
  Verification/ReceiptImageOCR/main.swift \
  -o /tmp/wealthy-receipt-image-ocr
/tmp/wealthy-receipt-image-ocr /path/to/private/images /tmp/wealthy-receipt-results.json
```

Compile the actual app service for local model evaluation:

```sh
xcrun swiftc -parse-as-library -module-cache-path /tmp/wealthy-receipt-cache \
  Wealthy/Wealthy/LocalLLMService.swift \
  Wealthy/Wealthy/ReplyLanguagePolicy.swift \
  Wealthy/Wealthy/ReceiptCategoryPolicy.swift \
  Wealthy/Wealthy/MoneyTipContext.swift \
  Verification/ReceiptModelEvaluation/Evaluate.swift \
  -o /tmp/wealthy-receipt-model-evaluation
/tmp/wealthy-receipt-model-evaluation /tmp/wealthy-receipt-results.json /tmp/wealthy-receipt-model-results.json
```

Manual labels must be independently transcribed and frozen before OCR. The evaluator accepts a private JSON array with `file`, `store`, `totalJPY` (null for unconfirmed/non-JPY), `date` (YYYY-MM-DD or null), `category`, `note` and two selected `lines`. Keep labels, images and output JSON outside the repository:

```sh
python3 Verification/evaluate_receipt_images.py /tmp/private-truth.json \
  /tmp/wealthy-receipt-results.json --model /tmp/wealthy-receipt-model-results.json \
  --output /tmp/wealthy-receipt-evaluation.json
```

Separate rule regression: `python3 Verification/verify_receipt_ocr.py` passed **79/79 fixtures** plus iOS Simulator SDK type checking. Those synthetic text/coordinate/date/category fixtures verify rules and regressions; they are not photographed-receipt accuracy measurements. End-to-end iPhone/iPad scanning, saving, capture-time fallback and category creation still require real-device interaction checks.
