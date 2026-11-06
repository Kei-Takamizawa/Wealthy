# Cycle 2b.1 Round 3 Report

Task ID: WEALTHY-C2B1-FIXED-CALENDAR
Status: PARTIAL

The two full UI suites are running. This checkpoint is not evidence that either suite completed. Starting HEAD: `a9a13dccd9fa81d793133095d38461679fd5001a`; branch: `codex/wealthy-c2b1-fixed-calendar`. Execution host: macOS, Xcode 27.2 (27B52), iPhone 15 Pro and 17 Pro simulators on iOS 27.0.

## Changed files
- .ai/LAST_REPORT.md
- Verification/verify_shell.py
- Wealthy/Wealthy/LedgerRoot.swift
- WealthyUITests/Cycle2bUITests.swift
- WealthyUITests/WealthyUITests.swift

Pre-existing changes to `.ai/CURRENT_TASK.md`, three `.DS_Store` files and an untracked design PDF were preserved.

## Requirements
- Narrow full-audit handler: implemented for the owner-approved Dynamic Type / `SwiftUI.AccessibilityNode` finding only, provided the element exists. Other issues remain failures. Logged and attached label, identifier and frame. Targeted runs: form light/dark/AX3 respectively 2/2/2 ignored on 15 Pro and 1/1/1 on 17 Pro; Home 15 on each device. Fixed costs, Calendar and Analysis: zero ignored. Targeted screen and Home audits PASS on both.
- Compensating Dynamic Type test: PASS on both after correcting the initial test fixture. Rule form Category and Day of month: 20.33 to 48 pt; Home representative body, monospaced amounts and button text: 20.33 to 48 pt (no-spend wraps to 96 pt); headline 52 to 78 pt; weekday subheadline 18 to 43 pt. All tested frames were inside the app window. Exact frames: `/tmp/wealthy-c2b1-r3-growth{15,17}.log`.
- Custom font check: PASS; no `.custom(` calls in `Wealthy/`. Checker also passed six in-memory positive and negative fixtures.
- Onboarding keyboard: `testPersistedOnboardingRelaunch` PASS on both. The unchanged test types the amount with keyboard visible and taps Next, then relaunches and checks persistence.
- Full UI suite: RUNNING on each simulator. Logs and result bundles: `/tmp/wealthy-c2b1-r3-full{15,17}.log` and `.xcresult`.
- Board/Core differences unchanged from Round 1: Core controls recurrence/clamping and catch-up has no undo; already-posted entries remain after deletion; no-spend marks can coexist with entries; analysis compares full months in a text list; native Info navigation replaces the board's separate tabs and custom surfaces.

## Verification commands
- `sh Verification/verify_core.sh` — PASS, 117 tests in 13 suites (after sandboxed SwiftPM failed with `sandbox-exec: sandbox_apply: Operation not permitted`, rerun with authorized access).
- `PYTHONPATH=/Users/harrison/Library/Python/3.14/lib/python/site-packages python3 Verification/verify_shell.py` — PASS, 199 keys in four languages and font checks. Initial default Python lacked `fontTools`.
- `sh Verification/verify_localization.sh` — PASS, shipping 199 keys x four languages and 2,420 archived checks.
- `git diff --check` — PASS before this report rewrite.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b1-r3-release build` — PASS.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/wealthy-c2b1-r3-device -allowProvisioningUpdates build` — PASS; `codesign --verify --deep --strict /tmp/wealthy-c2b1-r3-device/Build/Products/Release-iphoneos/Wealthy.app` PASS. Both builds warned App Intents metadata extraction was skipped because no framework dependency was found.
- Targeted commands: `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=<DEVICE>' -derivedDataPath /tmp/wealthy-c2b1-r3-<DEVICE_SHORT> -resultBundlePath /tmp/wealthy-c2b1-r3-target<DEVICE_SHORT>.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testC2bDynamicTypeGrowth -only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testC2bAccessibilityAndEvidence -only-testing:WealthyUITests/Cycle2aUITests/testPersistedOnboardingRelaunch test` (first growth test failed for wrong fixture; other three passed on each), then the same command with only `testC2bDynamicTypeGrowth` and result bundle `growth<DEVICE_SHORT>` — PASS both. Device IDs: 15 `870430A8-E557-4CED-8A8E-079801D804B9`, 17 `DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0`.
- Full suite commands: `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=<DEVICE>' -derivedDataPath /tmp/wealthy-c2b1-r3-<DEVICE_SHORT> -resultBundlePath /tmp/wealthy-c2b1-r3-full<DEVICE_SHORT>.xcresult -parallel-testing-enabled NO test` — RUNNING.
- `xcrun simctl ui <DEVICE> content_size` — `large` on both before and after targeted runs.

## Not done / unverified
- Full suites and screenshot refresh pending; no conclusion about acceptance yet.
- No fresh physical-device install, launch, manual VoiceOver or performance measurement in Round 3; prior physical evidence is historical.
- No Git staging, commit, push, merge, branch switch, production deployment, or unrelated cleanup. Operator owns Git.
