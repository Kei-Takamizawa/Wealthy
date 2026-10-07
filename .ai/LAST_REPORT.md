# Cycle 2a.4 Report

Task ID: `WEALTHY-C2A4-UITEST-TARGET`
Status: **PARTIAL**

## Branch and base

- Branch: `codex/wealthy-c2a4-uitest`.
- Base: PR #6 head `96da9ee` because PR #6 was still an open draft during task setup; `origin/main` was `2cfe37b`. No PR was reused or merged.
- New draft PR creation remains pending.

## Implemented

- Added `WealthyUITests` UI test bundle target and shared `WealthyUITests` scheme, with UI tests copied into the target.
- Home audit layout adjustment: compressed weekly status to keep content within the scrollable plate, made weekday controls at least 44 pt wide, and removed duplicate Home Goals/Settings buttons that sat behind the tab bar. Goals remains available in Info; Settings was added to Info.
- Removed custom horizontal tab paging because a text-field selection drag switched pages in the earlier test run. Native tab bar navigation remains. The segmented gesture test crashed once when the XCTest runner was killed; rerunning that test alone passed.
- No WealthyCore behavior or new dependency was changed.

## Files changed for this cycle

- `.ai/CURRENT_TASK.md`
- `.ai/LAST_REPORT.md`
- `Wealthy/Wealthy.xcodeproj/project.pbxproj`
- `Wealthy/Wealthy.xcodeproj/xcshareddata/xcschemes/WealthyUITests.xcscheme`
- `WealthyUITests/WealthyUITests.swift`
- `Wealthy/Wealthy/HomeInfo.swift`
- `Wealthy/Wealthy/LedgerRoot.swift`
- `Verification/Cycle2aEvidence/native/` (45 JPEG screenshots and `INDEX.md`, approx. 6.5 MB; each image <1 MB, long edge <=2000 px)

Pre-existing dirty `.DS_Store` files, two `Launch_Wealthy*.trace/` directories, and `design/v4/引き渡しシート.pdf` were not part of this task and must not be staged. `project.pbxproj` was already dirty before the task with whitespace changes; this task added UI test target settings while preserving the existing whitespace state.

## Verification and exact commands

### Target, scheme, build, unit tests

