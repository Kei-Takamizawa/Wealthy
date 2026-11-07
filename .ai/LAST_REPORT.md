# Cycle 2b.1 Round 6 Report

Task ID: WEALTHY-C2B1-FIXED-CALENDAR
Status: DONE

Starting HEAD: `9ea1e8dd0df402a8a94f84b80f41bc9a2962a976`; branch: `codex/wealthy-c2b1-fixed-calendar`. Host: macOS 27.2, Xcode 27.2 (27B52), iOS 27.0 simulators. The existing changes to `.ai/CURRENT_TASK.md`, three `.DS_Store` files and the untracked design PDF were preserved. `5db23f0` is an ancestor of HEAD.

## Changed files

- `Wealthy/Wealthy/HomeInfo.swift`
- `WealthyUITests/WealthyUITests.swift`
- `Verification/Cycle2aEvidence/native/INDEX.md`
- `Verification/Cycle2aEvidence/native/native-result-month-achieved-dark.jpg`
- `Verification/Cycle2aEvidence/native/native-result-month-achieved-light.jpg`
- `Verification/Cycle2aEvidence/native/native-result-month-few-dark.jpg`
- `Verification/Cycle2aEvidence/native/native-result-month-few-light.jpg`
- `Verification/Cycle2aEvidence/native/native-result-month-over-dark.jpg`
- `Verification/Cycle2aEvidence/native/native-result-month-over-light.jpg`
- `Verification/Cycle2aEvidence/native/native-result-week-achieved-dark.jpg`
- `Verification/Cycle2aEvidence/native/native-result-week-achieved-light.jpg`
- `Verification/Cycle2aEvidence/native/native-result-week-few-dark.jpg`
- `Verification/Cycle2aEvidence/native/native-result-week-few-light.jpg`
- `Verification/Cycle2aEvidence/native/native-result-week-over-dark.jpg`
- `Verification/Cycle2aEvidence/native/native-result-week-over-light.jpg`
- `.ai/LAST_REPORT.md`

## Requirements

1. **Before fix — reproduced.** `testResultDoneInsideSafeArea` ran three times on iPhone 15 Pro. Each run: default FAIL, Done `(164.33, 824.67, 64.33, 34.33)`, window `(0, 0, 393, 852)`, safe-area top `818`, hittable true but bottom `859`; AX3 PASS, Done `(132.67, 732, 127.67, 62)`, hittable true. The test checks containment and a 34-point bottom safe area, which applies to the two specified simulators. Frames are in points.
2. **Layout and targeted tests — PASS.** Done uses a bottom `safeAreaInset` with standard components; content spacing is 12 points. On the first fix, the 17 Pro audit failed 3/3 at default size for `Within allowance`, `(68.67, 767.17, 128, 20.33)`: the screenshot shows that text partly clipped at the fixed button region. Reduced Result spacing, then reran both tests 3 times on both simulators. On each simulator each audit invocation checks default and AX3 with the existing audit types; no audit exception was added. Final targeted runs passed 3/3 for both tests on both simulators at both sizes. All Done frames were hittable and identical across the three iterations:

   | Simulator | Size | Done frame | Window | Bottom safe-area top |
   | --- | --- | --- | --- | --- |
   | iPhone 15 Pro | default | (164.33, 771.67, 64.33, 34.33) | (0, 0, 393, 852) | 818 |
   | iPhone 15 Pro | AX3 | (132.67, 744, 127.67, 62) | (0, 0, 393, 852) | 818 |
   | iPhone 17 Pro | default | (169, 793.67, 64.33, 34.33) | (0, 0, 402, 874) | 840 |
   | iPhone 17 Pro | AX3 | (137.33, 766, 127.67, 62) | (0, 0, 402, 874) | 840 |

