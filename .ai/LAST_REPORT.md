# Cycle 2b.2 Final Round 3 Report

Task ID: WEALTHY-C2B2-QUICK-ENTRY
Status: PARTIAL

The Home swipe regression is fixed on both simulators. Expanded safe-line Home still fails the unchanged contrast audit because weekday text lies behind the floating tab bar. Do not merge on this report.

Branch: `codex/wealthy-c2b2-quick-entry`; starting HEAD `f86ae6837688ab292cf97055da69dd16cbf711b1`. `fc74376` is an ancestor (verified, exit 0). macOS execution host, Xcode 27.2 (27B52); both simulators run iOS 27.0. No Windows implementation was started. No staging, commit, push, branch switch or merge was performed.

## Changed files

Whole-cycle files relative to `fc74376` (including earlier checkpoint implementation and retained Round 2 evidence):

- `.ai/CURRENT_TASK.md`
- `.ai/LAST_REPORT.md`
- `README.md`
- `Verification/Cycle2bEvidence/c2b2/INDEX.md`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-ai-detail-light.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-ai-row-light.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-home-safe-dark.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-home-safe-light.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-quick-ax3.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-quick-dark.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-quick-light.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-swipe-failure-1.txt`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-swipe-failure-2.txt`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-swipe-failure-3.txt`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-ai-detail-light.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-ai-row-light.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-home-safe-dark.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-home-safe-light.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-quick-ax3.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-quick-dark.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-quick-light.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-swipe-failure-1.txt`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-swipe-failure-2.txt`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-swipe-failure-3.txt`
- `Verification/Cycle2bEvidence/c2b2/round3-home-audit.txt`
- `Wealthy/Wealthy/AppShortcuts.xcstrings`
- `Wealthy/Wealthy/CalendarAnalysis.swift`
- `Wealthy/Wealthy/EntryEditor.swift`
- `Wealthy/Wealthy/ExpenseIntents.swift`
- `Wealthy/Wealthy/GoalsTaxSettings.swift`
- `Wealthy/Wealthy/HomeInfo.swift`
- `Wealthy/Wealthy/LedgerRoot.swift`
- `Wealthy/Wealthy/LedgerSession.swift`
- `Wealthy/Wealthy/Localizable.xcstrings`
- `Wealthy/Wealthy/QuickAdd.swift`
- `Wealthy/Wealthy/RecurringSession.swift`
- `Wealthy/Wealthy/WealthyApp.swift`
- `WealthyCore/Sources/WealthyCore/SafeLine.swift`
- `WealthyCore/Tests/WealthyCoreTests/SafeLineTests.swift`
- `WealthyUITests/Cycle2bUITests.swift`
- `WealthyUITests/QuickEntryUITests.swift`
- `WealthyUITests/WealthyUITests.swift`

Round 3 implementation/test edits: HomeInfo.swift, QuickEntryUITests.swift, WealthyUITests.swift. All 14 JPEGs were recaptured; INDEX.md was updated; round3-home-audit.txt was added. CURRENT_TASK.md is the designer-supplied task, preserved without editing in this run. Historical Round 2 failure trees are retained. The three pre-existing .DS_Store changes and untracked design PDF were left alone. ReceiptExample was not read.

## Requirements

### Round 3 decided Home layout and entry points — PASS

HomeView now has the original direct Form container and original modifier order from fc74376: lineLimit, navigationTitle, navigationBarTitleDisplayMode, accessibilityIdentifier, toolbar, task. GeometryReader, manual container frame, clipping and the bottom safeAreaInset footer were removed. This cycle's in-Form content remains. The third-section borderedProminent `addEntry` row and leading `quickAddToolbar` both open the same Quick add sheet; the trailing result menu remains. DEBUG intentDialog uses a conditional top overlay, with no content when nil.

| Simulator | Restored Home frame, all three swipe assertions | fc74376 frame, fresh comparison | Tab bar |
| --- | --- | --- | --- |
| 15 Pro | x0 y0 w393 h852 | x0 y0 w393 h852 | x0 y769 w393 h83 |
| 17 Pro | x0 y0 w402 h874 | x0 y0 w402 h874 | x0 y791 w402 h83 |

The Round 2 failure frames were 393x686 / 402x708; those describe the old bounded container, not the baseline. The prior report did not retain baseline geometry, so fc74376 was remeasured this round. Current frames match the fresh baseline. Both initial and return-swipe hittability assertions pass without weakening or identifier relocation.

### Targeted execution order and audits — PARTIAL

