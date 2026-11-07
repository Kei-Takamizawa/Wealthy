# Cycle 2b.2 Round 2 Report

Task ID: WEALTHY-C2B2-QUICK-ENTRY
Status: PARTIAL

Round 2 is finished with the Home root hit-testing regression unresolved. No experimental app layout change is retained. The original assertions and accessibility-audit filter are unchanged. Do not merge on this report.

Branch: `codex/wealthy-c2b2-quick-entry`; starting HEAD: `bfff4bb93001f7c31391eaa204b4dcd3535ee702`. PR #10 merge `fc74376` is an ancestor (exit 0). Round 2 explicitly pins its comparison to that commit; local `origin/main` now points to `69d6eea9b4fd93b904d0db5bb53780219ec10ed2`. No fetch, branch switch, staging, commit, push or merge was performed. Execution host: macOS, Xcode 27.2 (27B52); both requested simulators run iOS 27.0. No second platform implementation was started.

## Changed files

Round 2 files (the 14 JPEGs were already untracked at start, are preserved, and are included in this delivery):

- `.ai/LAST_REPORT.md`
- `WealthyUITests/WealthyUITests.swift`
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

`WealthyUITests.swift` adds failure-only text and screenshot attachments to `assertRootVisible`; it does not change any assertion. The six text files preserve the unfixed checkpoint's complete synthetic-data accessibility trees. `HomeInfo.swift` was temporarily changed for three diagnostic trials, then restored byte-for-byte from HEAD; it has no final diff.

The implementation already committed at the checkpoint is unchanged in this round: README.md; AppShortcuts.xcstrings; CalendarAnalysis.swift; EntryEditor.swift; ExpenseIntents.swift; GoalsTaxSettings.swift; HomeInfo.swift; LedgerRoot.swift; LedgerSession.swift; Localizable.xcstrings; QuickAdd.swift; RecurringSession.swift; WealthyApp.swift; Core SafeLine.swift and SafeLineTests.swift; Cycle2bUITests.swift; QuickEntryUITests.swift. App files are under `Wealthy/Wealthy/`, tests under their respective test directories.

Pre-existing `.ai/CURRENT_TASK.md`, three `.DS_Store` changes, and the untracked design PDF were preserved and not included as implementation edits. ReceiptExample was not read.

## Requirements

### Round 2 item 1: diagnose and fix Home hit testing — FAIL / unresolved

Expected: Home is selected, `homePage` exists and is hittable initially and after each return swipe. Actual on the checkpoint: existence and selection pass, but all three Home hittability assertions fail on both devices.

| Source / experiment | Device | Results |
| --- | --- | --- |
| Checkpoint + diagnostic attachments | 15 Pro | 1 test failed, 3 assertions, 38.208 s; exit 65 |
| Checkpoint + diagnostic attachments | 17 Pro | 1 test failed, 3 assertions, 35.679 s; exit 65 |
| Unmodified `fc74376`, temporary worktree | 15 Pro | PASS, 1 test, 0 failures, 30.835 s; exit 0 |
| Trial 1: remove only `.clipped()` | 15 Pro | FAIL, same 3 assertions, 32.046 s; exit 65 |
| Trial 2: replace GeometryReader/manual frame/clip with native VStack, retaining safeAreaInset footer | 17 Pro | Swipe PASS, 29.481 s; Home audit FAIL (9 contrast assertions), 64.760 s; exit 65 |
| Trial 2, plus keyboard test | 15 Pro | Swipe PASS 32.137 s; keyboard PASS 59.007 s; Home audit FAIL (9 contrast assertions), 58.808 s; exit 65 |
| Trial 3: native VStack, clipped Form and sibling footer button | 17 Pro | Swipe FAIL (3 assertions), 34.705 s; keyboard PASS 48.948 s; Home/AI audits PASS 53.051 s; exit 65 |

This is a cycle regression, not a pre-existing baseline failure. The three source trials were all reverted. No test was weakened or excluded. The debugging workflow stops further speculative fixes after three unsuccessful candidates; a reviewed next approach is needed.

Failure-time geometry (points):

| Device | homePage | Quick add | Tab bar | Navigation bar |
| --- | --- | --- | --- | --- |
| 15 Pro | x0 y0 w393 h686 | x16 y620 w361 h58 | x0 y769 w393 h83 | x0 y59 w393 h54 |
| 17 Pro | x0 y0 w402 h708 | x16 y642 w370 h58 | x0 y791 w402 h83 | x0 y62 w402 h54 |

