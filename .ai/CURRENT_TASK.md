# CURRENT TASK — Cycle 1: WealthyCore, the new ledger foundation

| | |
| --- | --- |
| Task ID | WEALTHY-C1-CORE |
| Cycle | 1 of the redesign. Cycle 0, design exploration, is running in parallel and is outside this task. |
| Written | 2026-10-05 by the designer/reviewer (Claude) for the implementer (Codex) |
| Base | `main` at `5bcea8d` (Release v0.1.1) |
| Save as | `.ai/CURRENT_TASK.md` (commit it). Write your report to `.ai/LAST_REPORT.md`. |

This document is self-contained. You do not need any earlier conversation to carry it out.

## 1. Goal

Build **WealthyCore**, a new, fully tested Swift package that becomes the single source of truth for Wealthy's bookkeeping. It contains the data model and ledger rules, commands with preview and undo, recurring entries, budgets, queries, and backup.

In this cycle the package is **added and linked, but no screen uses it yet**. The app must look and behave exactly as it does today. Cycle 2 will build the redesigned UI on top of this package, and Cycle 3 will add voice control.

## 2. Background

Wealthy is an iPhone/iPad app for household budgets and expenses. It uses SwiftUI and SwiftData, targets iOS/iPadOS 26.0+, and has no third-party dependencies.

The product vision is a playful, exciting design unlike ordinary budget apps, with rigorous record-keeping. It should be intuitive for anyone, and eventually **every operation should be possible by voice alone**.

Roadmap:

| Cycle | Content |
| --- | --- |
| 1 (this task) | The WealthyCore package: new schema, ledger, commands, undo, preview, recurring entries, budgets, queries, and backup. No UI change. |
| 2 | A new design system and redesigned screens built directly on WealthyCore. The app switches to the new store, and the legacy models and screens are removed. |
| 3 | Voice control, with two parts. In-app push-to-talk: on-device speech recognition, then on-device Apple Foundation Models turns the utterance into a WealthyCore command, the user confirms by voice or on screen, the command saves, and instant undo is available. App Intents let Siri and Shortcuts run the same commands. |

Design every public API so that Cycles 2 and 3 can call it unchanged. The UI, the voice mode, and App Intents must all go through the same commands.

## 3. Decisions already made by the product owner

- **Apple Intelligence stays required.** The existing launch gate (`WealthyApp.swift`, `service.isReady`) stays. WealthyCore itself must not depend on AI.
- **Legacy data is not migrated.** The new schema starts empty in a new store file. New code never opens, modifies, or deletes the legacy data or receipt images. The new backup format does not restore legacy backup files.
- **New feature: monthly budgets.** There is one overall budget plus optional budgets per category, each kept separately per currency.
- **Multiple currencies stay, with no automatic conversion.** Amounts are integers in ISO 4217 minor units.

## 4. Current problems this package fixes

All of these were verified in the current code.

1. **Relations by display name.**
   - `Expense.assetName`, `Expense.categoryName`, and `RecurringItem.assetName` reference wallets and categories by name.
   - Renaming a wallet rewrites every matching record in a loop (`AssetsView.swift`, `EditAssetView.save`).
   - Deleting a category or wallet leaves records pointing at a name that no longer exists. A later save then silently auto-creates a provisional wallet with that name.
   - Duplicate category names are allowed, and duplicate wallet names make saves fail (`ledger.chooseWallet`).
2. **Stored, overwritable balances.**
   - `Asset.balance` is changed on every save (`ExpenseLedger.swift`).
   - The wallet edit screen overwrites it directly, so the difference is never recorded and balances cannot be re-derived from history.
   - There is no transfer between wallets.
3. **Draft state in the store.**
   - Unconfirmed receipt drafts rely on `balanceApplied = false`.
   - Receipt images are written to Documents before the user confirms, and are never removed after a cancel or a delete.
4. **Business logic inside views.** These rules live in views, so no other entry point (voice, Siri, widgets) can reuse them:
   - receipt-to-draft logic (`DashboardView.swift`)
   - wallet merge and duplicate rules (`AssetsView.swift`)
   - recurring posting (`ContentView.swift`)
