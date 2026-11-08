# Cycle 2b.2 Round 5 Report

Task ID: WEALTHY-C2B2-QUICK-ENTRY
Status: PARTIAL

Round 5's scrolled Home audit is implemented in tests only. The final targeted safe-line test fails on both simulators: seven audit assertions on iPhone 15 Pro, one on iPhone 17 Pro. Visible issues are not waived. The decision is to finish this round PARTIAL, as permitted by the owner's follow-up, and complete the remaining verification without changing product code or adding audit exceptions. The complete iPhone 15 Pro suite has finished (73 PASS / 1 FAIL, eight assertions, exit 65). The iPhone 17 Pro suite is in progress; its final observed results must be recorded before the run ends.

Execution: macOS, Xcode 27.2 (27B52), iOS 27.0 simulators. Branch `codex/wealthy-c2b2-quick-entry`; starting HEAD `c1c2ea6a94902d4904962542e0e4410abb115282`. `fc74376` is an ancestor (exit 0). The supplied Round 5 instructions in CURRENT_TASK.md were retained. No staging, commit, push, merge, branch switch, or remote update was performed.

## Changed files

This round changes only:

- `.ai/CURRENT_TASK.md` (owner follow-up appended verbatim)

- `.ai/LAST_REPORT.md`
- `WealthyUITests/QuickEntryUITests.swift`
- `Verification/Cycle2bEvidence/c2b2/INDEX.md`
- `Verification/Cycle2bEvidence/c2b2/round5-home-audit.txt` (new)

Whole-cycle files relative to `fc74376`, including retained checkpoint implementation and historical evidence:

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
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-safe-scheduled-dark.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone15pro-safe-scheduled-light.jpg`
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
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-safe-scheduled-dark.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-safe-scheduled-light.jpg`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-swipe-failure-1.txt`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-swipe-failure-2.txt`
- `Verification/Cycle2bEvidence/c2b2/iphone17pro-swipe-failure-3.txt`
- `Verification/Cycle2bEvidence/c2b2/round3-home-audit.txt`
- `Verification/Cycle2bEvidence/c2b2/round4-home-audit.txt`
- `Verification/Cycle2bEvidence/c2b2/round5-home-audit.txt`
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

The designer-supplied CURRENT_TASK.md was already modified at entry; its contents were retained and the owner follow-up was appended verbatim. Three dirty .DS_Store files and the untracked design PDF were left alone and are not task files. No JPEG or product source was changed this round.

## Requirements

### Round 5 decision and implementation

PASS for the scoped implementation: only Home in `testSafeLineAndAIInformationEvidence` uses `auditScrollableHome`. The full default audit runs at the initial position and at subsequent positions. The existing `auditWithSwiftUIException` method is unchanged; its exact dynamic-Type predicate is retained in the new helper. No other audit call changes. A non-Dynamic-Type issue may be postponed only when its existing element frame intersects the navigation or tab bar. Missing elements fail. Deferred elements are brought fully between the bars and rechecked by a full audit, with label, stable app identifier, issue type, original frame, visible frame and bar frames printed and attached. Visible issues fail. Unresolved deferrals fail after eight positions.

Slow 120-point drags with a hold avoid inertial overshoot. Deferred elements are queried afresh by type, label, stable app identifier and horizontal position because SwiftUI can rebuild the original audit nodes. A successful full-audit visible recheck is retained within the same helper call, so returning under a bar does not create an endless scroll cycle. That prior proof applies only to bar-overlapped issues; visible issues still fail. No new audit-type exception, exclusion, skip or disabled assertion was added. The Home Form, Quick add buttons, safe amount, scheduled page, Core and all production code remain unchanged.

FAIL for acceptance: the final targeted runs do not pass. Labels and frames below identify the failures; no internal AX identifiers are used. Frames are `(x, y, width, height)` in points. All named failure frames are fully between the bars. The audit provides no label or frame for its nil-element issues; these cannot qualify for a frame-based deferral and are not assigned a guessed element.

