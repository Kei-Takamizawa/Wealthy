# Cycle 2a.1 — PR #5 blocker fixes

- Task ID: WEALTHY-C2A1-FIXES
- Status: BLOCKED — code and host verification completed; required physical-device verification is blocked by the locked/unavailable iPhone.
- Branch: `codex/wealthy-c2a-shell`; base: `39ae7d531dc44695a5b41ef8ec8b3f10a77bab31`.
- Draft PR: https://github.com/Kei-Takamizawa/Wealthy/pull/5
- The revised task, including the clarified synchronous Core launch scope, is saved without abridgment in `CURRENT_TASK.md`.

## Per-item status

| Item | Implementation / evidence | Acceptance status |
| --- | --- | --- |
| 1. Result contrast | Date and late-entry explanation are placed in an opaque Plate with explicit ink/ink2 colors. The audit scrolls to `resultLateDetail` and asserts it is visible before running the same contrast/clipping/hit-region/description audit. No exclusion or assertion weakening. | NOT VERIFIED on device; no claim that the previous FAIL is fixed. Modifier bisection is required if the updated audit still fails. |
| 2. Monthly results | Distinct achieved/over/few/unset headlines and captions; Core logging threshold (22 of 31, 21 of 29, etc.), Core monthly festival count capped at four, areas shown in every state, and the achieved fireworks-decoration line from the board. Weekly captions are absent from monthly results. Cross-month weeks are classified using Core period day count, not month boundaries. | Core queries PASS; new three-state light/dark/AX3 GUI captures NOT RUN. `testMonthResultStatesMatrix` is ready. |
| 3. Household Home | Separate household summary feeds Home; Home targets and no-spend commands explicitly use household ID. Info selection remains independent. New entries from Home default to household. Voice background also uses household summary. | Compiles; `testHomeAlwaysHousehold` NOT RUN. |
| 4. Goals / input | Dedicated unset-month card with copy-previous/month-history/manual-entry controls, based on the local GoalsUnset board. Goals/Edit amount fields display grouped localized currency when idle and accept plain numeric input while focused. Core remains the parser/formatter. | Compiles; updated GoalsUnset matrix and four-language `testLocalizedGroupedAmountFields` NOT RUN. |
| 5. User copy | Removed cycle wording from voice placeholder in all four languages. Neutral coming-soon/typed-entry wording. Catalog now has 140 keys x four languages; no cycle/task wording found in catalog values. | Static catalog/font validation PASS; refreshed voice captures NOT RUN. |
| 6. Disk onboarding | `testPersistedOnboardingRelaunch` chooses Spanish/KRW/40,000, completes onboarding, terminates/relaunches, checks Home, target, language and currency. Real LedgerStore in a UUID-specific temporary directory, with UUID-specific persisted preferences. The ordinary fresh-store test now also uses this isolated real disk path. No real app preferences are cleared. | Compiles; physical execution NOT RUN. |
| 7. Idle stall / energy | Source inspection found no TimelineView, repeatForever, ambient timer or repeating island redraw task. Island Canvas draws only on SwiftUI invalidation. Existing button/page springs are finite. The display boundary added for launch is one-shot and invalidates after two callbacks. Normal-motion child workflow no longer uses the Reduce Motion test flag. | BLOCKED: old stall not reproduced; cause unknown. Before/after 60-second CPU recordings could not start. No CPU or battery number is claimed. |
| 8. Launch | Minimal localized loading state, VoiceOver announcement, task yield and two display callbacks before entering unchanged synchronous Core open. Foreground handler no longer eagerly opens the store before that loading frame. Native launch tests at 1k/10k/50k use five warm measured iterations each. Separate extended-launch tests hold the native responsive launch metric through Home presentation. StoreOpen/Snapshot/QuerySnapshot/HomeRender signposts provide a cost split. | Compiles; all device medians and target outcomes UNKNOWN. Core stays MainActor with synchronous reads as instructed. |

## Changes and constraints

App files: `HomeInfo.swift`, `GoalsTaxSettings.swift`, `EntryEditor.swift`, `LedgerSession.swift`, `LedgerRoot.swift`, `WealthyApp.swift`, `Localizable.xcstrings`; new `MoneyInputField.swift` and `DisplayFrameWaiter.swift`.

Core: `Targets.swift` extracts the existing integer logging threshold into a query; `IslandQueries.swift` adds monthly earned-festival query; `IslandTests.swift` adds two deterministic tests. Persistence, undo, backup format and tax/target semantics are unchanged. No third-party dependency was added; MetricKit is an Apple system framework.

