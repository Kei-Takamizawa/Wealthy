# Cycle 2b.1 Round 2 Further Decisions Report

Task ID: WEALTHY-C2B1-FIXED-CALENDAR
Status: PARTIAL

Both full suites completed. The form and Home default accessibility audits still report Dynamic Type issues on both simulators; the 15 Pro persisted-onboarding test also fails because the Next button is obscured by the keyboard. No audit or test was excluded. The designer's decisions (f)–(k) were applied; the remaining failures need further investigation or direction.

## Changed files
- .ai/CURRENT_TASK.md
- .ai/LAST_REPORT.md
- Wealthy/Wealthy/FixedCosts.swift
- WealthyUITests/Cycle2bUITests.swift
- WealthyUITests/WealthyUITests.swift
- Verification/Cycle2bEvidence/INDEX.md
- Verification/Cycle2bEvidence/iphone15pro-rule-form-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-rule-form-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-rule-form-ax3.jpg
- Verification/Cycle2bEvidence/iphone17pro-rule-form-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-rule-form-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-rule-form-ax3.jpg

## Requirements

### Preflight and scope — PASS
- Branch `codex/wealthy-c2b1-fixed-calendar`, starting and finishing HEAD `b81e9e2b632946bb9903ce3175e10e398c47d694` (committed Round 2 checkpoint). Read AGENTS.md, CURRENT_TASK.md and LAST_REPORT.md; appended the user's further decisions to the task.
- macOS 27.2 arm64, Xcode 27.2 (27B52), iOS 27.0 (24A434). Simulator IDs: 15 Pro `870430A8-E557-4CED-8A8E-079801D804B9`; 17 Pro `DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0`. Both simulator system content sizes were `large` before and after the runs.
- Preserved the three pre-existing .DS_Store modifications and untracked `design/v4/引き渡しシート.pdf`. ReceiptExample was not read. No WealthyCore, persistence, schema, tax/target rules, Home layout, fonts, localization or app dependencies changed in this continuation. No stage, commit, push, branch switch or merge was performed.

### (f) Unpinned first audits — FAIL
- Removed the default content-size launch argument; it is supplied only for `--ax3` layout/screenshot launches. No in-app content-size override exists. The combined C2b case performs each audit without a content-size argument and separately relaunches at AX3 for the screenshot.
- Before any further UI changes, ran only `testC2bAccessibilityAndEvidence` and `testHomeAccessibilityAudit` once per simulator. Both cases failed on both simulators. The 15 Pro form audit flagged `Category` and `Day of month` in all three audit iterations (6 issues); the 17 Pro form audit flagged `Day of month` in all three (3 issues). Home's four-type audit did not report clipping, but the default full audit reported 15 Dynamic Type issues on each device. These findings did not change when the argument was removed.
- Exact compact and detailed descriptions: `Dynamic Type font sizes are partially unsupported` / `User will not be able to change the font size of this SwiftUI.AccessibilityNode`. `/tmp/wealthy-c2b1-r2-f-audit{15,17}.log` and xcresult bundles retain the initial results.

### (g) Rule form — implemented; audit FAIL
- Replaced Category and Day of month Pickers with standard `NavigationLink` rows labeled by `LabeledContent`; their destination `List` has plain buttons and a checkmark on the selected row. Rows have no fixed sizes. The yearly month Picker remains unchanged. Parent links retain identifiers `ruleCategory` / `ruleDay` and expose their selected accessibility values.
- `testC2bChildIsolation` passed on both, including Category value `Food` before and after save; `testC2bForegroundCatchUp` passed on both with day selection. The separate unpinned default form audit still flagged Category and Day of month (15 Pro) and Day of month (17 Pro); the original full audit remained enabled and failed in both full suites. The temporary separate diagnostic case was removed after recording its output; no existing audit was weakened.

### (h) Home diagnostic — FAIL; no further Home layout changes
- Home's default full audit reported 15 elements on each device. Identifiers were empty. Frames are `(x, y, width, height)` in points, rounded to 0.01. XCTest's exposed `XCUIElement` did not provide a runtime font face or point size; the final column records the semantic font explicitly specified or inherited in `HomeInfo.swift`, not an observed runtime font. Duplicate weekday letters are separate elements ordered by horizontal position.

