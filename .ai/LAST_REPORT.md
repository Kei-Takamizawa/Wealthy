# Cycle 2a.5 Report

Task ID: WEALTHY-C2A5-SWIPE-LANG
Status: DONE

## Changed files
- Verification/Cycle2aEvidence/c2a5-device-launch.json
- .ai/LAST_REPORT.md
- LegacyApp/AppLanguage.swift
- LegacyApp/CoreTranslations.swift
- LegacyApp/FinanceTranslations.swift
- LegacyApp/UITranslations.swift
- LegacyApp/ar.lproj/InfoPlist.strings
- LegacyApp/fr.lproj/InfoPlist.strings
- LegacyApp/hi.lproj/InfoPlist.strings
- LegacyApp/id.lproj/InfoPlist.strings
- LegacyApp/pt.lproj/InfoPlist.strings
- LegacyApp/ru.lproj/InfoPlist.strings
- LegacyApp/zh-Hans.lproj/InfoPlist.strings
- Verification/DeviceUI/RESULTS.md
- Verification/DeviceUI/WealthyDeviceUITests.swift
- Verification/LEGACY_CHECKS.md
- Verification/Localization/main.swift
- Verification/MoneyTip/main.swift
- Verification/README.md
- Verification/TickerAdvice/Evaluate.swift
- Verification/TickerAdvice/RESULTS.md
- Verification/measure_device_launch.py
- Verification/verify_localization.sh
- Verification/verify_localization_catalog.py
- Wealthy/Wealthy/LedgerRoot.swift
- Wealthy/Wealthy/LedgerSession.swift
- WealthyUITests/WealthyUITests.swift

## Requirements

### Preflight and scope — PASS

- Run on the Mac terminal: arm64, macOS 27.0.1, Xcode 27.1 (27A9275).
- Branch `codex/wealthy-c2a5-swipe`; starting HEAD and `origin/main` were both `52d3839f479fd919e143ddc9903a366bc5a2e795`. `git ls-remote origin refs/heads/main` confirmed the same live remote SHA. `git merge-base --is-ancestor 5d53828 origin/main` succeeded; `git ls-tree --name-only origin/main AGENTS.md CLAUDE.md` listed both files. PR #7 and loop setup were already on main.
- Read AGENTS.md, CURRENT_TASK.md, LAST_REPORT.md and CLAUDE.md. CURRENT_TASK.md already contained the complete approved task and was preserved.
- The three dirty `.DS_Store` files and untracked `design/v4/引き渡しシート.pdf` predated the run and were left alone. No WealthyCore source, persistence, data model, tax/target rule, dependency, or font asset was changed.
- No commit, stage, push, branch change, merge or PR operation was performed; these belong to the operator under AGENTS.md.

### Physical-only resume — 2026-10-25

- Operator-confirmed fact: the developer was trusted and a normal `devicectl` launch succeeded at **2026-10-25T03:06Z**, with the phone unlocked and `passcodeRequired false`. This supersedes the earlier launch blocker. The resumed collector subsequently launched and measured the app successfully.
- Resume branch remained `codex/wealthy-c2a5-swipe`; HEAD was `f6c599629bdb5e818fe1591bb24c5a9bb3bcc909`. Earlier implementation changes had been recorded by the operator. This resume changes only this report and the new synthetic measurement JSON; the full cycle changed-files list above is retained.
- The operator deleted the earlier `/tmp/wealthy-c2a5*` logs, xcresults and temporary tooling with owner approval; only `/tmp/wealthy-c2a5-device` remained from the earlier run. Historical paths below identify the earlier runs and **are no longer available**, except that retained device build folder. Their observed results are preserved as historical results and were not re-run.
- Per the resume instruction, **no simulator tests, Core/language checks, builds, app installations or code changes were performed**. Only the remaining physical measurements and report/artifact validation ran. No commit, stage or push was performed.

### Swipe — PASS on both requested simulators

