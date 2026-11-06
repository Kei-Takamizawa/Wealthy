# Cycle 2b.1 Report

Task ID: WEALTHY-C2B1-FIXED-CALENDAR
Status: BLOCKED

The requested features are implemented and the physical Release installation/normal launch now succeeds. Acceptance is not complete: the optional rule-form Dynamic Type audit and the existing Home clipping audit fail on both requested simulators. No audit was excluded or weakened. Further form/Home UI decisions require the designer; the complete 59-test regression suite is not claimed to have passed.

## Changed files
- .ai/LAST_REPORT.md
- Wealthy/Wealthy/CalendarAnalysis.swift
- Wealthy/Wealthy/FixedCosts.swift
- Wealthy/Wealthy/GoalsTaxSettings.swift
- Wealthy/Wealthy/HomeInfo.swift
- Wealthy/Wealthy/LedgerRoot.swift
- Wealthy/Wealthy/LedgerSession.swift
- Wealthy/Wealthy/Localizable.xcstrings
- Wealthy/Wealthy/MoneyInputField.swift
- Wealthy/Wealthy/MonthControl.swift
- Wealthy/Wealthy/RecurringSession.swift
- Wealthy/Wealthy/WealthyApp.swift
- WealthyUITests/Cycle2bUITests.swift
- WealthyUITests/WealthyUITests.swift
- Verification/Cycle2bEvidence/INDEX.md
- Verification/Cycle2bEvidence/iphone15pro-analysis-ax3.jpg
- Verification/Cycle2bEvidence/iphone15pro-analysis-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-analysis-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-calendar-ax3.jpg
- Verification/Cycle2bEvidence/iphone15pro-calendar-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-calendar-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-catch-up-ax3.jpg
- Verification/Cycle2bEvidence/iphone15pro-catch-up-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-catch-up-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-day-detail-ax3.jpg
- Verification/Cycle2bEvidence/iphone15pro-day-detail-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-day-detail-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-fixed-costs-ax3.jpg
- Verification/Cycle2bEvidence/iphone15pro-fixed-costs-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-fixed-costs-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-rule-form-ax3.jpg
- Verification/Cycle2bEvidence/iphone15pro-rule-form-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-rule-form-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-analysis-ax3.jpg
- Verification/Cycle2bEvidence/iphone17pro-analysis-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-analysis-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-calendar-ax3.jpg
- Verification/Cycle2bEvidence/iphone17pro-calendar-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-calendar-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-catch-up-ax3.jpg
- Verification/Cycle2bEvidence/iphone17pro-catch-up-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-catch-up-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-day-detail-ax3.jpg
- Verification/Cycle2bEvidence/iphone17pro-day-detail-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-day-detail-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-fixed-costs-ax3.jpg
- Verification/Cycle2bEvidence/iphone17pro-fixed-costs-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-fixed-costs-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-rule-form-ax3.jpg
- Verification/Cycle2bEvidence/iphone17pro-rule-form-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-rule-form-light.jpg

## Requirements

### Preflight, resume and protected state — PASS

- Mac terminal: arm64, macOS 27.2, Xcode 27.2 (27B52), iOS SDK 27.2. Both requested simulator models run iOS 27.0.
- Branch remains `codex/wealthy-c2b1-fixed-calendar`; starting and finishing HEAD is `5db23f05241cdfb77161aad8eb6b4e1005869e0f`. Initial local `origin/main` and live `git ls-remote origin refs/heads/main` matched this SHA; its merge message identifies PR #9.
- Read AGENTS.md, CLAUDE.md, CURRENT_TASK.md, LAST_REPORT.md and both specified design boards. CURRENT_TASK.md already contained the complete approved instruction and was preserved.
- The last pre-resume run was interrupted by the **operator shell ending**, not by Codex. At resume, no Xcode test or runner processes remained. Earlier deliberately cancelled exploratory runs after known failures are separate from that interruption. No interrupted run is counted as a complete suite.
- Preserved the three pre-existing modified `.DS_Store` files, operator-provided modified `.ai/CURRENT_TASK.md` and untracked `design/v4/引き渡しシート.pdf`. The private ReceiptExample directory was not read.
- No WealthyCore source/test, persistence, schema, tax/target rule, app dependency or font asset changed. No stage, commit, push, branch switch, reset, merge, PR creation, physical uninstall or user-data deletion was performed. Git operations remain the operator's responsibility.

