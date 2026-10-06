# Cycle 2a — WealthyCore app shell

- Task ID: WEALTHY-C2A-SHELL
- Status: BLOCKED (result accessibility audit fails; visual acceptance and required manual device checks remain)
- Branch: `codex/wealthy-c2a-shell`
- Draft PR: https://github.com/Kei-Takamizawa/Wealthy/pull/5
- Base: PR #4 on main, commit `6d741cf67a256a3575d57f1a4e05ee61d8cd3804`.

## Implemented

The existing Wealthy app/target/scheme/bundle identifier/signing configuration is retained. App code and WealthyCore use Swift 6. The disposable XCTest runner uses Swift 5 because XCTest actor-isolation overrides did not compile in Swift 6; this does not change the app language mode.

All legacy screens and SwiftData models are archived in `LegacyApp/`, outside the synchronized app target. The app has no legacy imports, store references or migration path. It opens only the new `WealthyLedger.store`; no legacy user files or receipt images were opened, deleted or migrated. No app uninstall was performed.

The native pager contains Voice, Home, Info and initially selects Home. It exposes page labels, accessibility actions, escape actions and a page rotor. Typed onboarding, household/child information, monthly/category targets, entry add/edit, no-spend marks, tax, child setup/detail, language/currency settings and full font licenses are implemented. Voice is visibly a nonfunctional Cycle 3 placeholder.

Amounts remain integer minor units and use Core formatting. Tax totals and estimates come from Core; unknown rates are excluded and counted. Child support defaults to fixed and exempt. Target defaults exclude fixed costs. Reward state is derived; monthly eligibility is ceil(70% of days), weekly eligibility remains 5/7. Late entry deadlines and recent result recomputation are tested. Progress fill and overspend condition are provided by Core.

Four-language String Catalog: 125 keys in English, Japanese, Spanish and Korean, with placeholder parity. Four OFL font subsets total 7,229,980 bytes (6.90 MiB), source hashes verified against the task. Japanese subsets include the official Joyo first-column forms and variants (2,137 extracted forms), kana and Latin; Korean includes all 11,172 modern Hangul syllables; Spanish accents are covered. Original license/copyright metadata remains, and reserved font names are renamed to Wealthy-prefixed families. No runtime third-party dependency was added.

## Requirement status

| Requirement | Status / limits |
| --- | --- |
| Design system / native glass | Implemented tokens, Plate, Row, Pill, Sticker, PrimaryButton and thin/regular/thick glass mappings. Opaque money plates. Reduce Transparency uses opaque 1.5 pt outlines. Native thick glass is a tinted regular glass because SwiftUI has no matching browser blur-number API. Exact visual acceptance remains open. |
| Three-page shell | Implemented native paging, initial Home, direct Home/Voice/Info controls, Reduce Motion branch and accessibility page actions/rotor. Full manual VoiceOver pass pending. |
| Onboarding / empty day / AI gate | Implemented four steps and empty Home; real Foundation Models availability gate stays active. No-AI guidance is screenshot-previewed, not an actual unsupported-device test. |
| Home / island / results | Core binding and derived daily/festival/result state implemented. Canvas includes house, lighthouse, string lights, waves, bird, trees and earned areas; it is a reconstruction, not a pixel-perfect reproduction. Monthly achieved/over result presentation remains incomplete; Claude review required. |
| Info / child envelope | Implemented segmented envelopes, allowance plates, category jars (three columns; one at accessibility sizes), child setup/detail and recent entry editing. Child setup/detail are simpler than boards; see visual limits below. |
| Goals | Overall/category targets, monthly versions, fixed-cost switch and week-start picker implemented. Unset fields use localized placeholders; GoalsUnset has captured evidence but uses the same empty form rather than the distinct illustrated board. |
| Typed entry editing | Expense/income, amount/date/category/envelope/service/tax/note/fixed/review and no-spend command implemented. Existing manual tax/category metadata survives reopening. |
| Tax | Uses Core totals/by-rate/unknown count/estimate. Fixed costs are included unless exempt. No tentative tax for unknown rate. |
| Localization / fonts / settings | Four-language catalog and licensed subsets implemented. Fourteen destinations were captured in three variants; screenshot capture alone does not establish absence of all clipping. |
| Remove legacy target code | PASS static isolation. Legacy source is preserved outside target for existing verification; legacy user data is untouched. |
| Persistence / undo / backup constraints | No persistence internals, undo implementation or backup format changed. DEBUG performance fixture uses the existing backup restore API in a separate temporary store, with no backup UI. |
| Performance | Core disk benchmark completed. Weekly query medians increased about 20%; no blanket “no regression” claim. 50k device launch-to-accessibility-element timing measured; literal first-frame and visible-stall acceptance not established. |
| GUI / accessibility | Real-device automated workflows and screenshot matrix executed. Actual OS Reduce Motion/Transparency settings and spoken VoiceOver traversal are not yet verified. |

