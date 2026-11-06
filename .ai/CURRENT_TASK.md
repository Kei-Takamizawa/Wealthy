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