### 1. Entry points and root navigation — PASS for exercised cases

- Info pushes Fixed costs, Calendar and Analysis in the existing navigation stack for household and child envelopes; the three native tabs remain.
- `testC2bInfoEntryPointsAndPushedSwipe` passed on both models, including a horizontal drag on the pushed Fixed costs screen without a tab switch.
- `testC2bChildIsolation` passed on both: the child rule is isolated from household rules, its Food category survives editing/reopening, child Analysis is empty, and the seeded household day appears as zero/unmarked in the child Calendar.
- All seven exercised existing navigation/gesture tests passed on both models: pager taps, horizontal/vertical and short/diagonal drags, editor control drags, focused selection, Info segmented control and Reduce Motion/sheet isolation.

### 2. Fixed costs and catch-up — PASS for functional tests; form audit FAIL

- Native List/Form provide the requested fields, Core-based create/update/pause/delete commands, confirmations, localized monthly/weekly/yearly wording, original-currency money formatting, upcoming dates from Core and icon-plus-word paused state. Delete explains that posted entries remain.
- `testC2bRuleLifecycle` passed on both models: create, rename, pause, resume and delete a monthly rule; weekly/yearly wording is also asserted. The first resumed 17 Pro execution failed an immediate Paused-label check. The retained recording shows the state rendering after that assertion; the test now waits up to five seconds for the same label to appear/disappear. The corrected test passed on **both** models in the supplemental regression run. Production code was not changed for this timing issue.
- `testC2bRuleValidation` passed: amount zero is rejected by Core with the inline message `Enter an amount greater than zero.`
- `testC2bEditRuleKeepsItsCurrency` passed: while app currency is JPY, a USD rule displays $12.99, saves $15.25 and reopens with $15.25.
- `testC2bCatchUpRelaunch` passed: a disk fixture posts exactly three past occurrences, shows one notice/list with three records, and relaunch produces no second notice or duplicate occurrence. One record remains on the checked day.
- `testC2bForegroundCatchUp` passed: a newly due rule posts one occurrence after background/activation; another activation shows no second notice.
- `testC2bCatchUpFailureNamesRule` passed: an archived synthetic category produces a plain-word failure with the rule's title; no posted-record link is shown when nothing posted.
- `testC2bCatchUpWithPendingResults` passed: existing ended-period results and the recurring notice are presented sequentially without losing the notice. A single root presentation queue handles both.
- Catch-up calls `core.postRecurring` directly, after presentation on ledger open and activation, outside command undo history. The normal opening path ends its existing FirstFrame boundary before opening Core; catch-up is deferred through another display wait. This is source/control-flow evidence, **not a new physical timing measurement**.
- Rule edits copy current Core metadata immediately before saving, preserving cursors/pause history/creation date. All monetary totals and domain states are queried from Core; minor-unit scaling in the display formatter is presentation formatting, not a new ledger calculation.

### 3. Calendar and day detail — PASS for exercised cases

- Uses Core daily totals/no-spend state and week-start setting, a native month control, compact currency, today text/bold styling and a list fallback at accessibility sizes. Cells expose one composed date/precise-total/no-spend accessibility label.
- `testC2bCalendarAndDayDetail` passed on both: October 8 shows expense **1,130 JPY** with a no-spend mark; its lunch opens the existing editor at **800 JPY**; the mark toggles off and back on and the month reflects the change. The mark is allowed alongside entries, matching Core.
- MonthControl now uses one consistent vertical structure, a system-body semibold month title and a separate row of 44-point native month buttons. This layout/typography adjustment is included for designer review.
- All full Calendar audits passed on both models in light, dark and AX3. The Monday-start layout and AX3 fallback were also visually inspected in the saved images. Changing the week-start setting interactively was not separately tested; its source is the current Core setting.
- Automated labels/audits do not constitute a manual VoiceOver walkthrough.