The screenshots show Home content, and the tree contains no sheet, intentDialog or safeScheduled disclosure in this test. Quick add overlaps the Form's lower bounds, while the navigation bar overlaps its top bounds. These observations do not prove which UIView receives the hit. The regression also occurs at the initial Home assertion, before any swipe or Quick add presentation.

Trial 2 restores CollectionView hittability but allows weekday text behind the floating tab bar: for example, the 17 Pro audit reports T/W/T/F/S at y806, height18, inside the tab bar's y791–874 bounds. Trial 3 bounds the Form and clears those audits but loses root hittability again. The evidence narrows the problem to the bounded Home scroll-container/layout and hit-testing interaction; it does not establish that the assertion is wrong. No assertion or accessibility-identifier relocation is proposed as a proven fix.

Full `app.debugDescription` and `homePage.frame` at all three failures per simulator are in the six evidence text files and in the diagnostic xcresult attachments. Failure screenshots are retained in those xcresults. The temporary worktree `/tmp/wealthy-c2b2-baseline` was removed with `git worktree remove` after the comparison; no commits were made from it.

### Round 2 item 2: screenshot evidence — PASS

[INDEX.md](../Verification/Cycle2bEvidence/c2b2/INDEX.md) indexes all 14 JPEGs. Every image was opened and visually inspected in this round. All six Quick add images (15 Pro/17 Pro, light/dark/AX3) visibly show the Amount field, typed `650`, and Save above the number pad. The expanded Home images show ¥70,000 remaining, ¥2,000 scheduled, and ¥68,000 safe to spend, plus the date/title/amount of Synthetic Thursday. AI row/detail images show unavailable state and the explanation that all budgeting features work without AI.

Measured dimensions: 15 Pro images 921×2000; 17 Pro images 920×2000. File sizes range from 103,546 to 171,918 bytes; all are below 1 MB. They were present at start and not recaptured because the final app source is restored to the captured checkpoint. They are not screenshots of an accepted fix. AX3 may require scrolling for lower category buttons and More details; the required Amount/digits/Save remain visible.

### Round 2 item 3: full suites and required checks — PARTIAL

Fresh Core verification: PASS, 123 tests in 14 suites (117 existing plus six new test functions, including parameterized cases). SafeLine tests cover no target/rules, today/later/next week, paused/ended/income, fixed-cost include false/true, other envelope/currency, both week starts at a boundary, negative safe amount, and checked overflow. No Core source was changed in Round 2.

Fresh shell verification: PASS, 212 keys × four languages, placeholder parity, font checks. Fresh localization verification: PASS, 212 shipping keys × four languages, zero missing keys, plus 2,420 archived checks. Final `git diff --check`: PASS.

Fresh final-source Simulator Release build: PASS. Fresh final-source signed generic iOS Release build: PASS. Signature verification: PASS. No new targets, dependencies, extensions, App Groups, capabilities or entitlements were added.

Full suites after a successful targeted fix: NOT_RUN, because Round 2 explicitly requires item 1 to pass first and it remains unresolved. The preceding run's complete full-suite logs were inspected in this round: each has 74 tests, 73 passing and one failing (`testHorizontalTabSwipeAndVerticalScroll`, three assertions); 15 Pro 4,569.915 s, 17 Pro 4,543.491 s. These are failures, not acceptance passes. The previous 17 Pro run has finished; no full suite remains in progress.

### Original requirements 1–5: checkpoint implementation retained

The preceding full-suite logs on both simulators record PASS for `testQuickEntryWithoutAIFromOnboarding`, `testAvailableAIInformation`, `testQuickEntryThreeInteractionsAndUncategorized`, `testQuickEntryCategoryDetailsAndInvalidAmount`, `testQuickCategoryRankingAndPresets`, `testRecordExpenseIntentAndRelaunch`, `testIntentWithoutTargetAndInvalidAmount`, `testIntentIncludesTodaysRecurringExpense`, `testOpenQuickAddIntentAndPendingNotice`, `testLocalizedQuickEntryAndSafeLine`, `testQuickEntryKeyboardLayoutAndEvidence`, and `testSafeLineAndAIInformationEvidence`. These are explicitly preceding-run results, not newly rerun final-source UI acceptance in Round 2. Fresh diagnostic trial UI results are in the table above.

