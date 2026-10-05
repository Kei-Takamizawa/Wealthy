# Wealthy

[English](README.md)

Wealthy is an iPhone and iPad app for recording expenses, income, and wallet balances. Receipt scanning, spending summaries, and on-device AI help you review your finances.

## Features

- Record income and expenses by wallet and category.
- Scan receipts, review the details, and retain the original images.
- Review transactions in a calendar and spending by category.
- Apply monthly recurring entries when the app opens.
- Ask Apple Foundation Models questions about your records.
- Read short, lightly humorous tips based on recorded income, spending, and assets.
- Export and restore financial records, optionally including receipt images.
- Record assets and transactions in multiple currencies, with balances kept separate.


## Multiple currencies

- Wealthy supports **155 active ISO 4217 currencies**, based on the [SIX list published on 2026-09-17](https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml).
- After choosing a display language on first launch, select one or more currencies to enable. In **Home → Settings**, edit enabled currencies and choose the default currency for new entries.
- Assets and transaction history retain each record’s stored currency. Balances stay separate, and Analysis can switch between enabled currencies. Wealthy does not convert currencies automatically.
- Amounts are stored in ISO minor units, with 0 decimal places for JPY, 2 for USD, and 3 for KWD. Existing records remain in JPY.
- Receipt OCR is unchanged: it targets Japanese and English text and automatically extracts integer JPY. Foreign-currency amounts require manual entry and review.

## Payment methods and point cards

Receipts suggest the wallet matching their printed payment method; no payment evidence defaults to Cash. Confirming Save deducts the amount once. If the wallet is missing, it is created at zero and becomes negative (for example, `¥0 → ¥-1,200`). Editing or deleting a record adjusts its wallet balance. Multiple payment methods, points redemption, and several matching wallets require manual review. These are OCR text heuristics; payment-method accuracy on photographed receipts has not been measured.

In **Wallets**, edit an automatically created wallet to set its current balance, or register it with an opening balance that is added to the recorded balance. Register point cards with a name, optional member number, points balance, and optional expiry date. Points are entered manually, kept separate from monetary assets, and included in financial backups.

Automatic bank or payment-service synchronization is **not implemented**. SBI Shinsei Bank and DOCOMO SMTB Net Bank (formerly SBI Sumishin Net Bank) are the first proposed integrations. Opening a banking app alone cannot read its balance: an approved account-sharing service is required. See the [integration assessment](Documentation/FinancialServiceIntegration.md) for provider requirements and the proposed consent flow.

## Requirements

**iOS or iPadOS 26.0 or later** and an **Apple Intelligence-capable device** are required. Apple Intelligence must be enabled and its system model ready before the app can be used.

| Device | Supported hardware |
| --- | --- |
| iPhone | iPhone 15 Pro / Pro Max, iPhone 16 models and later, or iPhone Air |
| iPad | Models with M1 or later, or iPad mini with A17 Pro |

Apple's language and regional restrictions also apply. Wealthy checks model availability at launch and when returning to the foreground. See [Apple's current requirements](https://www.apple.com/apple-intelligence/).

## Using the app

1. Enable Apple Intelligence in **Settings → Apple Intelligence & Siri** and wait for its model to finish preparing.
2. Choose one of the **11 display languages** in the first-launch popup. English is the default; your choice is remembered. Change it later under **Home → Settings → Language Settings**. Arabic uses a right-to-left interface.
3. Select one or more currencies to enable. You can change them and the default entry currency later in **Home → Settings**.
4. Add a wallet and record income or scan a receipt. Review recognized details before saving.
5. Review the Calendar and Analysis tabs, or open the AI assistant to ask about your records.

The display languages are English, Japanese, Simplified Chinese, Hindi, Spanish, Arabic, French, Indonesian, Korean, Russian, and Portuguese. This list applies to the interface and these README editions; it does not mean the installed Apple AI model supports all 11 languages.

## On-device AI

Chat, receipt enrichment, and short spending comments use Apple's built-in **SystemLanguageModel**. The OS manages the model and its updates. There are no alternate models, model download or selection screens, or connections to Private Cloud Compute or another cloud AI provider.

Chat requests an answer in the language of the latest message, independently of the display language. If the input language cannot be determined, it uses the display language. Supported languages depend on the installed Apple model. Unsupported chat languages produce an explicit message: try a language supported by that model. Spending comments request the display language and combine an AI-written joke with an action derived from your records; a local tip is used when generation is unavailable.

## Records, receipts, and backup

Financial records and receipt images are stored on the device. Under **Home → Settings → Data Management**, export wallets, income, expenses, recurring entries, and categories as JSON. A popup shows the size of referenced receipt images and lets you include them or export records only. Shared images are embedded once. JSON encoding adds approximately **33%** to image data size.

Restoring replaces current records. Image-inclusive backups restore original image data; records-only backups cannot restore images. Older record backups remain readable, but chat history in them is ignored. Large image collections may require substantial memory during export or restore.

**Chat history is excluded from all app exports.** Messages expire **24 hours** after creation. Wealthy deletes expired messages while running and checks at launch and foreground return. If iOS suspends or terminates the app, deletion occurs when it next runs. Expired messages are excluded from display and AI context.

Receipt OCR targets **Japanese and English text**. Automatic amount extraction targets **integer Japanese yen**; foreign currencies need manual entry. Amounts and dates come from the OCR parser, not AI guesses. A readable printed date is used; otherwise the date is taken when the camera scan returns, before recognition, and marked for review. An appropriate existing category is reused; a new category is created when needed. All extracted details are editable.

In a native iPhone 16 Pro Max run on iOS 27.2 using the same **15 development images**, JPY totals matched in **6/10** readable cases; the other four were unconfirmed. Printed dates matched **14/14**, and hybrid categories matched **14/14 labeled samples**; selected-line character error rate remained **11.22%**. This corpus was also used during development: these are not held-out results or accuracy estimates for new receipts. See the [measurement report](Verification/ReceiptImageOCR/RESULTS.md) for the historical macOS results, exclusions, and details. Always review results before saving.

## Build from source

Use Xcode with the **iOS 26 SDK or later**. Development builds are checked with **Xcode 27.0**. Open `Wealthy/Wealthy.xcodeproj`, select the **Wealthy** scheme, configure your signing team, and run on a compatible iPhone or iPad. The project uses Apple system frameworks with no external Swift package dependencies.

Physical checks on an iPhone 16 Pro Max with iOS 27.2 confirmed Japanese/English AI replies and local expense, wallet, point-card and backup-dialog operations. Other devices and untested workflows remain unverified. See [verification instructions](Verification/README.md).

The **v0.1.1 pre-release** contains the source described here. It does not include a signed app download; review the verification limits above before building.

## License

All rights reserved. Redistribution of source code or binaries requires permission.