### 4. Analysis — PASS for exercised cases

- Queries full current/previous month expense totals and the Core-sorted category breakdown; no view-side summation or percentage calculation. The text list is complete; no optional chart was added.
- `testC2bAnalysisValuesAndEmptyMonth` passed on both: Food **800 vs 600 JPY**, Transport **330 vs 200 JPY**, correct descending order, and an empty next-month message. Displayed period totals are **1,130 vs 800 JPY**; Core's zero uncategorized bucket is retained.
- All full Analysis audits passed on both models in light, dark and AX3.

### 5. Languages and accessibility — PARTIAL / BLOCKED

- Shipping catalog: **199 keys x exactly en/ja/es/ko**, zero missing keys; English base, placeholder parity, four bundled subset hashes and Hangul/Spanish coverage passed. Both final Release app bundles contain exactly en/es/ja/ko localization directories.
- Added 50 catalog keys. No font assets or UI language choices changed. New screen audits/captures use English; catalog completeness is not native-speaker review of all translations.
- The three required new screens have **18 successful full audit calls**: 3 screens x 3 modes x 2 models, with no handler or issue/type exclusions.
- The additional rule-form full audit remains enabled and failing: 15 Pro reports Category/Day of month in light/dark and Category at AX3 (**5 issues**); 17 Pro reports Day of month in light/dark (**2 issues**). Exact message: `Dynamic Type font sizes are partially unsupported`. The cause has not been conclusively established; these are not waived as false positives.
- Four existing screen audits passed on both models: Entry, Info, Result and Voice. The existing Home audit failed with text clipping, detailed below.

### 6. Release builds and physical device — PASS

- Fresh Simulator Release and signed generic iOS Release builds passed on resumed/final production sources. The only subsequent source edit was the UI test's rendered-state wait; the app sources stayed unchanged.
- `codesign --verify --deep --strict` passed for the physical Release app.
- Device: **iPhone 16 Pro Max, iOS 27.3**. Fresh overwrite install and normal `devicectl` launch of `com.harrison.Wealthy` both returned `outcome: success`, without test/measurement arguments or a debugger.
- Operator also confirmed a normal launch at **2026-11-06 08:58 JST / 2026-11-05 23:58Z** after enabling developer trust. This and the fresh resumed launch resolve the earlier CoreDeviceError 10002 / FBS Security rejection. Developer trust is **not a remaining blocker**.
- No physical UI walkthrough, manual VoiceOver operation or new performance measurement was performed or inferred from simulator results.

### 7. Screenshots — PASS for artifact preparation; Git recording belongs to operator

- [Evidence index](../Verification/Cycle2bEvidence/INDEX.md): **36 JPEGs**, both models, six requested screens in light/dark/AX3. Synthetic fixtures only.
- JPEG quality set to 80; every long edge <=2,000 px; every file <1 MB. Total **4,417,197 bytes**; largest **181,161 bytes**. Dimensions and sizes were programmatically checked. Representative Calendar light/AX3, rule form and catch-up dark images were visually inspected.
- These images come from completed resumed capture cases that **failed on the rule-form audits**. Their existence is not evidence that the combined case or cycle passed.
- No Git recording was performed because AGENTS.md assigns it to the operator.

## Verification commands

### Required deterministic checks — PASS

```sh
sh Verification/verify_core.sh > /tmp/wealthy-c2b1-resume-core.log 2>&1
PATH=/tmp/wealthy-c2b1-tools/bin:$PATH python3 Verification/verify_shell.py
sh Verification/verify_localization.sh > /tmp/wealthy-c2b1-resume-localization.log 2>&1
git diff --check
```

- Core: exit 0, **117 tests in 13 suites**. Unchanged opt-in disk benchmarks retain their default skip behavior; no test was newly disabled.
- Shell: exit 0, 199 x 4, source isolation, placeholders, font hashes and glyph coverage.
- Localization: exit 0, shipping 199 x 4 / zero missing; archived 2,420 assertions / 196 x 4.
- Diff check: exit 0, repeated after final report/artifact validation.
- System Python initially lacked fontTools. Installed fonttools 4.68.0 only in the disposable `/tmp/wealthy-c2b1-tools` venv, not as an app dependency.