## Files changed

- New app: `DesignSystem.swift`, `LedgerSession.swift`, `LedgerRoot.swift`, `HomeInfo.swift`, `IslandScene.swift`, `EntryEditor.swift`, `GoalsTaxSettings.swift`, `MonthControl.swift`, replacement `WealthyApp.swift`, `Localizable.xcstrings`, `Info.plist`, `Fonts/`.
- Project: Swift language mode and four known regions only; bundle identifier, team, entitlements, target, scheme and signing settings retained.
- Core: `Currency.swift`, `Targets.swift`, new `IslandQueries.swift`; tests `DomainV2Tests.swift` and `IslandTests.swift`.
- Verification: UI suite/project generator, catalog/font/isolation validator, font preparation/manifest, evidence exporter; historical check scripts reference `LegacyApp/` with assertions preserved.
- Legacy: previous app Swift source and InfoPlist strings moved to `LegacyApp/`; original Info.plist retained there for historical fixtures.
- Documentation: English README, verification guidance, CURRENT_TASK and this report.
- Pre-existing `.DS_Store` changes and three project blank-line deletions and the untracked design reference PDF are excluded from the task commit.

## Builds and tests executed

| Check | Result |
| --- | --- |
| `sh Verification/verify_core.sh` | PASS: 113 tests; 1 opt-in benchmark skipped (114 total, 13 suites). Latest log `core-current.log`. |
| Opt-in Release disk benchmark | PASS: 1 benchmark test, 599.421 s. `benchmark.log`, `benchmark.json`. |
| `python3 Verification/verify_shell.py` | PASS: 125 keys x 4 languages, placeholders, target isolation, four subset hashes, font names, Hangul/Spanish coverage. |
| Historical OCR | PASS: 91 checks. |
| Historical backup | PASS: 114 checks. |
| Historical localization | PASS: 6,634 checks. |
| Historical payments | PASS: 96 checks. |
| Historical migration fixture | PASS: 11 checks; temporary fixture only, no user migration. |
| Historical currency | PASS: 40 checks. |
| Historical policies | PASS: 73 checks. |
| Historical money tips | PASS: 1,524 checks. |
| Generic Simulator build | PASS; no Simulator runtime available, so no Simulator launch claim. |
| Unsigned Release build | PASS. |
| Signed physical device build | PASS on paired iPhone 16 Pro Max, iOS 27.2. iOS 26 hardware execution not verified. |
| Real-device UI tests | 24 distinct current test methods executed: 23 PASS, 1 FAIL (result contrast audit), across separate runs; not a single all-green suite. |

Historical checks total 8,583 assertions. They verify archived components, not availability of those removed features in the new app. `prepare_device_tests.py` is retargeted for historical fixtures but its full historical device suite was intentionally not executed.

## Performance evidence

Disk benchmark medians in milliseconds, compared to the existing Cycle 1.2 benchmark artifact:

| Operation | 10k current | Change | 50k current | Change |
| --- | ---: | ---: | ---: | ---: |
| Add | 27.038 | -0.6% | 164.386 | -1.1% |
| Update | 26.215 | -2.2% | 168.421 | -7.8% |
| Delete | 25.748 | -1.8% | 174.220 | -5.8% |
| Undo | 33.917 | -4.6% | 244.853 | +0.3% |
| Preview | 16.672 | -2.2% | 115.945 | -7.4% |
| Recurring | 25.115 | +0.7% | 155.432 | -2.6% |
| Open | 395.831 | -0.5% | 2083.849 | -21.4% |
| Week query | 0.047 | +22.1% | 0.341 | +20.3% |
| Month query | 0.476 | -0.9% | 2.196 | -29.1% |
| Tax query | 0.041 | -0.8% | 0.182 | -4.7% |

