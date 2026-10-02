# Wealthy

English · [Japanese](README.ja.md)

Wealthy is an iPhone and iPad app for tracking everyday expenses, income, and wallet balances. It combines receipt scanning, spending summaries, and on-device AI in a single personal finance app.

## Features

- Record expenses and income with categories and separate wallets.
- Scan receipts, review the extracted details, and keep the original images.
- Browse transactions in a calendar and compare spending by category.
- Create monthly recurring entries, applied when the app opens.
- Ask questions about your records with Apple Foundation Models.
- Get lightly humorous money tips based on recorded income, spending, and assets.
- Export and restore financial records, optionally including receipt images.

## Requirements

Wealthy requires **iOS or iPadOS 26.0 or later** and an **Apple Intelligence-capable device**. Apple Intelligence must be enabled and its system model must be ready before the app can be used.

| Device | Supported hardware |
| --- | --- |
| iPhone | iPhone 15 Pro / Pro Max, iPhone 16 models and later, or iPhone Air |
| iPad | Models with M1 or later, or iPad mini with A17 Pro |

Availability also depends on Apple's language and regional support. Wealthy checks the operating system's model availability at launch and when returning to the foreground. See [Apple's current requirements](https://support.apple.com/en-us/121115).

## Using the app

1. Enable Apple Intelligence under **Settings → Apple Intelligence & Siri** and allow the system model to finish preparing.
2. At first launch, choose **English** or **日本語** in the language popup. English is the default until you choose; your choice is remembered. Change it later under **Home → Settings → Language Settings**.
3. Add a wallet, then record income or scan a receipt. Check the recognized details before saving.
4. Use the Calendar and Analysis tabs to review your records. Open the AI assistant to ask about them.

## On-device AI

Wealthy uses Apple's built-in **SystemLanguageModel** for chat, receipt enrichment, and short spending comments. Model installation and updates are managed by the operating system. There is no model download or selection screen.

Chat replies follow the language of the latest message, independently of the display language. For example, a Japanese question requests a Japanese answer even when the app is set to English. Inputs without a detectable language use the display language. Supported reply languages depend on the installed Apple model; spending comments use the display language. The ticker pairs a short AI-written joke with an action derived from your records, and uses a local fallback when generation is unavailable.

The app uses on-device inference and does not connect to Private Cloud Compute or another cloud AI provider.

## Records, receipts, and backup

Financial records and receipt images are stored on the device. Under **Home → Settings → Data Management**, export wallets, income, expenses, recurring entries, and categories as JSON. Before exporting, a popup shows the total size of the referenced receipt images and lets you include them or save records only. Images are embedded once even when several entries share an image. JSON encoding adds approximately 33% to the image data size.

Restoring replaces the current records. Image-inclusive backups restore the original image data; records-only backups cannot restore images. Older record backups remain readable, but any chat history in them is ignored. Large image collections may require significant memory during export or restore.

**Chat history is never included in app exports.** Each message expires 24 hours after it was created. Wealthy deletes expired messages while running and checks again on launch or return to the foreground. If iOS suspends or terminates the app, deletion takes place when it next runs. Expired messages are excluded from chat display and AI context.

Receipt amount extraction targets integer Japanese yen; foreign-currency receipts require manual entry. Amounts and dates come from the OCR parser rather than generated guesses. A readable printed date is used; otherwise the date is taken when the camera scan returns, before recognition starts. A matching existing category is reused, and a suitable new category is created when needed. All extracted details remain editable.

Recognition is imperfect. A development evaluation of 15 local sample images matched 6 of 10 readable JPY totals; the other four were left unconfirmed. Printed dates matched in 14 of 14 samples. See the [measurement report](Verification/ReceiptImageOCR/RESULTS.md) for text and category results, exclusions, and limitations. These samples were also used during development and do not establish accuracy on new receipts. Always review scanned records before saving.

## Build from source

Use Xcode with the iOS 26 SDK or later; development builds are checked with Xcode 27.0. Open `Wealthy/Wealthy.xcodeproj`, select the **Wealthy** scheme, configure your signing team, and run on a compatible iPhone or iPad. The project uses Apple system frameworks and has no external Swift package dependencies.

The Simulator can be used for build checks; Apple Intelligence behavior needs testing on a supported device. See [verification instructions](Verification/README.md) for automated checks and the remaining device tests.

## License

All rights reserved. Redistribution of the source code or binaries requires permission.
