# Wealthy

English · [Japanese](README.ja.md)

An iPhone and iPad app for tracking expenses, income, and balances. Financial records, receipt recognition, and AI inference are handled on device.

## Features

- Record expenses and income, with categories and separate wallets.
- Scan receipts and keep their images alongside expense records.
- Review transactions in a calendar and explore spending by category.
- Set monthly recurring entries, applied when the app opens.
- Use local AI chat and export or import records as JSON.

## Getting started

Wealthy requires iOS or iPadOS 26.0 or later. English is the default language for a new installation. Choose Japanese during setup or under **Home → Settings → Language Settings**. The app remembers your selection.

Receipt scanning and manual entry work independently of the optional AI model downloads. Apple Foundation Models is the default AI provider; its availability depends on the device and Apple Intelligence settings.

## On-device AI

Open **Home → Settings → AI Model Management** to view model sizes, download progress, and compatibility information for the current device. Download an optional model, then select it. Downloading alone does not change the active model.

| Model | Format | Download | Device RAM guide | Inference RAM estimate |
| --- | --- | ---: | ---: | ---: |
| Apple Foundation Models | OS managed | See below | Determined by iOS | Not measured |
| [Bonsai 8B](https://huggingface.co/inferencerlabs/Bonsai-8B-MLX-Q2) | MLX 2-bit | 2.32 GB | 6 GB | 3.5 GB |
| [MiniCPM5-1B (Reasoning)](https://huggingface.co/mlx-community/MiniCPM5-1B-4bit) | MLX 4-bit | 0.62 GB | 4 GB | 1.6 GB |
| [MiniCPM5-2B](https://huggingface.co/mlx-community/MiniCPM5-2B-mlx-4Bit) | MLX 4-bit | 1.43 GB | 6 GB | 2.5 GB |
| [K2 Horizon 3.7B](https://huggingface.co/mlx-community/K2-Horizon-3.7B-4bit) | MLX mixed 4/8-bit | 4.16 GB | 8 GB | 5.6 GB |

Download sizes were checked against the pinned model revisions on October 2, 2026. GB uses decimal units; all four optional downloads total approximately **8.52 GB**, plus temporary storage headroom. Only one model is loaded at a time.

Apple manages its model through the operating system. Wealthy downloads **0 B** for this provider; that does not mean the system model occupies no storage. The app reports unsupported devices, disabled Apple Intelligence, and a model that is still being prepared using [Apple's availability API](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.property).

RAM figures are application estimates, not verified minimum requirements. Optional models require Metal and sufficient available memory. Compatibility remains an estimate until a one-token inference succeeds in the current app session; this check does not establish response quality, speed, or long-session stability. MLX models cannot be selected in the Simulator.

Bonsai uses a third-party 2-bit conversion, which differs from the official 1-bit release. K2 uses a native Swift implementation. Model downloads require an internet connection; interrupted or failed downloads are not marked as installed. See [model management notes](Verification/AIModels/ModelManagement.md) for implementation details.

## Receipt review

Receipt recognition uses Apple Vision for Japanese and English. The parser fills in an amount only when it identifies an unambiguous, explicitly labeled total. AI does not overwrite that amount. If the total is unclear, review the saved image and enter it before saving.

Automatic amount extraction currently targets integer Japanese yen. Blurred images, shadows, unsupported labels, decimal amounts, and negative amounts may require manual entry. Recognition accuracy on photographed receipts has not been measured.

## Data and backup

Records and receipt images are stored locally. JSON exports include record data and chat history, but **do not embed receipt images or downloaded models**. Importing replaces the existing records. Keep receipt images separately if you need a complete archive.

## Building and verification

Open `Wealthy/Wealthy.xcodeproj` in Xcode, select the **Wealthy** scheme, configure signing, and choose a compatible device. The build checks below used Xcode 27.0 and SDK 27.0; they do not establish the oldest supported Xcode version.

Checks recorded for the receipt and model implementation on October 2, 2026:

| Check | Result | Scope |
| --- | --- | --- |
| Receipt parser | 42/42 passed | Text and coordinate fixtures |
| Model chat templates | 26 checks passed | Swift Jinja; no model weights |
| Download management | Passed, including 8 cancellation checks | Local HTTP server and synthetic files |
| App builds | Passed | Simulator and unsigned device builds |
| Native model harness | Type checking passed | Numerical execution pending |

The subsequent language-default update also passed a Simulator build and the Japanese source-comment audit.

Run `python3 Verification/verify_receipt_ocr.py` for receipt checks, `python3 Verification/ai_model_download_fixture.py` for download checks, and `python3 Verification/verify_ai_comments.py` for the source-comment audit. Template checks use `python3 Verification/verify_ai_templates.py --checkouts PATH`, where `PATH` points to the Xcode dependency checkouts.

These checks do not verify app launch, camera capture, Apple model responses on a device, or inference with the four downloaded models. Model speed, memory peaks, and recognition quality remain unmeasured. [Native model verification](Verification/AIModels/NativeModelVerification.md) records the remaining numerical checks.

## License

All rights reserved. Redistribution of the source code or binaries requires permission.