- Retained the standard system TabView and tab bar, with the single selection binding shared by taps and swipes.
- Added a UIKit pan recognizer through SwiftUI's UIGestureRecognizerRepresentable, attached only to the three root views. Only the selected, visible root is enabled; pushed destinations are excluded. The delegate rejects controls, text inputs, button/adjustable accessibility elements, first-responder focus and presented controllers. Result/error presentation and live VoiceOver state also gate navigation.
- Minimum horizontal travel is 80 pt, with horizontal displacement and initial velocity greater than twice the vertical component. No wrap-around; Reduce Motion uses a nil animation.
- iPhone 15 Pro and iPhone 17 Pro simulators both run iOS 27.0. The corrected four-test gesture run on 15 Pro passed 4/4 (`/tmp/wealthy-c2a5-gestures15-v3.xcresult`): full left/right/boundary swipes, Home/Info vertical scroll, editor kind/date/note drags, Info segmented drag, Reduce Motion and result-sheet isolation.
- Full 17 Pro run passed 10/10 (`/tmp/wealthy-c2a5-17.xcresult`), including tab taps, the four gesture tests and Home/Voice/Info/Entry/Result accessibility audits. No audit was filtered or suppressed.
- The final 15 Pro run passed **11/11** with zero failures (`/tmp/wealthy-c2a5-15-final.xcresult`): six navigation/gesture tests including short and diagonal drags, plus all five accessibility audits. It additionally verifies that the selected tab and hittable root content match after swipes. The supplemental 15 Pro long-selection/focus test passed **1/1** (`/tmp/wealthy-c2a5-15-selection.xcresult`). The 17 Pro supplemental run passed **3/3** (`/tmp/wealthy-c2a5-17-extra.xcresult`): strengthened tab/content synchronization, short/diagonal rejection and long-selection/focus isolation. Each simulator passed **12 distinct tests**, including all five audits. The 17 Pro horizontal test was repeated with the stronger visible-content assertions.

### Exactly four UI languages — PASS

- The former “196 keys in 11 languages / 6,634 checks” came from `verify_localization.sh` compiling the archived `LegacyApp` AppLanguage and Core/UI/Finance translation dictionaries. It did not inspect the shipping app's catalog. The shipping `Localizable.xcstrings` already had 149 keys in en, ja, es, ko.
- Removed the seven archived UI choices, translation dictionaries and InfoPlist resource directories: zh-Hans, hi, ar, fr, id, ru, pt. Retained en, ja, es, ko translations verbatim. Unsupported saved choices/locales fall back to English.
- Updated archived UI test language choices, money-tip checks/evaluator and documentation to four languages. Historical aggregate measurement totals remain explicitly historical; they were not relabeled as new measurements. Currency numeric-locale and natural-language detection fixtures remain because they are not supported UI language declarations.
- `verify_localization.sh` now checks the shipping catalog before running the archived regression checks: **149 keys x 4 languages, zero missing keys**, then **2,420 archived assertions / 196 keys x 4 languages, zero missing keys**.
- `verify_shell.py` passed: **149 keys x 4 languages**, placeholders, isolation, all four bundled font subset hashes, Hangul and Spanish glyph coverage. No font assets or font selection code changed (Patrick Hand, Klee One and Poor Story bundles preserved).
- Built Simulator Debug and physical Release measurement app bundles both contained exactly `en.lproj`, `es.lproj`, `ja.lproj`, `ko.lproj`. Project developmentRegion remains en; knownRegions is en/ja/es/ko plus Base.
- `verify_money_tip.sh` passed **572 checks across 17 synthetic fixtures**; this is deterministic policy verification, not new model generation.

### Physical device measurement — PASS

- Device freshly verified: **iPhone 16 Pro Max, iOS 27.2 (24B115)**. Device identifiers and uptime are omitted from public evidence.
- Used the already installed, optimized **Release** measurement build in `/tmp/wealthy-c2a5-device`, with `WEALTHY_LAUNCH_MEASUREMENT`. No rebuild or reinstall was needed. The real Apple Intelligence availability gate remained active.
- Used the existing app-level timing path instead of an XCTest runner. Valid measurement arguments select dedicated synthetic temporary disk stores, without opening the normal ledger or writing normal preferences. No app was uninstalled and no user data was deleted.
- The collector completed one excluded seed/warm-up and **five warm launches at each size**, without a debugger: 18 fresh launches total, including three warm-ups. All 18 launch identifiers were distinct and increasing, and medians were independently recomputed from the five samples.
- **10k HomeInteractive target: PASS**, median **1.184071 s**, with every warm sample <=2 s. The stop condition did not fire, so the collector proceeded to 50k. No Core persistence or performance optimization was changed.
- Durable full-precision synthetic evidence: [`Verification/Cycle2aEvidence/c2a5-device-launch.json`](../Verification/Cycle2aEvidence/c2a5-device-launch.json). Tables below show every measured warm launch, rounded to six decimal places in seconds. The JSON also retains excluded warm-ups and full-precision medians.
- FirstFrame is the loading view's two-display-callback boundary after LedgerSession initialization; HomeInteractive is Home's display callback. These are the existing in-app signpost boundaries, **not OS process-start first-frame or injected-touch-response measurements**. StoreOpen/Snapshot/QuerySnapshot/HomeRender are timings around those existing instrumented regions; per-column medians need not sum to the wall-clock median.