| Label | 15 Pro frame | 17 Pro frame | Font from source |
| --- | --- | --- | --- |
| Add entry | (35.33, 666.83, 111.33, 20.33) | (35.33, 669.83, 111.33, 20.33) | inherited system body |
| F | (239.74, 583.00, 8.67, 18.00) | (245.52, 586.00, 8.67, 18.00) | system subheadline, semibold |
| I spent nothing today | (130.00, 736.83, 160.67, 20.33) | (134.50, 739.83, 160.67, 20.33) | inherited system body |
| Left this month | (161.67, 407.67, 114.67, 20.33) | (170.67, 410.67, 114.67, 20.33) | inherited system body |
| M | (47.12, 583.00, 13.33, 18.00) | (47.76, 586.00, 13.33, 18.00) | system subheadline, semibold |
| Not a balance | (59.67, 383.33, 105.00, 20.33) | (59.67, 386.33, 105.00, 20.33) | inherited system body |
| S | (286.64, 583.00, 10.00, 18.00) | (293.71, 586.00, 10.00, 18.00) | system subheadline, semibold |
| S | (334.21, 583.00, 10.00, 18.00) | (342.57, 586.00, 10.00, 18.00) | system subheadline, semibold |
| Spent | (32.00, 407.67, 45.00, 20.33) | (32.00, 410.67, 45.00, 20.33) | inherited system body |
| T | (96.52, 583.00, 9.67, 18.00) | (98.45, 586.00, 9.67, 18.00) | system subheadline, semibold |
| T | (191.67, 583.00, 9.67, 18.00) | (196.17, 586.00, 9.67, 18.00) | system subheadline, semibold |
| This week | (16.00, 478.00, 361.00, 52.00) | (16.00, 481.00, 370.00, 52.00) | system headline |
| W | (141.43, 583.00, 15.00, 18.00) | (144.64, 586.00, 15.00, 18.00) | system subheadline, semibold |
| ¥2,900 | (89.67, 407.67, 56.00, 20.33) | (95.83, 410.67, 56.00, 20.33) | inherited system body, monospaced digits |
| ¥307,100 | (284.33, 407.67, 76.67, 20.33) | (293.33, 410.67, 76.67, 20.33) | inherited system body, monospaced digits |

- Each diagnostic issue was printed, explicitly failed via `XCTFail`, and returned false to retain the default audit failure. Full details and unrounded frames are in `/tmp/wealthy-c2b1-r2-g-check{15,17}.log`. No inference is made that the findings are false positives. The prior Round 2 Home baseline at 5db23f0 remains inconclusive because the ledger could not open, as documented in the checkpoint report.

### (i) Fixture month — PASS
- The two tests navigate the month control from the current Gregorian month to the existing injected October 2026 test date. Expected values remain `¥218` and `¥266`; Core and fixtures were not modified. `testIncomeEntry` and `testChildSupportDefaults` passed on both in the final full suites.

### (j) Child flow and persisted onboarding — PARTIAL
- With unpinned launches, `testChildEnvelopeAndLicenseFlow` initially failed on both: the test tapped the wide switch row's center while the actual switch was at its right edge. The test now taps the switch control, asserts value `1`, and selects the child envelope before opening the amount keyboard. The final full suite passed this test on both devices.
- `testPersistedOnboardingRelaunch`: after (f), 15 Pro still failed, while 17 Pro passed. A downward swipe did not dismiss the keyboard; a further attempt scrolls from above the keyboard before using the unchanged visibility-checking tap. Final result: 17 Pro PASS, 15 Pro FAIL. On 15 Pro the `onboardingNext` button frame was `(265.67, 749.00, 95.33, 34.33)` and the keyboard frame `(0, 567, 393, 227)`, so the button center was below the keyboard top. Expected: Next is visible and advances; actual: the helper's visibility assertion failed. Reproduce with the final suite command below plus `-only-testing:WealthyUITests/Cycle2aUITests/testPersistedOnboardingRelaunch`. Onboarding layout is outside the authorized Home/form changes and was not modified.

