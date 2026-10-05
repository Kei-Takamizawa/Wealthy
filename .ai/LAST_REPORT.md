# WealthyCore — Cycle 1 implementation report

- Task ID: WEALTHY-C1-CORE
- Cycle: 1
- Date: 2026-10-05 JST
- Status: COMPLETED (implementation and required verification); Git delivery recorded below.
- Branch: `codex/wealthy-c1-core`
- Base: `main` / `origin/main` at `5bcea8d35b289e0f37f2a90164745742772eb526`
- Pull request: pending creation after the source commit and branch push.

## Outcome and milestones

The separate WealthyCore package implements the new ledger, commands, previews, 20-step undo, receipts, recurring rules, budgets, queries, point cards, and versioned JSON backup. It is linked into the app. No app source imports it, and the existing UI continues to use the legacy store.

| Milestone | Status | Green gate |
| --- | --- | --- |
| M1: package, V1 schema/store/seeds, rules, wallet/entry/category commands | COMPLETED | 19 tests, 0 failures, 0 warnings |
| M2: preview/results, undo, attachment writes and cleanup | COMPLETED | 28 tests, 0 failures, 0 warnings |
| M3: recurring, budgets, queries | COMPLETED | 46 tests, 0 failures, 0 warnings |
| M4: backups, project linking, script/docs, final regression verification | COMPLETED | 62 tests, 0 failures, 0 warnings; both unsigned builds and physical-device test PASS |

There is no stored balance or persisted draft. Integer entry amounts are accumulated using Decimal. All references are UUIDs. Days are explicit Gregorian civil dates; calendar arguments supply the time zone for conversion/arithmetic without moving stored days.

## Changes and package layout

```text
WealthyCore/
  Package.swift
  Sources/WealthyCore/Backup.swift
  Sources/WealthyCore/Commands.swift
  Sources/WealthyCore/Currency.swift
  Sources/WealthyCore/Files.swift
  Sources/WealthyCore/Planning.swift
  Sources/WealthyCore/Queries.swift
  Sources/WealthyCore/Results.swift
  Sources/WealthyCore/Schema.swift
  Sources/WealthyCore/Store.swift
  Sources/WealthyCore/Values.swift
  Tests/WealthyCoreTests/BackupTests.swift
  Tests/WealthyCoreTests/EdgeTests.swift
  Tests/WealthyCoreTests/FoundationTests.swift
  Tests/WealthyCoreTests/LedgerTests.swift
  Tests/WealthyCoreTests/QueryTests.swift
  Tests/WealthyCoreTests/RecurringTests.swift
  Tests/WealthyCoreTests/UndoTests.swift
```

Added `.ai/CURRENT_TASK.md`, this report, and `Verification/verify_core.sh`. Updated `Verification/README.md` with the package test instructions. Changed `Wealthy/Wealthy.xcodeproj/project.pbxproj` only to reference and link the local package. Removed ten root translations: `README.ar.md`, `README.es.md`, `README.fr.md`, `README.hi.md`, `README.id.md`, `README.ja.md`, `README.ko.md`, `README.pt.md`, `README.ru.md`, `README.zh-Hans.md`. The English `README.md` remains; its obsolete translation links were removed.

The three pre-existing modified `.DS_Store` files and the user's Xcode-project blank-line changes are preserved outside the commits. No build products, caches, images, videos, or private device screenshots are committed.

## Public API

