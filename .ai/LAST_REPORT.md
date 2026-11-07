# Cycle 2b.1 Round 5 Report

Task ID: WEALTHY-C2B1-FIXED-CALENDAR
Status: PARTIAL

Starting HEAD: `c27d7342428eae126771687cf9c3ad0a589a02fb`; branch: `codex/wealthy-c2b1-fixed-calendar`. Host: macOS 27.2, Xcode 27.2 (27B52); both simulators use iOS 27.0. The pre-existing changes to `.ai/CURRENT_TASK.md`, three `.DS_Store` files and an untracked design PDF were preserved. `5db23f0` is an ancestor of HEAD.

## Changed files

- `Wealthy/Wealthy/LedgerRoot.swift` — hides the target-step island with an opacity transition while the amount is focused; keeps the title, step count and bottom bar.
- `Wealthy/Wealthy/MoneyInputField.swift` — accepts an optional external focus binding; other callers retain the internal focus state.
- `Verification/Cycle2bEvidence/INDEX.md`
- `Verification/Cycle2bEvidence/iphone15pro-onboarding-language-light.jpg`
- `Verification/Cycle2bEvidence/iphone15pro-onboarding-language-dark.jpg`
- `Verification/Cycle2bEvidence/iphone15pro-onboarding-currency-light.jpg`
- `Verification/Cycle2bEvidence/iphone15pro-onboarding-currency-dark.jpg`
- `Verification/Cycle2bEvidence/iphone15pro-onboarding-target-light.jpg`
- `Verification/Cycle2bEvidence/iphone15pro-onboarding-target-dark.jpg`
- `Verification/Cycle2bEvidence/iphone15pro-onboarding-child-light.jpg`
- `Verification/Cycle2bEvidence/iphone15pro-onboarding-child-dark.jpg`
- `Verification/Cycle2bEvidence/iphone17pro-onboarding-language-light.jpg`
- `Verification/Cycle2bEvidence/iphone17pro-onboarding-language-dark.jpg`
- `Verification/Cycle2bEvidence/iphone17pro-onboarding-currency-light.jpg`
- `Verification/Cycle2bEvidence/iphone17pro-onboarding-currency-dark.jpg`
- `Verification/Cycle2bEvidence/iphone17pro-onboarding-target-light.jpg`
- `Verification/Cycle2bEvidence/iphone17pro-onboarding-target-dark.jpg`
- `Verification/Cycle2bEvidence/iphone17pro-onboarding-child-light.jpg`
- `Verification/Cycle2bEvidence/iphone17pro-onboarding-child-dark.jpg`
- `.ai/LAST_REPORT.md`

A temporary `WealthyUITests/Round5FrameDiagnostics.swift` was created to log frames and removed after both diagnostic runs. `testOnboardingAmountVisibleWithKeyboard` remains exactly as committed.

## Requirements

1. **Focus-dependent island and keyboard acceptance — PASS.** The selected fix uses the existing bottom `safeAreaInset`, `@FocusState`, and a standard opacity transition. No additional content margins or scroll action were needed. `testOnboardingAmountVisibleWithKeyboard` passed on both simulators at default and AX3 sizes, both targeted and in the full suites. It checks field and Next hittability, the typed value, keyboard presence, and field position above the padded bar and keyboard. `testPersistedOnboardingRelaunch` also passed on both. The four target screenshots visibly show `40000` and the open keyboard. When focus ends the conditional restores the island; restoration on the same target step was not separately observed.

   Frames below are points from separate temporary diagnostic UI tests after the first and only Round 5 fix. Bar top uses the committed acceptance test's formula. `field` and `keyboard` are `(x, y, width, height)`.

   | Simulator / size | Field | Bar top | Next | Keyboard |
   | --- | --- | ---: | --- | --- |
   | 15 Pro default | (32, 309.33, 329, 42.33) | 474 | (317.33, 495, 59.67, 34) | (0, 567, 393, 227) |
   | 15 Pro AX3 | (32, 384, 329, 64) | 456 | (260.67, 472, 116.33, 62) | (0, 567, 393, 227) |
   | 17 Pro default | (32, 312.33, 338, 42.33) | 496.17 | (326.33, 517, 59.67, 34.33) | (0, 589, 402, 227) |
   | 17 Pro AX3 | (32, 406, 338, 64) | 478 | (269.67, 494, 116.33, 62) | (0, 589, 402, 227) |

   Before the fix, the Round 4 final 15 Pro default acceptance test recorded field `(32, 519.33, 329, 42.33)` and bar top `474`; the other pre-fix frames were not recorded. The designer's explanation for the failed scroll attempts remains a hypothesis, not an established root cause.

2. **Onboarding screenshots — PASS.** The 16 light/dark images for language, currency, target and child were exported from `testNativeOnboardingEvidenceLightAndDark` in the full suites. All four target images were visually inspected and show the synthetic `40000` above the bar and keyboard. `sips` converted them to JPEG quality 80, at 921 × 2000 (15 Pro) or 920 × 2000 (17 Pro), all 93,003–137,122 bytes. See `Verification/Cycle2bEvidence/INDEX.md`.

