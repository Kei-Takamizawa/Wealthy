# Cycle 2b.1 Round 3 Report

Task ID: WEALTHY-C2B1-FIXED-CALENDAR
Status: DONE

Starting HEAD: `8e97a8dfa64de57da1390d7b3fddd50ff3f823de`; branch: `codex/wealthy-c2b1-fixed-calendar`. Host: macOS 27.2, Xcode 27.2 (27B52). Both simulators ran iOS 27.0 (24A434). Items 1–4 were already implemented and committed at the starting HEAD; this run did not change product or test code.

## Changed files

- .ai/LAST_REPORT.md
- Verification/Cycle2bEvidence/INDEX.md
- Verification/Cycle2bEvidence/iphone15pro-onboarding-child-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-onboarding-child-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-onboarding-currency-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-onboarding-currency-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-onboarding-language-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-onboarding-language-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-onboarding-target-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-onboarding-target-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-onboarding-child-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-onboarding-child-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-onboarding-currency-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-onboarding-currency-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-onboarding-language-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-onboarding-language-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-onboarding-target-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-onboarding-target-light.jpg

Unrelated pre-existing changes to three `.DS_Store` files and an untracked design PDF were preserved. Historical device comparison screenshots remain historical device evidence.

## Requirements

1. **Narrow audit exception — PASS.** Full-suite audits used the existing owner-approved filter only for `.dynamicType` issues whose detailed description contains `SwiftUI.AccessibilityNode` and whose element exists. All other issues fail. Ignored labels, identifiers and frames are logged and attached. Counts from the completed full-suite logs:

   | Screen / condition | iPhone 15 Pro | iPhone 17 Pro |
   | --- | ---: | ---: |
   | Fixed costs, each of light / dark / AX3 | 0 / 0 / 0 | 0 / 0 / 0 |
   | Rule form, light / dark / AX3 | 2 / 2 / 2 | 1 / 1 / 1 |
   | Calendar, each of light / dark / AX3 | 0 / 0 / 0 | 0 / 0 / 0 |
   | Analysis, each of light / dark / AX3 | 0 / 0 / 0 | 0 / 0 / 0 |
   | Home | 15 | 15 |
   | **Total** | **21** | **18** |

   The 15 Pro rule-form findings are Category and Day of month in each condition; 17 Pro reports Day of month in each condition. `testC2bAccessibilityAndEvidence` and `testHomeAccessibilityAudit` passed on both. The Home audit also runs the existing four-type audit, which rejects every finding.
2. **Compensating Dynamic Type growth — PASS.** `testC2bDynamicTypeGrowth` passed in each full suite. Prior targeted evidence at the same committed product and test code: Category and Day of month 20.33 to 48 pt; Home representative body, monospaced amounts and button text 20.33 to 48 pt (no-spend wraps to 96 pt); headline 52 to 78 pt; weekday subheadline 18 to 43 pt. Tested frames were inside the window. See `/tmp/wealthy-c2b1-r3-growth15.log` and `growth17.log` for the earlier frame details.
3. **Custom fonts — PASS.** `verify_shell.py` checked custom font calls for `relativeTo:`; the previous targeted report found no `.custom(` calls in `Wealthy/` and recorded six positive/negative checker fixtures. The required shell check passed again in this run.
4. **Onboarding keyboard — PASS.** `testPersistedOnboardingRelaunch` passed on both simulators in the full suites. It entered the target with the keyboard visible, tapped Next and verified persistence on relaunch. The target screenshots show Next above the software keyboard. In the 15 Pro light target capture the target amount itself is below the visible portion of the form behind the bottom bar; this image alone does not establish whether the field can be scrolled into view. No product changes were made in this run.
5. **Full UI suites — PASS.** iPhone 15 Pro: 60 passed, 0 failed, 0 skipped, 0 expected failures (4170.699 test seconds). iPhone 17 Pro: 60 passed, 0 failed, 0 skipped, 0 expected failures (4275.965 test seconds). Both result bundles report Passed. Runs were sequential, with `-parallel-testing-enabled NO`; no tests or audits were disabled. The launch and interactive metric tests were included; simulator timings are not evaluated against the device target.
6. **Screenshots — PASS for this round's refresh.** Added 16 synthetic-data onboarding screenshots from the two completed `testNativeOnboardingEvidenceLightAndDark` runs: four steps in light and dark for each device. Indexed in `Verification/Cycle2bEvidence/INDEX.md`. JPEG quality 80, each long edge at most 2,000 px and each below 1 MB (largest 143,255 bytes). Other Cycle 2b captures were retained.
7. **Required verification — PASS.** Core 117 tests in 13 suites; shell/font and localization checks; `git diff --check`; Simulator Release and signed generic iOS Release builds; `codesign --verify --deep --strict` all passed. The builds each warn that App Intents metadata extraction was skipped because no AppIntents.framework dependency was found.