- `xcodebuild -list -project Wealthy/Wealthy.xcodeproj` — PASS; targets `Wealthy`, `WealthyUITests`; schemes `WealthyCore`, `WealthyUITests`.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2a4-clean -only-testing:WealthyUITests/Cycle2aUITests/testVoiceAccessibilityAudit test` — PASS from clean derived data, 1/1.
- `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2a4-derived -resultBundlePath /tmp/wealthy-c2a4-accessibility-15final.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testVoiceAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testInfoAccessibilityAudit test` — PASS (3/3), iPhone 15 Pro Simulator, iOS 27.0.
- Same accessibility command with destination `DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0` and result `/tmp/wealthy-c2a4-accessibility-17final.xcresult` — PASS (3/3), iPhone 17 Pro Simulator, iOS 27.0.
- Entry and Result accessibility audits — PASS on iPhone 15 Pro and iPhone 17 Pro in earlier runs; 15 Pro result `/tmp/wealthy-c2a4-accessibility-15pro.xcresult`, 17 Pro result `/tmp/wealthy-c2a4-accessibility-17pro.xcresult` (17 Pro run included Home, Voice, Info, Entry and Result; 5/5).
- Physical device audits — NOT RUN. The iPhone 16 Pro Max UI runner installation was rejected because the free developer profile already had three test apps installed (`com.harrison.Wealthy.DeviceTestUITests.xctrunner`, `com.harrison.Wealthy.Cycle2aUITests.xctrunner`, and `com.harrison.Wealthy`). No app was uninstalled.
- `sh Verification/verify_core.sh` — PASS, 117 tests in 13 suites; two opt-in disk/performance tests skipped by suite defaults.
- `sh Verification/verify_localization.sh` — PASS, 6,634 checks; 196 keys in 11 languages.
- Simulator Debug build using scheme `WealthyUITests` — PASS.
- Simulator Release build using scheme `WealthyUITests` — PASS.
- Generic signed iOS device build using `xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'generic/platform=iOS' -derivedDataPath /tmp/wealthy-c2a4-device build` — PASS.
- Initial build attempt using scheme `Wealthy` — FAIL: no scheme named `Wealthy` is shared; `xcodebuild -list` confirms the project exposes `WealthyCore` and `WealthyUITests` shared schemes. The UI test scheme builds the app host.

### Swipe and control tests

- `testHorizontalSwipeRemovedAndVerticalScrollDoesNotSwitchTabs` — PASS; horizontal swipe is explicitly verified not to change page after removal, Home/Info vertical scrolling does not switch pages, and native tab taps still work.
- `testEditorControlDragsDoNotSwitchTabs` — PASS; vertical Edit scroll, segmented kind picker, date picker drag, text-field selection drag leave the entry editor active.
- `testInfoSegmentedControlDragDoesNotSwitchTabs` — PASS when rerun alone (`/tmp/wealthy-c2a4-info-gesture-retry.xcresult`). It was killed once as part of a longer multi-test run, then passed alone.
- The earlier pre-removal run showed a text selection drag could leave the editor when the custom pager gesture was enabled. The custom horizontal paging gesture was therefore removed; tab navigation uses the standard tab bar.
- No in-scope `List.swipeActions` surface exists. The only `List` found is font licenses; its rows have no swipe action. No artificial action was added, so an in-app List swipe-action interaction was not testable.
- VoiceOver gesture-disabled navigation was not tested because the Computer Use prerequisite CLI was missing (`orca not found`).

### Screenshots

- `testNativeScreenEvidenceLightAndDark` — PASS, 34 screenshots (17 screens × light/dark), captured on iPhone 15 Pro Simulator, iOS 27.0, synthetic fixture; attachments exported from `/tmp/wealthy-c2a4-native-screens.xcresult` and optimized to JPEG q80.
- `testNativeHomeLanguageEvidence` — PASS; English/Japanese/Spanish/Korean Home plus English AX3 Home, captured on same simulator. Initial attempts used stale accessibility identifiers and failed; the final test waits for `homePage` for AX3 and passed.
- Additional OS-setting screenshots: 6 images for Home/Voice/Info with Reduce Motion and Reduce Transparency enabled. The iOS preference values were set/read back using `xcrun simctl spawn <UDID> defaults write/read com.apple.Accessibility ReduceMotionEnabled|ReduceTransparencyEnabled`; Settings was launched with `xcrun simctl launch <UDID> com.apple.Preferences`, then Wealthy was launched to capture. This does **not** satisfy the requested Settings UI interaction: the switches were not toggled through XCUITest/computer use. Values were confirmed true before each capture. The capture screenshots are listed in `Verification/Cycle2aEvidence/native/INDEX.md`.
- VoiceOver manual pass was not run; see Computer Use prerequisite failure above.
- Home screenshot/crop and accessibility tree evidence from the initial failures were in temporary result bundles/logs, not committed as standalone images.

### Performance and idle CPU

Simulator: Wealthy iPhone 15 Pro (iPhone 15 Pro device type), iOS 27.0, UDID `870430A8-E557-4CED-8A8E-079801D804B9`. Data set is synthetic test data. Tests:

`xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2a4-derived -resultBundlePath /tmp/wealthy-c2a4-performance.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testLaunchMetric1000 -only-testing:WealthyUITests/Cycle2aUITests/testLaunchMetric10000 -only-testing:WealthyUITests/Cycle2aUITests/testLaunchMetric50000 -only-testing:WealthyUITests/Cycle2aUITests/testHomeInteractiveMetric1000 -only-testing:WealthyUITests/Cycle2aUITests/testHomeInteractiveMetric10000 -only-testing:WealthyUITests/Cycle2aUITests/testHomeInteractiveMetric50000 test`

- `XCTApplicationLaunchMetric` AppLaunch averages over its five warm launches: 1k 2.748 s; 10k 3.188 s; 50k 3.298 s. These are XCTest AppLaunch values, not first-frame timing.
- OS signpost FirstFrame: 1k samples `[0.221, 0.299, 0.474, 0.451, 0.486]` s (median 0.451 s); 10k one XCTest-retained sample 0.499 s; 50k one retained sample 0.299 s.
- OS signpost HomeInteractive: 1k samples `[0.871, 1.135, 2.849, 1.728, 1.802]` s (median 1.728 s); 10k one retained sample 3.245 s; 50k one retained sample 5.890 s.
- XCTest warned that the signpost metrics were not measured in the first iteration for the 10k/50k interactive tests, so XCTest retained one observation rather than the requested five. Those are single observed samples, **not medians**. 10k Home interactive exceeded the 2 s target in this sample. The five-run requirement is therefore incomplete for 10k/50k signposts.
- Signpost cost split (single retained sample for 10k/50k): 10k StoreOpen 0.241 s, Snapshot 1.034 s, QuerySnapshot 0.061 s, HomeRender 1.409 s; 50k StoreOpen 0.142 s, Snapshot 4.019 s, QuerySnapshot 0.171 s, HomeRender 1.259 s. FirstFrame was 0.499/0.299 s respectively. These are disjoint instrument intervals from simulator runs; they should not be added as wall-clock totals.
- 60 s idle Time Profiler: `xcrun xctrace record --template 'Time Profiler' --device 870430A8-E557-4CED-8A8E-079801D804B9 --attach 51439 --time-limit 60s --output /tmp/wealthy-c2a4-idle.trace --quiet`; trace duration 60.640591 s. Exported `time-sample` table had 232 samples, 1 in Running/Runnable state (0.43% sample share). This is simulator CPU profiler sample share, not device battery usage or a direct CPU utilization average.

## Expected / actual

- Expected: UI target and shared scheme; audits, gestures, screenshot evidence, 5-run metrics and idle CPU evidence; Settings UI automation for Reduce Motion/Transparency; VoiceOver attempt.
- Actual: target/scheme, simulator audits, gestures (with swipe removed), required core screenshot matrices, simulator metrics and profiler samples were obtained. Acceptance is **not met** because physical audits were blocked by provisioning install limits, Settings switches were changed through `simctl defaults` rather than UI, VoiceOver was not run, 10k/50k signpost five-run medians were not available, and 10k interactive exceeded the target in the single retained sample. No hardware performance or battery claim is made.

## Errors / warnings / reproduction

- Home audit initially reported a low-contrast “Not a balance” footer below the tab bar at AX3. The UI hierarchy showed that the bottom month summary and its “Not a balance” label were at y≈820 under the tab bar; after moving/compacting Home status content and removing duplicate bottom controls, final Home/Voice/Info audits passed on both simulators.
- `testInfoSegmentedControlDragDoesNotSwitchTabs` runner was killed once in a 3-test run (`Test crashed with signal kill`); its isolated rerun passed.
- Xcode emits `IDELaunchParametersSnapshot: debugger version lookup failed for path '<nil>': noURL` and a duplicate WebKit accessibility class warning in simulator runtime; neither blocked successful runs.
- To reproduce screenshot export: `xcrun xcresulttool export attachments --path /tmp/wealthy-c2a4-native-screens.xcresult --output-path /tmp/wealthy-c2a4-exported-native`.

## Unresolved / not run

- Settings interaction via `com.apple.Preferences` XCUITest and VoiceOver manual pass.
- Physical iPhone audit and performance measurement; free provisioning profile’s test app install limit prevented physical UI test runner install.
- 5 retained signpost measurements for 10k/50k, and a direct CPU utilization/battery metric.
- The physical device was iPhone 16 Pro Max, not an iOS 26 device; iOS 26 hardware behavior was not checked.
- No design-vs-implementation comparisons were requested in Cycle 2a.4; screenshots are implementation captures only.
- `git diff --check` — PASS. Commit, push, and new draft PR are still to be completed.

## Intentionally not performed

- No WealthyCore behavior changes, no dependency changes, no PR merge, no deletion of data or existing user files, and no staging of unrelated dirty files.