| Run | iPhone 15 Pro | iPhone 17 Pro |
| --- | --- | --- |
| testHorizontalTabSwipeAndVerticalScroll (Swipe) | PASSED, 38.868s | PASSED, 38.875s |
| testHomeAccessibilityAudit (Initial Home run (obsolete footer comparison)) | PASSED, 21.043s | PASSED, 21.033s |
| testSafeLineAndAIInformationEvidence (Initial Home run (obsolete footer comparison)) | FAILED, 12.025s | FAILED, 12.039s |
| testHomeAccessibilityAudit (Home after geometry-reference update) | PASSED, 20.491s | PASSED, 20.384s |
| testSafeLineAndAIInformationEvidence (Home after geometry-reference update) | FAILED, 59.782s | FAILED, 59.302s |
| testHomeAccessibilityAudit (fc74376, light and dark) | PASSED, 39.123s | PASSED, 29.924s |
| testQuickEntryCategoryDetailsAndInvalidAmount (Quick add) | PASSED, 37.079s | PASSED, 35.853s |
| testQuickEntryKeyboardLayoutAndEvidence (Quick add) | PASSED, 53.478s | PASSED, 48.634s |
| testQuickEntryThreeInteractionsAndUncategorized (Quick add) | PASSED, 24.343s | PASSED, 23.153s |

Run order: swipe on both -> Home audits on both -> fc74376 comparison -> keyboard/3-interaction/row-button tests on both -> full suites. No audit exclusions were added. Only the existing narrow SwiftUI Dynamic Type filter is used.

Test adjustment, recorded in this report before editing: the old safeAmount-vs-addEntry-frame assertion failed with "No matches found" because the former footer is now an offscreen Form row. It now checks safeAmount.maxY < tabBars.firstMatch.frame.minY. Both safeAmount and scheduled-title hittability assertions and the full audit remain. The first Home runs stopped at that outdated reference; they are not audit passes.

Expected: readable Home content and zero audit issues. Actual: expanded-safe-line audit: 15 Pro has 10 contrast assertions, 17 Pro has 9 across light/dark. Weekday letters T/W/T/F/S are at y803 height18 on 15 Pro and y806 height18 on 17 Pro, intersecting the tab bars above. The screenshots visibly confirm the overlap. Safe amount itself remains above the bar (see round3-home-audit.txt). AI-information audit has no failures in these runs. Standard seeded Home audit passes. Fresh fc74376 full Home audit passes in light and dark on both simulators; it has no safe-line feature and cannot provide the identical expanded fixture. Comparison worktree `/tmp/wealthy-c2b2-baseline` was removed after testing; nothing was committed.

### Full WealthyUITests — final-source results

Failed-case counts below are test cases; XCTest suite summaries count the individual failing contrast assertions.

- iPhone 15 Pro: 74 test cases completed; 1 failed. Failures: testSafeLineAndAIInformationEvidence.
  Executed 74 tests, with 10 failures (0 unexpected) in 5335.666 (5335.739) seconds
- iPhone 17 Pro: 74 test cases completed; 1 failed. Failures: testSafeLineAndAIInformationEvidence.
  Executed 74 tests, with 9 failures (0 unexpected) in 5698.563 (5698.632) seconds

| Acceptance evidence test | 15 Pro | 17 Pro |
| --- | --- | --- |
| testQuickEntryWithoutAIFromOnboarding | PASSED, 35.873s | PASSED, 34.544s |
| testAvailableAIInformation | PASSED, 4.923s | PASSED, 5.149s |
| testQuickEntryThreeInteractionsAndUncategorized | PASSED, 26.727s | PASSED, 26.807s |
| testQuickEntryCategoryDetailsAndInvalidAmount | PASSED, 39.744s | PASSED, 42.243s |
| testQuickCategoryRankingAndPresets | PASSED, 22.737s | PASSED, 29.478s |
| testRecordExpenseIntentAndRelaunch | PASSED, 50.583s | PASSED, 55.236s |
| testIntentWithoutTargetAndInvalidAmount | PASSED, 16.512s | PASSED, 17.665s |
| testIntentIncludesTodaysRecurringExpense | PASSED, 11.550s | PASSED, 12.501s |
| testOpenQuickAddIntentAndPendingNotice | PASSED, 21.706s | PASSED, 24.780s |
| testLocalizedQuickEntryAndSafeLine | PASSED, 70.021s | PASSED, 65.791s |
| testQuickEntryKeyboardLayoutAndEvidence | PASSED, 56.852s | PASSED, 60.961s |
| testSafeLineAndAIInformationEvidence | FAILED, 73.262s | FAILED, 73.118s |
| testHorizontalTabSwipeAndVerticalScroll | PASSED, 31.850s | PASSED, 30.631s |