| Synthetic entries | Warm samples | FirstFrame median (s) | HomeInteractive median (s) | StoreOpen median (s) | Snapshot median (s) | QuerySnapshot median (s) | HomeRender median (s) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1,000 | 5/5 | 0.054591 | 0.221123 | 0.006565 | 0.054832 | 0.000583 | 0.104834 |
| 10,000 | 5/5 | 0.055596 | 1.184071 | 0.008107 | 0.513269 | 0.001875 | 0.619709 |
| 50,000 | 5/5 | 0.055157 | 5.689736 | 0.006783 | 2.734652 | 0.009884 | 2.845745 |

All warm samples (seconds):

| Entries | Launch | FirstFrame | HomeInteractive | StoreOpen | Snapshot | QuerySnapshot | HomeRender |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1,000 | 1 | 0.058976 | 0.289480 | 0.007408 | 0.058887 | 0.000403 | 0.163497 |
| 1,000 | 2 | 0.054837 | 0.221471 | 0.006565 | 0.056539 | 0.000604 | 0.102833 |
| 1,000 | 3 | 0.054591 | 0.221123 | 0.006760 | 0.054620 | 0.000583 | 0.104475 |
| 1,000 | 4 | 0.048312 | 0.215021 | 0.006372 | 0.054832 | 0.000579 | 0.104834 |
| 1,000 | 5 | 0.052494 | 0.219069 | 0.006381 | 0.054377 | 0.000639 | 0.105066 |
| 10,000 | 1 | 0.052890 | 1.161182 | 0.008568 | 0.502351 | 0.001789 | 0.595341 |
| 10,000 | 2 | 0.055596 | 1.172328 | 0.007448 | 0.500947 | 0.001832 | 0.606302 |
| 10,000 | 3 | 0.042244 | 1.184071 | 0.006777 | 0.513269 | 0.001915 | 0.619709 |
| 10,000 | 4 | 0.060301 | 1.247921 | 0.008239 | 0.520829 | 0.001875 | 0.656385 |
| 10,000 | 5 | 0.076701 | 1.247734 | 0.008107 | 0.537603 | 0.001955 | 0.623133 |
| 50,000 | 1 | 0.067142 | 5.605066 | 0.006717 | 2.695035 | 0.009884 | 2.826602 |
| 50,000 | 2 | 0.075556 | 5.655113 | 0.007017 | 2.734652 | 0.009455 | 2.828603 |
| 50,000 | 3 | 0.049446 | 5.936417 | 0.006783 | 2.718280 | 0.009482 | 3.152166 |
| 50,000 | 4 | 0.051866 | 5.689736 | 0.007205 | 2.774961 | 0.010108 | 2.845745 |
| 50,000 | 5 | 0.055157 | 5.788751 | 0.006527 | 2.772304 | 0.010189 | 2.944773 |

Excluded warm-up launches (seconds; excluded regardless of whether seeding was necessary):

| Entries | FirstFrame | HomeInteractive | StoreOpen | Snapshot | QuerySnapshot | HomeRender |
| --- | --- | --- | --- | --- | --- | --- |
| 1,000 | 0.044609 | 0.211094 | 0.010259 | 0.054907 | 0.000574 | 0.100644 |
| 10,000 | 0.049556 | 1.149577 | 0.012154 | 0.493916 | 0.001751 | 0.591913 |
| 50,000 | 0.056505 | 5.677816 | 0.008293 | 2.807586 | 0.009694 | 2.796078 |

The earlier native Security launch error is resolved; it is retained below only as run history. No simulator measurements are substituted for device numbers.

## Verification commands

### Required checks and supporting checks

- `sh Verification/verify_core.sh` — PASS, **117 tests in 13 suites**; the Disk ledger benchmarks suite and PERF opt-in disk latency test remain skipped by their unchanged defaults. First sandboxed attempt failed with `sandbox-exec: sandbox_apply: Operation not permitted`; the same command succeeded with authorized host access. Log: `/tmp/wealthy-c2a5-core.log`.
- `sh Verification/verify_localization.sh` — PASS, shipping 149 x 4 / archived 196 x 4, 2,420 assertions.
- `PATH=/tmp/wealthy-c2a5-tools/bin:$PATH python3 Verification/verify_shell.py` — PASS. The first run lacked fontTools; installed fonttools 4.67.0 in a disposable `/tmp/wealthy-c2a5-tools` venv, without adding an app dependency or changing system Python.
- `sh Verification/verify_money_tip.sh` — PASS, 572 checks / 17 fixtures.
- Python `ast.parse` on `Verification/measure_device_launch.py` and `Verification/verify_localization_catalog.py` — PASS.
- `git diff --check` — PASS (repeated after final report update).