5. **Language-dependent data.**
   - Default categories are stored with Japanese names (食費 and so on, in `ContentView.setupInitialData`).
   - Model defaults are `"現金"` and `"未分類"`.
   - Recurring entries get the fixed-cost category name in whatever display language is active, even for income.
   - Income entries share the expense category list.
6. **Coarse recurring logic.**
   - Rules are monthly only and are processed only when the app opens.
   - At most one occurrence is posted, even after several missed months.
   - Entries are dated on the processing day instead of the due day.
   - A rule for day 29–31 is skipped in shorter months.
   - Rules cannot be edited.
7. **Silent currency fallback.** `CurrencyPolicy.normalizedCode` silently turns unsupported codes into JPY.

## 5. Requirements

### 5.1 Package and project setup

- Create a local Swift package at the repository root: `WealthyCore/` containing `Package.swift`, `Sources/WealthyCore/`, and `Tests/WealthyCoreTests/`.
- Platforms: iOS 26, the same as the app. Add whichever macOS version lets `swift test` run on the development Mac without a simulator or device.
- Use Swift 6 language mode with strict concurrency. Tests use Swift Testing (`import Testing`).
- The library may use only Foundation, SwiftData, and ImageIO (ImageIO is needed to validate backup images). No SwiftUI, UIKit, FoundationModels, Vision, or third-party packages.
- Add the package to `Wealthy/Wealthy.xcodeproj` as a local package. Link the `WealthyCore` library to the `Wealthy` app target, so the iOS build proves it compiles. **No existing app source file imports it in this cycle.**
- The app target builds in Swift 5 mode with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and approachable concurrency. In Cycle 2 the app must be able to call WealthyCore's public API without workarounds.

### 5.2 Data model (new schema, version 1)

Principles. These are requirements.

- **Stable IDs.** Every persistent model has a stable `id: UUID`, assigned at creation and preserved through backup, restore, and undo. In Cycle 3 these IDs will also back App Intents entities.
- **No name references.** Models reference each other through SwiftData relationships or UUIDs, never by display name.
- **CloudKit-compatible schema.** iCloud sync must be addable later without a schema rewrite, although sync itself is out of scope. That means:
  - no `@Attribute(.unique)`
  - every stored property is optional or has a default value
  - every relationship is optional and has an inverse
  - no `.deny` delete rules and no ordered relationships

  Enforce uniqueness in the command layer instead.
- **Versioned schema.** Declare the schema as a `VersionedSchema` (V1) with a `SchemaMigrationPlan`, so later cycles can evolve it safely.
- **Naming.** Do not name a model `Transaction`; it collides with `SwiftUI.Transaction` in files that import both.
- **Appearance as keys.** Store appearance as stable keys (a color token name, an SF Symbol name), not raw hex values. The redesigned UI will map keys to its own palette.

Models. Field names are suggestions; their meaning is a requirement.

**Wallet** has no stored balance. Fields:
- `id`, `name`
- `kind`: cash, bank account, credit card, e-money/prepaid, or other
- `currencyCode`: ISO 4217, **immutable after creation**
- `paymentMethodKey`: optional. One of the keys in `ReceiptPaymentPolicy.methods` or `custom:<name>`; used later to match receipts to wallets.
- `colorKey`, `iconKey`, `sortOrder`, `isArchived`, `createdAt`
- `isProvisional`: the wallet was created automatically and its real balance is not confirmed yet

**Category**:
- `id`
- `kind`: expense or income. Income gets its own categories instead of sharing the expense list.
- `systemKey`: optional. Built-in categories store a language-independent key, and the app localizes it at display time.
- `customName`: optional; set when the user creates or renames a category
- `iconKey`, `colorKey`, `sortOrder`, `isArchived`
- "Uncategorized" is not a stored category; it is the absence of one.

**LedgerEntry**:
- `id`
- `kind`: expense, income, transfer, or adjustment
- `amount`: a positive integer in minor units. Adjustments also store a direction (increase or decrease).
- `currencyCode`
- `day`: the calendar day the entry belongs to (see rule 10 in 5.3), plus `timestamp` for ordering within a day
- `wallet`: the source for expense and transfer, the target for income and adjustment
- `counterpartWallet`: the transfer destination
- `category`: optional, expense and income only
- `title` (merchant or description) and `note`
- `source`: manual, receipt, voice, recurring, openingBalance, or reconciliation
- `reviewFlags`: a set of reason codes, for example paymentMethodUncertain, dateFromCaptureTime, amountUncertain, multipleWalletMatches. "Needs review" means the set is not empty.
- `receipt`: optional attachment
- an optional link to the recurring rule and occurrence day that produced the entry
- `createdAt`, `updatedAt`

