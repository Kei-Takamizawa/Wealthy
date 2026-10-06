# Cycle 2a.1 — PR #5 blocker fixes and physical-device acceptance

- Task ID: WEALTHY-C2A1-FIXES
- Status: BLOCKED — physical-device testing is complete, but the normal-motion child-envelope entry flow remains failing and needs diagnosis before acceptance.
- Branch: `codex/wealthy-c2a-shell`; base `39ae7d531dc44695a5b41ef8ec8b3f10a77bab31`; implementation head before this follow-up `5a21b6d9bdf4c3840008787265dc7f24625fbd8e`.
- Draft PR #5: https://github.com/Kei-Takamizawa/Wealthy/pull/5 (unmerged).
- Full clarified task instructions remain saved in `.ai/CURRENT_TASK.md`.
- Physical device: iPhone 16 Pro Max, iOS 27.2 (24B5089g), UDID `00008140-000C6164027B001C`.

## Outcome by requested item

| Item | Result and evidence | Acceptance |
| --- | --- | --- |
| 1. Result sheet contrast | `testResultAccessibilityAudit` PASS without excluded elements or weakened assertions. It brought `resultLateDetail` into view before audit. Result, Home and Entry accessibility audits all PASS on iOS 27.2. | PASS on this device; other OS accessibility settings not manually toggled. |
| 2. Monthly results | `testMonthResultStatesMatrix` PASS: achieved / over / too-few days in light, dark and AX3 (9 captures). Month screen matrix and result audit also PASS. Current-device comparisons include achieved/over/few screens where the boards are available. | PASS on this device. Dark board images are absent for achieved/over; see compare index. |
| 3. Home envelope | `testHomeAlwaysHousehold` PASS with Child selected on Info: Home still shows household `307,100`, Info shows Child `76,400`, and returning Home shows household again. | PASS. |
| 4. Goals / amounts | `testGoalsUnsetMatrix` PASS for 4 languages × light/dark/AX3 (12 captures). `testLocalizedGroupedAmountFields` PASS for Goals and Entry in en/ja/es/ko. | PASS on this device. |
| 5. Neutral voice copy | `testScreenMatrix` PASS for all 12 screens in 4 languages × 3 appearance/size modes; static validation was previously PASS for catalog parity. | PASS on this device. |
| 6. Persisted onboarding | `testPersistedOnboardingRelaunch` PASS using a UUID-isolated disk store and preferences: Spanish, KRW and 40,000 target remained after process termination and relaunch to Home. | PASS in isolated real disk store. This does not modify the user's regular preferences. |
| 7. Idle stall / CPU | `testChildEnvelopeAndLicenseFlow` (normal-motion, no Reduce Motion flag) FAILS; see reproducible failure below. Activity Monitor measured 186.86 ms CPU over 61.118 s on base `39ae7d5` (0.306%) and 191.95 ms over 61.027 s on this revision (0.315%). Idle wakeups: 54 before, 56 after. One sample each; this difference is too small to treat as a measured regression or improvement. | BLOCKED: GUI test is not passing. CPU was measured, but not a repeated controlled battery study. |
| 8. Launch performance | XCTest launch and signpost results extracted from the physical-device `.xcresult`; detail below and raw available results are in `Verification/Cycle2aEvidence/device-launch-metrics-2026-10-06.json`. Several native launch samples are missing from the result bundle, so the three-size/five-warm-sample requirement is incomplete. | PARTIAL: 10k targets have measurements; missing metrics and 50k interactive result above 2 s require follow-up/Core task. |

## Device UI test results

Ran the complete `Cycle2aUITests` suite on the iPhone 16 Pro Max: 34 test methods, 33 PASS and 1 FAIL, 2,577.094 seconds total. The final `testScreenMatrix` passed (12 screens × 4 locales × 3 visual modes); it took 725.542 seconds. The failing test was `testChildEnvelopeAndLicenseFlow` (118.836 seconds). The unmodified `testResultAccessibilityAudit` passed. No test was skipped or excluded.

The failing flow reproduced again in two focused reruns after correcting its ambiguous selection step. In the current failing run, the editor's accessibility tree after tapping Save remained on Add Entry with amount `3600`, Child envelope selected, Food selected, Takeout (8%) selected, and Save still present. The flow then could not find the Info button after eight scroll attempts (XCTest failure at `Cycle2aUITests.swift:14`). The child tax check and font-license screen were therefore not reached in this correctly child-selected path. A prior diagnostic rerun without selecting Child in the editor reached the Child tax screen but showed ¥0, because that entry remained in the default Household envelope while Tax was scoped to the currently selected Child envelope; that rerun does not validate the intended path.

The focused reruns do not establish why the child-selected Save leaves the editor visible. No product behavior or validation rules were changed to force the test through. Needed next evidence: inspect the actual save error/command and confirm whether this is a UI tap/focus issue or entry validation failure, then rerun the same flow. Do not count the child entry/tax acceptance as passed.

