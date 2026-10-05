# CURRENT TASK — Cycle 1.1: WealthyCore incremental persistence, change-set undo, and fixes

| | |
| --- | --- |
| Task ID | WEALTHY-C1.1-STORE |
| Cycle | 1.1, a follow-up to Cycle 1 (WEALTHY-C1-CORE, PR #1). Cycle 2, the new UI, starts after this task. |
| Written | 2026-10-05 by the designer/reviewer (Claude) for the implementer (Codex) |
| Base | The latest `main` that contains PR #1 (head commit `ebe6fbd`). If `main` does not contain `ebe6fbd` yet, branch from `codex/wealthy-c1-core` instead and say so in the report. |
| Save as | `.ai/CURRENT_TASK.md`, replacing the Cycle 1 document (git history keeps it). Write your report to `.ai/LAST_REPORT.md`, replacing the Cycle 1 report. |

This document is self-contained. You do not need any earlier conversation to carry it out.

## 1. Goal

Make WealthyCore ready to be the live store of the redesigned UI (Cycle 2) and of future iCloud sync, with no change users can see:

1. Persist only what changed, instead of rewriting the whole store on every change.
2. Undo with change sets instead of full snapshots.
3. Let the UI observe data changes.
4. Fix three correctness issues found in the Cycle 1 review, and tighten two command rules.

## 2. Background

- Wealthy is a SwiftUI + SwiftData household budget app for iOS/iPadOS 26+. The redesign runs in cycles:

  | Cycle | Content |
  | --- | --- |
  | 1 (done, PR #1) | `WealthyCore`, a local Swift package (Swift 6): schema V1, derived balances, commands with preview and undo, recurring entries, budgets, queries, backup. Linked to the app but not used by any screen. |
  | 1.1 (this task) | Persistence, undo, and correctness fixes inside WealthyCore. No UI change. |
  | 2 | Every screen rebuilt on WealthyCore with a new design; the app switches to the new store, which starts empty. |
  | 3 | Voice control and App Intents, calling the same commands. |

- The new store has never shipped and holds no user data. You may change schema V1 in place, without a migration stage, as long as the rules in section 5 hold.
- The Cycle 1 report says: "commands currently save a complete detached snapshot in one SwiftData save, and undo retains up to 20 snapshots; large-store mutation latency and memory have not been benchmarked." This task removes that limitation and measures it.

## 3. Decisions already made by the product owner

Do not revisit these.

- Apple Intelligence remains required by the app.
- No legacy data migration. The new store starts empty in Cycle 2.
- Monthly budgets: one overall budget plus optional per-category budgets, kept per currency.
- In Cycle 2 the UI languages become English (base), Japanese, Spanish, and Korean. WealthyCore does not depend on the language list, so nothing changes here for that.
- iCloud sync must be addable later without a schema rewrite. Sync itself is out of scope.

## 4. Current problems (at commit `ebe6fbd`)

**P1. Full rewrite on every write.** `LedgerStore.replace(_:)` (`WealthyCore/Sources/WealthyCore/Store.swift:57-80`) fetches and deletes every record of all seven models, inserts them all again, and saves. Commands, undo, recurring posting, and seeding all go through it, after a full `store.read()` (`Store.swift:42`). Consequences:
- The cost of one tap grows with the size of the whole ledger: about 2N row operations for N records.
- Every record gets a new persistent identity on every save.
- A future CloudKit mirror would upload deletes and inserts for the entire ledger after each change.

**P2. Snapshot undo.** `history` (`Commands.swift:136`, `:161-162`) keeps up to 20 pairs of full `LedgerState` values, so retained memory grows with ledger size times 20.

**P3. No change signal.** Nothing tells a future UI that data changed, other than reading the whole store again.

**P4. Recurring end day.** `RecurringEngine.occurrences` returns nothing when the range end is after `endDay` (`Planning.swift:17`), and `postRecurring` skips a rule when today is after `endDay` (`Planning.swift:149`). If the app was not opened between the last posting and the end day, the missed occurrences up to the end day are never posted. The test at `RecurringTests.swift:72-76` encodes this. The Cycle 1 sentence "A rule past its end day posts nothing" was ambiguous; section 5.4 states the intended rule.

**P5. A records-only restore deletes valid images.** When an archive has no images, `LedgerBackup.restore` (`Backup.swift:89-99`) removes every local file named by the archive's referenced receipts. Restoring a records-only backup on the same device therefore deletes the correct images. The intent, never attaching unrelated bytes from another device, is right; section 5.5 keeps it.

**P6. Orphan receipt metadata.** `deleteEntry` (`Commands.swift:253`) keeps the `ReceiptAttachment` record, which undo needs. But `cleanupOrphanReceipts` (`Commands.swift:181-187`) deletes only files, so unreferenced metadata records accumulate and are exported in backups.

**P7. Command rules too loose.** `addEntry` accepts `kind: .adjustment`, any `source` (including `recurring`, `openingBalance`, and `reconciliation`), and a recurring link. `updateEntry` can change `source`, `recurringRuleID`, or `occurrenceDay`, and can turn an entry into or out of an adjustment (`Commands.swift:80-110`, `:241-252`).

**P8. "Last entry" ordering.** `LedgerQueries.mostRecentEntry` (`Queries.swift:237-248`) orders by day, then timestamp. For "edit or undo the last one", users mean the most recently recorded entry.

## 5. Requirements

### 5.1 Persist only what changed

- Every command run, undo, recurring posting, seeding, and orphan cleanup persists only the records that changed: insert new records, update changed records in place, delete removed records. Use one `save()` per operation.
- Records that an operation does not change keep their SwiftData persistent identity (`persistentModelID`).
- On any failure (validation, file write, injected save failure), roll back. The store, the in-memory state, the undo history, and `revision` (5.3) stay exactly as they were.
- Restore (backup import) may still replace all records in one save. Afterwards, reload the in-memory state and clear the undo history, as today.
- Order: `snapshot()` keeps returning records in a stable order. Unchanged records keep their `recordOrder`, new records go after existing ones, and undoing a deletion restores the record's previous `recordOrder`. The state after an undo must equal the state before the command; the existing U1 and U2 tests compare whole states.
- Recommended approach; you may choose another one that meets the requirements: `LedgerCore` is the only writer and keeps one validated `LedgerState` in memory as the working copy. A command is applied to a copy, validated, and diffed per model by ID, as `StateChanges.ids` already does. The resulting change set is persisted, and the in-memory state is replaced only after a successful save. Records to update or delete are fetched by ID with predicates.
- Validation must not dominate latency. You may validate only the changed records and the records that reference them, provided the same invariants as `CoreValidation.validate` hold after every command. Keep full validation for restore. In the test suite, add a check that runs full validation after every command.
- You may add `#Index` declarations, for example on `id`, if Apple's documentation shows they work with a CloudKit-mirrored SwiftData store. Otherwise do not add them, and say why in the report.
- Keep every CloudKit rule from Cycle 1: no unique attributes, every stored property optional or defaulted, relationships (if any) optional with inverses, no `.deny` delete rules, no ordered relationships.

### 5.2 Undo with change sets

- Each history step stores only the records the operation changed: their values before and after, plus what is needed to restore their order. Keep the limit of 20 steps.
- Conflict behavior stays the same. If any record touched by the step no longer equals its value right after that step, undo throws `undoConflict` and changes nothing.
- Undo is persisted with the incremental writes of 5.1.
- Recurring posting and restore are still not recorded in the history. A restore still clears it.

### 5.3 Change signal for the UI

- Make `LedgerCore` observable by SwiftUI through the Observation framework.
- Expose the current state as a read-only value that does not fetch from the store on access.
- Expose `revision: Int`. It increases by exactly 1 after every operation that changed persisted data. It does not change on a preview, a failed operation, an operation that changed nothing, or an undo with empty history.
- Add `reload()`, which reads the store into memory again and increases `revision` if anything differs. It exists for future external writers such as iCloud sync. It keeps the undo history; the conflict check in 5.2 protects undo.
- Cycle 2 screens will read through `LedgerCore` and `LedgerQueries`, so they must not need SwiftData `@Query`.

### 5.4 Recurring end day

- Posting covers every missed occurrence from the rule's cursor (as in Cycle 1) through the earlier of today and the rule's end day, inclusive. Nothing after the end day is ever posted.
- Once every occurrence through the end day is processed, later calls post nothing for that rule.
- Occurrences inside paused periods are still skipped, and future occurrences are still never posted.
- `RecurringEngine.occurrences` follows the same rule: it limits the range to the end day instead of returning an empty list.

### 5.5 A records-only restore keeps matching images

- Store a SHA-256 hash of each receipt image (lowercase hex) in the receipt metadata when the image is saved, and include it in backups. Use CryptoKit.
- Archives without hashes must still decode; treat a missing hash as unknown. Keep the format identifier and version (`wealthy-ledger`, 1). The format has not shipped, so adding an optional field is fine.
- When an archive without images is restored, keep each referenced local file whose SHA-256 equals the archived hash. Remove the others as today, including files whose receipt has no hash. The entry then has no image.
- Restores that include images do not change.
- Read and hash one file at a time. Never load all images into memory at once.

### 5.6 Orphan receipt metadata

- `cleanupOrphanReceipts()` also deletes `ReceiptAttachment` records that no entry references, in the same operation as the file cleanup.
- It still refuses to run while undo history exists.
- Deleting an entry still keeps its receipt metadata until cleanup, so undo can restore the link.

### 5.7 Command rules

- `addEntry`: `kind` must be `expense`, `income`, or `transfer`. `source` must be `manual`, `receipt`, or `voice`. `recurringRuleID` and `occurrenceDay` must be nil. Otherwise throw `invalidField`; the field name is your choice.
- `updateEntry`: keeps the stored entry's `source`, `recurringRuleID`, and `occurrenceDay`, and rejects a change to them with `invalidField`. It cannot change `kind` to or from `adjustment`. Changes among `expense`, `income`, and `transfer` stay allowed, as in Cycle 1.
- Adjustments are created only by `createWallet` (opening balance) and `reconcileWallet`. Recurring posting keeps creating entries with source `recurring`.

### 5.8 Last recorded entry

- `mostRecentEntry` returns the most recently recorded entry: newest `createdAt` first, then newest `timestamp`, then ID. Keep the optional source filter, and update the doc comment.

### 5.9 Benchmarks

- Add a benchmark that is off by default and enabled by an environment variable, or a separate executable target; your choice. Document how to run it in `Verification/README.md`.
- It builds on-disk stores (not in-memory) with 10,000 and 50,000 entries, 10 wallets, 12 categories, 5 budgets, and 10 recurring rules.
- For each size, measure the median of at least 20 runs of: `run(addEntry)`, `run(updateEntry)`, `run(deleteEntry)`, `undo()`, `preview(addEntry)`, `postRecurring` with one month of catch-up, and opening the store (store creation plus the first load).
- Measure the baseline on the Cycle 1 code first, with the same harness and before your changes. Then measure again after them.
- Memory: report the process memory growth after 20 `addEntry` commands with full undo history at 10,000 entries, before and after.

## 6. UI/UX requirements

- **No user-visible change.** All current screens keep using the legacy models and store.
- The API must be ready for Cycle 2: an observable core, confirmation cards built from `preview`, instant undo, and lists that update right after a command.

## 7. Technical constraints

- Xcode 27 (iOS 26 SDK or later). The app deployment target stays iOS 26.0.
- Swift 6 language mode inside WealthyCore, with zero warnings, including concurrency diagnostics. The app target's build settings do not change.
- No third-party dependencies. Observation and CryptoKit are allowed; keep the library free of UI and AI frameworks.
- Code and comments in English. Write concise doc comments for the public API and for rules that are not obvious. No line-by-line comments.
- All date logic keeps taking an injectable calendar, time zone, and "today/now", so tests stay deterministic.

### Implementation order and milestones

Work in this order, and keep every milestone green before starting the next one. If you cannot finish, stop at the last completed milestone and report exactly what remains.

1. **M1**: benchmark harness, and baseline numbers on the Cycle 1 code.
2. **M2**: incremental persistence, the in-memory working state, `revision`, and `reload()`.
3. **M3**: change-set undo.
4. **M4**: fixes 5.4 to 5.8.
5. **M5**: benchmarks after the change, docs, and the report.

## 8. Files to add or change

| Action | Path |
| --- | --- |
| Change | `WealthyCore/Sources/WealthyCore/**` |
| Add or change | `WealthyCore/Tests/WealthyCoreTests/**`. Change existing tests only where this document changes behavior, and list each one in the report. |
| Change | `WealthyCore/Package.swift`, only if the benchmark needs a target |
| Change | `Verification/README.md`: how to run the benchmark |
| Replace | `.ai/CURRENT_TASK.md` (this document) and `.ai/LAST_REPORT.md` (your report) |

## 9. Do not change

- Anything under `Wealthy/Wealthy/`: app sources, translations, `Info.plist`, assets, entitlements. No screen may use WealthyCore yet.
- The legacy SwiftData models and store, the legacy receipt images, and the legacy backup code.
- The bundle identifier, signing, the deployment target, and the Apple Intelligence gate.
- The README files.
- The behavior of the existing verification scripts.
- The command cases' meaning, and the backup format identifier and version.
- Do not push directly to `main`. Work on a branch and open a pull request.

## 10. Acceptance criteria

1. `swift test` in `WealthyCore/` passes on the development Mac, and every scenario below has at least one test.
2. WealthyCore builds with zero warnings.
3. The existing unsigned app builds succeed (commands in section 11).
4. `git diff --stat main...HEAD -- Wealthy/Wealthy/` prints nothing.
5. The existing verification scripts still pass.
6. `.ai/LAST_REPORT.md` contains everything in section 13.

Required test scenarios:

| # | Scenario |
| --- | --- |
| P1 | In a store with existing records, adding one entry performs exactly one insert and no update or delete. Updating one entry performs one update, and deleting one entry performs one delete. Use a test-only write counter or an equivalent check. |
| P2 | After add, update, delete, transfer, reconcile, category delete, recurring posting, and undo, every record the operation did not change keeps its `persistentModelID`. |
| P3 | Deleting a category writes only the category and the entries, rules, and budgets that referenced it. |
| P4 | An injected save failure leaves the store, the in-memory state, the undo history, and `revision` unchanged. |
| P5 | The history step created by adding one entry contains only that entry, plus its receipt metadata if one was attached. |
| P6 | `revision` increases by exactly 1 per successful operation that changed data, and not on a preview, a failure, a no-op, or an undo with empty history. `reload()` picks up a change written to the store from outside `LedgerCore`. |
| P7 | All Cycle 1 undo scenarios still pass, including the exact record order after undo. |
| R6 | A monthly rule for day 31 that starts on 2027-01-01 and ends on 2027-01-31: posting through 2027-02-28 posts Jan 31 only, and a second call posts nothing. |
| R7 | A monthly rule for day 31 that ends on 2027-03-31 and was last posted on 2027-01-31: posting through 2027-05-10 posts Feb 28 and Mar 31 only. An end day that is itself an occurrence day is posted. An occurrence inside a paused period in that range is skipped. |
| K3 | Restoring a records-only backup on the same device keeps local images whose hash matches. A file whose bytes differ, and a receipt without a hash, are removed as before. Archives without hash fields decode. Round trips with images still give identical data and image bytes. |
| S3 | Cleanup removes unreferenced receipt metadata together with unreferenced files, and still refuses while undo history exists. |
| C1 | `addEntry` rejects the adjustment kind, non-user sources, and recurring links. `updateEntry` rejects a change of source, recurring link, or occurrence day, and a change to or from adjustment. Changing an expense into a transfer still works. |
| Q2 | `mostRecentEntry` returns the most recently created entry, even when an entry with an earlier day was recorded later. |
| PERF | At 10,000 entries, the median `run(addEntry)` time after this task is at most one fifth of the baseline measured with the same harness. Report all numbers either way. |

Existing tests that encode behavior this document changes must be updated, not deleted, and listed in the report with the reason. Known examples: the end-day case in `RecurringTests.swift:72-76`, and the `mostRecentEntry` expectations in `QueryTests.swift` if they depend on the old ordering.

## 11. Builds and tests to run

```sh
# Package tests (from the repository root)
sh Verification/verify_core.sh          # or: (cd WealthyCore && swift test)

# Benchmark (document the exact command in Verification/README.md)

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

If you can run the benchmark on the iPhone used for earlier checks, add those numbers too. This is optional.

## 12. GUI checks

There is no new UI. On the iPhone used for earlier checks, with Apple Intelligence ready, install the build over the existing app and confirm:

1. The app launches and shows the same screens as before, and the existing records are still visible.
2. Adding and then deleting one expense in the current UI works and updates the wallet as before.
3. Nothing in the UI has changed.

## 13. Report to write in `.ai/LAST_REPORT.md`

1. A summary, and which milestones (M1 to M5) are complete.
2. The pull request link and branch name.
3. How the new persistence works: the in-memory state, the change set, how order is kept, and how failures roll back. List public API additions and changes with their signatures.
4. Schema changes, field by field, and confirmation that the CloudKit rules still hold.
5. Every deviation from this document, with the reason.
6. Test results: the command; the number of tests passed and failed, and the duration; which test names cover each new scenario ID (P1 to PERF); and every existing test you changed, with the reason.
7. Build results, and the result of each existing verification script.
8. Benchmark tables before and after (Mac, plus iPhone if run), and the memory numbers.
9. GUI check results with the device model and iOS version, or "not run" with the reason.
10. Whether SwiftData with CloudKit supports the Codable composite properties in the schema (`LedgerDay`, `RecurringSchedule`, `[LedgerPeriod]`, `[String]`), with links to Apple documentation, or "unverified".
11. Known issues, risks, and open questions for the designer.