**ReceiptAttachment**: `id`, `fileName` (the image in the new receipts directory, see 5.9), and `capturedAt`.

**RecurringRule**:
- `id`, `title`
- `kind`: expense, income, or transfer
- `amount`, `currencyCode`
- `wallet`, `counterpartWallet` (transfers only), `category` (optional)
- schedule: monthly on day 1–31, weekly on a weekday, or yearly on a month and day
- `startDay`, optional `endDay`, `isPaused`, the last posted occurrence day, `createdAt`

**Budget**: `id`, `currencyCode`, `category` (nil means the overall budget for that currency), and `monthlyAmount` (positive, minor units). Allow at most one overall budget per currency and one budget per currency and category pair.

**PointCard**: `id`, `name`, `memberNumber`, `points` (an integer ≥ 0, never mixed with money), optional `expiryDay`, `colorKey`, and `sortOrder`.

These stay outside the core schema in this cycle: chat history, display language, and enabled/default currencies. They stay in the app, and Cycle 2 decides where they finally live.

### 5.3 Ledger rules (invariants)

1. **Derived balances.** A wallet's balance is computed from its entries:
   - income adds the amount
   - expense subtracts it
   - transfer subtracts it from the source and adds it to the destination
   - adjustment adds or subtracts according to its direction

   An opening balance is an adjustment with source `openingBalance`, created only when it is not zero. It is dated on the wallet's creation day unless another day is given.
2. **No stored balance.** If you add a cache for performance, it must be rebuildable from entries, and tests must prove it equals the derived value.
3. **Amount limits.** `amount` is greater than 0 and fits in `Int`. All aggregation is overflow-safe (use `Decimal` or checked arithmetic). Totals larger than `Int.max` must still be correct.
4. **Currency consistency.** An entry's currency equals its wallet's currency. A transfer needs two different wallets with the same currency. Cross-currency transfers are out of scope; reject them with a specific error.
5. **Categories by kind.** Expense and income entries may have a category of the matching kind. Transfers and adjustments never have a category.
6. **Archiving.** Archived wallets and categories keep their history and still count in balances, totals, and historical queries. They reject new entries and new assignments.
7. **No stored drafts.** Unconfirmed drafts, such as a scanned receipt still under review, are never stored as ledger entries. They exist only as values until a command saves them. There is no `balanceApplied` concept.
8. **Unique names.** Wallet names are unique across all currencies among non-archived wallets. Custom category names are unique per kind among non-archived categories. Comparison uses the app's normalization (trimmed, width-insensitive, case-insensitive; see `AppLocalization.normalized`). Archived names may be reused. Comparing against localized built-in category names is the app's job.
9. **Atomic commands.** Every command either saves all of its changes, or saves none and leaves no partial state.
10. **Day semantics.**
    - Each entry stores its calendar day explicitly: the local date when it was recorded, or the printed receipt date.
    - Calendars, monthly periods, and budgets group entries by this day. An entry never moves to another day or month when the device's time zone changes.
    - Recurring occurrences and budget periods also use days.

### 5.4 Commands: one entry point for every change

Every change is a **command**: a `Sendable`, `Codable` value whose parameters are IDs and plain values, run through a single entry point. The UI, the voice mode, and App Intents will all use these commands.

Required commands:

**Wallets**
- create, with an optional opening balance
- update name, kind, appearance, payment method key, or order. Currency cannot change.
- **reconcile**: the user states the actual balance on a day. Create one adjustment for the difference from the derived balance at the end of that day, or none if the difference is zero, and clear `isProvisional`. This replaces overwriting a balance.
- archive, unarchive
- delete: allowed only when the wallet has no entries other than its opening balance. Otherwise fail with a specific error that suggests archiving.