3. **Screenshots — PASS.** Refreshed the 12 existing week/month Result images (three states in light/dark) from the 15 Pro full-suite `testNativeScreenEvidenceLightAndDark` attachments. All are 921 x 2000 JPEGs, 164,159–206,611 bytes; week achieved light and month over dark were visually inspected. Index updated. Synthetic data only.
4. **Full suites — PASS.** 15 Pro: 62 tests, zero failures, 4213.004 seconds. 17 Pro: 62 tests, zero failures, 4249.823 seconds. The 17 Pro run started after the 15 Pro process exited. Both included the Result audit and safe-area test at default and AX3, the full matrices, and the metric tests. Simulator metrics were not judged against a physical-device target.
5. **Required checks — PASS.** Core 117 tests / 13 suites; shell 199 keys x four languages plus font checks; localization 199 shipping keys x four languages and 2,420 archived checks. Simulator Release and signed generic iOS Release builds passed; signature verified. Both builds warned that App Intents metadata extraction was skipped because AppIntents.framework is not linked.

## Verification commands

- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r6-derived15 -resultBundlePath /tmp/wealthy-c2b1-r6-before.xcresult -parallel-testing-enabled NO -test-iterations 3 -only-testing:WealthyUITests/Cycle2aUITests/testResultDoneInsideSafeArea test` — FAIL as expected, default 3/3, AX3 pass 3/3; `/tmp/wealthy-c2b1-r6-before.log`.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r6-derived15 -resultBundlePath /tmp/wealthy-c2b1-r6-finaltarget15.xcresult -parallel-testing-enabled NO -test-iterations 3 -only-testing:WealthyUITests/Cycle2aUITests/testResultDoneInsideSafeArea -only-testing:WealthyUITests/Cycle2aUITests/testResultAccessibilityAudit test` — PASS, six test invocations; `/tmp/wealthy-c2b1-r6-finaltarget15.log`. Repeated with destination `DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0`, derived data `derived17`, result `finaltarget17.xcresult` — PASS; `/tmp/wealthy-c2b1-r6-finaltarget17.log`.
- First fix targeted run with the same command on 17 Pro and result `target17.xcresult` — FAIL, audit 3/3, Done assertion 3/3 PASS; `/tmp/wealthy-c2b1-r6-target17.log`. 15 Pro `target15.xcresult` — PASS.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r6-derived15 -resultBundlePath /tmp/wealthy-c2b1-r6-full15.xcresult -parallel-testing-enabled NO test` — PASS, 62 tests, zero failures; `/tmp/wealthy-c2b1-r6-full15.log`. The same command with simulator ID `DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0` and paths `derived17` / `full17.xcresult` — PASS, 62 tests, zero failures; `/tmp/wealthy-c2b1-r6-full17.log`.
- `xcrun xcresulttool export attachments --path /tmp/wealthy-c2b1-r6-full15.xcresult --output-path /tmp/wealthy-c2b1-r6-final-evidence15 --test-id 'Cycle2aUITests/testNativeScreenEvidenceLightAndDark()'` — PASS; exported 12 Result images with `sips -Z 2000 -s format jpeg -s formatOptions 80`, and checked dimensions with `sips -g pixelWidth -g pixelHeight`. An earlier export attempt while the suite was running failed because the result bundle Info.plist had not yet been finalized.
- `sh Verification/verify_core.sh` — PASS; `/tmp/wealthy-c2b1-r6-core.log`.
- `PYTHONPATH=/Users/harrison/Library/Python/3.14/lib/python/site-packages python3 Verification/verify_shell.py` — PASS; `/tmp/wealthy-c2b1-r6-shell.log`.
- `sh Verification/verify_localization.sh` — PASS; `/tmp/wealthy-c2b1-r6-localization.log`.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b1-r6-release-sim build` — PASS; `/tmp/wealthy-c2b1-r6-final-release-sim.log`.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/wealthy-c2b1-r6-release-device -allowProvisioningUpdates build` — PASS; `/tmp/wealthy-c2b1-r6-final-release-device.log`.
- `codesign --verify --deep --strict /tmp/wealthy-c2b1-r6-release-device/Build/Products/Release-iphoneos/Wealthy.app` — PASS.
- `git diff --check` — PASS.

## Not done / unverified

- The safe-area test uses a 34-point bottom inset for the two specified iPhone Pro simulators; it does not infer the inset for other device models.
- Physical-device install, UI, VoiceOver and performance were not assessed in this round.
- No staging, commit, push, merge, branch switch, or unrelated cleanup was performed. The operator owns Git.
