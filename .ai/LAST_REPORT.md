# Cycle 2b.1 Round 4 Report

Task ID: WEALTHY-C2B1-FIXED-CALENDAR
Status: PARTIAL

Starting HEAD: `61e22d6c85847317e75c0816e611367f5ead1a45`; branch: `codex/wealthy-c2b1-fixed-calendar`. Host: macOS 27.2, Xcode 27.2 (27B52); iPhone 15 Pro and iPhone 17 Pro simulators use iOS 27.0. Pre-existing changes to `.ai/CURRENT_TASK.md`, three `.DS_Store` files, and an untracked design PDF were preserved.

## Changed files

- `WealthyUITests/WealthyUITests.swift` — adds `testOnboardingAmountVisibleWithKeyboard`, running at the default size and AX3, checking the input value, hittability, keyboard, navigation-bar boundary, and Next button. The bar boundary calculation reflects the current padded HStack layout and must be adjusted if that layout changes.
- `.ai/LAST_REPORT.md`

No product-code change is retained. Experimental changes were removed after they failed the new test.

## Requirements

1. **Test first — PASS for reproduction; acceptance FAIL.** On the unchanged product code, the first 15 Pro run failed at default size: field `(32.0, 519.33, 329.0, 42.33)` has bottom `561.67`; the original test's conservative bar boundary was `479.0` (`/tmp/wealthy-c2b1-r4-red.log`). The final test computes the bar boundary from both button sizes and HStack padding: 15 Pro default fails with field bottom `561.67` and bar top `474.0`; AX3 produced no additional assertion failure. 17 Pro passed both default and AX3. Both final test runs include keyboard present, typed `40000`, field and Next hittability, and field geometry assertions. The 15 Pro failure remains red.
2. **Fix — NOT DONE.** The existing `safeAreaInset(edge: .bottom)` in `OnboardingView` and keyboard overlap the field on 15 Pro at default size. An initial `ScrollViewReader` using a bottom anchor after the keyboard appeared did not move it sufficiently; dispatching the scroll and repeating it on amount changes also failed, including at AX3. Moving Back/Next into the form and adding a keyboard toolbar still left the field overlapping the toolbar at both sizes. Combining the toolbar with a top-anchored scroll still failed at default size (field bottom `531.0`, Next top `508.0` in `/tmp/wealthy-c2b1-r4-target15d.log`). These were test experiments and were reverted. `testPersistedOnboardingRelaunch` passed on 15 Pro in the first scroll and toolbar experiments, but that does not establish a working fix. The reason SwiftUI did not position the field sufficiently is not established. Designer/Claude judgment is needed on the next standard-component approach before another implementation attempt.
3. **Screenshots — NOT DONE.** The 16 Round 3 onboarding images remain unchanged: no corrected 15 Pro target capture exists. Synthetic-data target image acceptance remains unmet.
4. **Full UI suites — NOT COMPLETED.** Both full runs were started with `-parallel-testing-enabled NO` and interrupted after the unresolved blocker was established. 15 Pro had started `testAdditionalSetupMatrix`; 17 Pro was interrupted during build/setup. No complete suite counts or pass claim are available. Both logs report interruption. No audits or tests were deliberately excluded.
5. **Required checks — PARTIAL.** Core 117/117, shell with the existing Python dependency path, localization, `git diff --check`, Simulator Release build, signed generic iOS Release build, and signature verification passed. The bare `python3 Verification/verify_shell.py` failed because the default Python environment does not contain `fontTools`; using the installed site-packages path passed. Both builds warned that App Intents metadata extraction was skipped because the framework is not linked.

## Verification commands

- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r4-derived15 -resultBundlePath /tmp/wealthy-c2b1-r4-red.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testOnboardingAmountVisibleWithKeyboard test` — FAIL as expected before product changes; log `/tmp/wealthy-c2b1-r4-red.log`.
- Same command on final product and test state with `-resultBundlePath /tmp/wealthy-c2b1-r4-final15.xcresult` — FAIL, 1 assertion at default; `/tmp/wealthy-c2b1-r4-final15.log`.
- Same command with destination `platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0`, derived data `/tmp/wealthy-c2b1-r4-derived17`, result `/tmp/wealthy-c2b1-r4-final17.xcresult` — PASS, default and AX3; `/tmp/wealthy-c2b1-r4-final17.log`.
- Targeted experimental runs are recorded in `/tmp/wealthy-c2b1-r4-target15.log`, `target15b.log`, `target15c.log`, and `target15d.log`; each had at least one failure of the new test. The product changes tested there were reverted.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r4-derived15 -resultBundlePath /tmp/wealthy-c2b1-r4-full15.xcresult -parallel-testing-enabled NO test` — INTERRUPTED; `/tmp/wealthy-c2b1-r4-full15.log`.
- Same full-suite command with destination `platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0`, derived data `/tmp/wealthy-c2b1-r4-derived17`, result `/tmp/wealthy-c2b1-r4-full17.xcresult` — INTERRUPTED; `/tmp/wealthy-c2b1-r4-full17.log`.
- `sh Verification/verify_core.sh` — PASS, 117 tests in 13 suites; `/tmp/wealthy-c2b1-r4-core.log`.
- `python3 Verification/verify_shell.py` — FAIL, `ModuleNotFoundError: No module named 'fontTools'`.
- `PYTHONPATH=/Users/harrison/Library/Python/3.14/lib/python/site-packages python3 Verification/verify_shell.py` — PASS, 199 keys × four languages, custom-font and other checks.
- `sh Verification/verify_localization.sh` — PASS, 199 shipping keys × four languages and 2,420 archived checks.
- `git diff --check` — PASS.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b1-r4-release-sim build` — PASS; `/tmp/wealthy-c2b1-r4-release-sim-final.log`.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/wealthy-c2b1-r4-release-device -allowProvisioningUpdates build` — PASS; `/tmp/wealthy-c2b1-r4-release-device.log`.
- `codesign --verify --deep --strict /tmp/wealthy-c2b1-r4-release-device/Build/Products/Release-iphoneos/Wealthy.app` — PASS.

## Not done / unverified

- The 15 Pro default-size overlap is unresolved. Reproduce by launching onboarding, advancing to monthly target, tapping the amount field, and typing `40000`; compare the field bottom with the navigation bar above the open keyboard. See the final 15 Pro result bundle and failure above.
- A corrected product implementation, two full zero-failure suites, and 16 refreshed onboarding screenshots are not available. No physical-device check was performed. The interrupted suites cannot support any pass or failure count for the whole suite.
- No staging, commit, push, merge, branch switch, or unrelated cleanup was performed; the operator owns Git.