Other notable physical UI PASS results: `testChildAndResultMatrix`, `testChildInfoMatrix`, `testChildSetupMatrix`, `testChildSupportDefaults`, `testEntryAccessibilityAudit`, `testFormMatrix`, `testHomeAccessibilityAudit`, `testHomeInteractiveMetric10000`, `testHomeInteractiveMetric1000`, `testHomeInteractiveMetric50000`, `testHomeWithFiftyThousandPersistedEntries`, `testLaunchMetric10000`, `testLaunchMetric1000`, `testLaunchMetric50000`, `testLocalizedGroupedAmountFields`, `testLocalizedOnboarding`, `testManualTaxAndMetadataSurviveReopening`, `testMonthResultStatesMatrix`, `testNavigationMatrix`, `testNoSpendDayFromEmptyLedger`, `testOnboardingEntryTaxNoSpendTarget`, `testPagerNavigation`, `testPersistedOnboardingRelaunch`, `testResultAccessibilityAudit`, `testResultAndAccessibilityVariants`, and `testScreenMatrix`.

Full UI log and `.xcresult` are outside Git: `/private/tmp/wealthy-c2a1-logs/device-full.log`, `/private/tmp/wealthy-c2a1-device-full.xcresult`. Focused rerun logs/results: `/private/tmp/wealthy-c2a1-logs/child-rerun.log`, `/private/tmp/wealthy-c2a1-logs/child-rerun2.log`, `/private/tmp/wealthy-c2a1-child-rerun.xcresult`, `/private/tmp/wealthy-c2a1-child-rerun2.xcresult`.

## Launch performance evidence and limits

All figures below came from the iPhone 16 Pro Max at iOS 27.2. The test-created ledger fixtures were synthetic. `XCTOSSignpostMetric` medians are over the 3 measurements returned by `xcresulttool` for the applicable Home signposts; they are not full app-launch durations. The `XCTApplicationLaunchMetric` result bundle returned only two usable `AppLaunch` measurements, and only for 10k. Apple documents this metric as first frame; without an extended task it measures first frame only. It did not return values for 1k or 50k despite those test methods reporting PASS.

| Entry count | XCTest native first frame | Home interactive signpost | StoreOpen | Snapshot | QuerySnapshot | HomeRender |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1,000 | no values in result bundle | 0.256 s (n=3) | 0.008 s | 0.038 s | 0.003 s | 0.134 s |
| 10,000 | 0.408 s (n=2; only two values returned) | 0.990 s (n=3) | 0.011 s | 0.375 s | 0.024 s | 0.506 s |
| 50,000 | no values in result bundle | 4.819 s (n=3) | 0.007 s | 2.136 s | 0.142 s | 2.445 s |

At 50,000 entries, the warm persisted-store `testHomeWithFiftyThousandPersistedEntries` also reported launch-to-accessibility-ready values `[5.201, 5.225, 5.314, 5.266, 5.176]` seconds; median 5.225 s. This includes XCTest launch/idle/accessibility overhead, excludes fixture creation, and is not a first-frame metric. The measured Home interactive signpost is above the 2 s criterion at 50k; the user-specified 2 s acceptance threshold was for 10k, where the signpost median is below target. However, no assertion in the test enforces a 2 s threshold.

The first-frame target under 1 s cannot be fully accepted because 1k and 50k metric samples are missing. The available 10k first-frame median is under 1 s. The interactive custom interval starts at session initialization and ends after the Home presentation callback; the separate native responsive launch metric did not yield extractable samples. Do not interpret the custom interval as a complete OS launch-to-responsive time. In particular, cost split shows that 50k is dominated by snapshot (2.136 s) and Home rendering (2.445 s), not store open (0.007 s). The Core persistence boundary remains unchanged and synchronous as instructed.

## CPU / energy observation

Activity Monitor template recordings were 61.118 s on base and 61.027 s on this revision. Process CPU was 186.86 ms and 191.95 ms respectively: 0.306% and 0.315% of one logical core over the recording window. This is a single before/after sample on iOS 27.2 with the app launched on Home using temporary UserDefaults launch arguments. It suggests no full-frame-rate idle loop during those samples, but the child-envelope GUI test still fails, and these short measurements do not prove battery-life equivalence. Raw traces remain outside Git at `/private/tmp/wealthy-c2a1-idle-before.trace` and `/private/tmp/wealthy-c2a1-idle-after2.trace`; extracted Activity Monitor XML is under `/private/tmp/wealthy-c2a1-logs/`.

## Build, tests, warnings

