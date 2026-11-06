# Cycle 2b.1 Round 2 Report

Task ID: WEALTHY-C2B1-FIXED-CALENDAR
Status: PARTIAL

The final-source full UI runs are in progress; this checkpoint does not establish completion. The rule-form default audit and the strengthened, unfiltered Home audit have reported Dynamic Type issues. No audit is disabled or waived.

## Changed files
- .ai/CURRENT_TASK.md (pre-existing Round 2 task preserved; resume instructions appended)
- .ai/LAST_REPORT.md
- Wealthy/Wealthy/FixedCosts.swift
- Wealthy/Wealthy/HomeInfo.swift
- Wealthy/Wealthy/LedgerRoot.swift
- WealthyUITests/Cycle2bUITests.swift
- WealthyUITests/WealthyUITests.swift
- Verification/Cycle2bEvidence/INDEX.md
- Verification/Cycle2bEvidence/iphone15pro-rule-form-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-rule-form-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-rule-form-ax3.jpg
- Verification/Cycle2bEvidence/iphone15pro-home-light.jpg
- Verification/Cycle2bEvidence/iphone15pro-home-dark.jpg
- Verification/Cycle2bEvidence/iphone15pro-home-ax3.jpg
- Verification/Cycle2bEvidence/iphone17pro-rule-form-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-rule-form-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-rule-form-ax3.jpg
- Verification/Cycle2bEvidence/iphone17pro-home-light.jpg
- Verification/Cycle2bEvidence/iphone17pro-home-dark.jpg
- Verification/Cycle2bEvidence/iphone17pro-home-ax3.jpg

## Requirements

### Scope and environment
- Mac arm64, macOS 27.2, Xcode 27.2 (27B52); iPhone 15 Pro (`870430A8-E557-4CED-8A8E-079801D804B9`) and iPhone 17 Pro (`DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0`) run iOS 27.0 (24A434). Branch `codex/wealthy-c2b1-fixed-calendar`, HEAD `5fee7164e7fac6536ed751091f53ab363ee257ff`; local `origin/main` was `5db23f05241cdfb77161aad8eb6b4e1005869e0f`.
- Read AGENTS.md, CLAUDE.md, CURRENT_TASK.md and LAST_REPORT.md; appended the user's resume instructions without replacing the pre-existing task. Three unrelated pre-existing .DS_Store modifications and `design/v4/引き渡しシート.pdf` remain untouched. ReceiptExample was not read. No Core, persistence, schema, tax/target rule, font, localization or dependency changes.
- No stage, commit, push, merge or branch switch. The specifically requested detached baseline worktree was created at `/tmp/wealthy-c2b1-baseline` and removed without committing.

### Test environment — implemented; final after-state pending
- Before changes, both simulators reported content size `large` via `xcrun simctl ui <UDID> content_size`. The after readings will be recorded after the final suite.
- Removed the SwiftUI `LegacyUITestTypeSize` override. All XCTest app launches use `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryL`, or `UICTContentSizeCategoryAccessibilityXL` for `--ax3`; the production app follows the actual system category.
- Before further UI changes, default form audits still reported Category and Day of month (15 Pro) and Day of month (17 Pro) as `Dynamic Type font sizes are partially unsupported`. The existing four-type Home audit still found `Not a balance` and `I spent nothing today` clipped (15 Pro), and `Not a balance` and `Within allowance` clipped (17 Pro). `testC2bChildIsolation`, updated to assert the Category Picker value `Food`, passed on both.

