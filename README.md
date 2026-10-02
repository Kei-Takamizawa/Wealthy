# Wealthy

English · [Japanese](README.ja.md)

Wealthy is an iPhone and iPad app for tracking everyday expenses, income, and wallet balances. It combines receipt scanning, spending summaries, and on-device AI in a single personal finance app.

## Features

- Record expenses and income with categories and separate wallets.
- Scan receipts, review the extracted details, and keep the original images.
- Browse transactions in a calendar and compare spending by category.
- Create monthly recurring entries, applied when the app opens.
- Ask questions about your records with Apple Foundation Models.
- Export and import records as JSON.

## Requirements

Wealthy requires **iOS or iPadOS 26.0 or later** and an **Apple Intelligence-capable device**. Apple Intelligence must be enabled and its system model must be ready before the app can be used.

| Device | Supported hardware |
| --- | --- |
| iPhone | iPhone 15 Pro / Pro Max, or iPhone 16 and later |
| iPad | Models with M1 or later, or iPad mini with A17 Pro |

Availability also depends on Apple's language and regional support. Wealthy checks the operating system's model availability at launch and when returning to the foreground. See [Apple's current requirements](https://www.apple.com/apple-intelligence/).

## Using the app

1. Enable Apple Intelligence under **Settings → Apple Intelligence & Siri** and allow the system model to finish preparing.
2. Open Wealthy and choose a display language. English is the default; Japanese is available during setup and under **Home → Settings → Language Settings**.
3. Add a wallet, then record income or scan a receipt. Check the recognized details before saving.
4. Use the Calendar and Analysis tabs to review your records. Open the AI assistant to ask about them.

## On-device AI

Wealthy uses Apple's built-in **SystemLanguageModel** for chat, receipt enrichment, and short spending comments. Model installation and updates are managed by the operating system. There is no model download or selection screen.

Chat replies follow the language of the latest message, independently of the display language. For example, a Japanese question requests a Japanese answer even when the app is set to English. Inputs without a detectable language use the display language. Supported reply languages depend on the installed Apple model; spending comments use the display language.

The app uses on-device inference and does not connect to Private Cloud Compute or another cloud AI provider.

## Records, receipts, and backup

Records, chat history, and receipt images are stored locally. JSON exports include records and chat history, but **do not include receipt image files**. Importing a backup replaces the existing records.

Receipt amount extraction currently targets integer Japanese yen. An ambiguous total requires manual entry, and AI does not overwrite the amount selected by the receipt parser. Blurred images, shadows, and unsupported receipt layouts can affect recognition. Always review the result before saving.

## Build from source

Use Xcode with the iOS 26 SDK or later; development builds are checked with Xcode 27.0. Open `Wealthy/Wealthy.xcodeproj`, select the **Wealthy** scheme, configure your signing team, and run on a compatible iPhone or iPad. The project uses Apple system frameworks and has no external Swift package dependencies.

The Simulator can be used for build checks; Apple Intelligence behavior needs testing on a supported device. See [verification instructions](Verification/README.md) for automated checks and the remaining device tests.

## License

All rights reserved. Redistribution of the source code or binaries requires permission.