Verification: updated `Cycle2aUI/Cycle2aUITests.swift` (34 test methods), new `compare_v4_design.py`, positional-argument-aware catalog validation, compact comparisons under `Cycle2aEvidence/compare/`. No tests were excluded or newly skipped. The previous explicit XCTest availability skip now fails if the real AI gate prevents execution, preserving the launch gate rather than bypassing it.

No legacy user files/images were opened or deleted. No app uninstall, merge, force push or credential workaround occurred. Pre-existing `.DS_Store` changes, three project-file blank-line deletions and the untracked reference PDF remain outside the task commit.

## Build / test results

| Command / check | Result |
| --- | --- |
| `sh Verification/verify_core.sh` | PASS: 115 tests passed, existing opt-in benchmark skipped (116 total, 13 suites). New threshold/festival queries included. |
| `WEALTHY_BENCHMARK=1 ... swift test --package-path WealthyCore -c release` | PASS: all 116 tests / 13 suites, 815.635 seconds, no skips; includes the opt-in disk benchmark. |
| `python3 Verification/verify_shell.py` | PASS: 140 keys x four languages, placeholder parity, legacy-target isolation, four font subset hashes and Hangul/Spanish coverage. |
| Historical checks | PASS: OCR 91, backup 114, localization 6,634, payments 96, migration fixture 11, currency 40, policies 73, money tips 1,524; total 8,583 assertions. Archived components only. |
| Generic Simulator build | PASS. Runtime launch not performed; no installed Simulator runtime. |
| Unsigned Release build | PASS. |
| Generic signed build-for-testing | PASS: app and UI runner compile/sign with existing app identity/team. No physical install/launch success is claimed for this revision. |
| Physical-device UI tests | NOT RUN for this revision: device locked/unavailable. Previous Cycle 2a results are not reused as current PASS. |

Intermediate compile errors in GoalsUnset (unknown color token and optional TimeZone) were corrected. A new festival fixture initially removed one logged day, which correctly left a 6/7 eligible week; corrected the fixture to remove four days, then reran the full Core suite successfully. Expected AppIntents extraction warning remains because that feature is out of scope.

## Physical-device blocker: expected / actual / reproduction

Expected: launch the app on the paired iPhone, record 60 seconds of idle CPU, execute audit/normal-motion/persisted-onboarding tests, then capture refreshed screens and launch metrics.

Actual: CoreDevice launch returned error 10002 / FBSOpenApplicationErrorDomain 7: “Unable to launch ... because the device was not, or could not be, unlocked.” The device also intermittently reported unavailable or connection reset. Activity Monitor recordings returned “Cannot find process matching name: Wealthy”; no CPU trace was produced. A user-input request to unlock the iPhone was sent; no unlock confirmation was received during this cycle.

Reproduction: `xcrun devicectl device process launch --device 00008140-000C6164027B001C --terminate-existing com.harrison.Wealthy -- --cycle2a-test --cycle2a-seed --screen home`. Logs: `baseline-launch3.log`, `idle-before2.log`. A build targeting this exact device also failed destination discovery while disconnected; the generic signed build succeeded independently.

Device context from prior execution: iPhone 16 Pro Max / iOS 27.2. Manual VoiceOver traversal, actual OS Reduce Motion/Transparency settings and iOS 26 hardware remain unverified. No new physical GUI operation or screenshot is claimed.

## Performance measurements

| Entries | First-frame median, five warm launches | Home interactive median, five warm launches | Target outcome |
| ---: | --- | --- | --- |
| 1,000 | NOT MEASURED | NOT MEASURED | UNKNOWN |
| 10,000 | NOT MEASURED | NOT MEASURED | UNKNOWN |
| 50,000 | NOT MEASURED | NOT MEASURED | UNKNOWN |

Idle Home CPU over 60 seconds: before NOT MEASURED; after NOT MEASURED. No battery estimate or zero-CPU inference is made from static code inspection.

`testLaunchMetric1000/10000/50000` use XCTest's native first-frame launch metric, without an extended launch task. `testHomeInteractiveMetric1000/10000/50000` register an extended task before scene activation and finish it after Home's display boundary; they also assert that the visible Home Info control is hittable. Fixture creation precedes measured warm launches. The custom HomeInteractive interval starts at session initialization, excluding earlier process/dyld startup; the native extended responsive launch metric supplies the full launch boundary. HomeRender is the post-query Home presentation interval, not the loading first-frame metric. Tracking failures show an error and fail the hittability assertion rather than silently accepting incomplete timing.