Full-suite contrast assertion counts: 10 on 15 Pro and 9 on 17 Pro, all on `home-safe-line`. Failure frames match the targeted runs: weekday text y803/h18 on 15 Pro and y806/h18 on 17 Pro, inside the tab bars at y769–852 and y791–874 respectively. See [round3-home-audit.txt](../Verification/Cycle2bEvidence/c2b2/round3-home-audit.txt) for the per-element frames; full logs remain in /tmp.

Both full runs used `-parallel-testing-enabled NO` with no only-testing, skip-testing or exclusions. Targeted successes do not override the full-suite failures.

### Original requirements 1–5

- E3/AI: existing implementation opens the ledger regardless of availability, keeps availability information in Settings/detail, accepts both DEBUG switches, and updates README. See full-suite `testQuickEntryWithoutAIFromOnboarding` and `testAvailableAIInformation` results. No AI-gate coverage was removed.
- Quick add: the toolbar completes tap/type/save in exactly 3 interactions on both simulators; uncategorized day detail and analysis, category save, invalid amount, ranking/presets and More details are covered by the named tests. Row opening now has an explicit sheet-existence assertion. All amount arithmetic remains in Core/session.
- App Intents: unchanged checkpoint implementation. `LedgerSession.shared` has a private initializer and retains the process's single Core/store. UI, entity queries and intents use it; Quick add and RecordExpenseIntent share `recordExpense`, including recurring catch-up. Scene activation reload remains. Intent hooks exercise actual perform(), category/nil, relaunch without duplication and no-target/error cases in isolated synthetic stores. No extension, capability, entitlement, App Group or dependency was added.
- Safe line: unchanged read-only Core query reuses upcoming schedule logic and checked arithmetic. Fresh Core verification passes 123 tests in 14 suites (117 previous plus six new functions with parameterized cases), covering all specified boundary/filter/negative/overflow cases. Persistence/model/target/tax behavior was not changed. Safe-line content is present, but its Home accessibility acceptance fails as described above.
- Languages: 212 shipping keys x en/ja/es/ko, zero missing keys, placeholder/font checks pass; archived verification adds 2,420 checks. Japanese wording retained: クイック記録, 未分類, 今週あと安心して使える額. No new wording was added in Round 3.

### Keyboard frames and screenshots — PASS for required Quick add controls

| Simulator/type | Amount y / height | Save y / height | Keyboard top |
| --- | --- | --- | --- |
| 15 Pro default (light/dark) | 186 / 42.67 | 495 / 34.33 | 550 |
| 15 Pro AX3 | 209 / 64 | 472 / 62 | 550 |
| 17 Pro default (light/dark) | 189 / 42.67 | 517 / 34.33 | 572 |
| 17 Pro AX3 | 212 / 64 | 494 / 62 | 572 |

Expected/Actual: recording the synthetic 650-yen expense changes this week remaining from 70,000 to 69,350 yen on both simulators. Expanded Home shows 70,000 yen remaining, 2,000 yen scheduled and 68,000 yen safe, with Synthetic Thursday on October 8. The tests and screenshots observe these values. All Amount/Save frames are fully above the keyboard and hittable. Both interaction counters print 3. All 14 images in [INDEX.md](../Verification/Cycle2bEvidence/c2b2/INDEX.md) were recaptured and individually opened in this round. All six Quick add images visibly show Amount, typed digits 650 and Save above the number pad. AX3 lower options may need scrolling. Home images show the new leading plus, expanded scheduled date/title/amount, and the unresolved tab-bar overlap. AI images show unavailable state and the no-AI-required explanation. JPEG quality 80, long edge 2000; 15 Pro 921x2000, 17 Pro 920x2000; sizes 103,637–180,335 bytes, all below 1 MB.

### Release, metadata and physical device — PASS

Simulator Release build: PASS. Signed generic iOS Release build: PASS; codesign strict/deep verification PASS. Both use existing task build directories in /tmp. Product source did not change after these builds.

The final signed app contains Metadata.appintents/extract.actionsdata. Observed actions: OpenQuickAddIntent (openAppWhenRun=true, no parameters), RecordExpenseIntent (openAppWhenRun=false, required amount, optional category). Auto-shortcut keys and compiled en/ja/es/ko AppShortcuts.strings were inspected:

| Language | Quick add | Record expense |
| --- | --- | --- |
| en | Quick add in ${applicationName} | Record an expense in ${applicationName} |
| ja | ${applicationName}でクイック記録 | ${applicationName}で支出を記録 |
| es | Registro rápido en ${applicationName} | Registrar un gasto en ${applicationName} |
| ko | ${applicationName}에서 빠른 기록 | ${applicationName}에서 지출 기록 |

Paired iPhone 16 Pro Max, iOS 27.3 (24C5037i): Release install exit 0; one normal launch exit 0. No taps or entries were made in the owner's ledger. No uninstall/deletion was performed. Optional owner check: run Record expense once from the Shortcuts app only for an expense the owner actually intends to record.

## Verification commands

All logs/result bundles use `/tmp/wealthy-c2b2-r3-*`. Baseline runs used cwd=/tmp/wealthy-c2b2-baseline; other runs used the repository root. Exact invocations are listed below; simulator IDs are test destinations, physical-device ID is intentionally omitted.

```sh
sh Verification/verify_core.sh > /tmp/wealthy-c2b2-r3-core.log 2>&1
PYTHONPATH=/Users/harrison/Library/Python/3.14/lib/python/site-packages python3 Verification/verify_shell.py > /tmp/wealthy-c2b2-r3-shell.log 2>&1
sh Verification/verify_localization.sh > /tmp/wealthy-c2b2-r3-localization.log 2>&1
git diff --check
```

Core, shell, localization and final diff check: PASS. Targeted/full test commands:

`swipe15`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9" -derivedDataPath /tmp/wealthy-c2b2-r3-15 -resultBundlePath /tmp/wealthy-c2b2-r3-swipe15.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll" test > /tmp/wealthy-c2b2-r3-swipe15.log 2>&1
```

`swipe17`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0" -derivedDataPath /tmp/wealthy-c2b2-r3-17 -resultBundlePath /tmp/wealthy-c2b2-r3-swipe17.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll" test > /tmp/wealthy-c2b2-r3-swipe17.log 2>&1
```

`home15`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9" -derivedDataPath /tmp/wealthy-c2b2-r3-15 -resultBundlePath /tmp/wealthy-c2b2-r3-home15.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testSafeLineAndAIInformationEvidence" test > /tmp/wealthy-c2b2-r3-home15.log 2>&1
```

`home17`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0" -derivedDataPath /tmp/wealthy-c2b2-r3-17 -resultBundlePath /tmp/wealthy-c2b2-r3-home17.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testSafeLineAndAIInformationEvidence" test > /tmp/wealthy-c2b2-r3-home17.log 2>&1
```

`home15b`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9" -derivedDataPath /tmp/wealthy-c2b2-r3-15 -resultBundlePath /tmp/wealthy-c2b2-r3-home15b.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testSafeLineAndAIInformationEvidence" test > /tmp/wealthy-c2b2-r3-home15b.log 2>&1
```

`home17b`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0" -derivedDataPath /tmp/wealthy-c2b2-r3-17 -resultBundlePath /tmp/wealthy-c2b2-r3-home17b.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit" "-only-testing:WealthyUITests/Cycle2aUITests/testSafeLineAndAIInformationEvidence" test > /tmp/wealthy-c2b2-r3-home17b.log 2>&1
```

`baseline15`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9" -derivedDataPath /tmp/wealthy-c2b2-round2-baseline-build -resultBundlePath /tmp/wealthy-c2b2-r3-baseline15.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit" test > /tmp/wealthy-c2b2-r3-baseline15.log 2>&1
```

`baseline17`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0" -derivedDataPath /tmp/wealthy-c2b2-r3-baseline17-build -resultBundlePath /tmp/wealthy-c2b2-r3-baseline17.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit" test > /tmp/wealthy-c2b2-r3-baseline17.log 2>&1
```

`quick15`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9" -derivedDataPath /tmp/wealthy-c2b2-r3-15 -resultBundlePath /tmp/wealthy-c2b2-r3-quick15.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testQuickEntryKeyboardLayoutAndEvidence" "-only-testing:WealthyUITests/Cycle2aUITests/testQuickEntryThreeInteractionsAndUncategorized" "-only-testing:WealthyUITests/Cycle2aUITests/testQuickEntryCategoryDetailsAndInvalidAmount" test > /tmp/wealthy-c2b2-r3-quick15.log 2>&1
```

`quick17`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0" -derivedDataPath /tmp/wealthy-c2b2-r3-17 -resultBundlePath /tmp/wealthy-c2b2-r3-quick17.xcresult -parallel-testing-enabled NO "-only-testing:WealthyUITests/Cycle2aUITests/testQuickEntryKeyboardLayoutAndEvidence" "-only-testing:WealthyUITests/Cycle2aUITests/testQuickEntryThreeInteractionsAndUncategorized" "-only-testing:WealthyUITests/Cycle2aUITests/testQuickEntryCategoryDetailsAndInvalidAmount" test > /tmp/wealthy-c2b2-r3-quick17.log 2>&1
```