| Check | Result |
| --- | --- |
| `sh Verification/verify_core.sh` | PASS in preceding implementation run: 115 tests passed; existing opt-in benchmark skipped (116 total, 13 suites). |
| `WEALTHY_BENCHMARK=1 ... swift test --package-path WealthyCore -c release` | PASS in preceding implementation run: 116 tests / 13 suites, no skips. |
| `python3 Verification/verify_shell.py` | PASS in preceding implementation run: catalog key/placeholder parity and font subset validation. |
| Historical checks | PASS in preceding run: 8,583 assertions across archived verification scripts. |
| Generic Simulator build / unsigned Release build | PASS in preceding implementation run. Simulator runtime GUI was unavailable. |
| Current signed device `build-for-testing` | PASS after the test adjustment. App and UI runner signed with configured Apple Development identity. |
| Physical-device UI suite | 33 PASS / 1 FAIL, not an acceptance pass. |
| Focused child-flow reruns | 2 FAIL; both stopped in Entry after Save when the correctly selected child path was used. |
| Comparison generator | PASS: `python3 Verification/compare_v4_design.py --manifest /private/tmp/wealthy-c2a1-evidence-export/manifest.json --capture-dir /private/tmp/wealthy-c2a1-evidence-export --capture-label "Cycle 2a.1 device run after 5a21b6d"`; generated 39 compact current-device comparisons. |

Expected benign warning: AppIntents metadata extraction was skipped because the target does not link AppIntents.framework. No other build error was recorded. Xcode emitted transient debugger-version lookup messages while relaunching UI tests; the suite completed.

## Design comparison and screenshots

`Verification/Cycle2aEvidence/compare/INDEX.md` now identifies the current-device captures rather than the old pre-fix baseline. It contains 39 side-by-side JPEGs, 3,896,539 bytes total; each file is under 2 MB and the directory is 3.8 MB. The images use synthetic test data and are within the 2,400 px long-edge cap. Seven board/capture combinations are listed as missing in the index, primarily because no dark exported board exists and the older week-result fixture mappings are absent. Month achieved/over/few and GoalsUnset light/dark comparisons are present where the source boards exist. Full XCTest attachment exports and `.xcresult` bundles were not added to Git.

Raw launch metrics are saved in `Verification/Cycle2aEvidence/device-launch-metrics-2026-10-06.json`.

## Modified files in this follow-up

- `Verification/Cycle2aUI/Cycle2aUITests.swift`: made the selected Child envelope explicit before opening tax after returning to Info; the normal-motion Save-to-Info child flow still fails as documented.
- `Verification/Cycle2aEvidence/compare/INDEX.md` and 39 comparison JPEGs: refreshed from the current physical-device run.
- `Verification/Cycle2aEvidence/device-launch-metrics-2026-10-06.json`: raw `xcresulttool` metrics output.
- `.ai/LAST_REPORT.md`: this physical-device completion report.
- `.ai/CURRENT_TASK.md`: retained unchanged; already contains the complete clarified Cycle 2a.1 instructions.

The pre-existing `.DS_Store` edits, three blank-line deletions in `Wealthy/Wealthy.xcodeproj/project.pbxproj`, and untracked `design/v4/引き渡しシート.pdf` are user changes and were not included. No PR merge, app uninstall, store deletion, or real-user preference reset occurred. The full 251-image inventory, videos, and `.xcresult` bundles remain outside Git.

## Expected / actual and remaining work

- Expected: all 34 device UI methods pass, including a normal-motion child expense saved to the Child envelope and included in the Child tax result; launch metrics available for all 3 sizes; current light/dark comparison captures; before/after idle CPU.
- Actual: 33/34 full-suite methods pass; the child-selected add/save flow remains in Entry after Save and never reaches Info. Focused reruns confirm this. First-frame metrics are extractable only for 10k (n=2); 1k/50k native metrics are missing. Home 50k interactive signpost median is 4.819 s. CPU observations were 0.306% base vs 0.315% current from one 60 s sample per revision. Current comparisons are refreshed (39 pairs).
- Reproduce child issue: on the device run `testChildEnvelopeAndLicenseFlow`; create Child envelope, set its 80,000 monthly target, select Child in Info, go Home, add JPY 3,600 Food/Takeout expense, select Child in Entry, Save. The UI remains on Add Entry and the follow-on Info button lookup fails at test helper line 14.
- Unverified: manual VoiceOver traversal; manual OS Reduce Motion / Reduce Transparency settings; iOS 26 hardware; physical app-store/Release launch; native first-frame values for 1k/50k; reliable native app-responsive launch samples for all sizes; a multi-sample power comparison.
- Claude/product-owner diagnosis is needed for the child-selected Save failure before changing product validation or envelope behavior. No speculative Core, tax, target, persistence, or UI behavior change was made.
- Intentionally not implemented: Cycle 2b/3, persistent stickers, async Core reads, any persistence/undo/backup changes, and out-of-scope screens.

The PR remains Draft and unmerged. Previous Cycle 2a.1 implementation checks and original host benchmark remain documented in Git history; no baseline commit was rewritten.