### New UI test runs — FAIL; failures retained

The actual expanded commands printed by the runner are:

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1 -resultBundlePath /tmp/wealthy-c2b1-resume-15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testC2bInfoEntryPointsAndPushedSwipe -only-testing:WealthyUITests/Cycle2aUITests/testC2bRuleLifecycle -only-testing:WealthyUITests/Cycle2aUITests/testC2bRuleValidation -only-testing:WealthyUITests/Cycle2aUITests/testC2bCatchUpRelaunch -only-testing:WealthyUITests/Cycle2aUITests/testC2bCalendarAndDayDetail -only-testing:WealthyUITests/Cycle2aUITests/testC2bAnalysisValuesAndEmptyMonth -only-testing:WealthyUITests/Cycle2aUITests/testC2bAccessibilityAndEvidence -only-testing:WealthyUITests/Cycle2aUITests/testC2bCatchUpFailureNamesRule -only-testing:WealthyUITests/Cycle2aUITests/testC2bForegroundCatchUp -only-testing:WealthyUITests/Cycle2aUITests/testC2bChildIsolation -only-testing:WealthyUITests/Cycle2aUITests/testC2bCatchUpWithPendingResults -only-testing:WealthyUITests/Cycle2aUITests/testC2bEditRuleKeepsItsCurrency test > /tmp/wealthy-c2b1-resume-15.log 2>&1
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b1-17 -resultBundlePath /tmp/wealthy-c2b1-resume-17.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testC2bInfoEntryPointsAndPushedSwipe -only-testing:WealthyUITests/Cycle2aUITests/testC2bRuleLifecycle -only-testing:WealthyUITests/Cycle2aUITests/testC2bRuleValidation -only-testing:WealthyUITests/Cycle2aUITests/testC2bCatchUpRelaunch -only-testing:WealthyUITests/Cycle2aUITests/testC2bCalendarAndDayDetail -only-testing:WealthyUITests/Cycle2aUITests/testC2bAnalysisValuesAndEmptyMonth -only-testing:WealthyUITests/Cycle2aUITests/testC2bAccessibilityAndEvidence -only-testing:WealthyUITests/Cycle2aUITests/testC2bCatchUpFailureNamesRule -only-testing:WealthyUITests/Cycle2aUITests/testC2bForegroundCatchUp -only-testing:WealthyUITests/Cycle2aUITests/testC2bChildIsolation -only-testing:WealthyUITests/Cycle2aUITests/testC2bCatchUpWithPendingResults -only-testing:WealthyUITests/Cycle2aUITests/testC2bEditRuleKeepsItsCurrency test > /tmp/wealthy-c2b1-resume-17.log 2>&1
```

- 15 Pro: exit **65**, **12 tests: 11 passed / 1 failed**, five rule-form audit issues; zero skipped.
- 17 Pro: exit **65**, **12 tests: 10 passed / 2 failed**, two rule-form issues and the initial Paused-label timing assertion; zero skipped. The latter was corrected and passed in the supplemental run below.

### Supplemental lifecycle and existing regression — FAIL; Home audit retained

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9" -derivedDataPath /tmp/wealthy-c2b1 -resultBundlePath /tmp/wealthy-c2b1-resume-15-regression.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testC2bRuleLifecycle" "-only-testing:WealthyUITests/Cycle2aUITests/testPagerNavigation" "-only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll" "-only-testing:WealthyUITests/Cycle2aUITests/testShortAndDiagonalDragsDoNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testEditorControlDragsDoNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testInfoSegmentedControlDragDoesNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testReduceMotionSwipeAndSheetIsolation" "-only-testing:WealthyUITests/Cycle2aUITests/testFocusedSelectionAndEditorSwipeIsolation" "-only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testVoiceAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testInfoAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testEntryAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testResultAccessibilityAudit" test > /tmp/wealthy-c2b1-resume-15-regression.log 2>&1
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0" -derivedDataPath /tmp/wealthy-c2b1-17 -resultBundlePath /tmp/wealthy-c2b1-resume-17-regression.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testC2bRuleLifecycle" "-only-testing:WealthyUITests/Cycle2aUITests/testPagerNavigation" "-only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll" "-only-testing:WealthyUITests/Cycle2aUITests/testShortAndDiagonalDragsDoNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testEditorControlDragsDoNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testInfoSegmentedControlDragDoesNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testReduceMotionSwipeAndSheetIsolation" "-only-testing:WealthyUITests/Cycle2aUITests/testFocusedSelectionAndEditorSwipeIsolation" "-only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testVoiceAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testInfoAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testEntryAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testResultAccessibilityAudit" test > /tmp/wealthy-c2b1-resume-17-regression.log 2>&1
```