- `WalletValue`, `CategoryValue`, `EntryValue`, `ReceiptValue`, `RuleValue`, `BudgetValue`, `PointCardValue`, and `LedgerState` are detached Codable/Sendable values. `LedgerDay`, `LedgerPeriod`, and the domain enums describe days and stable reason/type keys.
- `LedgerStore(inMemory:directory:seed:)` provides isolated memory/disk storage. Disk defaults are Application Support/`WealthyLedger.store` and `WealthyLedgerReceipts/`. Ten default categories are seeded by system key, with no wallet. Low-level replacement, save-failure injection, and the ModelContainer are internal.
- `@MainActor LedgerCore` is the mutation boundary. `run(_:now:)`, `preview(_:now:)`, `undo(now:)`, `snapshot()`, `undoCount`, `clearUndoHistory()`, and `cleanupOrphanReceipts()` expose commands and transferable results.
- `LedgerCommand` is Codable/Sendable: create/update/reconcile/archive/delete wallet; add/update/delete/review entry; create/update/archive/delete category; create/update/pause/resume/delete recurring rule; set/remove budget; create/update/delete point card. Archive and pause Boolean commands cover both directions. The generic entry command covers expense, income, and transfer with kind-specific validation.
- `CommandResult(affectedIDs, summary)` and `CommandPreview(errors, summary)` contain `WalletImpact` and monthly `BudgetImpact` values. A preview shares execution validation and writes neither records nor files. Before/after nil values indicate creation or removal.
- Undo stores a bounded 20-step in-memory history. It restores exact UUIDs/values/references, preserves unrelated external changes, and refuses conflicting inverses. Failed commands do not alter history. Recurring posting is excluded; restore clears history only on success.
- `ReceiptInput` keeps image bytes and metadata outside persistence until confirmation. `ReceiptFiles` validates single-frame complete images, performs rollback-safe writes/removals, and cleans only unreferenced direct regular files. Deleted entries retain files for undo.
- `postRecurring(through:now:)` returns `RecurringResult(posted, failures)`. Each failure identifies rule/day/error. Persisted processed cursors prevent retry/repost, and pause intervals skip only paused days while retaining earlier missed occurrences.
- Pure `LedgerQueries`: `walletBalances`, `totalBalances`, `entries`, `periodSummary`, `dailyTotals`, `categoryBreakdown`, `walletTotals`, `budgetStatuses`, `upcoming`, `mostRecentEntry`, `currenciesInUse`. `LedgerPeriod.month` centralizes budget/month boundaries; `budgetSpent` is shared with previews. Upcoming means tomorrow through the next N days.
- `LedgerBackup.size(in:)`, `export(_:includeImages:now:appVersion:coreVersion:)`, and `restore(_:into:)` use `LedgerBackupArchive`, `BackupImage`, and `ImageSize`. Format is `wealthy-ledger`, version 1, with an explicit image-inclusion flag. Numeric Date encoding preserves fractional timestamps. Legacy schemas 1–4 are rejected. All records and images are validated before writes. Records-only restore removes colliding omitted image filenames so stale bytes cannot become attached to imported entries; unrelated old images remain for explicit orphan cleanup.
- `CoreCurrency` copies the existing 155-code table and exact parsing/formatting behavior while throwing for unsupported currency codes. It never falls back to JPY.
- `CoreError` identifies invalid fields/record IDs, missing/dangling references, duplicate IDs/names, unsupported or mismatched currencies, transfer restrictions, archived assignments, category kinds, wallet history, undo conflicts, persistence/file failures, legacy/invalid/versioned backup errors, unsafe filenames, invalid images, and cleanup attempted with undo history. It contains no localized UI messages.

## Final persisted V1 schema