### Simulator commands

Initial corrected gesture run:

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests \
  -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' \
  -derivedDataPath /tmp/wealthy-c2a5 -resultBundlePath /tmp/wealthy-c2a5-gestures15-v3.xcresult \
  -parallel-testing-enabled NO \
  -only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll \
  -only-testing:WealthyUITests/Cycle2aUITests/testEditorControlDragsDoNotSwitchTabs \
  -only-testing:WealthyUITests/Cycle2aUITests/testInfoSegmentedControlDragDoesNotSwitchTabs \
  -only-testing:WealthyUITests/Cycle2aUITests/testReduceMotionSwipeAndSheetIsolation test
```

PASS 4/4. The complete final simulator commands follow. Every command below passed; all tests use synthetic fixtures. The long-selection case enters synthetic text, holds for 1.2 seconds and drags within the note field, then attempts a horizontal swipe while editing. The editor remains active and Home remains selected.

iPhone 15 Pro: PASS 11/11, zero failures; log `/tmp/wealthy-c2a5-15-final.log`.

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9" -derivedDataPath /tmp/wealthy-c2a5 -resultBundlePath /tmp/wealthy-c2a5-15-final.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testPagerNavigation" "-only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll" "-only-testing:WealthyUITests/Cycle2aUITests/testShortAndDiagonalDragsDoNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testEditorControlDragsDoNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testInfoSegmentedControlDragDoesNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testReduceMotionSwipeAndSheetIsolation" "-only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testVoiceAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testInfoAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testEntryAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testResultAccessibilityAudit" test
```

iPhone 15 Pro supplemental: PASS 1/1, zero failures; log `/tmp/wealthy-c2a5-15-selection.log`.

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9" -derivedDataPath /tmp/wealthy-c2a5 -resultBundlePath /tmp/wealthy-c2a5-15-selection.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testFocusedSelectionAndEditorSwipeIsolation" test
```

iPhone 17 Pro: PASS 10/10, zero failures; log `/tmp/wealthy-c2a5-17.log`.

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0" -derivedDataPath /tmp/wealthy-c2a5-17 -resultBundlePath /tmp/wealthy-c2a5-17.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testPagerNavigation" "-only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll" "-only-testing:WealthyUITests/Cycle2aUITests/testEditorControlDragsDoNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testInfoSegmentedControlDragDoesNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testReduceMotionSwipeAndSheetIsolation" "-only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testVoiceAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testInfoAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testEntryAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testResultAccessibilityAudit" test
```

iPhone 17 Pro supplemental: PASS 3/3, zero failures; log `/tmp/wealthy-c2a5-17-extra.log`.

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0" -derivedDataPath /tmp/wealthy-c2a5-17 -resultBundlePath /tmp/wealthy-c2a5-17-extra.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll" "-only-testing:WealthyUITests/Cycle2aUITests/testShortAndDiagonalDragsDoNotSwitchTabs" "-only-testing:WealthyUITests/Cycle2aUITests/testFocusedSelectionAndEditorSwipeIsolation" test
```

### Ordinary Release build — PASS

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2a5 build
```

PASS without the measurement compile condition, for arm64 and x86_64 Simulator. Log: `/tmp/wealthy-c2a5-release.log`.

### Initial physical Release build and collector — historical attempt

Device UDID is redacted as `$DEVICE_UDID` below; the actual paired identifier was supplied when running these commands.

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests \
  -configuration Release -destination "platform=iOS,id=$DEVICE_UDID" \
  -derivedDataPath /tmp/wealthy-c2a5-device -allowProvisioningUpdates \
  'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) WEALTHY_LAUNCH_MEASUREMENT' build
xcrun devicectl device install app --device "$DEVICE_UDID" \
  /tmp/wealthy-c2a5-device/Build/Products/Release-iphoneos/Wealthy.app
python3 Verification/measure_device_launch.py --device "$DEVICE_UDID" \
  --output /tmp/wealthy-c2a5-device-samples.json
xcrun devicectl device process launch --device "$DEVICE_UDID" --terminate-existing \
  com.harrison.Wealthy -- --cycle2a-performance --entry-count 1000 -v4.language en -v4.currency JPY
