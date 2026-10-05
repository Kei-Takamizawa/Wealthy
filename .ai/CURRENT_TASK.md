# CURRENT TASK — Cycle 1.2: Domain v2 (targets, envelopes, consumption tax; wallets removed)

Task ID: WEALTHY-C1.2-DOMAIN-V2
Base: latest `main` (WealthyCore with PR #1 and PR #2 merged: incremental persistence, change-set undo, observable `LedgerCore` with `revision`/`reload()`, SHA-256 receipt matching, orphan cleanup, command provenance rules, createdAt ordering are DONE and must be preserved). Work on a new branch, open a PR. Do not touch the app target or any UI.

## 1. Goal
Reshape the WealthyCore domain to the product pivot: no wallets/assets, monthly targets with weekly/monthly evaluation, a separate child-expense envelope, and consumption-tax tracking. The persistence rework and the PR #1 review fixes were delivered in PR #2 (previous task WEALTHY-C1.1-STORE, written against the wallet model); do not redo them, but port them to the new model.

## 2. Background
- The app is a household budget app. Manual wallet/balance entry was judged too burdensome (no bank sync), so wallets, transfers, balances and balance adjustments are removed entirely.
- Instead the user sets a monthly overall target and optional per-category targets. Weekly allowance = sum of daily allowances. Staying within target is rewarded (reward UI is a later cycle; this cycle only provides the numbers).
- Tax: Japan only, JPY only for tax features. Voice words decide the rate (eat-in vs takeout). Apple Intelligence will only classify/propose; this core does all arithmetic, tax rounding and validation.
- Schema V1 is unshipped: change it in place, no migration code.

## 3. Requirements

### 3.1 Remove
Wallet, transfer, adjustment, derived balance, everything that references them (types, commands, queries, backup fields, tests). Entries no longer carry a wallet. Keep multi-currency entries, but targets and tax summaries are per currency.

### 3.2 Envelope (new)
- `Envelope` entity: id, kind (`household` | `child`), name, archived, createdAt. A default `household` envelope exists in a fresh ledger; exactly one `child` envelope may exist and is created on demand.
- Every entry belongs to exactly one envelope (default household). Child-envelope entries use child-envelope categories; household entries use household categories. Categories get `envelopeID`.
- Child envelope ships with preset categories (system keys, translated at display time): `child.food`, `child.education`, `child.clothing`, `child.medical`, `child.activities`, `child.support`, `child.other`. `child.support` means child-support payments the user pays to another person (e.g. monthly 養育費 to a separate household); it has `taxHint` exempt (no consumption tax) and is typically driven by a recurring rule (mark it `isFixedCost`; targets may still include it if the user sets `includeFixedCostsInTargets`). The child envelope therefore covers both spending on the child and support payments; no separate envelope type. Money received as child support is out of scope (not modeled). Users can add/rename/archive categories freely (system-key categories are renamed via `customName`, never deleted if used).
- Child envelope has its own targets and is evaluated separately from household targets. Household totals/targets never include child-envelope entries.

### 3.3 Targets (replaces Budget)
- `Target`: id, envelopeID, categoryID? (nil = overall), currency, amountMinor, effectiveMonth (LedgerMonth). Versioned by month: the target in force for month M is the latest with effectiveMonth <= M; changing a target creates/updates the version for the current month only and never rewrites history.
- Fixed costs: entries from recurring rules flagged `isFixedCost` are excluded from target evaluation by default; add a ledger setting `includeFixedCostsInTargets` (default false).
- Daily allowance for a day = monthly overall target for that day's month / number of days in that month (integer minor units; distribute the remainder one unit at a time from day 1 so the month sums exactly to the target). Weekly allowance = sum of daily allowances of the 7 days; weeks may span months. Week start is a ledger setting (default Monday).
- `TargetStatus` queries for week and month, per envelope/category/currency: allowance, spent (after fixed-cost rule), remaining, `loggedDays`, `noSpendDays`, `isRewardEligible` (spent <= allowance AND loggedDays >= 5 of the 7 days for weeks; for months, loggedDays >= 80% of days). A day counts as logged if it has >=1 entry or a NoSpendMark.
- `NoSpendMark`: id, envelopeID, day. Command `markNoSpend(day)` / `unmarkNoSpend(day)`. Adding an expense on a marked day removes nothing but the mark stops counting as "no spend" (the day stays logged).
- Remaining can be negative; never clamp. No streak counters in this cycle.

### 3.4 Consumption tax (new)
- `TaxRate` enum: `.standard` (10%), `.reduced` (8%), `.exempt` (0%, e.g. non-taxable). Stored on entries as `taxRate` (optional, nil = unknown/not applicable, e.g. non-JPY).
- Amounts are tax-inclusive. `TaxMath.taxPart(inclusiveMinor:, rate:)` = floor(amount * rate / (100 + rate)). Rounding rule is isolated in one function and documented so it can change (Japanese invoice rounding is per-invoice per-rate; per-entry floor is the accepted approximation here; document this limitation).
- `TaxRuleBook`: effective-dated data (not hard-coded in logic): list of (effectiveFrom day, standardRate, reducedRate). Seed: effective 2019-10-01, standard 10, reduced 8. Lookups take the entry's day. Do NOT add any speculative future rate change.
- `ServiceMode` on entries (optional): `dineIn`, `takeout`, `delivery`, `none`. Helper `TaxClassifier.suggestedRate(category tax hint, serviceMode, day)` is deterministic: food/drink category + `takeout`/`delivery` -> reduced; food/drink + `dineIn` -> standard; other categories -> standard; categories may carry a `taxHint` (`food`, `nonfood`, `exempt`). This is the code that validates whatever Apple Intelligence proposes later.
- `EntryDraft` (AI -> code boundary, plain Sendable value): amountMinor?, currency?, categoryID?, envelopeID?, day?, note?, serviceMode?, proposedTaxRate?, confidence fields optional. `DraftResolution`: either `.ready(EntryValue-to-add + preview)` or `.needsInput([MissingField])`. The resolver validates and fills deterministic defaults (tax rate via classifier when `proposedTaxRate` is nil or inconsistent with the rule book; flag disagreement in the result so the UI can tell the user).
- Queries: `taxSummary(month|week, envelope, currency)` -> total tax paid, per-rate breakdown, taxable-base per rate; `takeoutSavingEstimate(month)` -> for dine-in food entries, the tax that would have been saved at the reduced rate (computed from the rule book; state as an estimate and exclude entries with unknown mode).

### 3.5 Commands and preview
- Keep the command layer and the change-set undo from PR #2. Remove wallet commands; add envelope, target, noSpend commands; entry commands take envelope/serviceMode/taxRate.
- `CommandPreview` gains: target impact (week and month: remaining before -> after, for overall and the entry's category) and tax part of the entry. This feeds voice confirmation.
- Tighten commands: `addEntry`/`updateEntry` must not create or alter adjustment-like data (adjustments no longer exist), must not set `source` to recurring, must not set recurring links; those only come from the recurring engine.

### 3.6 Preserve Cycle 1.1 behavior on the new model
- Persistence stays incremental: new entities (Envelope, Target, NoSpendMark, tax fields) get per-model change sets, incremental validation, undo change sets (still 20 steps) and `revision`/`reload()` handling. Tests from PR #2 are adapted (not deleted) where wallets disappear; keep their intent (write counts, undo exactness, conflict detection, failure rollback).
- Keep: recurring back-fill through min(today, endDay), records-only restore hash matching, orphan receipt cleanup, addEntry/updateEntry provenance restrictions (now without adjustments), mostRecentEntry by createdAt.
- Performance: re-run the disk benchmark at 10,000 and 50,000 entries; do not regress add/update/delete/undo medians by more than 20% versus PR #2 numbers (36 ms add at 10k, 338 ms at 50k). Opening got slower in PR #2 (651 ms at 10k, 2,805 ms at 50k); do not make it worse, and if you find a cheap improvement (e.g. cheaper validation at load), report it. Report numbers for target/tax queries at 50k entries too (week/month status, taxSummary).

### 3.7 Decisions on open questions (final)
1. Tax rate before the first rule-book date (2019-10-01): the lookup returns nil ("unknown"), not an error and not extra historical data. Entries on such days keep `taxRate` nil; `taxSummary` excludes them from totals and reports `unknownTaxEntryCount`. Do not seed pre-2019 rates.
2. Month with no target: `TargetStatus` returns an explicit not-set state (e.g. `allowance`/`remaining` nil), never allowance = 0. `spent`, `loggedDays` and `noSpendDays` are still reported. `isRewardEligible` is false when not set. Use nil/optional values, not a magic zero, so a UI can show "no target set".
3. Fixed-cost classification is a snapshot: the entry stores its own `isFixedCost` (default false), copied from the rule when the recurring engine posts it (and settable on manually added entries). Changing a rule's flag affects only entries posted afterwards; deleting a rule leaves past entries untouched. Past weeks/months are never re-evaluated by later rule edits. Add the field to the schema, backup, change sets and tests.

## 4. Technical constraints
- Swift 6 strict concurrency, no external dependencies, no UI imports. Money is integer minor units. Days are `LedgerDay` civil dates.
- All new fields CloudKit-compatible (optional or defaulted, UUID references, no unique constraints), matching the existing schema rules.
- Backup format "wealthy-ledger" version 1 is changed in place (remove wallet data, add envelopes, targets, noSpendMarks, tax fields, settings).
- Reference data (rule book, preset child categories) lives in data tables, not scattered literals.
- Performance work is out of scope; do not change persistence internals beyond what the model change forces.

## 5. Files to change
`WealthyCore` package only (sources, tests, README of the package if it mentions wallets). Do not modify the app target or Xcode project; `Verification/README.md` may be updated.

## 6. Do not change
App UI, app target, existing app SwiftData models, the 8,583 existing verification checks, public naming style, license/README of the repository root.

## 7. Acceptance criteria
- No type, command, query, backup field or test refers to wallets, transfers, adjustments or balances.
- Child envelope entries never appear in household totals/targets, and vice versa (tested).
- Daily allowances sum exactly to the monthly target for 28/29/30/31-day months; weekly allowance across a month boundary is correct (tested, including negative remaining).
- Reward eligibility tested: within target but 4/7 logged days -> not eligible; 5/7 -> eligible; no-spend marks count as logged.
- Tax: 1,100 at 10% -> 100; 1,080 at 8% -> 80; 999 at 8% floor rule; rule-book lookup before/after 2019-10-01; takeout food -> reduced, dine-in food -> standard, non-food -> standard; resolver flags a proposed rate that disagrees with the classifier.
- takeoutSavingEstimate is deterministic and excludes unknown-mode entries (tested).
- All PR #2 regression tests still pass (adapted for wallet removal) and write-count tests cover the new entities.
- Backup round-trip (export -> import) preserves envelopes, targets, marks, tax fields.

## 8. Build and test
Run `sh Verification/verify_core.sh`, the opt-in disk benchmark, the simulator and Release app builds, and the existing verification scripts exactly as in PR #2. All must pass. Report actual output; do not summarize failures away.

## 9. GUI check
None (no UI in this cycle). Confirm the app still builds and launches on the simulator or device unchanged.

## 10. Report back (`.ai/LAST_REPORT.md`)
Branch and PR link; per-requirement done/not-done; test counts (new/existing) with commands run; any deviation from this spec and why; assumptions you made (especially tax rounding, week handling, fixed-cost flag); anything you found ambiguous.
