# Cycle 2b.1 - WEALTHY-C2B1-FIXED-CALENDAR

## Goal
Add the first Cycle 2b screens on top of the existing WealthyCore queries and commands:
1. Fixed costs (recurring rules): list, add, edit, pause/resume, delete, and automatic catch-up posting with a one-time notice.
2. Calendar: month view with per-day totals and no-spend marks, and a day detail.
3. Analysis: category breakdown for the month with the previous-month comparison.

## Branch
New branch `codex/wealthy-c2b1-fixed-calendar` from latest `origin/main` (must contain PR #9, `5db23f0`; if not, stop as BLOCKED). The operator opens a NEW draft PR.

## Context
- Owner decisions still in force: standard iOS components only (no custom glass, plates or capsule buttons); tabs `Voice | Home | Info` with tap and swipe; exactly 4 languages (en base, ja, es, ko); all amounts and states from WealthyCore, no arithmetic in views.
- Design boards (content and wording reference only, not visual spec): `design/v4/固定費.png`, `design/v4/カレンダーと分析.png`. Where a board and WealthyCore differ, WealthyCore wins; list the differences in the report.
- WealthyCore already provides what this cycle needs: `RuleValue` with `RecurringSchedule` (`monthly(day:)`, `weekly(weekday:)`, `yearly(month:day:)`), commands `createRule` / `updateRule` / `pauseRule` / `deleteRule`, `markNoSpend` / `unmarkNoSpend`, `LedgerCore.postRecurring(through:now:)` (outside undo history by design), and queries `LedgerQueries.dailyTotals`, `categoryBreakdown`, `upcoming`, `entries(filter:)`, `periodSummary`.

## Requirements

### 1. Entry points (no new tabs, no dead entry points)
- From Info (household and child envelope): rows "Fixed costs", "Calendar", "Analysis" pushed in the existing `NavigationStack`. The tab bar and the three tabs stay as they are.
- Root-tab swipe must keep working only on the three root pages; pushed screens (these new ones included) must not switch tabs on horizontal drags. Extend the existing gesture tests to cover one new pushed screen.

### 2. Fixed costs
- List of rules for the selected envelope: title, amount (locale currency format), schedule in words (e.g. "Every month on the 25th", "Every Monday", "Every year on 4/1"), next occurrence (from `upcoming`), paused state shown with icon + word.
- Add/edit form (`Form`): title, expense/income, amount (`MoneyInputField`), category, envelope, schedule type and its day/weekday/month-day, start day, optional end day, fixed-cost flag, tax rate / service mode where the entry editor already offers them. Validation errors come from WealthyCore and are shown inline in plain words.
- Pause/resume and delete with `confirmationDialog`; delete explains that already-posted entries remain.
- Catch-up: call `postRecurring(through: today, now:)` after the ledger opens and whenever the app becomes active (scene phase). If entries were posted, show one dismissible notice ("N fixed costs were recorded while the app was closed") with a way to view them (day detail or list). If there were failures, show them in plain words with the rule name. Never block launch on this; it must not count toward first frame. Posting is not an undo step (Core rule); do not add one.

### 3. Calendar
- Month view (`MonthControl` for month switching): each day shows the expense total (compact currency) and a no-spend mark, from `dailyTotals` and Core's no-spend state. Today is marked. Week start follows the setting already in Core.
- Must work at AX3 without clipping (allow a list-style fallback layout for large text if a grid cannot fit).
- Day detail: that day's entries (tap opens the existing entry editor), totals, and a toggle for the no-spend mark (`markNoSpend` / `unmarkNoSpend`). Core currently allows a mark on a day that has entries; do not add a UI-side rule, show what Core returns, and show any Core error in plain words.
- VoiceOver: each day cell reads date, total and no-spend state as one element.

### 4. Analysis
- Month selector; category breakdown for expenses from `categoryBreakdown` (current vs previous month), sorted by amount; totals from `periodSummary`.
- A chart is allowed using Swift Charts (system framework, not a new dependency) with an accessible text list that carries the same numbers; the list alone must be complete. Color is never the only carrier of meaning.
- Empty month: a plain message, no chart.

### 5. Languages and accessibility
- All new strings in `Localizable.xcstrings` for en, ja, es, ko; `verify_shell.py` must report zero missing keys.
- Accessibility audits for the three new screens (no exclusions), on iPhone 15 Pro and iPhone 17 Pro simulators.

## Do not change
WealthyCore behavior, persistence, data model, tax/target rules (small read-only query helpers allowed only if strictly needed, with tests; prefer none). Fonts, the tab structure, the standard-UI decision. No new dependencies.

## Tests (UI tests in `WealthyUITests`, synthetic data)
- Create, edit, pause/resume and delete a monthly rule; a weekly and a yearly rule show the right schedule text.
- Catch-up: a seeded rule with past occurrences posts entries on launch, the notice appears once, and relaunch does not post duplicates.
- Calendar: totals and no-spend marks match seeded data; day detail opens an entry; toggling no-spend works and is reflected in the month.
- Analysis: breakdown order and previous-month values match seeded data; empty month message.
- Horizontal drag on a pushed screen does not switch tabs.
- Accessibility audits: Fixed costs list, Calendar, Analysis (and the rule form if feasible).

## Acceptance
- All tests above pass on iPhone 15 Pro and iPhone 17 Pro simulators; existing UI tests and audits still pass.
- `sh Verification/verify_core.sh` (117 tests unchanged), `python3 Verification/verify_shell.py`, `sh Verification/verify_localization.sh`, `git diff --check` pass.
- Simulator Release build and signed generic iOS build pass.
- Screenshots (light, dark, AX3 for Calendar) of Fixed costs list, rule form, catch-up notice, Calendar, Day detail, Analysis, committed under `Verification/Cycle2bEvidence/` with an `INDEX.md` (JPEG q≈80, long edge ≤ 2000 px, each < 1 MB). Synthetic data only.
- Physical device: install and normal launch of the signed Release build succeeds (no new performance measurement required). If the device rejects the launch because the profile is not trusted, report it as an owner action, not a failure of the task.

## Report (`.ai/LAST_REPORT.md`, format in `AGENTS.md`)
Per requirement with evidence, exact commands, board-vs-Core differences, anything not run and why.

## Round 2 (designer decisions, 2026-11-06, after PR #10 head 5fee716)
Same Task ID, same branch `codex/wealthy-c2b1-fixed-calendar`, same PR #10. Read `.ai/LAST_REPORT.md` first. Only the items below; do not change anything else that already passes.

1. **Rule form audit ("Dynamic Type font sizes are partially unsupported" on Category and Day of month).** Restructure with standard controls only:
   - Day of month: replace the fixed-width (`frame(width: 100)`) number `TextField` with a standard `Picker` over 1...31 (and 1...12 for the yearly month), using `.pickerStyle(.navigationLink)` so the value list is a pushed list that scales with Dynamic Type. The value shown in the row is the plain number. Core still validates the day (month-end clamping stays a Core rule).
   - Category (and other pickers in this form if the audit flags them): use the plain `Picker(title, selection:)` initializer without a custom label view, `.pickerStyle(.navigationLink)`.
   - Remove fixed widths/heights around text in this form; rows may grow vertically.
   - The audit stays the default `performAccessibilityAudit()` with no exclusions. A diagnostic issue handler is allowed only if it logs the element (label, identifier, frame) and still fails the test for every issue; if the automatic approval reviewer rejects it, skip the handler and report.
2. **Home "Text clipped" (Not a balance, I spent nothing today).** Make every text on Home wrap at accessibility sizes: no `lineLimit(1)` or fixed heights on these texts or their containers; button labels may wrap to multiple lines (`.fixedSize(horizontal: false, vertical: true)` where needed). The big amount may keep `minimumScaleFactor` if the audit accepts it; otherwise let it wrap. Classify the failure: run `testHomeAccessibilityAudit` once on `origin/main` (5db23f0) in a temporary git worktree under `/tmp/wealthy-c2b1-baseline` with the same simulator Dynamic Type state and report whether it already failed there. Do not commit anything from that worktree; remove it afterwards.
3. **Full UI suite.** After 1 and 2, run the whole `WealthyUITests` scheme once per simulator (iPhone 15 Pro, iPhone 17 Pro) in single runs, with `-parallel-testing-enabled NO`. Report counts and every failure. The launch/interactive metric tests may be slow; they must run, but their simulator numbers are not judged against the device target.
4. Keep the screenshots in `Verification/Cycle2bEvidence/` in sync: re-capture only the rule form and Home-affected images if they change.

Acceptance for round 2: rule-form audit and Home audit pass on both simulators with no exclusions; the full suite has zero failures on both simulators; required checks (`verify_core.sh`, `verify_shell.py`, `verify_localization.sh`, `git diff --check`, Simulator Release and signed generic iOS builds) pass. Then set `Status: DONE`. If a failure remains, keep it red, report the exact test, element and message, and set `Status: PARTIAL`.


## Round 2 resume instructions (user, after usage-limit interruption)

You stopped on a usage limit; the limit has reset. Continue Round 2 from where you stopped (your two full-suite runs ended when you stopped; no xcodebuild is running now) and finish with the full report.

Designer notes for the rest of Round 2:
(a) Test environment first. On main, UI tests pinned Dynamic Type with `.environment(\.dynamicTypeSize, LedgerSession.isUITest ? (--ax3 ? .accessibility3 : .large) : actual)`; this branch now pins only for --ax3 (LegacyUITestTypeSize) and otherwise inherits whatever the simulator is set to, which makes results depend on simulator state. Replace the SwiftUI environment pin with the system launch argument in the tests: launch with `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryL` by default and `UICTContentSizeCategoryAccessibilityXL` (AX3) for AX3 cases, and remove the in-app environment override, so the app follows a real content size category and the audit can vary it. Record the simulator's own content size before and after. Then re-run the rule-form and Home audits before changing UI further; report whether the 'partially unsupported' and 'Text clipped' issues change.
(b) Rule form: keep navigationLink Pickers for Day/Month/Category only (not form-wide). If the dynamic-type issue remains, check for anything in the row hierarchy that stops text scaling (fixed font sizes, fixedSize(), frame heights, minimumScaleFactor, lineLimit) and report the element's label, identifier, frame and the exact audit description.
(c) testC2bChildIsolation: update it to assert the Category picker's accessibility value ('Food') instead of its label. This matches the standard control and keeps the assertion as strong.
(d) Home baseline classification may stay inconclusive; just fix Home so the audit passes under (a).
(e) Then the full suite on both simulators, single runs, as in the Round 2 text.


## Round 2 further designer notes (checkpoint b81e9e2)

Continue Round 2 of WEALTHY-C2B1-FIXED-CALENDAR. The checkpoint is committed. Apply these designer notes in order, then finish Round 2 and rewrite .ai/LAST_REPORT.md.
(f) Both full audits report 'Dynamic Type font sizes are partially unsupported'. A pinned content size (in-app dynamicTypeSize override, or the -UIPreferredContentSizeCategoryName launch argument, which lands in the highest-priority defaults domain) can stop the app from following the audit's own size changes. Launch the audit tests (testC2bAccessibilityAndEvidence, testHomeAccessibilityAudit, and the rule-form audit if separate) with NO content-size launch argument and no in-app override, simulator at default size; keep the size argument only in tests that need a fixed AX3 layout (matrix and screenshot tests). Run only these audit tests once per simulator first and report each result.
(g) If Category / Day of month in the rule form still fail after (f): replace each Picker(.navigationLink) with a standard NavigationLink whose label is LabeledContent(title) { Text(value) } and whose destination is a List of plain Button rows with a checkmark on the selection. Standard components only, no fixed sizes. Keep identifiers and the value tests read ('Food').
(h) If Home still fails after (f): report label, frame and font of each flagged element; no Home layout changes beyond Round 2 item 2.
(i) testIncomeEntry and testChildSupportDefaults assume October fixtures. Make the test data relative to the current month (or use an existing injectable test date) so the expected values hold in any month. Do not change expected numbers to match the screen; do not change WealthyCore.
(j) testChildEnvelopeAndLicenseFlow and testPersistedOnboardingRelaunch (15 Pro): first check whether (f) fixes them. If not, find the cause and fix within task scope; if the cause is outside the task, keep red and report.
(k) Then run the full WealthyUITests once per simulator with -parallel-testing-enabled NO. If budget looks short, run the full suites before re-capturing screenshots. Status DONE only if all acceptance items have evidence; otherwise PARTIAL with exact failures.

## Round 3 (designer, 2026-11-06, after PR #10 head a9a13dc; owner-approved scope)
Same Task ID, branch and PR #10. Read `.ai/LAST_REPORT.md` first. Only the items below; do not change anything else that already passes.

**Owner decision (2026-11-06):** a narrow exception to AGENTS.md "never exclude accessibility audits" is approved for exactly one case: the Dynamic Type finding that Apple DTS describes as a SwiftUI audit false positive ("User will not be able to change the font size of this SwiftUI.AccessibilityNode", Apple Developer Forums thread 828525, June 2026). Nothing else may be excluded.

1. **Narrow audit filter.** In `testC2bAccessibilityAndEvidence` and `testHomeAccessibilityAudit` (and any other audit that reports this finding), keep the default `performAccessibilityAudit()` (all audit types) and add an issue handler that ignores an issue only when ALL hold: `auditType == .dynamicType`; the issue's detailed description says the element is a `SwiftUI.AccessibilityNode`; the element exists. Every other issue (any other type, or a Dynamic Type issue on a non-SwiftUI element) still fails the test. Put the handler in one shared helper with a comment citing the owner decision and the forum thread. Log each ignored issue (label, identifier, frame) and attach the list to the test result; count them in the report per screen and simulator.
2. **Compensating Dynamic Type check (required, replaces what the filter ignores).** Add a UI test that launches the rule form and Home once at the default size and once with `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXL`, and asserts for each element that Round 2 reported (rule form: Category, Day of month; Home: the 15 listed elements, or a representative set that includes every distinct text style among them) that its frame height at AX3 is larger than at the default size, and that it is fully inside the window. If an element does not grow, that is a real failure: keep it red and report it.
3. **Custom fonts.** Extend `Verification/verify_shell.py` so it fails if any `Font.custom(` / `.custom(` call in `Wealthy/` lacks `relativeTo:` (or confirm none exist and add the check anyway). Report the result.
4. **Onboarding Next button (iPhone 15 Pro).** Fix `testPersistedOnboardingRelaunch`: make the Next button reachable while the keyboard is up, with standard components only (for example a `ScrollView` with `.scrollDismissesKeyboard(.interactively)`, or the button in a `safeAreaInset(edge: .bottom)` that moves above the keyboard). Do not change onboarding content, wording or flow. Do not weaken the test.
5. **Full UI suite** once per simulator (iPhone 15 Pro, iPhone 17 Pro), `-parallel-testing-enabled NO`, only after 1-4 pass in targeted runs. Run the full suites before re-capturing any screenshots; re-capture only images that changed (onboarding if affected). Keep logs/xcresults under `/tmp/wealthy-c2b1-r3*`.

Acceptance for Round 3: full suite zero failures on both simulators with only the item-1 filter; item-2 test passes; required checks (`verify_core.sh` 117, `verify_shell.py`, `verify_localization.sh`, `git diff --check`, Simulator Release and signed generic iOS builds) pass. Then `Status: DONE`. Otherwise `PARTIAL` with the exact test, element and message.

## Round 4 (designer, 2026-11-07, after PR #10 head 61e22d6)
Same Task ID, branch and PR #10. Read `.ai/LAST_REPORT.md` first. One item only; do not change anything else that already passes.

**Review finding (blocker).** In `Verification/Cycle2bEvidence/iphone15pro-onboarding-target-light.jpg` and `-dark.jpg`, while the number pad is up, the monthly target amount field is hidden behind the new bottom bar (Back / Next), so the user cannot see the number they type. On iPhone 17 Pro the field is visible. This came from the Round 3 item 4 change (`safeAreaInset(edge: .bottom)` in `OnboardingView`, `LedgerRoot.swift`).

1. **Test first.** Extend `testPersistedOnboardingRelaunch` (or add one onboarding test) so that, on the target step with the keyboard up and digits typed, it asserts: the amount field is hittable; its whole frame lies above the top of the Back/Next bar and above the keyboard; its value shows the typed digits; Next is hittable. It must fail on iPhone 15 Pro with the current code (report that failure), then pass after the fix.
2. **Fix with standard components only**, keeping onboarding content, wording and flow. Prefer one of: (a) keep the bottom bar but make the form scroll the focused field above it (for example `ScrollViewReader` + `@FocusState`, scrolling to the field when it gains focus and when the keyboard appears); or (b) remove the bottom bar, put Back/Next back in the form, and add the Next action to a keyboard toolbar (`ToolbarItemGroup(placement: .keyboard)`). Pick the simpler one that passes item 1 on both simulators, also at AX3 (`-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXL`), and say which you chose.
3. Re-capture the 16 onboarding screenshots (light/dark, both simulators); the target-step images must show the typed amount.
4. Full `WealthyUITests` once per simulator, `-parallel-testing-enabled NO`; required checks (`verify_core.sh` 117, `verify_shell.py`, `verify_localization.sh`, `git diff --check`, Simulator Release and signed generic iOS builds). Keep logs under `/tmp/wealthy-c2b1-r4*`.

Acceptance for Round 4: item-1 test passes on both simulators (and at AX3), full suites zero failures on both, required checks pass, screenshots updated. Then `Status: DONE`; otherwise `PARTIAL` with exact failures.

## Round 5 (designer decision, 2026-11-07, after PR #10 head c27d734)
Same Task ID, branch and PR #10. Read `.ai/LAST_REPORT.md` first. Keep `testOnboardingAmountVisibleWithKeyboard` exactly as committed (it is the acceptance test).

**Why the scroll fixes failed (designer's reading, not verified):** on iPhone 15 Pro the target step is short; the amount field is the last row, so the form cannot scroll far enough to lift it above the bar and keyboard. Scrolling tricks cannot create space that the layout does not have. So the fix is to free vertical space while typing.

1. **Fix (decided):** keep the Round 3 bottom bar (Back / Next in `safeAreaInset(edge: .bottom)`). On the target step, while the amount field has focus (`@FocusState`), hide the island illustration in the step header (the title and "3 / 4" stay); show it again when focus ends. Use a standard transition; no new components, wording or flow changes. If the test still fails at the default size or at AX3 after this, additionally add bottom scroll space with `.contentMargins(.bottom, <bar height>, for: .scrollContent)` and scroll the field into view on focus. Report the frames after each step.
2. Re-capture the 16 onboarding screenshots (light/dark, both simulators); the target-step images must show the typed amount.
3. Full `WealthyUITests` once per simulator, `-parallel-testing-enabled NO`; required checks (`verify_core.sh` 117, `verify_shell.py` with the PYTHONPATH that provides fontTools, `verify_localization.sh`, `git diff --check`, Simulator Release and signed generic iOS builds). Keep logs under `/tmp/wealthy-c2b1-r5*`.

Acceptance for Round 5: `testOnboardingAmountVisibleWithKeyboard` passes on both simulators at default size and AX3; full suites zero failures on both; required checks pass; screenshots updated. Then `Status: DONE`; otherwise `PARTIAL` with the exact frames and failures.
