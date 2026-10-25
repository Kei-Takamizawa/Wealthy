# Cycle 2a.5 Report

Task ID: WEALTHY-C2A5-SWIPE-LANG
Status: PARTIAL

## Changed files
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

### Physical device measurement — BLOCKED before launch

- Device observed: **iPhone 16 Pro Max, iOS 27.2 (24B115)**, paired over a wired connection, Developer Mode enabled. Device identifiers are omitted from this public report.
- Added an opt-in `WEALTHY_LAUNCH_MEASUREMENT` compile condition for the existing synthetic disk-store fixture path in an optimized Release build. Ordinary Release builds do not include that path. The real Apple Intelligence availability check remains active. The measurement launch uses dedicated temporary performance stores and does not open the normal ledger or write normal preferences.
- Added a bounded collector that seeds/warms once, then requests five warm launches per size without a debugger. It copies only `tmp/Cycle2aLaunchMeasurement.json`, rejects stale launch identifiers, publishes medians only after five samples, and stops at a measured 10k HomeInteractive >2 s. It does not install an XCTest runner.
- Release build and update installation of the existing `com.harrison.Wealthy` app succeeded. No app was uninstalled and no user data was deleted. The installed app is the opt-in measurement build; normal launches without measurement arguments follow the ordinary app path.
- The iPhone rejected the first 1k launch before any measurement. Exact native error: `com.apple.dt.CoreDeviceError 10002`, underlying `FBSOpenApplicationErrorDomain 3 (Security)`: **“Unable to launch com.harrison.Wealthy because it has an invalid code signature, inadequate entitlements or its profile has not been explicitly trusted by the user.”** Host-side `codesign --verify --deep --strict` passed; that does not establish device trust or entitlement acceptance.
- External check to unblock: on the iPhone, confirm the development signer is trusted under Settings > General > VPN & Device Management and the phone is unlocked. If already trusted, the operator must check the installed provisioning profile/signature/entitlements for this phone. A normal `devicectl ... process launch` must succeed before rerunning the collector. No security check was bypassed.

| Synthetic entries | Warm-up completed | Measured launches | FirstFrame samples / median | HomeInteractive samples / median |
| --- | --- | --- | --- | --- |
| 1,000 | No (launch rejected) | 0/5 | NOT_RUN | NOT_RUN |
| 10,000 | NOT_RUN | 0/5 | NOT_RUN | NOT_RUN |
| 50,000 | NOT_RUN | 0/5 | NOT_RUN | NOT_RUN |

- No device 10k target judgment or StoreOpen/Snapshot/HomeRender split is available because the process never launched. No simulator numbers are substituted.
- The in-app FirstFrame boundary is the loading view's two-display-callback waiter after LedgerSession initialization, and HomeInteractive is Home's display callback. These are the existing signpost boundaries, not OS process-start first-frame or injected-touch-response metrics. The collector is built and syntax checked but not validated end to end on hardware because of the launch blocker.

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

### Physical Release build and collector

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

Build PASS; install PASS; collector FAIL/BLOCKED at first launch; direct diagnostic launch FAIL with the exact Security error above; host codesign verification PASS. The initial build without `-allowProvisioningUpdates` failed for a missing development profile; normal automatic signing resolved the build, but device launch remains blocked. Build log: `/tmp/wealthy-c2a5-device-build-final.log`; collection log/result: `/tmp/wealthy-c2a5-device-measure.log`, `/tmp/wealthy-c2a5-device-samples.json`.

## Errors, expected / actual and not done / unverified

- Expected: synchronized native tabs and safe root swipe, four-language checks, five warm physical samples at each size, 10k HomeInteractive <=2 s or an exact external blocker. Actual: all 12 distinct simulator tests passed on each requested simulator, and language/Core checks passed; physical launch was rejected before measurement. Status remains PARTIAL because no physical launch samples or timing target evidence could be obtained.
- Initial recognizer attempt used an unsupported `simultaneousGesture` overload and failed to build; replaced it with the documented `.gesture` bridge and simultaneous-recognition delegate. A subsequent preliminary run exposed a selected-Home/visible-Voice mismatch and editor test failures; the final implementation restricts recognition to the selected visible root and uses SwiftUI global-coordinate conversion. The corrected four-test 15 Pro run passed. The earlier failed run was interrupted after simulator runner relaunch errors; it is not counted as a pass.
- Xcode emitted simulator `invalidDigitCount(94232)`, debugger `noURL` and duplicate WebKit accessibility-class warnings. AppIntents metadata extraction was skipped because the app has no AppIntents dependency. No product changes were made for these tool/runtime warnings.
- Actual VoiceOver navigation/gesture toggling was not exercised; the implementation checks live `UIAccessibility.isVoiceOverRunning` before recognition and switching. Reduce Motion's deterministic UI-test override was exercised, rather than changing the phone's Settings.
- Baseline observation for the designer: current SwiftUI sources do not call `Font.custom`; bundled fonts/licenses are present. This cycle leaves that baseline unchanged and does not establish per-language handwritten rendering. No independent font/UI design change was made.
- No real financial records, ReceiptExample files, camera input, production deployment, new app dependencies, physical-app removal, persistence change, historical data migration, or new performance optimization was performed.
- The current free-provisioning runner app limit was not re-tested; the chosen app-level path installs no test runner. Hardware acceptance and any raw device samples remain unavailable until the native launch blocker is resolved.