| Simulator / appearance | Failing label | Issue | Observed frame |
| --- | --- | --- | --- |
| 15 Pro / dark | Quick add | Contrast | (32, 681.67, 141.33, 34.33), then (32, 647.67, 141.33, 34.33) |
| 15 Pro / dark | I spent nothing today | Text clipped | (130, 730.83, 160.67, 20.33) |
| 15 Pro / dark | Add your first entry, or mark a day with no spending. | Contrast | (32, 575.33, 297.67, 42.33) |
| 15 Pro / dark | Not supplied by audit | Potentially inaccessible text | Not supplied by audit |
| 15 Pro / dark (full suite only) | This week | Contrast | (16, 359, 361, 52) |
| 17 Pro / dark | Not supplied by audit | Contrast | Not supplied by audit |

15 Pro navigation frame: (0, 59, 393, 54); tab bar: (0, 769, 393, 83). 17 Pro navigation: (0, 62, 402, 54); tab bar: (0, 791, 402, 83). The 17 Pro xcresult issue description only says `Contrast failed for SwiftUI.AccessibilityNode`. Its attached screenshot was opened, but does not establish a definitive element label/frame. The exact logs and frame-based rechecks are in `Verification/Cycle2bEvidence/c2b2/round5-home-audit.txt`.

Expected: every deferred element has zero issues when fully visible, and no other unhandled issue. Actual: light-mode empty-state elements pass the visible recheck on both simulators; dark-mode full audits report the failures above. Repeated assertions account for seven failures in the single 15 Pro targeted case. No unverified deferral or stale-element query error remains in the final targeted runs. Product correction or further treatment of these issues requires a new designer instruction; none was attempted.

| Final targeted check | iPhone 15 Pro | iPhone 17 Pro |
| --- | --- | --- |
| testSafeLineAndAIInformationEvidence | FAIL, 7 assertions, 188.632 s | FAIL, 1 assertion, 101.890 s |
| testHomeAccessibilityAudit | PASS, 20.112 s | PASS, 19.424 s |
| testHorizontalTabSwipeAndVerticalScroll | PASS, 29.543 s | PASS, 29.401 s |

Targeted safe-line runs on both -> existing Home audits and swipe on both -> full suites sequentially. All xcodebuild test commands use `-parallel-testing-enabled NO`. Home frames remain (0,0,393,852) / (0,0,402,874), matching the retained `fc74376` measurements from Round 3 (baseline not rerun this round).

### Full-suite results

- iPhone 15 Pro: COMPLETED, 74 cases, 73 PASS / 1 FAIL, eight failing assertions, 4,757.725 test seconds; xcodebuild exit 65. Sole failing case: testSafeLineAndAIInformationEvidence (189.088 s). The full audit additionally flags This week as listed above; all other failing labels/frames match the targeted table. Completed xcresult summary was read successfully.
- iPhone 17 Pro: in progress, started only after 15 Pro xcodebuild exited. No completed result claimed yet.

### Whole-cycle behavior and evidence

- E3 / AI information: checkpoint implementation opens the ledger regardless of AI availability, retains DEBUG availability overrides, and presents informational settings/detail. README states iOS 26 or later, Apple Intelligence not required. Final targeted AI-detail assertions/audits have no failures; all corresponding onboarding/Quick add tests pass in the completed 15 Pro full suite; final 17 Pro results remain pending.
- Quick add: checkpoint implementation uses the normal undoable command path, permits Uncategorized, offers category shortcuts and More details, and announces confirmation. Amount/keyboard/three-interaction tests pass in the completed 15 Pro full suite (interaction count 3); final 17 Pro results remain pending. Fresh 15 Pro amount/Save frames: default/light/dark y=186,h=42.67 / y=495,h=34.33; AX3 y=209,h=64 / y=472,h=62. UIKit keyboard top=550. All controls are hittable and fully above it, with typed value 650. Physical VoiceOver listening and a physical three-second timing measurement are unverified.
- App Intents: the UI and both intents use `LedgerSession.shared` (private initializer). `open()` returns when Core already exists, avoiding a second UI/intent store. Quick add and RecordExpenseIntent share `recordExpense`, including late-entry validation, catch-up and the undoable add command. Built metadata lists both intents and all four language phrases. Real Shortcuts UI execution is an optional owner check, not an observed result here.
- Safe line Core: PASS, 123 tests in 14 suites (117 previous plus six added test functions/parameterized cases). Existing safeLine tests cover no target/rules, today/later/next week, paused/ended/income rules, fixed-cost inclusion both ways, other envelope/currency, Sunday/Monday week boundary, negatives and checked overflow. No persistence, data-model, tax or target-rule change this round. Safe-line values and scheduled-page assertions/audits pass within the targeted tests; Home acceptance fails as above.
- Languages: PASS, 213 shipping keys x four languages, zero missing keys; placeholder/font checks pass. Archived localization verification passes 2,420 checks. Retained Japanese wording: クイック記録, 未分類, 今週あと安心して使える額, 今週の予定支出. No wording changes in Round 5. No dependency, extension, capability, entitlement, App Group, target, deployment-target, font or tab-structure change.