### Rule form — PARTIAL
- Day is selected from 1...31, yearly month from 1...12, through plain numeric standard navigation-link Pickers; Category uses the plain title/selection Picker initializer and navigation-link style. Other pickers retain their original styles. Core still validates schedule values. The form-wide navigation-link experiment was reverted after new contrast warnings.
- Removed fixed widths/heights and `fixedSize` from those rows. Inspection found no fixed font size, fixed height, `minimumScaleFactor`, or `lineLimit` on the Category/Day/Month Picker rows. Explicit `.font(.body)` did not change the finding and was reverted.
- The unchanged default `performAccessibilityAudit()` reported `Dynamic Type font sizes are partially unsupported`; exact detail: `User will not be able to change the font size of this SwiftUI.AccessibilityNode`. A temporary diagnostic invoked the full audit, printed every element, called XCTFail for every issue and returned false. 15 Pro: `Category`, empty identifier, frame `{{32, 488.83334350585938}, {307, 20.333343505859375}}`; `Day of month`, empty identifier, frame `{{32, 627.83331298828125}, {307, 20.33331298828125}}`. 17 Pro: `Day of month`, empty identifier, frame `{{32, 630.83331298828125}, {316, 20.33331298828125}}`. Parent Picker identifiers are `ruleCategory` and `ruleDay`. The temporary diagnostic was removed after evidence collection; the default audit remains in `testC2bAccessibilityAndEvidence` and still fails. Evidence: `/tmp/wealthy-c2b1-r2-resume-diag{15,17}.log`, associated xcresults.
- `testC2bChildIsolation` checks accessibility value `Food` before and after saving; both models passed. `testC2bForegroundCatchUp` was changed to select the day before entering the amount so the keyboard does not cover the Picker; focused follow-up passed on both (`...resume-follow{15,17}.log`).

### Home — PARTIAL
- Changed affected labels to wrapping standard text/image arrangements, removed fixed text-container dimensions, and stack week/month values and status at accessibility sizes. The weekly title/value also stack at accessibility sizes and logged-days text takes its natural vertical height. No UI arithmetic or domain behavior changed.
- The existing Home audit's four types (contrast, text clipped, hit region, sufficient element description) passed on both in the completed prior full runs. To cover the requested no-exclusion criterion, the test now additionally invokes the default full `performAccessibilityAudit()` with no handler: focused follow-up failed on both with multiple `Dynamic Type font sizes are partially unsupported` reports for Home text. This is not claimed as a pass. The pre-final-layout focused full audit emitted 15 Dynamic Type issues per simulator for `This week`, `I spent nothing today`, `¥2,900`, weekday labels M/T/W/T/F/S/S, `¥307,100`, `Left this month`, `Not a balance`, `Add entry`, and `Spent`; the exact issue name was `Dynamic Type font sizes are partially unsupported`. The final-source suite is rechecking them.
- Enhanced `testHomeAX3LanguageMatrix`: check the Home collection and second tab without an English-only label, and run the text-clipped audit both before and after scrolling to the add-entry button. The earlier full run failed on missing offscreen `addEntry` and localized tab name; following that correction, Spanish `Te queda esta semana` and then `6 días registrados` were reported clipped. After the targeted layout changes, `testHomeAX3LanguageMatrix` passed in en/ja/es/ko on both models, as did `testNativeHomeLanguageEvidence` (`...resume-axfinal{15,17}.log`).
- Baseline classification remains inconclusive: one run on unmodified 5db23f0, 15 Pro, system content size `large`, failed at the zero-alert assertion because the ledger could not open (`Unable to complete` / `The new ledger could not be opened. Try again.`); the screen was onboarding, not Home. No baseline source or test was changed. `/tmp/wealthy-c2b1-r2-baseline.log` and corresponding xcresult retain the evidence.

### Full UI suite — final-source runs IN PROGRESS
- Previous resumed run, before the final Home fixes and stronger Home audit: 15 Pro 59 tests, 52 passed / 7 failed / 0 skipped; 17 Pro 59, 54 passed / 5 failed / 0 skipped. These are historical and do not establish the final-source result. Full results: `/tmp/wealthy-c2b1-r2-resume-summary{15,17}.json`.
- Prior failures: `testC2bAccessibilityAndEvidence` (form audit, both); `testC2bForegroundCatchUp` (15 Pro Picker hidden by keyboard, subsequently passed focused on both); `testChildEnvelopeAndLicenseFlow` (both: child toggle remained off and Targets was absent); `testChildSupportDefaults` (both: expected October fixture tax ¥266 but displayed November ¥0); `testHomeAX3LanguageMatrix` (both: no scrolling / English-only tab lookup, subsequently fixed and focused pass on both); `testIncomeEntry` (both: expected October fixture tax ¥218 but November ¥0 displayed); `testPersistedOnboardingRelaunch` (15 Pro: keyboard covered Next). Existing unrelated flows were not altered.
- The full runs on the latest sources, one per simulator, have no test filter and use `-parallel-testing-enabled NO`. Counts and every final failure remain pending. Launch/interactive metric methods run as part of the suite; simulator numbers are not judged against the physical-device target.