`WealthySchemaV1` contains seven models and `WealthyMigrationPlan` declares V1 with no migration stage yet. Every persisted property is optional or has a default. There are no SwiftData relationships, ordered relationships, unique attributes, or deny rules: UUID reference fields are used as explicitly permitted by the task. The schema follows the stated [Apple CloudKit compatibility restrictions](https://developer.apple.com/documentation/swiftdata/syncing-model-data-across-a-persons-devices); actual synchronization is disabled and was not tested.

`recordOrder` preserves detached-array ordering for exact undo and backup round trips; it is an integer attribute, not an ordered relationship. Raw string fields map to the domain enums through validated decoding. Stored days and periods are Codable civil-date values.

### Wallet

`recordOrder: Int`, `id: UUID`, `name: String`, `kindRaw: String`, `currencyCode: String`, `paymentMethodKey: String?`, `colorKey: String`, `iconKey: String`, `sortOrder: Int`, `isArchived: Bool`, `createdAt: Date`, `isProvisional: Bool`.

### Category

`recordOrder: Int`, `id: UUID`, `kindRaw: String`, `systemKey: String?`, `customName: String?`, `iconKey: String`, `colorKey: String`, `sortOrder: Int`, `isArchived: Bool`.

### LedgerEntry

`recordOrder: Int`, `id: UUID`, `kindRaw: String`, `amount: Int`, `directionRaw: String?`, `currencyCode: String`, `day: LedgerDay`, `timestamp: Date`, `walletID: UUID`, `counterpartWalletID: UUID?`, `categoryID: UUID?`, `title: String`, `note: String`, `sourceRaw: String`, `reviewFlagsRaw: [String]`, `receiptID: UUID?`, `recurringRuleID: UUID?`, `occurrenceDay: LedgerDay?`, `createdAt: Date`, `updatedAt: Date`.

### ReceiptAttachment

`recordOrder: Int`, `id: UUID`, `fileName: String`, `capturedAt: Date`.

### RecurringRule

`recordOrder: Int`, `id: UUID`, `title: String`, `kindRaw: String`, `amount: Int`, `currencyCode: String`, `walletID: UUID`, `counterpartWalletID: UUID?`, `categoryID: UUID?`, `schedule: RecurringSchedule`, `startDay: LedgerDay`, `endDay: LedgerDay?`, `isPaused: Bool`, `lastPostedDay: LedgerDay?`, `lastProcessedDay: LedgerDay?`, `pauseStartedDay: LedgerDay?`, `pausedPeriods: [LedgerPeriod]`, `createdAt: Date`.

### Budget

`recordOrder: Int`, `id: UUID`, `currencyCode: String`, `categoryID: UUID?`, `monthlyAmount: Int`.

### PointCard

`recordOrder: Int`, `id: UUID`, `name: String`, `memberNumber: String`, `points: Int`, `expiryDay: LedgerDay?`, `colorKey: String`, `sortOrder: Int`.

## Implementation choices and deviations

1. The later user instruction explicitly extended scope to delete non-English README files. Broken translation navigation was consequently removed from the remaining English README; its product content was not rewritten.
2. Platforms are iOS 26 and macOS 26; development used macOS 27.0.1. Swift 6 language mode provides strict concurrency. MainActor execution is one of the task's allowed choices and matches the Swift 5 app's isolation.
3. UUID reference fields, detached value APIs, and raw enum keys are permitted choices. The extra internal recurring fields `lastProcessedDay`, `pauseStartedDay`, and `pausedPeriods` preserve skipped failures/pauses without falsely labeling skipped dates as posted occurrences.
4. Wallet deletion also refuses a live recurring-rule reference to prevent a dangling wallet; archive remains available. Expired rules post nothing when today is after endDay, following the document's explicit wording. Resume's pause interval is inclusive of its civil day.
5. The GUI check used XCTest UI automation and a temporary project instead of a native desktop Computer Use surface. The test targeted the actual production bundle `com.harrison.Wealthy`, used no preference/launch overrides, and did not run the existing destructive DeviceTest suite. Only a uniquely named one-yen expense was created and removed.
6. No required feature was omitted. No app source file, app translation catalog, asset, entitlement, signing setting, deployment target, gate, existing verification script, or legacy backup implementation was changed.

## Tests and required scenario coverage

Environment: Apple M4, 24 GiB RAM, macOS 27.0.1, Xcode 27.0 (27A266a), Swift 6.4, iOS/Simulator SDK 27.0.

Final command: `sh Verification/verify_core.sh` (runs `swift test --package-path WealthyCore`). **PASS: 62 tests in seven suites, 0 failed, 0 compiler warnings.** Reported test duration: **0.871 seconds**; incremental build: **0.98 seconds**. Timings are the tool-reported test/build durations, not total process startup time.

| Scenario | Test functions |
| --- | --- |
| L1 | `LedgerTests.derivedBalancesAndOpening` |
| L2 | `LedgerTests.transferValidation`, `derivedBalancesAndOpening` |
| L3 | `LedgerTests.reconcile` |
| L4 | `LedgerTests.currencies`, `FoundationTests.currencyPrimitives` |
| L5 | `LedgerTests.amounts`, `QueryTests.balancesAndCurrencies` |
| L6 | `LedgerTests.archiveWallet` |
| L7 | `LedgerTests.updateEntry` |
| L8 | `LedgerTests.deleteWallet` |
| L9 | `LedgerTests.categoryValidation` |
| L10 | `LedgerTests.deleteCategory`, `UndoTests.relationalUndoExact` |
| L11 | `LedgerTests.normalizedNames` |
| L12 | `LedgerTests.saveFailure`, `FoundationTests.replacementFailureIsAtomic`, `UndoTests.receiptSaveFailure` |
| U1 | `UndoTests.entryUndoExact`, `relationalUndoExact`, `EdgeTests.metadataAndReviewCommands` |
| U2 | `UndoTests.boundedHistory`, `undoConflict`, `RecurringTests.recurringHistory`, `BackupTests.restoreClearsHistory`, `EdgeTests.undoPreservesUnrelatedExternalChanges` |
| U3 | `UndoTests.previewBudgetAndReceipt`, `failedAndMetadataPreview`, `EdgeTests.metadataAndReviewCommands` |
| R1 | `RecurringTests.monthEndClamping` |
| R2 | `RecurringTests.catchUpAndRelaunch`, `persistedRelaunch` (new disk container after closing the previous one) |
| R3 | `RecurringTests.pauseResumeAndEnd`, `pausePreservesEarlierBacklog` |
| R4 | `RecurringTests.yearlyAndWeekly` |
| R5 | `RecurringTests.deletionAndFailures`, `EdgeTests.existingOccurrenceAndOtherRules` |
| B1 | `QueryTests.independentBudgets` |
| B2 | `QueryTests.monthAcrossTimeZones` |
| Q1 | `QueryTests.balancesAndCurrencies`, `summaryBreakdownAndWalletTotals`, `filtersAndRecent`, `upcomingRules`, `periodBoundaries` |
| K1 | `BackupTests.roundTrip`, `FoundationTests.allRecordsRoundTrip` |
| K2 | `BackupTests.headers`, `records`, `unsafeNames`, `invalidImages`, `imageMembership`, `planningRecords`, `restoreSaveFailure`, `recordsOnlyCollision` |
| S1 | `FoundationTests.seedingIsIdempotent`, `diskStoreIsSeparateAndPersists` |
| S2 | `UndoTests.orphanCleanup` |

Additional tests cover rule/budget/point-card CRUD, invalid command atomicity, recurring-batch save failure, cross-actor command Codable/Sendable values, review clearing, and ID-based rename preservation.

Existing scripts were run before changes and again on the final tree. Final results:

| Command | PASS checks | FAIL | Duration |
| --- | ---: | ---: | ---: |
| `python3 Verification/verify_receipt_ocr.py` | 91, plus compile/SDK/type checking | 0 | 7.010 s |
| `sh Verification/verify_backup.sh` | 114 | 0 | 6.302 s |
| `sh Verification/verify_localization.sh` | 6,634 | 0 | 3.252 s |
| `sh Verification/verify_payments.sh` | 96 | 0 | 3.850 s |
| `sh Verification/verify_migration.sh` | 11 | 0 | 2.789 s |
| `sh Verification/verify_currency.sh` | 40 | 0 | 1.658 s |
| `sh Verification/verify_policies.sh` | 73 | 0 | 2.572 s |
| `sh Verification/verify_money_tip.sh` | 1,524 | 0 | 3.259 s |
| Total | 8,583 | 0 | 30.692 s |

## Builds and compatibility

Both required commands passed with the final core sources:

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

WealthyCore compiled with zero warnings for Simulator arm64/x86_64 and device arm64. The app's metadata processor reports `Metadata extraction skipped, no AppIntents.framework dependency found`; this is outside the core compiler and App Intents are Cycle 3 work. The Swift 5/MainActor consumer type-check also passed without workaround imports or isolation adapters:

```sh
xcrun swiftc -typecheck -swift-version 5 -default-isolation MainActor \
  -enable-upcoming-feature NonisolatedNonsendingByDefault \
  -I WealthyCore/.build/out/Products/Debug /private/tmp/wealthy-c1-consumer.swift
```

App source diff: no task changes under `Wealthy/Wealthy/`; the user's `.DS_Store` is deliberately unstaged. The committed `main...HEAD` comparison is verified during Git delivery.

## Performance (informational)

`QueryTests.tenThousandEntryPerformance` creates 10,000 synthetic entries across ten wallets, runs each query 20 times, and reports the median. Final Debug measurement on the development Mac:

| Query | Median |
| --- | ---: |
| All wallet balances | 3.636 ms |
| One monthly summary | 2.869 ms |
| One category breakdown with previous-period comparison | 4.528 ms |

These measure queries on a detached snapshot; SwiftData fetch/save time and UI rendering are excluded. There is no performance pass/fail threshold.

## Physical-device GUI verification

**PASS**, iPhone 16 Pro Max, **iOS 27.2** (live device information). Final signed build was installed over the existing production bundle without uninstalling or resetting its container. Apple Intelligence's normal launch gate allowed the Home screen.

Executed one XCTest UI case, **0 failures, 38.926 seconds**; an earlier execution of the same smoke case also passed in 39.440 seconds. Final run:

```sh
xcodebuild -project /private/tmp/wealthy-c1-device-project/Wealthy.xcodeproj \
  -scheme Wealthy -destination 'id=YOUR_CONNECTED_IPHONE_UDID' \
  -derivedDataPath /private/tmp/wealthy-c1-device-build -allowProvisioningUpdates \
  -resultBundlePath /private/tmp/wealthy-c1-device-results3.xcresult \
  -only-testing:WealthyDeviceUITests/CycleOneSmokeTests test
```

| Operation | Expected | Actual |
| --- | --- | --- |
| Launch linked app over existing installation | Current Home, four tabs, old records visible | PASS; Home and existing record visible |
| Open Wallets | Existing wallet names/balances retained | PASS; labels captured before mutation |
| Add a uniquely named JPY 1 expense to an existing cash wallet | New row visible and wallet decreases | PASS; row visible, cash balance label changed |
| Delete only that new row | Row removed, wallet balances restored, old record retained | PASS; all prior wallet labels identical, old record visible, marker absent |
| Inspect Home/Wallets and app source diff | No redesigned UI | PASS; same controls/appearance; no app-source changes |

Screenshots and accessibility evidence stay in the local xcresult because they include existing user financial records. The test project is temporary and contains only this focused case; the existing broader DeviceTest cases were not run against production. This smoke check does not re-verify every legacy screen or AI/OCR feature.

## Errors, logs, reproduction, and remaining review items

Final required checks have no failures. Intermediate syntax/build issues (qualified SwiftData defaults, throwing formatter fallback, a throwing test assertion) and temporary UITest scheme setup were corrected and verified. Unused-result test warnings were removed. The final Core build/test warnings are zero; app metadata warnings are described above.

Local evidence directory: `/private/tmp/wealthy-c1-logs/`.

- `m1-tests.log`, `m2-tests.log`, `m3-tests.log`, `final-core-tests.log`
- `final-simulator-build.log`, `final-release-build.log`, `swift5-consumer.log`
- `final-baseline.json`, `final-verify_*.log`
- `final-device-gui.log`, `/private/tmp/wealthy-c1-device-results3.xcresult`
- Temporary GUI source: `/private/tmp/wealthy-c1-device-project/SmokeUI/CycleOneSmokeTests.swift`

Reproduction: run `sh Verification/verify_core.sh` and the build/script commands above from the repository root. Individual regressions can be selected with `swift test --package-path WealthyCore --filter pausePreservesEarlierBacklog`, `--filter persistedRelaunch`, or `--filter recordsOnlyCollision`. The GUI operations are reproducible manually on an Apple Intelligence-ready device, using a disposable expense and an existing wallet, without resetting data.

No unresolved implementation or acceptance blocker remains. Designer review items: commands currently save a complete detached snapshot in one SwiftData save, and undo retains up to 20 snapshots; large-store mutation latency and memory have not been benchmarked. Actual CloudKit sync, the Cycle 2 UI/store switch, legacy migration, on-device voice, App Intents, and real receipt OCR accuracy are intentionally outside this cycle and were not claimed as verified. Calendar/Analysis were not separately visually compared in this focused device case. No merge or main push was performed.

## Git delivery

Initial source commit, verified branch push, PR creation, and report-link update are part of this same cycle. The user's pre-existing changes remain outside the commits. Stop after the final branch push is verified; do not start Cycle 2 or extra improvements.