**Entries**
- add expense, add income, add transfer
- update any field, with the same validation as creation, including a change of wallet or kind
- delete
- mark reviewed, which clears the review flags

**Categories**
- create, optionally with a `systemKey`
- update: rename, appearance, order
- archive, unarchive
- delete: entries keep all their other data and become uncategorized, budgets for that category are removed, and recurring rules drop the category

**Recurring rules**: create, update, pause, resume, delete. On delete, posted entries remain and their rule link is cleared.

**Budgets**: set (create, or change the amount for a currency and optional category), remove.

**Point cards**: create, update, delete.

**Preview.** Any command can be validated and previewed without saving.
- On failure, the preview returns the validation errors.
- On success, it returns the before and after balances of every affected wallet. For changes to expenses, it also returns the before and after remaining amount of every affected budget.
- A preview never modifies the store.

The preview powers the confirmation card in the redesigned UI and the voice mode, for example "PayPay ¥3,200 → ¥2,550 · Food budget left ¥12,000 → ¥11,350".

**Result.** Running a command returns the affected IDs and the same before/after summary. Results and previews are `Sendable` value types, not live model objects.

**Undo.**
- Keep a bounded in-memory history of at least 20 steps for the current app session.
- Undo restores the exact prior state: the same IDs, field values, and relationships. That includes a deleted entry's receipt link and a deleted category's former assignments.
- Undo with an empty history does nothing.
- Recurring auto-posting (5.6) and backup restore (5.8) cannot be undone and are not recorded in the history. A restore clears the history.
- If data has changed outside the history so that the inverse no longer applies, undo fails with a specific error and changes nothing. For example, undoing a wallet's creation after recurring posting has added entries to that wallet.

**Receipt files.**
- Core stores image data (`Data`) as an attachment file.
- Deleting an entry does not delete its image file right away, so undo can restore it.
- Provide a cleanup function that deletes files in the new receipts directory that no entry references, including images saved for drafts that were cancelled. It is meant to run when no undo history exists, for example at app launch.

**Execution context.** Commands may run on the main actor or on a single model actor, your choice, as long as they are correct under Swift 6 strict concurrency.

### 5.5 Queries (read side)

These are the read functions the current screens, the AI summaries, and the voice mode need, covering existing behavior plus budgets. They must be pure and tested. Signatures are up to you; return `Sendable` values.

1. **Balances.**
   - Each wallet's balance, now and as of the end of a given day.
   - The total balance per currency. Today's home header shows this per enabled currency.
2. **Entry lists.**
   - Filters: day range, wallet, category (including uncategorized), kind, currency, needs-review, and text search on title and note.
   - Sorted by day descending, then timestamp descending, with an optional limit.
   - This also covers the calendar's single-day detail and the "20 most recent entries" in the AI chat context.
3. **Period summary per currency.** Income total, expense total, net, and the number of income and expense entries. Transfers and adjustments are excluded from income and expense. Today's AI chat context and money tip use these figures for the current month.
4. **Daily totals for a month per currency.** Income and expense for each day. These feed the calendar day cells and the analysis bar chart.
5. **Category breakdown for a period and currency.**
   - Expenses by default, income optionally.
   - Uncategorized is its own bucket, sorted by amount in descending order.
   - Include each bucket's amount in the previous period, for month-over-month comparison.
6. **Per-wallet totals.** Income and expense for a period or for all time. Today's wallet card shows these on its back.
7. **Budget status for a month and currency.** For the overall budget and each category budget: budget, spent, remaining, and ratio.
8. **Upcoming recurring occurrences** within the next N days.
9. **Most recent entry**, optionally filtered by source. This is for "edit or undo the last one".
10. **Currencies in use** anywhere in the data. After a restore, today's app adds these to the enabled currencies.

### 5.6 Recurring engine

- A monthly rule for day N posts on the last day of shorter months: day 31 becomes Feb 28 or 29, or Apr 30.
- A yearly rule for Feb 29 posts on Feb 28 in non-leap years. A weekly rule posts on its weekday.
- One call, given an injected "today" and calendar, posts **every** missed occurrence up to and including today.
  - Posting starts from the later of the start day and the day after the last posted occurrence.
  - Each entry is dated on its own occurrence day.
  - Future occurrences are never posted.
  - No occurrence is posted twice, including across relaunches.