### Images and GUI verification

All 18 retained JPEGs were opened individually this round. In each of the six Quick add images (15 Pro/17 Pro, light/dark/AX3), Amount, the typed digits `650`, and Save are visible above the number pad. AX3 lower options can scroll. All Home images show ¥68,000 and the one scheduled expense (¥2,000) link above the tab bar; scheduled-page images show October 8 / Synthetic Thursday / ¥2,000 fully above it. AI settings row and detail are readable. Starting-position Home images retain the lower empty-state overlap; they do not prove an audit pass.

Capture provenance is unchanged: Round 3 for Quick add/AI, Round 4 for Home/scheduled. Fresh reinspection is not fresh capture. Round 5 changes no UI, so no screenshot was replaced. JPEG quality retains approximately 80; fresh `sips`/file-size validation confirms 18 images, maximum long edge 2,000, 71,147–174,170 bytes, all below 1 MB. INDEX.md links the screenshots and new text evidence. Extra issue diagnostics were inspected only under /tmp.

### Builds, metadata and physical device

PASS: final-source Simulator Release build, signed generic iOS Release build, and `codesign --verify --deep --strict`. Built metadata reports:

```text
OpenQuickAddIntent openAppWhenRun=True parameters=[]
RecordExpenseIntent openAppWhenRun=False parameters=[('amount', False), ('category', True)]
```

| Language | Quick add phrase | Record expense phrase |
| --- | --- | --- |
| en | Quick add in ${applicationName} | Record an expense in ${applicationName} |
| ja | ${applicationName}でクイック記録 | ${applicationName}で支出を記録 |
| es | Registro rápido en ${applicationName} | Registrar un gasto en ${applicationName} |
| ko | ${applicationName}에서 빠른 기록 | ${applicationName}에서 지출 기록 |