The 50k weekly query increased by about 0.058 ms. These are sequential benchmark runs on this Mac; they do not establish a causal regression or prove device rendering performance. Detached 50k island snapshot in the final Core run: 0.141559750 s. This is a Mac query timing, not a phone first-frame measurement.

## GUI Expected / Actual and evidence

Expected: complete onboarding, create a JPY 2,400 takeout expense, see Core tax 177, mark no spend, change overall target, and see updated Info/Tax. Actual: this real-device workflow passed. Expected: manually override takeout tax to 10%, save/reopen and retain category/rate; actual: PASS. Four-language onboarding at default/dark/AX3 passed.

Final inventory: 251 uniquely named screenshots outside Git, including a complete 168-image destination matrix (14 screens x 4 languages x light/dark/AX3). Contact sheets and selected full-resolution evidence are committed; full attachments and videos are excluded. Screenshots contain synthetic records only. Native date/month controls and navigation chrome differ from browser mockups. The app uses a vertically scrolling allowance layout rather than matching every board position. The simplified child detail omits fixed-cost management and past analysis because those destinations are out of scope.

## Errors, warnings and reproduction

- First seeded screen capture run incorrectly passed despite a visible “store could not open” alert. Cause: app created preset child categories after Core had already seeded them. Removed duplicate creation, then added a no-alert assertion before every saved screenshot. The earlier seeded screenshots are invalid and excluded from final evidence.
- A child-envelope workflow stalled in XCTest animation-idle waits (repeated 60-second waits on iOS 27.2). Interrupted that run; it is not counted as PASS. The isolated Reduce Motion child-envelope/license workflow passed (122.611 s). Normal-motion child workflow remains unresolved until reproduced successfully.
- A newly added test initially omitted `try` when constructing a date; corrected the test and reran the full Core suite successfully.
- Expected Xcode warning: AppIntents metadata extraction skipped because no AppIntents framework dependency is present (Cycle 3 is out of scope). XCTest logs also contain debugger version lookup warnings; successful tests are counted only from final case results.
- Luna delegation failed because this session reached its agent-thread limit. Implementation and verification continued in the root agent; no alternate model was used.

Reproduce: run Core/shell checks, generate a temporary project with `prepare_cycle2a_tests.py`, then run its Wealthy scheme on the paired eligible iPhone. Workflow tests use a separate in-memory ledger. `testHomeWithFiftyThousandPersistedEntries` uses only `temporaryDirectory/Cycle2aPerformance/WealthyLedger.store`; it never opens the legacy store.

Logs/build products/xcresult bundles are outside Git under `/private/tmp/wealthy-c2a-logs/` and `/private/tmp/wealthy-c2a-*`. Only selected synthetic screenshots and contact sheets are retained in `Verification/Cycle2aEvidence/`.

## Open decisions and intentionally omitted work

Claude review is required for the island illustration and remaining layout differences against the approved boards. The Home page currently follows the envelope selected on Info; confirm that context if a different Home envelope is intended. No new product or persistence architecture was introduced to address visual/performance gaps.

Voice/speech/AI interpretation, App Intents, receipt scanning/attachments, calendar/analysis, fixed-cost management, category management, backup/restore UI, undo history, sticker-album persistence and iPad layout are intentionally absent. No dead entry points to these features were added. No merge, force push, legacy-data deletion or dangerous credential workaround was performed.

## Final verification / Git

Final Simulator, unsigned Release and signed-device builds all returned BUILD SUCCEEDED. Final signed app installation and normal launch returned success, without test flags. No uninstall occurred. This report is finalized for the task commit; remote commit/push verification is reported in the final chat response.

## Final real-device verification details

Device: iPhone 16 Pro Max, iOS 27.2 (24B5089g), Apple Intelligence available. Simulator build only: no installed runtime. Onboarding completion/empty Home was tested with an in-memory ledger. Normal launch into the first onboarding step was separately verified on the new disk store; persisted onboarding completion was not verified.