### (k) Full UI suites — FAIL, completed
- iPhone 15 Pro: **59 tests, 56 passed, 3 failed, 0 skipped**. Failing methods: `testC2bAccessibilityAndEvidence`, `testHomeAccessibilityAudit`, `testPersistedOnboardingRelaunch`. XCTest reports 22 individual failure assertions across those cases (6 form issues, 15 Home issues, 1 visibility assertion).
- iPhone 17 Pro: **59 tests, 57 passed, 2 failed, 0 skipped**. Failing methods: `testC2bAccessibilityAndEvidence`, `testHomeAccessibilityAudit`. XCTest reports 18 individual failure assertions (3 form, 15 Home).
- Both runs were single unfiltered runs with `-parallel-testing-enabled NO`. All six launch/interactive metric methods and the persisted 50,000-entry method ran and passed on both. These are simulator results, not measurements against the physical-device target. Each `testScreenMatrix` completed all 144 cases.

| UI test method | 15 Pro | 17 Pro |
| --- | --- | --- |
| `testAdditionalSetupMatrix` | PASS | PASS |
| `testC2bAccessibilityAndEvidence` | FAIL | FAIL |
| `testC2bAnalysisValuesAndEmptyMonth` | PASS | PASS |
| `testC2bCalendarAndDayDetail` | PASS | PASS |
| `testC2bCatchUpFailureNamesRule` | PASS | PASS |
| `testC2bCatchUpRelaunch` | PASS | PASS |
| `testC2bCatchUpWithPendingResults` | PASS | PASS |
| `testC2bChildIsolation` | PASS | PASS |
| `testC2bEditRuleKeepsItsCurrency` | PASS | PASS |
| `testC2bForegroundCatchUp` | PASS | PASS |
| `testC2bInfoEntryPointsAndPushedSwipe` | PASS | PASS |
| `testC2bRuleLifecycle` | PASS | PASS |
| `testC2bRuleValidation` | PASS | PASS |
| `testChildAndResultMatrix` | PASS | PASS |
| `testChildEnvelopeAndLicenseFlow` | PASS | PASS |
| `testChildInfoMatrix` | PASS | PASS |
| `testChildSetupMatrix` | PASS | PASS |
| `testChildSupportDefaults` | PASS | PASS |
| `testEditorControlDragsDoNotSwitchTabs` | PASS | PASS |
| `testEntryAccessibilityAudit` | PASS | PASS |
| `testExistingChildSetupRemainsEnabled` | PASS | PASS |
| `testFocusedSelectionAndEditorSwipeIsolation` | PASS | PASS |
| `testFormMatrix` | PASS | PASS |
| `testGoalsUnsetMatrix` | PASS | PASS |
| `testHomeAX3LanguageMatrix` | PASS | PASS |
| `testHomeAccessibilityAudit` | FAIL | FAIL |
| `testHomeAlwaysHousehold` | PASS | PASS |
| `testHomeInteractiveMetric1000` | PASS | PASS |
| `testHomeInteractiveMetric10000` | PASS | PASS |
| `testHomeInteractiveMetric50000` | PASS | PASS |
| `testHomeWithFiftyThousandPersistedEntries` | PASS | PASS |
| `testHorizontalTabSwipeAndVerticalScroll` | PASS | PASS |
| `testIncomeEntry` | PASS | PASS |
| `testInfoAccessibilityAudit` | PASS | PASS |
| `testInfoSegmentedControlDragDoesNotSwitchTabs` | PASS | PASS |
| `testKoreanAmountsMatrix` | PASS | PASS |
| `testLaunchMetric1000` | PASS | PASS |
| `testLaunchMetric10000` | PASS | PASS |
| `testLaunchMetric50000` | PASS | PASS |
| `testLocalizedGroupedAmountFields` | PASS | PASS |
| `testLocalizedOnboarding` | PASS | PASS |
| `testManualTaxAndMetadataSurviveReopening` | PASS | PASS |
| `testMonthResultStatesMatrix` | PASS | PASS |
| `testNativeHomeLanguageEvidence` | PASS | PASS |
| `testNativeOnboardingEvidenceLightAndDark` | PASS | PASS |
| `testNativeScreenEvidenceLightAndDark` | PASS | PASS |
| `testNavigationMatrix` | PASS | PASS |
| `testNoSpendDayFromEmptyLedger` | PASS | PASS |
| `testNormalNewStoreLaunch` | PASS | PASS |
| `testOnboardingEntryTaxNoSpendTarget` | PASS | PASS |
| `testPagerNavigation` | PASS | PASS |
| `testPersistedOnboardingRelaunch` | FAIL | PASS |
| `testReduceMotionSwipeAndSheetIsolation` | PASS | PASS |
| `testResultAccessibilityAudit` | PASS | PASS |
| `testResultAndAccessibilityVariants` | PASS | PASS |
| `testScreenMatrix` | PASS | PASS |
| `testShortAndDiagonalDragsDoNotSwitchTabs` | PASS | PASS |
| `testVoiceAccessibilityAudit` | PASS | PASS |
| `testVoicePlaceholderIsShownOnce` | PASS | PASS |