- Posted entries have source `recurring` and link to their rule and occurrence day. Deleting a posted entry does not cause it to be posted again.
- A paused rule posts nothing. Occurrences that fall while a rule is paused are skipped, not filled in on resume. A rule past its end day posts nothing.
- An occurrence that fails validation, for example because its wallet is archived, is skipped and returned in the result with its error. It does not block other rules or later occurrences.
- The call returns the posted entries and the failures. Today's app shows them in an alert.

### 5.7 Budgets

- The budget period is the calendar month of the entry's day; months start on day 1. Compute periods in one place, so a configurable start day (for example payday) can be added later.
- Spent is the sum of expense entries in the budget's currency whose day falls in the month. For a category budget, only that category's entries count.
  - Income, transfers, and adjustments never count.
  - Uncategorized expenses count only toward the overall budget.
- Remaining equals budget minus spent, and may be negative (over budget).
- Category budgets are independent of the overall budget. Their sum may differ from the overall amount, and nothing is allocated automatically.

### 5.8 Backup format (new)

- **Format.** A versioned JSON archive with a **distinct format identifier and version**, for example `"format": "wealthy-ledger", "version": 1`.
  - Legacy archives from `BackupArchiveCodec.swift` have no identifier, only `schemaVersion` 1–4. They must be recognized and rejected with a specific "legacy backup not supported" error.
- **Contents.**
  - Records: wallets, categories, entries, receipt attachment metadata, recurring rules, budgets, point cards, export date, and app/core version.
  - Optionally the receipt images. Each file is embedded once, even when several entries share it.
- **Excluded:** chat history, app settings, undo history.
- **Size check.** Before exporting, the caller can get the count and total size of referenced images. Today's UI shows these.
- **Import replaces all data.**
  1. Decode and fully validate first:
     - format and version
     - supported currency codes, positive amounts, and unique IDs
     - every reference resolvable, and entry and wallet currencies consistent
     - image file names, using the existing safe-filename rule in `BackupArchiveCodec.swift`: not empty, at most 255 UTF-8 bytes, not `.` or `..`, and only Unicode letters/digits plus `-`, `_`, `.`
     - images: each must be a fully decodable single-frame image, checked with ImageIO as today
  2. Only after validation succeeds, replace the store contents in one save and write the images.
  3. On any failure, existing data and files stay unchanged.
- **Round trip.** Exporting and then importing into an empty store yields identical data: IDs, fields, relationships, derived balances, and image bytes.

### 5.9 Store, files, and seed data

- The new SwiftData store lives in a **new file location**, for example `Application Support/WealthyLedger.store`. New code must never open, modify, or delete the legacy default store or the legacy receipt images in Documents.
- Receipt images go in a new directory, separate from the legacy images.
- The store factory also supports an in-memory configuration for tests and SwiftUI previews.
- On first creation of the new store, seed default categories by `systemKey`. Seeding must not create duplicates if it runs again.
  - **Expense:** the six current defaults plus fixed costs, using the existing translation keys from `AppLocalization.standardCategoryKeys`: `catFood`, `catTransport`, `catDaily`, `catHobby`, `catClothing`, `catOthers`, `categoryFixedCosts`. The other standard keys (`categoryBooks`, `categoryHomeDIY`, `categoryHealthcare`, `categoryShopping`) are created on demand by `systemKey`, for example by the receipt flow.
  - **Income:** new keys `incomeSalary`, `incomeBonus`, `incomeOther`. Their translations are added in Cycle 2, when the UI first shows them.
- No default wallet is seeded. Today's app does not seed one either.

### 5.10 Errors

- Use typed errors that carry no user-facing strings. The app will localize them in Cycle 2, and the voice mode will speak them in Cycle 3.
- Each error identifies its cause precisely: which field, which wallet or category ID, or which backup record.

### 5.11 Currency

- Copy, do not move, the ISO 4217 minor-unit table and the parsing and formatting logic WealthyCore needs from `Wealthy/Wealthy/CurrencyPolicy.swift`.
- Unlike the legacy `normalizedCode`, WealthyCore must **reject** unsupported codes instead of falling back to JPY.
- The app's own `CurrencyPolicy.swift` stays untouched in this cycle. The duplication will be removed in Cycle 2, when the UI moves to WealthyCore.