codesign --verify --deep --strict /tmp/wealthy-c2a5-device/Build/Products/Release-iphoneos/Wealthy.app
```

Initial attempt: build PASS; install PASS; collector FAIL/BLOCKED at first launch; direct diagnostic launch FAIL with `CoreDeviceError 10002` / `FBSOpenApplicationErrorDomain 3 (Security)`: "Unable to launch com.harrison.Wealthy because it has an invalid code signature, inadequate entitlements or its profile has not been explicitly trusted by the user." Host codesign verification PASS. This earlier launch blocker is now resolved. The initial build without `-allowProvisioningUpdates` failed for a missing development profile; normal automatic signing resolved the build. Device launch subsequently succeeded after the operator confirmed trust. Build log: `/tmp/wealthy-c2a5-device-build-final.log`; collection log/result: `/tmp/wealthy-c2a5-device-measure.log`, `/tmp/wealthy-c2a5-device-samples.json`.

### Resumed physical collector — PASS

Device UDID is redacted as `$DEVICE_UDID`; the actual paired identifier was supplied. Executed only these device operations:

```sh
xcrun devicectl device info details --device "$DEVICE_UDID" \
  --json-output /tmp/wealthy-c2a5-resume-device.json \
  > /tmp/wealthy-c2a5-resume-device.log 2>&1
python3 Verification/measure_device_launch.py --device "$DEVICE_UDID" \
  --output /tmp/wealthy-c2a5-resume-samples.json \
  > /tmp/wealthy-c2a5-resume-measure.log 2>&1
```

Both commands PASS; collector exit code **0**, status **COMPLETED**. Each collector launch uses `device process launch --terminate-existing com.harrison.Wealthy -- --cycle2a-performance --entry-count N -v4.language en -v4.currency JPY`. It copies only `tmp/Cycle2aLaunchMeasurement.json` from the app container after each launch. Local resumed logs and raw output are new files; the durable, identifier-free full-precision measurements are in the changed-files JSON artifact.

Validation PASS: exactly 5 warm samples plus 1 excluded warm-up per size, expected entry counts, finite nonnegative metrics, 18 fresh launch identifiers, independently recomputed medians, and all five 10k HomeInteractive samples <=2 s. `git diff --check` PASS after the report/artifact update. No earlier automated test was rerun, as explicitly instructed.

## Errors, expected / actual and not done / unverified

- Expected: synchronized native tabs and safe root swipe, four-language checks, five warm physical samples at each size and 10k HomeInteractive <=2 s. Actual: earlier simulator results (12 distinct tests on each requested simulator) and language/Core passes are preserved; the resumed physical collector completed all 15 warm measurements and the 10k target passed. Status is DONE for this task. Earlier logs/xcresults were deleted with owner approval and are not claimed to be retained.
- Initial recognizer attempt used an unsupported `simultaneousGesture` overload and failed to build; replaced it with the documented `.gesture` bridge and simultaneous-recognition delegate. A subsequent preliminary run exposed a selected-Home/visible-Voice mismatch and editor test failures; the final implementation restricts recognition to the selected visible root and uses SwiftUI global-coordinate conversion. The corrected four-test 15 Pro run passed. The earlier failed run was interrupted after simulator runner relaunch errors; it is not counted as a pass.
- Xcode emitted simulator `invalidDigitCount(94232)`, debugger `noURL` and duplicate WebKit accessibility-class warnings. AppIntents metadata extraction was skipped because the app has no AppIntents dependency. No product changes were made for these tool/runtime warnings.
- Actual VoiceOver navigation/gesture toggling was not exercised; the implementation checks live `UIAccessibility.isVoiceOverRunning` before recognition and switching. Reduce Motion's deterministic UI-test override was exercised, rather than changing the phone's Settings.
- Baseline observation for the designer: current SwiftUI sources do not call `Font.custom`; bundled fonts/licenses are present. This cycle leaves that baseline unchanged and does not establish per-language handwritten rendering. No independent font/UI design change was made.
- No real financial records, ReceiptExample files, camera input, production deployment, new app dependencies, physical-app removal, persistence change, historical data migration, or new performance optimization was performed.
- The current free-provisioning runner app limit was not re-tested; the chosen app-level path installs no test runner. Physical UI audits, actual VoiceOver operation, Settings interaction and OS process-start/injected-touch latency were not newly tested; this resume was limited to the remaining app-level physical launch measurement. No remaining decision or external blocker is required for these measurements.