PASS workflows: onboarding, household expense, takeout tax 177 for JPY 2,400, no-spend mark, target edit, manual 10% override/category preservation, child expense/tax, child-support fixed/exempt defaults, income, empty-ledger no-spend, licenses, actual pager buttons/swipes, existing child setup remaining enabled. Seeded weekly achieved/over/few result states were captured. Monthly few-days state was captured; monthly achieved/over UI was not verified.

PASS screenshot groups include four-language onboarding, 14 destination matrix in light/dark/AX3, child information/setup/detail, forms, goals unset, and Korean AX3 amounts. Capture code asserts that no alert is present. Screenshots are visible viewport evidence, not proof that every offscreen control is unclipped.

Accessibility: Home and Entry audits PASS for English/default visible viewport (contrast, clipped text, hit region, description). Result audit FAIL: the late-entry explanation is flagged for contrast. Explicit ink color and hiding the bottom scroll-edge effect did not resolve the failure. Sampled dominant foreground/background colors yield 13.16:1, but the cause of the audit discrepancy is unknown; the failure is not dismissed as a false positive. No spoken VoiceOver traversal, actual OS Reduce Motion/Transparency switch test or iOS 26 hardware pass was performed. DEBUG accessibility variants exercise component branches only.

Five DEBUG warm launches against a separate persisted 50,000-entry fixture measured launch-call to Add Entry accessibility-element existence: 7.826, 7.378, 5.810, 8.094, 5.925 seconds; median 7.378 seconds. Fixture creation is excluded; XCTest launch/idle overhead is included. These are not GPU first-render timings and do not certify absence of visible stalls. Source changes after measurement were UI-only; the measurement was not repeated.

Additional implementation defects corrected and retested: existing child setup accidentally archived its envelope when enabled state loaded (fixed toggle condition; regression PASS); a GoalsUnset test assumed an empty field value instead of checking its placeholder (test corrected, PASS); Swift 6 Canvas required the pure color helper to be nonisolated. Initial small hit regions, weekday text contrast and Korean AX3 amount wrapping were corrected. Result contrast failure remains.

## Design differences requiring review / unfinished acceptance

- Island artwork and vertical card arrangement differ from approved boards. Child setup routes to Targets instead of showing the standalone overall-target card. Child detail omits fixed-cost management and historical analysis as out of scope.
- GoalsUnset uses the goals form with empty values. Native month/date controls and Liquid Glass differ from browser drawings.
- Monthly achieved result currently shares the weekly “Festival earned” caption and single-festival illustration. Monthly reward caption/area presentation needs completion against the board; Home's derived area count is capped at four. No claim of full monthly result acceptance is made.
- Home follows the envelope selected on Info; confirm this context during design review.
- Result accessibility audit, normal-motion child XCTest idle stall, manual VoiceOver/OS settings and literal 50k first-render acceptance remain unresolved.

Evidence: [English contact sheet](../Verification/Cycle2aEvidence/comparison-en.jpg), [Japanese](../Verification/Cycle2aEvidence/comparison-ja.jpg), [Spanish](../Verification/Cycle2aEvidence/comparison-es.jpg), [Korean](../Verification/Cycle2aEvidence/comparison-ko.jpg), [audit failure](../Verification/Cycle2aEvidence/result-audit-failure.png), [comparison limits](../Verification/Cycle2aEvidence/COMPARISON_NOTES.md).

Latest logs: `core-current.log`, `release-current.log`, `simulator-current.log`, `signed-current.log`, `device-ui-matrix-final.log`, `device-ui-screens-current.log`, `device-ui-workflows-final.log`, `device-ui-money-current.log`, `device-ui-child-setup-current.log`, `device-audit-separated.log`, `final-device-install.log`, `final-device-launch.log`, all under `/private/tmp/wealthy-c2a-logs/`. XCTest bundles with corresponding names are under `/private/tmp/wealthy-c2a-*`.

Reproduce result failure: generate the disposable test project, run `Cycle2aUITests/testResultAccessibilityAudit` on the eligible paired device. Expected: no contrast audit issues. Actual: late-entry explanation flagged, test FAIL. This blocker is retained for Claude/user assessment; no audit exclusion or weakened assertion was added.

Staged whitespace check flags one trailing space in each of the three upstream OFL texts (license paragraph line 21). These source license texts are preserved; no Swift/code whitespace issue was reported. Git also normalizes the Klee One license CRLF to LF.