## 6. UI/UX requirements

- **No user-visible change in this cycle.** Every current screen keeps using the legacy models and store.
- Build the future UX into the API: preview before saving, structured results, multi-step undo, review flags, entry source, and ID-based parameters. These are the building blocks of the redesigned confirmation cards and of voice operation, such as "record it", "undo that", or "how much food budget is left?".

## 7. Technical constraints

- Xcode 27 (iOS 26 SDK or later). The app deployment target stays iOS 26.0.
- Swift 6 language mode inside WealthyCore. The app target's build settings do not change.
- No third-party dependencies anywhere.
- Code and comments in English. Write concise doc comments for the public API and for rules that are not obvious. Do not add line-by-line comments.
- All date logic takes an injectable calendar, time zone, and "today/now", so tests are deterministic.
- Keep the library free of UI and AI frameworks (see 5.1).
- SwiftData predicates cannot always filter on `Codable` enum properties. Storing raw values is fine if it keeps queries working.

### Implementation order and milestones

Work in this order, and keep every milestone green before starting the next one. If you cannot finish, stop at the last completed milestone and report exactly what remains.

1. **M1**: package setup, schema V1, store factory, seeding, ledger rules, wallet/entry/category commands, typed errors.
2. **M2**: preview, results, undo, receipt attachments and orphan cleanup.
3. **M3**: recurring engine, budgets, queries.
4. **M4**: backup format, Xcode project linking, verification script and docs.

## 8. Files to add or change

| Action | Path |
| --- | --- |
| Add | `WealthyCore/**` (package, sources, tests) |
| Add | `Verification/verify_core.sh`: runs the package tests from the repository root, in the style of the existing scripts |
| Add | `.ai/CURRENT_TASK.md` (this document) and `.ai/LAST_REPORT.md` (your report) |
| Change | `Wealthy/Wealthy.xcodeproj/project.pbxproj`: the local package reference and link only |
| Change | `Verification/README.md`: add one section on running the core tests |

## 9. Do not change

- Anything under `Wealthy/Wealthy/`: app sources, translations, `Info.plist`, assets, entitlements.
- The legacy SwiftData models and store, the legacy receipt images, and the legacy backup code.
- The bundle identifier, signing, the deployment target, and the Apple Intelligence gate.
- The README files, since nothing visible changes.
- The behavior of the existing verification scripts.
- Do not push directly to `main`. Work on a branch and open a pull request.

## 10. Acceptance criteria

1. `swift test` in `WealthyCore/` passes on the development Mac, and every scenario in the table below has at least one test.
2. The existing unsigned app builds succeed with the package linked (commands in section 11).
3. WealthyCore builds with zero warnings, including Swift 6 concurrency diagnostics.
4. `git diff --stat main...HEAD -- Wealthy/Wealthy/` prints nothing.
5. The existing verification scripts still pass (section 11).
6. `.ai/LAST_REPORT.md` exists and contains everything listed in section 13.

Required test scenarios:

| # | Scenario |
| --- | --- |
| L1 | The derived balance is correct for every entry kind, including an opening balance. A zero opening balance creates no entry. |
| L2 | A transfer moves money between two wallets. Same-wallet and cross-currency transfers are rejected. |
| L3 | Reconcile creates exactly one adjustment equal to the difference, none for a zero difference, and clears `isProvisional`. |
| L4 | A currency mismatch is rejected. An unsupported currency code is rejected, with no JPY fallback. |
| L5 | Amounts of zero, negative amounts, and overflowing amounts are rejected. Totals above `Int.max` are computed correctly. |
| L6 | An archived wallet rejects new entries but keeps its history and balance. |
| L7 | Changing an entry's amount, wallet, or kind gives correct balances for both the old and the new wallet. |
| L8 | Deleting a wallet that has entries is rejected. Deleting one that has only an opening balance succeeds. |
| L9 | A category of the wrong kind is rejected. Transfers and adjustments cannot have a category. |
| L10 | Deleting a category leaves its entries uncategorized, removes its budgets, and clears it from recurring rules. |
| L11 | Names are unique among active wallets and among active categories, after normalization (full-width/half-width, case, surrounding spaces). Archived names can be reused. |
| L12 | An injected save failure leaves no partial changes. |
| U1 | Undo restores the exact prior state after add, update, delete (same ID, fields, and receipt link), transfer, reconcile, and category delete. |
| U2 | Multi-step undo works in reverse order. Undo with an empty history does nothing. Recurring posting and restore are not recorded in the history. An undo whose inverse no longer applies fails cleanly. |
| U3 | A preview returns before/after balances and the budget impact, and leaves the store unchanged. |
| R1 | A monthly rule for day 31 posts on Jan 31, Feb 28 (2027), Feb 29 (2028), and Apr 30. |
| R2 | After three missed months, three entries are posted on the correct days. A second run posts nothing. |
| R3 | Future occurrences are never posted. A paused rule posts nothing, resuming does not fill in missed occurrences, and the end day is respected. |
| R4 | A yearly rule for Feb 29 posts on Feb 28 in non-leap years. A weekly rule posts on its weekday. |
| R5 | Deleting a posted entry does not cause it to be posted again. An invalid occurrence is reported and does not block other rules. |
| B1 | Overall and category spending are correct. Income, transfers, adjustments, and other currencies are excluded. Uncategorized expenses count only toward the overall budget. |
| B2 | An entry recorded at 23:30 on the last day of a month stays in that month when evaluated in a different time zone. |
| Q1 | Period summaries exclude transfers and adjustments and count entries correctly. Daily totals cover every day of a month. The category breakdown includes an uncategorized bucket and the previous month's amounts. Per-wallet totals and currencies in use are correct. |
| K1 | A backup round trip, with and without images, gives identical IDs, fields, relationships, balances, and image bytes. An image shared by several entries is stored once. |
| K2 | Import rejects legacy schema 1–4 archives, malformed JSON, unknown versions, dangling references, unsupported currencies, unsafe file names, and undecodable images. In every case, existing data and files are unchanged. |
| S1 | Seeding is idempotent. The new store path differs from the legacy store. Legacy files in a temporary directory are untouched. |
| S2 | Orphan cleanup removes only unreferenced receipt files. |

## 11. Builds and tests to run

```sh
# New package tests (from the repository root)
sh Verification/verify_core.sh          # or: (cd WealthyCore && swift test)

# App builds with the package linked
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build

# Existing checks must still pass
python3 Verification/verify_receipt_ocr.py
sh Verification/verify_backup.sh
sh Verification/verify_localization.sh
sh Verification/verify_payments.sh
sh Verification/verify_migration.sh
sh Verification/verify_currency.sh
sh Verification/verify_policies.sh
sh Verification/verify_money_tip.sh
```

Also measure, as a report item and not a pass/fail gate: the time to compute all wallet balances, one monthly summary, and one category breakdown with 10,000 synthetic entries across 10 wallets on the Mac.

## 12. GUI checks

There is no new UI. On the iPhone used for earlier checks, with Apple Intelligence ready, install the build over the existing app and confirm the following.

1. The app launches and shows the same screens as before, and the existing records are still visible.
2. Adding and then deleting one expense in the current UI works, and updates the wallet as before.
3. Nothing in the UI has changed.

## 13. Report to write in `.ai/LAST_REPORT.md`

1. A summary, and which milestones (M1–M4) are complete.
2. The pull request link and branch name.
3. The package layout as a file tree, and an overview of the public API: models, commands, preview and result types, queries, backup API, errors.
4. The final schema: each model with its fields and types.
5. Every deviation from this document, with the reason.
6. Test results:
   - the command used
   - the number of tests passed and failed, and the duration
   - which test names cover each scenario ID (L1 to S2)
7. Build results, and the result of each existing verification script.
8. The 10,000-entry performance measurements.
9. GUI check results with the device model and iOS version, or "not run" with the reason.
10. Known issues, risks, and open questions for the designer.

## Additional user instruction — 2026-10-05

英語以外のreadme.mdも消してください。

This explicitly extends Cycle 1 to remove the ten translated root README files. Keep the English README.md and Verification/README.md; remove obsolete links to the deleted translations from the English README.