Reference metric definitions: [Apple launch metric](https://developer.apple.com/documentation/xctest/xctapplicationlaunchmetric/init(waituntilresponsive:)), [extended launch measurement](https://developer.apple.com/documentation/metrickit/mxmetricmanager/extendlaunchmeasurement(fortaskid:)). The paired metric APIs remain compatible with iOS 26; their newer replacement is not required for this cycle.

## Design comparison evidence

Local exported v4 PNG boards already exist in `design/v4/`; they were not invented or duplicated. Several are multi-screen canvases, so the script records explicit crop boxes. Available comparisons: 37 JPEGs, 3,597,495 bytes total, maximum long edge 1,652 px, largest individual file 133,423 bytes; JPEG quality 80. No full screenshot inventory, video or xcresult bundle was added.

IMPORTANT: the device sides are the PR #5 base `39ae7d5` captures, not this revision's fixed screens. This is labeled in [compare/INDEX.md](../Verification/Cycle2aEvidence/compare/INDEX.md). They support design review but do not prove the new fixes. Nine combinations remain missing, including new monthly achieved/over captures and unavailable dark board variants. Source captures remain outside Git under `/private/tmp/wealthy-v4-compare-source`.

Rebuild with `python3 Verification/compare_v4_design.py --manifest /path/to/manifest.json --capture-dir /path/to/export --capture-label "revision being compared"`. Newly required monthly three-state and GoalsUnset screenshots must replace these baseline comparisons after device testing.

## Reproducible remaining verification

1. Unlock/reconnect the eligible iPhone; retain legacy data and do not uninstall.
2. Generate a disposable UI project using `python3 Verification/prepare_cycle2a_tests.py /private/tmp/wealthy-c2a1-ui-project-next`.
3. Run the Wealthy scheme on UDID `00008140-000C6164027B001C`, with a new DerivedData/result-bundle path. Execute all 34 UI methods; start with result audit and the normal-motion child workflow. Result audit must include the visible explanation; if FAIL, bisect modifiers without excluding any issue.
4. Record idle CPU before/after for 60 seconds with Activity Monitor, then extract actual samples. Baseline build must be installed intentionally from the base revision in a separate host checkout; no real-store reset.
5. Extract native metrics with `xcrun xcresulttool get test-results metrics --path /path/to/result.xcresult`; report five raw values and medians for each size/boundary, plus signpost cost split if 10k misses two seconds.
6. Export synthetic screenshots and refresh comparisons; include monthly achieved/over/few in light/dark/AX3 and the distinct GoalsUnset.

## Open issues / intentionally omitted work

- Required device acceptance remains BLOCKED, including confirmation of the contrast fix and normal-motion stall resolution. The stall's cause is not established; no speculative animation redesign was made.
- Read-only review identified a potential mid-month fresh-onboarding edge case: retroactive monthly target versions could make an unlogged prior full week eligible for automatic result presentation. This was not physically reproduced and no new result-presentation policy was introduced; Claude review may be needed if it is observed.
- Cycle 2b/3 features, persistence-boundary redesign, sticker album persistence and layout redesign remain out of scope. This is not a COMPLETED acceptance claim.

Logs/build products are outside Git under `/private/tmp/wealthy-c2a1-logs/` and `/private/tmp/wealthy-c2a1-*`. The final commit/push identity and verified remote result are reported in the final chat response. PR remains draft.

## Final host benchmark evidence

The Release run collected 20 measured values per operation/size after warm-up. Host builds were running during parts of this run; these values are not a controlled before/after regression comparison and are not device launch measurements.

| Operation | 10k median (ms) | 50k median (ms) |
| --- | ---: | ---: |
| addEntry | 31.014 | 260.429 |
| updateEntry | 30.128 | 283.969 |
| deleteEntry | 28.358 | 248.861 |
| undo | 46.523 | 304.763 |
| previewAddEntry | 21.190 | 114.888 |
| postRecurring | 34.249 | 129.678 |
| openStore | 639.095 | 2896.471 |
| weekTargetStatus | 0.093 | 0.388 |
| monthTargetStatus | 0.729 | 3.633 |
| taxSummary | 0.052 | 0.276 |

10k/20-undo-step host physical footprint growth: 22,413,312 bytes. Raw results: [benchmark-cycle2a1.json](../Verification/Cycle2aEvidence/benchmark-cycle2a1.json). Final logs: `core-release-all.log`, `release-final-current.log`, `simulator-final-current.log`, `signed-final-current.log`. All final host checks completed before commit.