The prior board/Core differences remain: Core controls recurrence and month-end clamping; catch-up has no undo; posted entries remain after rule deletion; no-spend marks can coexist with entries; analysis compares full months in a text list; native Info navigation replaces the board's separate tabs and custom surfaces.

## Verification commands

- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r3-authorized.qWAWO5/derived15 -resultBundlePath /tmp/wealthy-c2b1-r3-authorized.qWAWO5/full15.xcresult -parallel-testing-enabled NO test` — PASS, 60/60; log `full15.log` in the same directory.
- After that command completed: `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b1-r3-authorized.qWAWO5/derived17 -resultBundlePath /tmp/wealthy-c2b1-r3-authorized.qWAWO5/full17.xcresult -parallel-testing-enabled NO test` — PASS, 60/60; log `full17.log`.
- `xcrun xcresulttool get test-results summary --path <result-bundle> --format json` for both bundles — PASS; counts and runtime warnings verified. `xcrun xcresulttool export attachments --path <result-bundle> --test-id 'Cycle2aUITests/testNativeOnboardingEvidenceLightAndDark()' --output-path <export-directory>` — PASS for both.
- `sh Verification/verify_core.sh` — PASS, 117 tests in 13 suites; `/tmp/wealthy-c2b1-r3-authorized.qWAWO5/core-final-verified.log`. An earlier wrapper printed a zsh read-only `status` variable error after the tests completed; the corrected invocation returned exit 0.
- `PYTHONPATH=/Users/harrison/Library/Python/3.14/lib/python/site-packages python3 Verification/verify_shell.py` — PASS, 199 keys × four languages, custom font and other checks.
- `sh Verification/verify_localization.sh` — PASS, 199 shipping keys × four languages and 2,420 archived checks.
- `git diff --check` — PASS after report and evidence updates.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b1-r3-authorized.qWAWO5/release-sim build` — PASS; `release-sim.log`.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/wealthy-c2b1-r3-authorized.qWAWO5/release-device -allowProvisioningUpdates build` — PASS; `release-device.log`.
- `codesign --verify --deep --strict /tmp/wealthy-c2b1-r3-authorized.qWAWO5/release-device/Build/Products/Release-iphoneos/Wealthy.app` — PASS.
- `sips` conversion and dimension/size checks on 16 onboarding JPEGs — PASS.

## Errors and warnings

- The first sandboxed full-suite attempts exited 74 before tests began: CoreSimulatorService connection refused and SwiftPM could not write its manifest diagnostics cache (`Operation not permitted`). The authorized sequential full suites then completed successfully. Logs: `/tmp/wealthy-c2b1-r3-run.Yi4deg/full15.log` and `full17.log`.
- iPhone 15 Pro result bundle runtime warning: `Detected a metric that was not measured in the first iteration: com.apple.dt.XCTMetric_ApplicationLaunch-ApplicationFirstFramePresentationResponsive.duration`.
- iPhone 17 Pro result bundle runtime warnings: `Received unexpected number of metrics: 6 in iteration with index 2. Got 7 in iteration with index 0` and the same message for index 4. These warnings limit interpretation of simulator performance measurements; all six metric tests on each device were executed and passed.
- First sandboxed attachment export could not write Xcode's TestReport, and the first authorized export used an incorrect test identifier. Export succeeded with the identifier shown above.

## Not done / unverified

- No fresh physical-device installation, launch, manual VoiceOver navigation, or device performance measurement in this round. Simulator results are not equivalent to physical-device evidence.
- No product or test code modifications, staging, commit, push, merge, branch switch, deployment, or unrelated cleanup; the operator owns Git. New evidence files are present in the working tree for the operator to record.