Physical device NOT_RUN this round (Round 4's no-device instruction retained). Prior-cycle evidence, not a fresh install of this build: Round 3 report at 2440c0a records signed Release install/normal launch on iPhone 16 Pro Max, iOS 27.3, both exit 0, launch only. No owner-ledger interaction this round. Optional owner check: run Record expense once from the Shortcuts app only for an expense the owner intends to record.

## Verification commands

Run from the repository root. Required checks:

```sh
sh Verification/verify_core.sh > /tmp/wealthy-c2b2-r5-core-host.log 2>&1
PYTHONPATH=/Users/harrison/Library/Python/3.14/lib/python/site-packages python3 Verification/verify_shell.py > /tmp/wealthy-c2b2-r5-shell.log 2>&1
sh Verification/verify_localization.sh > /tmp/wealthy-c2b2-r5-localization.log 2>&1
git diff --check
```

All PASS, exit 0. Core first failed inside the restricted sandbox (`sandbox_apply: Operation not permitted`); the authorized host rerun above passed. Shell and localization passed without changing checks.

Final targeted commands (safe15d/safe17d exit 65; home15d/home17d exit 0):

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r5-15 -resultBundlePath /tmp/wealthy-c2b2-r5-safe15d.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testSafeLineAndAIInformationEvidence test > /tmp/wealthy-c2b2-r5-safe15d.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r5-15 -resultBundlePath /tmp/wealthy-c2b2-r5-home15d.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll test > /tmp/wealthy-c2b2-r5-home15d.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b2-r5-17 -resultBundlePath /tmp/wealthy-c2b2-r5-safe17d.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testSafeLineAndAIInformationEvidence test > /tmp/wealthy-c2b2-r5-safe17d.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b2-r5-17 -resultBundlePath /tmp/wealthy-c2b2-r5-home17d.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll test > /tmp/wealthy-c2b2-r5-home17d.log 2>&1
```

Final complete-suite commands (sequential detached runner): full15e exit 65, completed; full17e in progress. Commands run sequentially with no overlap:

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r5-15 -resultBundlePath /tmp/wealthy-c2b2-r5-full15e.xcresult -parallel-testing-enabled NO test > /tmp/wealthy-c2b2-r5-full15e.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b2-r5-17 -resultBundlePath /tmp/wealthy-c2b2-r5-full17e.xcresult -parallel-testing-enabled NO test > /tmp/wealthy-c2b2-r5-full17e.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b2-r5-release-sim build > /tmp/wealthy-c2b2-r5-release-sim-final-d.log 2>&1
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination generic/platform=iOS -derivedDataPath /tmp/wealthy-c2b2-r5-release-device -allowProvisioningUpdates build > /tmp/wealthy-c2b2-r5-release-device-final-d.log 2>&1
codesign --verify --deep --strict --verbose=2 /tmp/wealthy-c2b2-r5-release-device/Build/Products/Release-iphoneos/Wealthy.app
```

All PASS, exit 0. Build logs end BUILD SUCCEEDED; codesign reports valid on disk and satisfies its Designated Requirement. Metadata inspection command (exit 0); action/phrase output is transcribed above:

```sh
python3 - <<'PYMETA'
import json, subprocess
from pathlib import Path
app=Path('/tmp/wealthy-c2b2-r5-release-device/Build/Products/Release-iphoneos/Wealthy.app')
d=json.loads((app/'Metadata.appintents/extract.actionsdata').read_text())
for name,action in sorted(d['actions'].items()):
 print(name,'openAppWhenRun=',action.get('openAppWhenRun'),'parameters=',[(p.get('name'),p.get('isOptional')) for p in action.get('parameters',[])])
print('autoShortcuts:',d['autoShortcuts'])
for lang in ('en','ja','es','ko'):
 print(lang,subprocess.check_output(['plutil','-p',str(app/(lang+'.lproj')/'AppShortcuts.strings')],text=True))
PYMETA
```


## Errors and warnings

- Targeted Home audit failures above are acceptance failures. No product correction or broader audit exception was attempted.
- Preliminary helper trials exposed inertial overshoot, re-deferral cycles and transient audit-node references. These test implementation issues were corrected before final targeted runs. safe15 was interrupted; safe15b/c and safe17 were superseded. Their results are not final acceptance evidence.
- A preliminary full15 run was interrupted after 19 passing cases to correct the helper. A later full15d process disappeared with the log last updated at 16:28:32; no exit code or completed xcresult was available, and full17d never started. Cause is unverified. An earlier commentary incorrectly called that process ongoing; process/log checks corrected the claim. Neither interrupted run counts as a completed full suite. The replacement full15e/full17e runner is detached and records start, completion and exit status separately.
- Simulator and xcresulttool access required authorized host execution after sandbox access errors. No unsafe workaround was used.
- The completed 15 Pro xcresult includes a runtime warning that the first iteration did not measure the first-frame-presentation-responsive launch metric. It is not treated as physical performance evidence.
- Xcode emits debugger-version lookup and duplicate UIAccessibility loader warnings. No cause or functional effect is inferred from those warnings alone.

## Not done / unverified

- Status remains PARTIAL: final targeted Home audits fail as listed. Full15e has completed as above; full17e completion is pending and must be recorded before ending this run. No merge is authorized by this report.
- No additional product/layout changes, new audit exclusions or unrelated fixes. A designer decision is needed for the visible audit failures and the issues with no supplied element.
- Physical install/launch of this build, physical VoiceOver listening, actual owner Shortcuts execution, physical Home-interactive <=2 s, physical three-second entry timing, and iOS 26 runtime compatibility are unverified here. Simulator timing does not establish physical-device acceptance.
- No real personal/financial fixture data, ReceiptExample access, owner-ledger write, uninstall, deletion of user data, production deployment, added dependency/capability or Git mutation.