Single-store implementation, confirmed by source inspection: `LedgerSession.shared` has a private initializer and caches the process's Core/store. UI, entity queries and intents use this owner. Quick add and RecordExpenseIntent both call `recordExpense`; intent recording also runs recurring catch-up before reporting remaining allowance. No persistence/model/target/tax behavior was changed this round.

Japanese wording retained: クイック記録 (Quick add), 未分類 (Uncategorized), 今週あと安心して使える額 (Safe to spend). No new strings were added this round.

Built metadata was inspected on the final signed app:

- `Metadata.appintents/extract.actionsdata`: actions `OpenQuickAddIntent`, `RecordExpenseIntent`.
- OpenQuickAddIntent: openAppWhenRun=true; no parameters.
- RecordExpenseIntent: openAppWhenRun=false; amount required, category optional.
- Auto-shortcut phrase keys: `Quick add in ${applicationName}`, `Record an expense in ${applicationName}`.
- Compiled `AppShortcuts.strings` exists in en, ja, es, ko, with phrases below (every phrase includes `${applicationName}`).

| Language | Quick add | Record expense |
| --- | --- | --- |
| en | Quick add in ${applicationName} | Record an expense in ${applicationName} |
| ja | ${applicationName}でクイック記録 | ${applicationName}で支出を記録 |
| es | Registro rápido en ${applicationName} | Registrar un gasto en ${applicationName} |
| ko | ${applicationName}에서 빠른 기록 | ${applicationName}에서 지출 기록 |

### Round 2 item 4: physical device — PARTIAL / owner action

Final-source signed Release installation on the paired iPhone 16 Pro Max: PASS (devicectl exit 0). No real expense was recorded, no data was deleted, and no app was uninstalled. Normal launch: first attempt failed with CoreDevice error 4000 / network timeout; one retry reached the device and was denied with `FBSOpenApplicationErrorDomain error 7`, `BSErrorCodeDescription = Locked`. Launch remains NOT_VERIFIED pending owner unlock; the lock is an owner action, not an app failure. No further retries were made.

Optional owner check after unlocking: run Record expense once from the Shortcuts app, only for an expense the owner intends to add to the real ledger.

## Verification commands

All xcodebuild commands used `-parallel-testing-enabled NO` for tests. Logs and result bundles remain under `/tmp`.

```sh
# Diagnostic reproductions (both exit 65)
for pair in '15 870430A8-E557-4CED-8A8E-079801D804B9' '17 DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0'; do
  set -- $pair
  xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination "platform=iOS Simulator,id=$2" -derivedDataPath /tmp/wealthy-c2b2-round2-$1 -resultBundlePath /tmp/wealthy-c2b2-round2-diagnose$1.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll test > /tmp/wealthy-c2b2-round2-diagnose$1.log 2>&1
done

# Baseline: exit 0, worktree subsequently removed
 git worktree add --detach /tmp/wealthy-c2b2-baseline fc74376
# Executed with cwd=/tmp/wealthy-c2b2-baseline:
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-round2-baseline-build -resultBundlePath /tmp/wealthy-c2b2-round2-baseline.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll test > /tmp/wealthy-c2b2-round2-baseline.log 2>&1
# Executed from the main work folder:
git worktree remove /tmp/wealthy-c2b2-baseline

sh Verification/verify_core.sh > /tmp/wealthy-c2b2-round2-core.log 2>&1
PYTHONPATH=/Users/harrison/Library/Python/3.14/lib/python/site-packages python3 Verification/verify_shell.py > /tmp/wealthy-c2b2-round2-shell.log 2>&1
sh Verification/verify_localization.sh > /tmp/wealthy-c2b2-round2-localization.log 2>&1
git diff --check

xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b2-round2-release-sim build > /tmp/wealthy-c2b2-round2-final-release-sim.log 2>&1
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS' -derivedDataPath /tmp/wealthy-c2b2-round2-release-device -allowProvisioningUpdates build > /tmp/wealthy-c2b2-round2-final-release-device.log 2>&1
codesign --verify --deep --strict --verbose=2 /tmp/wealthy-c2b2-round2-release-device/Build/Products/Release-iphoneos/Wealthy.app
sips -g pixelWidth -g pixelHeight Verification/Cycle2bEvidence/c2b2/*.jpg
```