### Screenshots — PASS for artifact validation; final suite pending
- `Verification/Cycle2bEvidence/INDEX.md` indexes 42 JPEGs. Round 2 refreshed only the two devices' rule-form and Home images; other screens retain Round 1 images. Synthetic data only. Home AX3 images are from the final focused run; other refreshed images are from the previous completed resumed suite, with unchanged presentation at those sizes.
- `sips` quality 80; all 42 images have long edge 2,000 px, total 5,439,353 bytes, largest 181,161 bytes, zero files >=1 MB. Representative Home AX3 and rule form images were visually inspected. Screenshots are not proof of a passing audit or of physical-device/VoiceOver behavior.

## Verification commands

```sh
# Before/after simulator content size (after still pending)
xcrun simctl ui 870430A8-E557-4CED-8A8E-079801D804B9 content_size
xcrun simctl ui DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0 content_size
# Final-source full runs, both still in progress
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b1-r2 -resultBundlePath /tmp/wealthy-c2b1-r2-last-full15.xcresult -parallel-testing-enabled NO test > /tmp/wealthy-c2b1-r2-last-full15.log 2>&1
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b1-r2-17 -resultBundlePath /tmp/wealthy-c2b1-r2-last-full17.xcresult -parallel-testing-enabled NO test > /tmp/wealthy-c2b1-r2-last-full17.log 2>&1
# Final production source checks
sh Verification/verify_core.sh > /tmp/wealthy-c2b1-r2-last-core.log 2>&1
PATH=/tmp/wealthy-c2b1-tools/bin:$PATH python3 Verification/verify_shell.py > /tmp/wealthy-c2b1-r2-last-shell.log 2>&1
sh Verification/verify_localization.sh > /tmp/wealthy-c2b1-r2-last-localization.log 2>&1
git diff --check
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b1-r2-release build > /tmp/wealthy-c2b1-r2-resume-release-last.log 2>&1
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/wealthy-c2b1-r2-device -allowProvisioningUpdates build > /tmp/wealthy-c2b1-r2-resume-device-last.log 2>&1
codesign --verify --deep --strict /tmp/wealthy-c2b1-r2-device/Build/Products/Release-iphoneos/Wealthy.app
```

Core PASS: 117 tests in 13 suites. Shell PASS: 199 keys x four languages and zero missing. Localization PASS: shipping catalog and 2,420 archived checks. Simulator Release PASS; signed generic iOS Release PASS; signature PASS; diff check PASS. Builds reported the existing AppIntents metadata warning (no dependency found). Initial sandboxed Core test failed because nested sandbox-exec was not permitted; the authorized run passed. Result-bundle attachment exports initially conflicted when run against the same bundle concurrently; sequential exports succeeded.

Focused commands use the same xcodebuild arguments with `-only-testing` for `testHomeAccessibilityAudit`, `testHomeAX3LanguageMatrix`, `testNativeHomeLanguageEvidence`, `testC2bForegroundCatchUp` or `testC2bChildIsolation`; exact command line and logs remain under `/tmp/wealthy-c2b1-r2-resume-*.log` with corresponding xcresults. Baseline command and original interrupted runs are in the previous checkpoint; original completed Round 1 report remains in HEAD.

## Not done / unverified
- Final-source full-suite completion, precise final failures and simulator content-size after values pending. Status remains PARTIAL even if other checks pass while required default audits report issues.
- No physical install, launch, performance measurement or VoiceOver walkthrough was repeated in Round 2. Prior physical-device evidence is historical, not a new observation.
- No deploy, Git recording, user-data deletion or unrelated cleanup. The operator owns Git. Round 1 board/Core differences are retained in the report at HEAD; this round does not alter them.


Final-source run checkpoint: both devices reached `testScreenMatrix` after 55 of 59 tests. `testHomeAX3LanguageMatrix`, `testC2bForegroundCatchUp` and `testC2bChildIsolation` passed on both. Completed failures so far on both: `testC2bAccessibilityAndEvidence`, `testChildEnvelopeAndLicenseFlow`, `testChildSupportDefaults`, `testHomeAccessibilityAudit`, and `testIncomeEntry`. On 15 Pro, `testPersistedOnboardingRelaunch` also failed because the keyboard covered Next; 17 Pro passed that method. Remaining cases and final counts are pending.
