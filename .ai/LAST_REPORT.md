# WealthyCore — Cycle 1.1 implementation report

- Task ID: WEALTHY-C1.1-STORE
- Cycle: 1.1
- Date: 2026-10-05 JST
- Status: COMPLETED.
- Branch: `codex/wealthy-c1-1-store`
- Base: latest `origin/main`, `9b86de2`, which already contains PR #1 / `ebe6fbd`.
- Pull request: https://github.com/Kei-Takamizawa/Wealthy/pull/2

## Outcome and milestones

Commands, undo, recurring posting, seeding and orphan cleanup now persist changed rows only. LedgerCore holds observable cached values; undo retains changed records only. The requested recurring, image, cleanup, provenance and last-recorded fixes are complete. Current app screens still use the legacy store.

| Milestone | Status | Evidence |
| --- | --- | --- |
| M1 | COMPLETED | Harness and Cycle 1 baseline; 62 passed, 1 opt-in benchmark skipped, 0 failures, 0.810 s |
| M2 | COMPLETED | Incremental persistence, cache, Observation, revision, reload; 68 passed, 1 opt-in benchmark skipped, 0 failures, 0.636 s |
| M3 | COMPLETED | Bounded change-set undo; 72 passed, 1 opt-in benchmark skipped, 0 failures, 1.175 s |
| M4 | COMPLETED | Correctness fixes and command restrictions; 89 passed, 1 opt-in benchmark skipped, 0 failures, 1.379 s |
| M5 | COMPLETED | Both disk sizes benchmarked before/after; documentation, app builds, existing scripts and device smoke passed |

The 10,000-entry add median is 36.285 ms versus 2134.099 ms: 58.82x faster, below the 426.820 ms PERF threshold. Opening regressed at both sizes; measurements and limits are reported below.

## Persistence, state, order and rollback

LedgerCore loads and fully validates one detached LedgerState at initialization. `state` and `snapshot()` return cached values without database access. Each operation applies to a copy, validates changed records and their dependencies, then builds per-model UUID change sets. Global UUID and recurring-occurrence uniqueness are still checked. Small planning/wallet/category metadata is validated; unchanged receipt metadata and unchanged entry invariants are not repeatedly revalidated. A dedicated test runs full CoreValidation after every command case and each undo.

LedgerStore uses a fresh autosave-disabled ModelContext for each read/transaction. Updates and deletes fetch only their UUID with predicates; updates assign fields in place. One successful save publishes both order maps and internal write counters. No-op operations perform no save. File-only changes perform one empty model save so injected save failures still roll back files and revision. Seeding inserts only missing defaults.

Record order is separate from presentation sortOrder. Unchanged rows keep recordOrder, new rows receive max existing order plus one, and deletion undo restores the previous order. Reads and undo break tied orders by ascending UUID for stable external-write ordering. Surviving rows retain persistentModelID. A restored deleted row is a new SwiftData identity with the original domain UUID/order, as expected.

Each undo step stores only before/after values and orders of touched records, with a 20-step limit. Unrelated rows are preserved. The conflict check compares touched values/orders in the cache, then checks their actual persisted rows before writing, so an unseen external edit to a touched row also fails safely. Inverse relationship validation rejects dependent-state conflicts. Recurring posting and cleanup create no history; successful restore clears it.

Candidate state/history/revision are published only after successful database and file transactions. Failed validation, file writes and injected saves leave persisted rows, cached values, history, revision, order maps and previous successful write diagnostics unchanged. Receipt rollback originals are staged on disk and restored one at a time. Backup restore validates all data first, replaces records only when values differ, then refreshes the working state from the validated values it saved; a file-only restore uses an incremental empty-row save. Exact no-op restores still clear history but do not change revision or row identities.

External writers use `reload()` to refresh cached values and all relationships. It reads through a fresh context, fully validates, retains history and increases revision once if the detached state differs. Live iCloud synchronization is not implemented or tested here.

Public API additions/changes:

```swift
@Observable @MainActor public final class LedgerCore
public init(store: LedgerStore, calendar: Calendar = .current) throws
public private(set) var state: LedgerState
public private(set) var revision: Int
public func reload() throws
public func snapshot() throws -> LedgerState // existing signature, now cached
public func cleanupOrphanReceipts() throws -> [String] // now removes metadata and files atomically
public var imageSHA256: String? // ReceiptValue and ReceiptAttachment
public init(id: UUID = UUID(), fileName: String, capturedAt: Date = Date(), imageSHA256: String? = nil) // ReceiptValue
```

The throwing initializer is an intentional API adjustment to propagate initial load/validation errors. Revision increases once for persisted value or image-byte changes; previews, failures, empty undo and exact no-ops leave it unchanged. Undo history itself does not change revision. No screen needs SwiftData @Query to consume the observable state.

## Schema and correctness changes

Only ReceiptAttachment adds `imageSHA256: String? = nil`, mirrored by ReceiptValue and its backward-compatible Codable optional field. Wallet, Category, LedgerEntry, RecurringRule, Budget and PointCard fields are unchanged. V1 stays `1.0.0`; no migration stage is added because this store has not shipped. Backup remains `wealthy-ledger`, version 1. New saved receipt inputs compute lowercase CryptoKit SHA-256. Unknown hashes decode as nil; known hashes must be 64 lowercase hexadecimal characters.

All seven models still have optional/defaulted stored properties, no unique attributes, no relationships, no deny delete rules and no ordered relationships. No #Index was added: Apple documents local query indexes in [WWDC24](https://developer.apple.com/videos/play/wwdc2024/10137/), but explicit support for SwiftData #Index with a CloudKit-mirrored store was not verified, so the task's condition was not met.

- Recurring ranges clip to min(today, endDay), inclusive; missed occurrences before the end are posted later. Paused intervals, future dates, existing occurrences and consumed cursors retain their protections.
- Records-only restore hashes each referenced local file in 65,536-byte buffers, one file at a time. A file is retained only when every referenced metadata record naming it has a known matching hash; unknown or mismatching files are removed transactionally. Included-image round trips remain exact.
- DeleteEntry retains receipt metadata for undo; cleanup removes unreferenced records and files in one transaction, while history blocks cleanup. Shared referenced filenames survive; ordinary orphan filenames containing spaces can be removed safely as direct children.
- AddEntry rejects adjustments, system sources and either recurring link field. UpdateEntry rejects source/link/occurrence changes and transitions to or from adjustment. Expense/income/transfer transitions remain allowed.
- MostRecentEntry selects createdAt descending, timestamp descending, then ascending UUID, retaining the optional source filter. Civil day no longer decides "last recorded".