Trial commands use the same test project/scheme and destination above:

- Trial 1: derivedDataPath `/tmp/wealthy-c2b2-round2-15`; resultBundlePath `/tmp/wealthy-c2b2-round2-unclip15.xcresult`; `-only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll`; log `/tmp/wealthy-c2b2-round2-unclip15.log`; exit 65.
- Trial 2, 17 Pro: derivedDataPath `/tmp/wealthy-c2b2-round2-17`; resultBundlePath `/tmp/wealthy-c2b2-round2-native17.xcresult`; only-testing swipe and `testSafeLineAndAIInformationEvidence`; log `/tmp/wealthy-c2b2-round2-native17.log`; exit 65.
- Trial 2, 15 Pro: derivedDataPath `/tmp/wealthy-c2b2-round2-15`; resultBundlePath `/tmp/wealthy-c2b2-round2-target15.xcresult`; only-testing swipe, `testQuickEntryKeyboardLayoutAndEvidence`, `testSafeLineAndAIInformationEvidence`; log `/tmp/wealthy-c2b2-round2-target15.log`; exit 65.
- Trial 3, 17 Pro: derivedDataPath `/tmp/wealthy-c2b2-round2-17`; resultBundlePath `/tmp/wealthy-c2b2-round2-target17.xcresult`; same three only-testing selectors as the previous line; log `/tmp/wealthy-c2b2-round2-target17.log`; exit 65.

Attachment export (exit 0; repeated for 17):

```sh
xcrun xcresulttool export attachments --path /tmp/wealthy-c2b2-round2-diagnose15.xcresult --output-path /tmp/wealthy-c2b2-round2-diagnose15-all
```

`--only-failures` exported no matching attachments because manually added diagnostic attachments are not marked associatedWithFailure; the unrestricted export above recovered all text and screenshots.

Final metadata inspection (observed output summarized above):

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

Physical commands (device identifier redacted from this publishable report; the paired iPhone was selected, not the iPad):

```sh
xcrun devicectl device install app --device <paired-iPhone-ID> /tmp/wealthy-c2b2-round2-release-device/Build/Products/Release-iphoneos/Wealthy.app
xcrun devicectl device process launch --device <paired-iPhone-ID> com.harrison.Wealthy
```

Install log `/tmp/wealthy-c2b2-round2-final-device-install.log` (exit 0); launch logs `/tmp/wealthy-c2b2-round2-final-device-launch.log` and `...-launch-retry.log` (both exit 1, timeout then Locked). No device identifiers or installation container paths are copied into repository evidence.

## Errors and warnings

The restricted environment initially refused CoreSimulator access and SwiftPM's nested sandbox (`sandbox_apply: Operation not permitted`). Their authorized runs succeeded with normal host permissions; the Core manifest error was environmental, not a test failure. Worktree creation was initially rejected by automatic approval because of the general outside-repository rule; the explicit Round 2 instruction authorizing that exact `/tmp` worktree was presented, and the action was then approved. No rejection was bypassed.

Xcode logs contain simulator duplicate UIAccessibilityLoaderWebShared warnings and debugger-version lookup messages. The test runner's metadata extraction warns that it has no AppIntents.framework dependency; the shipping app's intent metadata is present and was inspected. No audit exclusions were added.

## Not done / unverified

- Remaining acceptance failure: Home root hittability regression on both simulators. No validated app fix remains in the working tree.
- New full UI runs intentionally not started: the explicitly required targeted-success prerequisite was not met. Prior full runs both failed; neither is promoted to PASS.
- Physical launch requires the owner to unlock the phone. Physical VoiceOver, performance medians, and manual Shortcuts execution were not measured.
- No claim of iOS 26 simulator execution: available/requested simulators ran iOS 27.0.
- No real-data device testing, new features, dependencies, capabilities, extensions, targets, Git commit/push/merge, or unrelated-file cleanup.

Claude decision needed: review the six failure trees and the passing native-layout / failing bounded-layout experiments, then specify the next focused approach to preserving the Home scroll boundary and hit testing together. The evidence does not justify weakening the assertion. If a different accessibility root is chosen, validate that choice against actual interaction and document it before changing coverage.