`full15`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9" -derivedDataPath /tmp/wealthy-c2b2-r3-15 -resultBundlePath /tmp/wealthy-c2b2-r3-full15.xcresult -parallel-testing-enabled NO test > /tmp/wealthy-c2b2-r3-full15.log 2>&1
```

`full17`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0" -derivedDataPath /tmp/wealthy-c2b2-r3-17 -resultBundlePath /tmp/wealthy-c2b2-r3-full17.xcresult -parallel-testing-enabled NO test > /tmp/wealthy-c2b2-r3-full17.log 2>&1
```

`release-sim`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination "generic/platform=iOS Simulator" -derivedDataPath /tmp/wealthy-c2b2-round2-release-sim build > /tmp/wealthy-c2b2-r3-release-sim.log 2>&1
```

`release-device`:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination generic/platform=iOS -derivedDataPath /tmp/wealthy-c2b2-round2-release-device -allowProvisioningUpdates build > /tmp/wealthy-c2b2-r3-release-device.log 2>&1
```

```sh
git worktree add --detach /tmp/wealthy-c2b2-baseline fc74376
# Baseline-only instrumentation: print Home/tab frames and accessibility tree;
# testHomeAccessibilityAudit calls audit("home") and audit("home", flags: ["--dark"]).
# No product code, assertions or audit filter changed in the temporary worktree.
git worktree remove --force /tmp/wealthy-c2b2-baseline
codesign --verify --deep --strict --verbose=2 /tmp/wealthy-c2b2-round2-release-device/Build/Products/Release-iphoneos/Wealthy.app
xcrun devicectl device install app --device <paired-iPhone-ID> /tmp/wealthy-c2b2-round2-release-device/Build/Products/Release-iphoneos/Wealthy.app
xcrun devicectl device process launch --device <paired-iPhone-ID> com.harrison.Wealthy
```

Device logs: /tmp/wealthy-c2b2-r3-device-install.log and ...-device-launch.log; both subprocesses returned 0. No device identifiers or private container paths are copied into repository evidence.

Metadata inspection:

```sh
python3 - <<'PYMETA'
import json, subprocess
from pathlib import Path
app = Path('/tmp/wealthy-c2b2-round2-release-device/Build/Products/Release-iphoneos/Wealthy.app')
d = json.loads((app/'Metadata.appintents/extract.actionsdata').read_text())
print('Actions:', sorted(d['actions']))
for name, action in sorted(d['actions'].items()):
    print(name, action.get('openAppWhenRun'), [(p.get('name'), p.get('isOptional')) for p in action.get('parameters', [])])
print(d['autoShortcuts'])
for language in ('en', 'ja', 'es', 'ko'):
    print(language, subprocess.check_output(['plutil', '-p', str(app/(language+'.lproj')/'AppShortcuts.strings')], text=True))
PYMETA
```

Screenshots: xcresulttool exports for home15b/home17b and quick15/quick17; sips conversion commands and capture test names are in INDEX.md. Every image was opened with view_image.

## Errors and warnings

Initial sandbox-only simctl failed to connect to CoreSimulator; authorized host execution succeeded. First attachment export failed because xcresulttool could not expand a temporary TestReport; authorized execution exported successfully. These environmental errors are not test passes or app failures. Xcode emitted debugger-version/UIAccessibility loader messages and the test runner's no-AppIntents-framework metadata warning; shipping-app metadata is present. No audit conditions were relaxed.

## Not done / unverified

- Acceptance remains PARTIAL: expanded-safe-line Home contrast failures on both simulators. The decided plain Form remains; no independent layout redesign or new exclusion was attempted.
- Claude decision needed: specify the next scoped correction for the weekday content under the floating tab bar while retaining the restored Form/hittability. Reproduce with testSafeLineAndAIInformationEvidence, --quick-safe-rule, expand safeScheduled, light/dark. See round3-home-audit.txt and the four Home JPEGs.
- Physical VoiceOver, physical performance medians/Home-interactive <=2s, manual Shortcuts execution and iOS 26 runtime compatibility were not measured in this round. Simulator metrics do not establish those results.
- No unrelated fixes, real-data manipulation, dependencies, extensions, targets, capabilities, deployment, commit, push or merge.