Both: exit **65**, **13 tests: 12 passed / 1 failed**, zero skipped. The rule lifecycle passes; the failure is the existing Home audit. Combining distinct tests across the two resumed runs gives **24 distinct tests per model: 22 PASS / 2 FAIL**. This is not a single green suite.

### Release and physical commands — PASS

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b1-release build > /tmp/wealthy-c2b1-resume-release.log 2>&1
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/wealthy-c2b1-device -allowProvisioningUpdates build > /tmp/wealthy-c2b1-resume-device.log 2>&1
codesign --verify --deep --strict /tmp/wealthy-c2b1-device/Build/Products/Release-iphoneos/Wealthy.app
xcrun devicectl device install app --device "$DEVICE_UDID" /tmp/wealthy-c2b1-device/Build/Products/Release-iphoneos/Wealthy.app --json-output /tmp/wealthy-c2b1-resume-install.json
xcrun devicectl device process launch --device "$DEVICE_UDID" --terminate-existing com.harrison.Wealthy --json-output /tmp/wealthy-c2b1-resume-launch.json
```

The actual paired identifier was passed; it is redacted from this public report. Both builds and host signature check exit 0. Device JSON outcomes are `success` for install and launch. No normal ledger was exported.

### Current distinct UI results

| Test | 15 Pro | 17 Pro |
| --- | --- | --- |
| `testC2bInfoEntryPointsAndPushedSwipe` | PASS | PASS |
| `testC2bRuleLifecycle` | PASS | PASS |
| `testC2bRuleValidation` | PASS | PASS |
| `testC2bCatchUpRelaunch` | PASS | PASS |
| `testC2bCalendarAndDayDetail` | PASS | PASS |
| `testC2bAnalysisValuesAndEmptyMonth` | PASS | PASS |
| `testC2bAccessibilityAndEvidence` | FAIL | FAIL |
| `testC2bCatchUpFailureNamesRule` | PASS | PASS |
| `testC2bForegroundCatchUp` | PASS | PASS |
| `testC2bChildIsolation` | PASS | PASS |
| `testC2bCatchUpWithPendingResults` | PASS | PASS |
| `testC2bEditRuleKeepsItsCurrency` | PASS | PASS |
| `testEditorControlDragsDoNotSwitchTabs` | PASS | PASS |
| `testEntryAccessibilityAudit` | PASS | PASS |
| `testFocusedSelectionAndEditorSwipeIsolation` | PASS | PASS |
| `testHomeAccessibilityAudit` | FAIL | FAIL |
| `testHorizontalTabSwipeAndVerticalScroll` | PASS | PASS |
| `testInfoAccessibilityAudit` | PASS | PASS |
| `testInfoSegmentedControlDragDoesNotSwitchTabs` | PASS | PASS |
| `testPagerNavigation` | PASS | PASS |
| `testReduceMotionSwipeAndSheetIsolation` | PASS | PASS |
| `testResultAccessibilityAudit` | PASS | PASS |
| `testShortAndDiagonalDragsDoNotSwitchTabs` | PASS | PASS |
| `testVoiceAccessibilityAudit` | PASS | PASS |

## Errors, blockers and designer decisions

### Rule form

Reproduce by running `testC2bAccessibilityAndEvidence` above, or launch the Debug synthetic fixture with:

```text
--cycle2a-test --cycle2b-seed --reset-test-preferences -v4.language en -v4.currency JPY --screen rule-form
```

Run the full accessibility audit. The failure is emitted at `WealthyUITests/Cycle2bUITests.swift:137`; related native labels/controls are in `Wealthy/Wealthy/FixedCosts.swift` (RuleEditor). Attempts to let labels wrap, use native labeled content, constrain the two-digit input and inherit natural Dynamic Type did not clear all issues. The audit stays enabled and red. Further restructuring of the form or a focused SDK/runtime investigation needs the designer's direction; no extra UI architecture was introduced to force a pass.

### Existing Home audit

Reproduce with `testHomeAccessibilityAudit` in either supplemental command. The helper fails at `WealthyUITests/WealthyUITests.swift:199` after collecting every issue.

- 15 Pro: `Text clipped` for **I spent nothing today** and **Not a balance**.
- 17 Pro: `Text clipped` for **Not a balance**.
- Detailed message: `Text of this SwiftUI.AccessibilityNode may be clipped at larger Dynamic Type sizes.`
- Related layout: HomeView in `Wealthy/Wealthy/HomeInfo.swift`. This cycle added Info links but did not edit Home's layout. Normal UI-test launches now inherit system Dynamic Type rather than freezing it at Large, so the testing environment is different. No original-HEAD baseline rerun was performed; the failure is **not conclusively classified as pre-existing or newly introduced**.

Expected: both new and existing required audits pass without exclusions. Actual: the three required new screens pass, the form and Home checks above fail. AGENTS.md reserves UI/UX and important fix direction for the designer and requires reporting outside-scope issues. Stopped further UI changes with Status BLOCKED. Needed next instruction: an approved form/Home accessibility fix or an approved diagnostic direction that retains the no-exclusion rule. The optional form audit remains enabled; accepting a different scope requires an explicit task decision.

### Other execution errors / warnings

- Initial fixed-date fixtures used October 2026 but commands/previews used the advancing real month. Aligned Debug fixture commands/previews and Goals' initial selected month with the session day; production command time remains Date(). No Core rule changed.
- Native List row button behavior initially activated both month actions; borderless individual month buttons fixed it. Early Calendar label placement and compact/dynamic layouts were corrected and re-audited.
- Xcode emitted debugger `noURL`, generic-destination OS-version placeholder and no-AppIntents metadata warnings. Builds succeeded; no AppIntents feature was requested.
- An automatic approval review rejected a proposed diagnostic accessibility callback, interpreting it as ignoring audit results. It was not applied. New audits remain default `performAccessibilityAudit()` calls without handlers/exclusions. Existing helpers retain their explicit assertion rejecting every collected issue.
- Earlier exploratory runs after known failures were cancelled to verify revised sources. One early replacement runner was terminated during overlapping cleanup; it was not counted as a pass. The last pre-resume interruption was the operator shell ending. Resumed selected runs completed normally with their reported failures.

## Board versus Core/task

- Uses three native tabs with Info push navigation, rather than the board's separate Calendar/Analysis tabs and custom visual surfaces.
- Core controls month-end clamping, pause periods and successful/failed occurrence cursors; UI does not add alternative scheduling rules.
- Catch-up is outside undo history; no board-style undo action was added. Deleting a rule retains posted entries.
- Uses the Core fixed-cost flag and existing global target-inclusion setting; no extra per-rule target/notification settings or UI-side monthly fixed-cost summation were invented.
- No-spend marks coexist with entries and are not automatically cleared by this UI.
- Analysis compares full months as the task requests, rather than board-style month-to-date percentages/weekly graphs. Its complete text list replaces the optional chart.
- Compact grid currency uses Foundation formatting; accessibility and the large-text list retain precise Core amounts. [Apple Foundation currency notation](https://developer.apple.com/documentation/updates/foundation).

## Not done / unverified

- **NOT_RUN as a completed suite:** all 59 UI tests together. Earlier full-suite attempts were interrupted; resumed runs deliberately record the requested feature tests and focused regression. With unresolved audit failures and UI decisions required, no full-suite pass or complete acceptance is claimed.
- The following **35 methods were not completed in the resumed verification**. `testAdditionalSetupMatrix` had pre-resume passes on both models; that is historical evidence, not a resumed complete-suite result.
- `testAdditionalSetupMatrix` — NOT_RUN in resumed verification.
- `testChildAndResultMatrix` — NOT_RUN in resumed verification.
- `testChildEnvelopeAndLicenseFlow` — NOT_RUN in resumed verification.
- `testChildInfoMatrix` — NOT_RUN in resumed verification.
- `testChildSetupMatrix` — NOT_RUN in resumed verification.
- `testChildSupportDefaults` — NOT_RUN in resumed verification.
- `testExistingChildSetupRemainsEnabled` — NOT_RUN in resumed verification.
- `testFormMatrix` — NOT_RUN in resumed verification.
- `testGoalsUnsetMatrix` — NOT_RUN in resumed verification.
- `testHomeAX3LanguageMatrix` — NOT_RUN in resumed verification.
- `testHomeAlwaysHousehold` — NOT_RUN in resumed verification.
- `testHomeInteractiveMetric1000` — NOT_RUN in resumed verification.
- `testHomeInteractiveMetric10000` — NOT_RUN in resumed verification.
- `testHomeInteractiveMetric50000` — NOT_RUN in resumed verification.
- `testHomeWithFiftyThousandPersistedEntries` — NOT_RUN in resumed verification.
- `testIncomeEntry` — NOT_RUN in resumed verification.
- `testKoreanAmountsMatrix` — NOT_RUN in resumed verification.
- `testLaunchMetric1000` — NOT_RUN in resumed verification.
- `testLaunchMetric10000` — NOT_RUN in resumed verification.
- `testLaunchMetric50000` — NOT_RUN in resumed verification.
- `testLocalizedGroupedAmountFields` — NOT_RUN in resumed verification.
- `testLocalizedOnboarding` — NOT_RUN in resumed verification.
- `testManualTaxAndMetadataSurviveReopening` — NOT_RUN in resumed verification.
- `testMonthResultStatesMatrix` — NOT_RUN in resumed verification.
- `testNativeHomeLanguageEvidence` — NOT_RUN in resumed verification.
- `testNativeOnboardingEvidenceLightAndDark` — NOT_RUN in resumed verification.
- `testNativeScreenEvidenceLightAndDark` — NOT_RUN in resumed verification.
- `testNavigationMatrix` — NOT_RUN in resumed verification.
- `testNoSpendDayFromEmptyLedger` — NOT_RUN in resumed verification.
- `testNormalNewStoreLaunch` — NOT_RUN in resumed verification.
- `testOnboardingEntryTaxNoSpendTarget` — NOT_RUN in resumed verification.
- `testPersistedOnboardingRelaunch` — NOT_RUN in resumed verification.
- `testResultAndAccessibilityVariants` — NOT_RUN in resumed verification.
- `testScreenMatrix` — NOT_RUN in resumed verification.
- `testVoicePlaceholderIsShownOnce` — NOT_RUN in resumed verification.

- Optional rule-form audit and existing Home audit remain FAIL; nothing was excluded, disabled or relabeled PASS.
- Not every expense/income, schedule/date/tax/service permutation was exercised through the new form; Core's unchanged 117 tests and the listed UI scenarios are the evidence boundary.
- New-screen translation completeness was checked in all four languages; native-speaker review and a full new-screen four-language UI matrix were not performed.
- Actual VoiceOver gestures/speech, physical UI audits and new physical performance measurements were not run. Simulator audit results are not substituted for these.
- Day detail/Analysis follow the selected app currency; the posted list formats each entry with its own currency. Cross-currency day-detail/editor navigation was not separately verified. Existing entry editor idle-format behavior was not changed.
- No production deployment, App Store/TestFlight operation, real receipt/camera validation, unrelated cleanup, app dependency addition, user-data deletion or Git operation was performed. Temporary build/result files remain under `/tmp` for operator review/cleanup.
- Next cycle or further UI changes require the designer/operator's instruction under AGENTS.md. Physical developer trust is resolved and requires no further owner action from this report.