CloudKit composite status: **unverified for the exact SwiftData LedgerDay, associated-value RecurringSchedule, [LedgerPeriod] and [String] schema types**. Apple [documents SwiftData Codable value support](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches) and [Core Data composite/nested-composite support with NSPersistentCloudKitContainer on SQLite](https://developer.apple.com/documentation/coredata/nscompositeattributedescription). Its [CloudKit mapping documentation](https://developer.apple.com/documentation/coredata/reading-cloudkit-records-for-core-data) also describes transformable data. Those general capabilities and local round trips do not establish live synchronization of these exact types. No schema serialization redesign was introduced.

## Tests and scenario coverage

Final command: `sh Verification/verify_core.sh`.

**89 passed, 1 opt-in disk benchmark skipped, 0 failed, 1.349 seconds**. Final Core compiler/concurrency warnings: **0**. Each enabled disk benchmark run independently passed its single test with 20 measured samples per metric: baseline 2,392.146 seconds; after 654.218 seconds. The PERF comparison of raw medians also passed.

| Scenario | Test names / evidence |
| --- | --- |
| P1 | PersistenceTests.singleEntryWrites: exactly one insert/update/delete and one save per entry operation |
| P2 | singleEntryWrites; relationalWritesAndIdentity; ChangeSetUndoTests.tiedExternalOrder; untouched persistent IDs retained |
| P3 | relationalWritesAndIdentity: category cascade exactly 2 updates + 2 deletes, other records unchanged |
| P4 | revisionAndFailure; FixTests.fileOnlyEntryUpdate; orphanMetadataCleanup; mismatchingAndUnknownImages; existing receipt/save failure tests |
| P5 | ChangeSetUndoTests.retainedChangedRecords; boundedRecordHistory: one entry, or entry+receipt; 20 additions retain 20 records |
| P6 | revisionAndFailure; externalContextReload; observableStateAndRevision; fileOnlyEntryUpdate; fileOnlyCleanupRevision; matchingImageRecordsRestore |
| P7 | All original undo cases; sparseOrderUndo; touchedOrderConflict; tiedExternalOrder; unseenExternalConflict; exact state/order restored |
| R6 | FixTests.endedRuleCatchUp: engine and posting include Jan31 after Feb28, then no repeat |
| R7 | cursorAndPausedEndCatchUp: Jan cursor, Feb28/Mar31 catch-up after May10; Feb pause skipped; inclusive end |
| K3 | matchingImageRecordsRestore; mismatchingAndUnknownImages; omittedHashArchiveDecodes; imageInclusiveRoundTrip; original backup tests |
| S3 | orphanMetadataCleanup; sharedReceiptCleanup; cleanupNonMetadataFilename; original orphanCleanup |
| C1 | addCommandRestrictions; updateProvenanceRestrictions; adjustmentKindRestrictions |
| Q2 | lastRecordedOrdering: newer recording with earlier civil day wins; timestamp/UUID/source filters |
| PERF | BenchmarkTests.diskMeasurements and raw JSON median comparison; 36.285 <= 426.820 ms |

Existing tests changed, none deleted:

- LedgerTests.derivedBalancesAndOpening: creates +50/-25 adjustments via reconciliation instead of now-forbidden addEntry, retaining all balance/direction checks.
- LedgerTests.categoryValidation: addAdjustment now fails kind first; a direct invalid historical state still verifies adjustment category rejection.
- RecurringTests.pauseResumeAndEnd: an expired but unprocessed rule now expects Jan31 catch-up rather than no entries.
- QueryTests.filtersAndRecent: explicitly gives the next-day row a newer createdAt for the last-recorded expectation; entry-list day ordering remains unchanged.
- UndoTests.orphanCleanup: additionally asserts receipt metadata is removed.
- Constructors in BackupTests.core, LedgerTests.makeCore, UndoTests.core, RecurringTests.core/catchUpAndRelaunch/persistedRelaunch, and the three Core-using EdgeTests now use the throwing initializer. The benchmark differs from its baseline harness only by the same required `try` at three constructors; measurement boundaries/fixtures are unchanged.
- Direct raw store fixture/external writes now explicitly call reload in LedgerTests.deleteCategory; UndoTests.relationalUndoExact/undoConflict/previewBudgetAndReceipt/failedAndMetadataPreview/receiptSaveFailure/receiptFileFailure; RecurringTests.recurringHistory; BackupTests.roundTrip; EdgeTests.existingOccurrenceAndOtherRules/undoPreservesUnrelatedExternalChanges. This synchronizes the new cache contract; conflict and exact-state assertions are retained.

## Disk benchmark results

Host: Apple M4, 10 CPU cores, 24 GiB RAM, macOS 27.0.1; Xcode 27.0 (27A266a), Swift 6.4. Release configuration, arm64. The baseline used unchanged Cycle 1 source from the merged main before production edits. No builds/tests ran in parallel with the timing runs.

Exact after command:

```sh
WEALTHY_BENCHMARK=1 WEALTHY_BENCHMARK_LABEL=after \
WEALTHY_BENCHMARK_OUTPUT=/private/tmp/wealthy-c1-1-logs/after.json \
swift test --package-path WealthyCore -c release --filter BenchmarkTests
```

Every store has 10 wallets, 12 categories, 5 budgets and 10 rules. Each metric uses 20 samples after one warm-up, fresh copies of a closed seeded disk store, UTC Gregorian January 2027. Setup/copy/disposal are outside timing; opening includes store initialization and first load. Undo reverses one prepared addition, with the preparation excluded. Recurring posts exactly one month/10 occurrences. OS file caches are not flushed. Constant assertion overhead is included. Raw samples are retained locally in baseline.json/after.json.

### 10,000 entries

| Operation | Cycle 1 median ms | Cycle 1.1 median ms | Before / after speed |
| --- | ---: | ---: | ---: |
| `addEntry` | 2134.099 | 36.285 | 58.82x |
| `updateEntry` | 2135.784 | 43.577 | 49.01x |
| `deleteEntry` | 2133.847 | 45.645 | 46.75x |
| `undo` | 2129.915 | 109.208 | 19.50x |
| `previewAddEntry` | 354.743 | 59.363 | 5.98x |
| `postRecurring` | 2149.782 | 61.957 | 34.70x |
| `openStore` | 365.346 | 651.170 | 0.56x |

### 50,000 entries

| Operation | Cycle 1 median ms | Cycle 1.1 median ms | Before / after speed |
| --- | ---: | ---: | ---: |
| `addEntry` | 11251.196 | 337.830 | 33.30x |
| `updateEntry` | 11287.994 | 309.047 | 36.53x |
| `deleteEntry` | 11411.054 | 304.692 | 37.45x |
| `undo` | 14649.749 | 408.936 | 35.82x |
| `previewAddEntry` | 2203.285 | 203.708 | 10.82x |
| `postRecurring` | 14281.009 | 185.132 | 77.14x |
| `openStore` | 2066.601 | 2805.114 | 0.74x |

| Metric at 10,000 entries | Cycle 1 bytes (MiB) | Cycle 1.1 bytes (MiB) |
| --- | ---: | ---: |
| Before 20 additions | 30,196,600 (28.80) | 32,998,288 (31.47) |
| After 20 additions | 343,180,440 (327.28) | 54,363,072 (51.84) |
| Process growth | 312,983,840 (298.48) | 21,364,784 (20.38) |

Process-footprint growth decreased by 93.17%. This measures the combined persistence/history/allocator behavior, not isolated undo allocations. History record-count regressions separately establish that full snapshots are no longer retained.

Opening is 1.78x slower at 10k and 1.36x slower at 50k. Initial full validation, deterministic ordering and fresh-context reading are included in the changed initialization path. No startup improvement is claimed. Commands still scan/copy detached values and build summaries/diffs; row writes are incremental, while CPU cost is not O(1). The 50k results are an explicit limit for Cycle 2 UI responsiveness. The optional iPhone disk benchmark was not run; no phone latency/memory claim is made.

## App builds and existing verification

Both required commands passed:

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy -configuration Release \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

The app's existing AppIntents metadata extraction warning is recorded in the build logs; it is separate from the warning-free Core compiler. No build/signing/deployment settings were changed.

| Existing verification command | Result | Checks | Wall time |
| --- | --- | ---: | ---: |
| `python3 Verification/verify_receipt_ocr.py` | PASS | 91 | 8.309 s |
| `sh Verification/verify_backup.sh` | PASS | 114 | 6.242 s |
| `sh Verification/verify_localization.sh` | PASS | 6,634 | 3.254 s |
| `sh Verification/verify_payments.sh` | PASS | 96 | 3.809 s |
| `sh Verification/verify_migration.sh` | PASS | 11 | 2.736 s |
| `sh Verification/verify_currency.sh` | PASS | 40 | 1.669 s |
| `sh Verification/verify_policies.sh` | PASS | 73 | 2.576 s |
| `sh Verification/verify_money_tip.sh` | PASS | 1,524 | 3.097 s |

The existing scripts are unchanged. Total checks: 8,583; failures: 0.

## GUI smoke on the existing production app

Device: iPhone 16 Pro Max, iOS 27.2 (24B5089g), Apple Intelligence ready. A temporary focused XCTest UI project uses the unchanged production bundle/signing, linked current Core and existing app sources. It installs over the existing app; no uninstall, preference override, data reset or broad destructive test suite is used.

Command (substitute the paired device ID):

```sh
xcodebuild -project /private/tmp/wealthy-c1-1-device-project/Wealthy.xcodeproj \
  -scheme Wealthy -destination 'id=YOUR_CONNECTED_IPHONE_UDID' \
  -derivedDataPath /private/tmp/wealthy-c1-1-device-build -allowProvisioningUpdates \
  -resultBundlePath /private/tmp/wealthy-c1-1-device-results.xcresult \
  -only-testing:WealthyDeviceUITests/CycleOneSmokeTests test
```

| Operation | Expected | Actual |
| --- | --- | --- |
| Launch over existing installation | Same Home/four tabs, existing records retained | PASS |
| Open Wallets | Existing names and balances retained | PASS, all row labels captured |
| Add one uniquely named JPY 1 expense to existing cash wallet | New row visible, wallet balance changes | PASS |
| Delete only that test expense | Marker removed, existing record retained, all wallet labels/Home balance restored | PASS |
| Compare current screens/source | No redesign or store switch | PASS for Home/Wallets; app-source branch diff empty |

One UI test passed with 0 failures in 40.561 seconds. Screenshots/accessibility attachments remain private in the local xcresult because they show existing financial records. Calendar/Analysis and AI/OCR behavior were not separately re-verified in this focused smoke check. No user-visible Core/UI switch was made.

## Changed files, deviations, logs and reproduction

- Core: Store.swift, Commands.swift, Results.swift, Planning.swift, Backup.swift, Files.swift, Queries.swift, Schema.swift, Values.swift; new Changes.swift, IncrementalValidation.swift, PersistenceRecords.swift.
- Tests: new BenchmarkTests.swift, PersistenceTests.swift, ChangeSetUndoTests.swift, FixTests.swift; existing adaptations listed above.
- Documentation: Verification/README.md, .ai/CURRENT_TASK.md, .ai/LAST_REPORT.md.
- Package.swift, root README files, app sources/translation/assets/Info.plist/entitlements, legacy models/images/backup, bundle/signing/deployment settings and Apple Intelligence gate are unchanged.

No required feature or acceptance deviation remains. Implementation choices permitted by the task: off-by-default Swift Testing benchmark instead of an executable; throwing Core initialization; fresh ModelContexts; deterministic UUID ties; disk-staged rollback files; file-only save/revision handling. #Index was omitted under the explicit documentation condition. Optional phone performance measurement was intentionally omitted. No live CloudKit sync, legacy migration, UI redesign, App Intents/voice or real receipt accuracy test was attempted. Subagents prepared harness/implementation/regressions; after they hit usage limits, the main agent completed integration and verification.

Local evidence: `/private/tmp/wealthy-c1-1-logs/` (milestone/final Core logs, baseline/after benchmark logs and raw JSON, benchmark-environment.txt, perf-comparison.json, final-baseline.json, final-verify_*.log, final-simulator-build.log, final-release-build.log, final-device-gui.log). GUI result: `/private/tmp/wealthy-c1-1-device-results.xcresult`. Large logs, build caches, temporary projects and private screenshots are intentionally not committed.

Reproduction: run the commands in Verification/README.md and above. Individual regressions can be selected with `swift test --package-path WealthyCore --filter singleEntryWrites`, `--filter unseenExternalConflict`, `--filter endedRuleCatchUp`, `--filter matchingImageRecordsRestore`, or `--filter observableStateAndRevision`.

Errors/warnings: all final required checks passed; Core compiler/concurrency warnings are zero. Baseline Core Data WAL checkpoint/maintenance debug annotations are not compiler warnings. No unresolved implementation blocker or designer decision is required to complete this cycle. Designer review items: the measured startup regression, O(N) detached-state CPU work and 50k operation latency; exact composite CloudKit synchronization remains unverified. Future external writers must coordinate reloads before acting on cached relationships. No additional optimization or Cycle 2 work is started.

## Git delivery

Source commit: `12c145b9d1258bb236ea49daca107835039dde21`. Its feature-branch push was verified against origin, and PR #2 was created with base main. This report-link update is recorded in a separate final commit and pushed on the same feature branch. The three original .DS_Store changes and three removed blank lines in the Xcode project remain outside the commits. `git diff --stat main...HEAD -- Wealthy/Wealthy/` is empty. Final delivery verification compares local HEAD, the remote branch and PR head; work stops after that verification. No merge or main push is performed.