3. **Full UI suites — PARTIAL.** 15 Pro: 61 tests, 1 failure; 17 Pro: 61 tests, 0 failures. On 15 Pro `Cycle2aUITests.testResultAccessibilityAudit` failed at `WealthyUITests.swift:236`: `Contrast failed / Contrast failed for SwiftUI.AccessibilityNode`, label `Done`, identifier empty, frame `(164.33, 824.67, 64.33, 34.33)`. The same test passed on 17 Pro. This is a contrast issue on the existing result screen, outside the Round 5 change; no audit was weakened and it remains unresolved. The existing owner-approved narrow Dynamic Type SwiftUI-node exception remains in place, and no new exception was added. The full matrix and metric tests ran; simulator metric values were not judged as physical-device performance.

4. **Required checks — PASS.** Core: 117 tests in 13 suites. Shell: 199 keys × four languages and font checks. Localization: 199 shipping keys × four languages and 2,420 archived checks. Both Release builds and device-app signature verification passed. Both builds warned that App Intents metadata extraction was skipped because AppIntents.framework is not linked. `git diff --check` passed after the report was written.

## Verification commands

- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r5-derived15 -resultBundlePath /tmp/wealthy-c2b1-r5-target15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testOnboardingAmountVisibleWithKeyboard test` — PASS; `/tmp/wealthy-c2b1-r5-target15.log`.
- Same targeted command with destination `platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0`, derived data `/tmp/wealthy-c2b1-r5-derived17`, result `/tmp/wealthy-c2b1-r5-target17.xcresult` — PASS; `/tmp/wealthy-c2b1-r5-target17.log`.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r5-derived15 -resultBundlePath /tmp/wealthy-c2b1-r5-full15.xcresult -parallel-testing-enabled NO test` — FAIL, 61 tests, 1 failure; `/tmp/wealthy-c2b1-r5-full15.log`.
- Same full-suite command with destination `platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0`, derived data `/tmp/wealthy-c2b1-r5-derived17`, result `/tmp/wealthy-c2b1-r5-full17.xcresult` — PASS, 61 tests; `/tmp/wealthy-c2b1-r5-full17.log`.
- Temporary diagnostic: `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r5-diagnostic15 -resultBundlePath /tmp/wealthy-c2b1-r5-frames15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Round5FrameDiagnostics/testFrames test` — PASS; `/tmp/wealthy-c2b1-r5-frames15.log`. Same command with 17 Pro ID `DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0`, paths `diagnostic17` and `frames17.xcresult` — PASS; `/tmp/wealthy-c2b1-r5-frames17.log`.
- `sh Verification/verify_core.sh` — initial sandboxed invocation FAIL: SwiftPM `sandbox-exec: sandbox_apply: Operation not permitted`; authorized rerun PASS, 117 tests; `/tmp/wealthy-c2b1-r5-core-authorized.log`.
- `PYTHONPATH=/Users/harrison/Library/Python/3.14/lib/python/site-packages python3 Verification/verify_shell.py` — PASS; `/tmp/wealthy-c2b1-r5-shell.log`.
- `sh Verification/verify_localization.sh` — PASS; `/tmp/wealthy-c2b1-r5-localization.log`.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b1-r5-release-sim build` — PASS; `/tmp/wealthy-c2b1-r5-release-sim.log`.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/wealthy-c2b1-r5-release-device -allowProvisioningUpdates build` — PASS; `/tmp/wealthy-c2b1-r5-release-device.log`.
- `codesign --verify --deep --strict /tmp/wealthy-c2b1-r5-release-device/Build/Products/Release-iphoneos/Wealthy.app` — PASS.
- `xcrun xcresulttool export attachments --path /tmp/wealthy-c2b1-r5-full15.xcresult --output-path /tmp/wealthy-c2b1-r5-attachments15 --test-id 'Cycle2aUITests/testNativeOnboardingEvidenceLightAndDark()'` — PASS; repeated for `full17.xcresult` and `attachments17` — PASS. `sips -Z 2000 -s format jpeg -s formatOptions 80 <source> --out <destination>` produced each of the 16 images; `sips -g pixelWidth -g pixelHeight` verified dimensions.
- `git diff --check` — PASS.

## Not done / unverified

- The 15 Pro result-screen contrast finding requires designer/Claude review; reproduction is the failing full-suite audit and log above. Whether it is intermittent or pre-existing was not determined in this round.
- No physical-device installation, physical-device UI, VoiceOver, or performance assessment was performed in Round 5. The physical-device item from the original cycle was not revalidated.
- No design-board comparison was performed in this narrow round; prior cycle findings were not revalidated.
- No staging, commit, push, merge, branch switch, or unrelated cleanup was performed. The operator owns Git.