### Screenshots — PASS for artifact validation
- After the full suites, refreshed only the 6 rule-form JPEGs for both simulators and light/dark/AX3, and updated `Verification/Cycle2bEvidence/INDEX.md`. AX3 images are from the separate AX3 screenshot launches; audits ran without a content-size argument. Home and other previously committed images were not changed in this continuation.
- Synthetic data only. 42 JPEGs total, 5,442,181 bytes; largest 181,161 bytes; every long edge <=2,000 px and each file <1 MB. JPEG quality set to 80 with `sips`. Representative light and AX3 form images were visually inspected. Images are not evidence that the full audit passed or that physical VoiceOver was exercised.

## Verification commands

```sh
# First unpinned audit, one run per simulator
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r2 -resultBundlePath /tmp/wealthy-c2b1-r2-f-audit15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testC2bAccessibilityAndEvidence test > /tmp/wealthy-c2b1-r2-f-audit15.log 2>&1
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b1-r2-17 -resultBundlePath /tmp/wealthy-c2b1-r2-f-audit17.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testC2bAccessibilityAndEvidence test > /tmp/wealthy-c2b1-r2-f-audit17.log 2>&1
# Final full suites, exit 65 on both; no filters
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r2 -resultBundlePath /tmp/wealthy-c2b1-r2-k-full15.xcresult -parallel-testing-enabled NO test > /tmp/wealthy-c2b1-r2-k-full15.log 2>&1
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b1-r2-17 -resultBundlePath /tmp/wealthy-c2b1-r2-k-full17.xcresult -parallel-testing-enabled NO test > /tmp/wealthy-c2b1-r2-k-full17.log 2>&1
sh Verification/verify_core.sh > /tmp/wealthy-c2b1-r2-f-core.log 2>&1
PATH=/tmp/wealthy-c2b1-tools/bin:$PATH python3 Verification/verify_shell.py > /tmp/wealthy-c2b1-r2-f-shell.log 2>&1
sh Verification/verify_localization.sh > /tmp/wealthy-c2b1-r2-f-localization.log 2>&1
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b1-r2-release build > /tmp/wealthy-c2b1-r2-f-release.log 2>&1
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/wealthy-c2b1-r2-device -allowProvisioningUpdates build > /tmp/wealthy-c2b1-r2-f-device.log 2>&1
codesign --verify --deep --strict /tmp/wealthy-c2b1-r2-device/Build/Products/Release-iphoneos/Wealthy.app
xcrun simctl ui 870430A8-E557-4CED-8A8E-079801D804B9 content_size
xcrun simctl ui DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0 content_size
git diff --check
```

Core PASS: 117 tests / 13 suites. Shell PASS: 199 keys x four languages, no missing keys. Localization PASS: shipping catalog and 2,420 archived checks. Simulator Release, signed generic iOS Release and host signature verification PASS. Builds emitted `Metadata extraction skipped, no AppIntents.framework dependency found`. The earlier sandboxed Core invocation was blocked by sandbox-exec permissions; authorized execution passed. Exact focused invocation arguments and output are in `/tmp/wealthy-c2b1-r2-g-check{15,17}.log` and `/tmp/wealthy-c2b1-r2-j{15,17}.log`, with corresponding xcresults. Result summaries are `/tmp/wealthy-c2b1-r2-k-summary{15,17}.json`.

## Not done / unverified
- Form and Home default full accessibility audits remain FAIL; the 15 Pro persisted-onboarding visibility assertion remains FAIL. Approval or designer direction is needed for any onboarding UI change outside this task.
- Runtime font face and point size for flagged Home elements are unverified; the table reports source-level semantic fonts only.
- No physical-device install, launch, performance measurement or VoiceOver walkthrough was repeated in this continuation. Prior physical-device evidence in the checkpoint is historical, not a new observation.
- No production deployment, Git recording, user-data deletion or unrelated cleanup. The operator owns Git. Round 1 board/Core differences are retained in the committed checkpoint history; no corresponding product behavior changed here.
