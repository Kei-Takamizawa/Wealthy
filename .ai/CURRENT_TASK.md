# Cycle 2b.2 - WEALTHY-C2B2-QUICK-ENTRY

## Goal
Make Wealthy usable by people who cannot keep a budget going, on any iPhone that runs iOS 26:
1. **No AI gate (E3).** The ledger opens and every budgeting feature works whether or not Apple Intelligence is available.
2. **3-second entry.** One tap opens a number pad; one more tap saves. Saving without a category is allowed. The same action is available outside the app through App Shortcuts (Shortcuts, Spotlight, Action Button, a Control Center "Shortcut" control), with no new app extension.
3. **Safe line (A3).** On Home, "safe to spend this week" = what is left this week minus fixed costs already scheduled for the rest of the week.

## Branch
New branch `codex/wealthy-c2b2-quick-entry` from latest `origin/main` (must contain PR #10, merge `fc74376`; if not, stop as BLOCKED). The operator opens a NEW draft PR.

## Context
- Owner decisions in force: standard iOS components only; tabs `Voice | Home | Info` (tap and swipe); exactly 4 languages (en base, ja, es, ko); amounts and states come from WealthyCore, no money arithmetic in views; performance judged on the physical iPhone (Home interactive <= 2 s at 10,000 entries).
- Owner decision 2026-11-06 (design-review doc 10 §8): E3 adopted. The old "iPhone 15 Pro minimum" now applies only to future AI features, not to the app.
- Today the only use of Apple Intelligence is the gate: `LedgerSession.refreshAvailability()` sets `available`, `LedgerSession.open()` returns early when it is false, and `LedgerRoot` shows `NoAIView` instead of the ledger. Nothing calls a language model.
- WealthyCore already supports uncategorized entries (`EntryValue.categoryID` is optional; `LedgerQueries.categoryBreakdown` returns a `nil` bucket; `EntryFilter.uncategorized` exists).
- `LedgerQueries.upcoming(in:nextDays:today:)` lists future rule occurrences. Catch-up (`postRecurring(through: today)`) already posts occurrences dated today or earlier.
- The owner signs with a free (personal) team. App Intents need no capability or entitlement. Do NOT add app extensions, App Groups, or any new capability or entitlement in this cycle (widgets and dedicated controls are the next cycle).

## Requirements

### 1. No AI gate (E3)
- The ledger opens, onboarding runs and all existing features work when `SystemLanguageModel.default.availability` is `.unavailable` for any reason. Remove the early return in `open()` and the `NoAIView` branch in `LedgerRoot`.
- Keep availability detection. Show it as information only: one row in Info's settings area, "On-device AI" with a plain state ("Available", "Not available on this iPhone", "Turned off in Settings", "Getting ready"), and a detail screen that says all budgeting features work without it and that voice features later may use it. Reuse `NoAIView` for the detail if that is simpler (rename and reword it; no "blocked" wording). The Voice tab stays as it is.
- DEBUG test switch: `WEALTHY_TEST_AI_AVAILABLE=0` forces unavailable, `=1` forces available (keep accepting the old `WEALTHY_CYCLE2A_TEST_AI_AVAILABLE=1`). Tests must not depend on the simulator's real AI state.
- README.md: replace the "compatible iPhone with Apple Intelligence" requirement with "iPhone with iOS 26 or later; Apple Intelligence is not required". Keep the README plain and short.

### 2. Quick add (in the app)
- Home: the existing "Add entry" action becomes **Quick add**: it opens a sheet with
  - the amount field (`MoneyInputField`) focused immediately with the number pad up;
  - up to 4 category buttons: the household's most-used expense categories in the last 30 days (by entry count, ties by sort order), filled up with the presets `catFood`, `catDaily`, `catOthers` when there are fewer; tapping a category button saves at once with that category;
  - a **Save** button that saves without a category;
  - **More details**, which opens the full `EntryEditor` with the typed amount carried over.
  Defaults: expense, today, household envelope, the app currency, not fixed cost, no review flag. Same late-entry rule as the editor (`LedgerQueries.canAddEntry`). The save is a normal Core command (undoable as today).
- A Save with an empty or invalid amount shows the Core error in plain words and keeps the sheet open.
- After saving: the sheet closes, Home updates, and a short confirmation is announced to VoiceOver.
- Layout: the amount field and the Save button must stay visible above the keyboard on iPhone 15 Pro and iPhone 17 Pro, at the default size and at AX3 (use the lesson from Cycle 2b.1 onboarding: test the frames, then check the screenshots).
- Uncategorized display: wherever an entry's category is shown (day detail, entry lists, analysis), an entry without a category shows the localized word "Uncategorized"; analysis shows the `nil` bucket as one "Uncategorized" row. The full editor's "None" option stays.

### 3. App Intents (outside the app, main app target only)
- `RecordExpenseIntent` ("Record expense"): parameters `amount` (required, in the app currency) and `category` (optional; an `AppEntity` or `AppEnum` over the household's non-archived expense categories, shown with localized names). Runs without opening the app, saves through the SAME code path as Quick add, and returns a spoken/visible dialog such as "Recorded ¥650 (Food). Left this week: ¥12,350." (without a target: no "left" part).
- `OpenQuickAddIntent` ("Quick add"): opens the app straight to the Quick add sheet on Home (after onboarding; before onboarding it just opens the app).
- An `AppShortcutsProvider` exposing both, with short phrases in en, ja, es, ko (each phrase must contain the app name as App Intents requires).
- Store access: one ledger store per process. The intent must not open a second `LedgerStore` while the UI has one open; use one shared owner (for example a process-wide accessor that `LedgerSession` also uses). When the app becomes active after an intent ran, Home shows the new entry (scene-phase reload already exists; verify it).
- Works with AI unavailable. No new targets, extensions, App Groups, capabilities or entitlements.
- DEBUG test hook: launch argument `--run-intent-record-expense <amount> [category-system-key]` runs the real `RecordExpenseIntent.perform()` against the isolated UI-test store after the ledger opens, and shows the returned dialog text in a test-only element so the test can read it.

### 4. Safe line (A3)
- WealthyCore: add ONE read-only query, e.g. `LedgerQueries.safeLine(in:today:envelopeID:currencyCode:calendar:) -> SafeLine` with `weekRemaining: Int?`, `scheduled: [UpcomingOccurrence]`, `scheduledTotal: Int`, `safeAmount: Int?`.
  - `weekRemaining` = the existing week `TargetStatus.remaining` (week from `settings.weekStart`).
  - `scheduled` = expense occurrences of active (not paused, not ended) rules for that envelope and currency, dated strictly after `today` and on or before the week's last day; include a rule only if it would count toward the target (`!rule.isFixedCost || settings.includeFixedCostsInTargets`). Reuse `upcoming` logic; do not duplicate schedule math.
  - `safeAmount = weekRemaining - scheduledTotal` (may be negative); `nil` when no target. Use the existing checked arithmetic.
  - No persistence, data model, target or tax rule change.
- Home week card: when a target is set and `scheduled` is not empty, show "Safe to spend" with `safeAmount`, and under it "after N scheduled (¥Y)" that expands (standard `DisclosureGroup`) to the scheduled items: date, title, amount. When `scheduled` is empty, show nothing extra. Negative amounts use the existing "over" color and word, never color alone. Keep "Not a balance". Include it in the week card's VoiceOver label.

### 5. Languages and accessibility
- Every new string in `Localizable.xcstrings` for en, ja, es, ko; `verify_shell.py` must report zero missing keys. Natural Japanese for the target users (for example ja "クイック記録", "未分類", "今週あと安心して使える額" or shorter if it clips; choose wording that fits and report it).
- Accessibility audits with the existing narrow SwiftUI Dynamic Type filter only (no new exclusions): Quick add sheet, Home with the safe line, the AI information screen.

## Do not change
WealthyCore persistence, data model, target and tax rules, existing Core behavior (only the one new read-only query and its tests are allowed). The tab structure, fonts, the standard-UI decision, languages. No new dependencies, targets, extensions, capabilities or entitlements. Deployment target stays as it is.

## Tests
Core (`WealthyCore/Tests`): `safeLine` cases: no target; no rules; rule today (excluded, already posted); rule later this week (included); rule next week (excluded); paused and ended rules; income rule; fixed-cost rule with `includeFixedCostsInTargets` false and true; other envelope; other currency; `weekStart` 1 vs 2 at a week boundary; negative result.

UI (`WealthyUITests`, synthetic data):
- AI unavailable (`WEALTHY_TEST_AI_AVAILABLE=0`): fresh launch reaches onboarding, finishes it, Home appears, Quick add saves an entry; Info shows the AI row with the unavailable state; the AI detail screen opens.
- Quick add: from Home, tap Quick add, type `650`, tap Save -> Home shows the expense and the week numbers change by 650; the entry is uncategorized and shows "Uncategorized" in day detail. The test counts its own interactions after Home is visible (must be at most 3: tap, type, tap).
- Quick add with a category button saves with that category; More details carries the amount into the editor.
- Quick add keyboard layout (15 Pro and 17 Pro, default and AX3): amount field and Save are hittable, fully above the keyboard, and the field shows the typed digits.
- Intent hook: `--run-intent-record-expense 650 catFood` adds one expense with Food and the dialog text contains the amount; without a category the entry is uncategorized; relaunch does not duplicate it.
- Safe line: seeded target and a weekly rule later this week -> Home shows the safe amount and the scheduled item; no rule -> no safe line.
- Update tests that asserted the old AI gate (`--screen no-ai` etc.) to the new behavior; do not delete coverage.
- Audits listed in Requirement 5.

## Acceptance
- All tests above pass; the full `WealthyUITests` scheme has zero failures once per simulator (iPhone 15 Pro, iPhone 17 Pro), `-parallel-testing-enabled NO`.
- `sh Verification/verify_core.sh` (the previous 117 plus the new tests, all pass), `python3 Verification/verify_shell.py` (with the PYTHONPATH that provides fontTools), `sh Verification/verify_localization.sh`, `git diff --check` pass.
- Simulator Release build and signed generic iOS build pass with the existing team and no new capability.
- The built app contains `Metadata.appintents` listing both intents and the App Shortcuts phrases in all 4 languages (show the command and the relevant output).
- Screenshots (JPEG q~80, long edge <= 2000 px, each < 1 MB, synthetic data) under `Verification/Cycle2bEvidence/c2b2/` with an `INDEX.md`: Quick add with keyboard (light, dark, AX3; both simulators), Home with safe line expanded (light, dark), Info AI row and detail with AI unavailable (light). Open every screenshot and confirm in the report that the amount field, typed digits and Save are visible.
- Physical device: install and normal launch of the signed Release build succeeds. Do not write to the owner's real ledger on the device; list "run Record expense once from the Shortcuts app" as an optional owner check in the report. An untrusted-profile launch error is an owner action, not a failure.

## Report (`.ai/LAST_REPORT.md`, format in `AGENTS.md`)
Per requirement with evidence, exact commands, Japanese wording chosen, anything not run and why, and a short note on how the single-store rule for intents was implemented.
