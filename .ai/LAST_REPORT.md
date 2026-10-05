# Cycle 1.2 — Domain v2 report

- Task ID: WEALTHY-C1.2-DOMAIN-V2
- Date: 2026-10-05 JST
- Status: COMPLETED
- Branch: `codex/wealthy-c1-2-domain-v2-implementation`
- Base: latest origin/main `62a425c` (PR #1, #2 and the blocked-report PR #3 merged).
- PR: https://github.com/Kei-Takamizawa/Wealthy/pull/4

## Result and requirement coverage

| Requirement | Result | Evidence |
| --- | --- | --- |
| 3.1 Removed old Core domain | DONE | No removed types/commands/query/backup fields in Core sources or tests; legacy app unchanged |
| 3.2 Envelopes | DONE | Default household, on-demand single child, seven child presets, scoped categories, archived/deletion validation, household/child isolation |
| 3.3 Targets and marks | DONE | Effective-month versions, exact integer daily remainder, cross-month weeks, nil unset target, negative remaining, envelope logging, reward thresholds, settings and marks |
| 3.4 Tax and draft boundary | DONE | Effective reference table, pre-seed nil, per-entry floor, classifier, previews/disagreement, summaries/unknown count and takeout estimate |
| 3.5 Commands and previews | DONE | Envelope/target/mark/settings mutations; week/month overall/category remaining impacts; entry tax part; recurring provenance protected |
| 3.6 Cycle 1.1 invariants | DONE | Incremental write counters, touched-row identity/order, 20 change-set history, reload/revision, conflict checks, file/save rollback, ended-rule catch-up, image hashes/cleanup, createdAt ordering |
| 3.6 Performance limits | PASS | Full table below; every required metric checked against exact Cycle 1.1 raw medians |
| 3.7 Final decisions | DONE | Pre-seed unknown; explicit nil unset status; fixed-cost entry snapshot survives rule edits/deletion |
| App builds and unchanged launch | PASS | Simulator/Release unsigned builds plus signed device build, installation over existing app and successful launch |

## Implementation and storage

EnvelopeValue, TargetValue, NoSpendMarkValue and LedgerSettings replace the removed ownership/planning entities. EntryValue and RuleValue carry envelopeID, taxRate, serviceMode and isFixedCost. CategoryValue carries envelopeID and taxHint. Schema V1 remains version 1.0.0 in place, with optional/defaulted fields, UUID references, no unique constraints or relationships. No migration, external dependency or UI import was added. The isolated Core store is not connected to any current screen.

Fresh stores always persist the stable household and singleton settings; seed:false suppresses only preset categories. Child creation atomically inserts its seven category presets. Used system-key categories cannot be deleted, and their display override is customName. Category deletion also rejects targets outside the current month, matching the direct target-removal restriction; archive remains available and retains those versions. Household existence and one envelope per kind are validated.

Per-model changes, record orders, predicate-based row mutations, fresh contexts, rollback, detached state, revision/reload and 20-step undo are ported to all nine record types. Settings is a persisted singleton and participates in change sets and undo. Untouched rows retain their persistent identifiers/order. Backup remains wealthy-ledger version 1 with the new LedgerState fields; receipt-image matching/rollback mechanics are unchanged. Deleting a recurring rule preserves historical entry values and their provenance UUIDs; validation allows those historical rule UUIDs to refer to a deleted rule.

## Explicit calculation choices and assumptions

- Monthly allowance is quotient plus one minor unit on the earliest remainder days. Category versions use the same distribution as overall versions. A week uses the ledger's Foundation weekday setting (Monday=2 by default), seven civil days, and each day's month/version. If any day lacks an applicable target, allowance and remaining are nil and reward eligibility is false.
- Logging and no-spend status are envelope-wide, independent of requested category/currency. Any entry logs its day. A mark counts as no-spend only if that envelope has no expense that day, including fixed costs and other currencies. Fixed-cost exclusion changes target spent only, not whether the day was logged or had an expense.
- Monthly eligibility uses ceiling(0.8 × number of days); weekly eligibility requires five of seven logged days. No streak counter is introduced.
- Entries store isFixedCost, including manually classified entries. The recurring engine copies the rule flag at posting. Later rule changes/deletion do not change past entries. includeFixedCostsInTargets is the requested ledger setting applied at query time.
- Tax uses nonnegative integer inclusive amounts and isolated floor arithmetic, split into quotient/remainder to avoid multiplying a full Int amount by the percentage. Per-entry floor approximates per-invoice/per-rate rounding. The only production reference row is effective 2019-10-01 with 10/8 percent; synthetic alternative rates exist only in a test.
- Pre-seed/non-JPY entries retain nil tax. Summaries exclude unknown tax from tax/base totals and count unknown expense entries. Only expenses represent tax paid; income is excluded. Tax-exempt entries have zero tax.
- Takeout saving compares standard and reduced tax portions of the same recorded tax-inclusive amount. It is an estimate of tax portions, not a forecast of prices or equal pretax merchant pricing. It includes only JPY dine-in food expenses with known tax and an effective rule; unknown mode is excluded.
- Draft resolver defaults envelope to household and day to the caller's current civil day. Amount and currency are required rather than guessed. Category is optional (uncategorized uses nonfood); supplied invalid/archived/cross-envelope category requires input. It normalizes currency, preserves injected chronology, runs deterministic classification, flags disagreement, and produces a command preview without writes. Food without a known service mode falls back to standard; no unknown-mode takeout savings are counted.

These are documented implementation assumptions; no further unresolved design blocker remains. No performance internals were redesigned beyond porting record types. Untargeted preview scopes skip status arithmetic and still return nil remaining impacts.

## Tests and original-test adaptations

Command: `sh Verification/verify_core.sh`.

105 tests PASS, 1 opt-in benchmark SKIP, 0 FAIL, 1.575 seconds. Core compiler/concurrency warnings: zero. The original 89 normal tests remain represented; 16 additional cases cover domain acceptance and regressions (13 DomainV2Tests, one persistence entity-counter case, one fixed-cost snapshot case, one explicit query chronology case). One enabled Release disk benchmark test passed separately in 615.905 seconds (20 samples per metric).

- FoundationTests: retained six tests; fresh seeding/order/Codable/disk/image/isolated backup checks now use envelopes, targets, marks/settings and tax fields.
- LedgerTests: retained 13 tests; old ownership movement/correction cases map to valid envelope assignments, archives/deletion, currency amounts and target version boundaries; integer overflow and atomic failure remain covered.
- RecurringTests: retained 12 tests plus snapshot test; targets replace planning limits; child creation/dependent-history conflict replaces the removed ownership creation case. Month-end/leap/pause/backlog/dedup/cursor/save failure checks remain.
- QueryTests: retained eight tests plus explicit createdAt regression; envelope summary/category/currency/target isolation, archived history, Decimal aggregate overflow, civil-day/timezone filters, upcoming and timing intents remain.
- UndoTests: retained nine tests; entry reassignment/fixed classification and category deletion replace removed relation commands. Target previews replace old planning previews; file/history/failure/conflict invariants remain.
- EdgeTests: retained four tests; envelope metadata replaces removed metadata fields; external unrelated child/value edits survive undo; Codable/Sendable commands remain covered.
- PersistenceTests: retained six tests plus one new record-type counter case; one entry insert/update/delete, exact category cascade, persistent identifiers, sparse/tied orders, full-versus-incremental validation for every command, external context reload and save rollback remain. Child creation writes eight records (envelope plus seven presets); targets/marks/settings write only changed rows.
- ChangeSetUndoTests: retained five tests; changed-record counts, bounded history, persisted order/value conflicts and external identities unchanged in intent.
- FixTests: retained 16 tests; removed entry kinds cannot exist in EntryKind. Their former correction-edit case now verifies manual fixed-cost edits/undo; source/link protection, createdAt sorting, ended catch-up, SHA matching, unknown hashes, receipt cleanup/shared files/file-only revision and Observation cases remain.
- BenchmarkTests: disabled-by-default harness retains counts/boundaries and adapts fixture ownership to one household and planning records to five target versions. Adds weekly/monthly status and tax timing.

New DomainV2Tests verify 28/29/30/31-day exact sums, cross-month version arithmetic/negative remaining, unset/partial target behavior, 4-versus-5 logged reward, monthly 80% ceiling, child isolation, tax arithmetic/classification/overflow, known/unknown summaries, takeout mode exclusions, draft disagreement/chronology/no writes, pre-seed unknown tax, unset spending/marks, injected effective tables, configurable Sunday/Monday weeks, and historical category-target deletion protection.

Initial integration attempts failed during compilation while old tests were being adapted. After compilation, 10 tests failed because fixtures changed immutable household creation metadata; fixtures now copy persisted metadata. Final execution has no failures. No failures were hidden or reported as successful.

## Disk benchmark comparison

Host and configuration are the same Mac/Xcode/Swift as Cycle 1.1: Apple M4, 10 cores, 24 GiB, macOS 27.0.1, Xcode 27.0, Swift 6.4, arm64 Release. No heavy build/test ran concurrently with latency sampling. Exact command:

```sh
WEALTHY_BENCHMARK=1 WEALTHY_BENCHMARK_LABEL=cycle1.2 \
WEALTHY_BENCHMARK_OUTPUT=/private/tmp/wealthy-c1-2-logs/after.json \
swift test --package-path WealthyCore -c release --filter BenchmarkTests
```

Each disk size uses one household, 12 categories, five target versions, ten rules, one warm-up and 20 measured samples per operation. Fresh copied closed stores isolate each sample; setup/copy/disposal/prepared undo addition are excluded. Opening includes store initialization/first fully validated snapshot. OS caches are not flushed. The final category-deletion history guard was added while the benchmark binary was already running; it does not execute in any timed operation. Its regression and all final app builds are re-run after this guard. Tax-summary timing uses the fixture's nil-tax expenses and measures unknown counting; known-rate arithmetic is verified by unit tests, so this timing does not establish latency of a fully classified 50k ledger.

| Entries | Operation | Cycle 1.1 median ms | Cycle 1.2 median ms | Change | Acceptance |
| --- | --- | ---: | ---: | ---: | --- |
| 10,000 | addEntry | 36.285 | 27.188 | -25.1% | PASS |
| 10,000 | updateEntry | 43.577 | 26.808 | -38.5% | PASS |
| 10,000 | deleteEntry | 45.645 | 26.215 | -42.6% | PASS |
| 10,000 | undo | 109.208 | 35.567 | -67.4% | PASS |
| 10,000 | previewAddEntry | 59.363 | 17.051 | -71.3% | Informational |
| 10,000 | postRecurring | 61.957 | 24.928 | -59.8% | Informational |
| 10,000 | openStore | 651.170 | 397.726 | -38.9% | PASS |
| 50,000 | addEntry | 337.830 | 166.138 | -50.8% | PASS |
| 50,000 | updateEntry | 309.047 | 182.733 | -40.9% | PASS |
| 50,000 | deleteEntry | 304.692 | 184.965 | -39.3% | PASS |
| 50,000 | undo | 408.936 | 244.043 | -40.3% | PASS |
| 50,000 | previewAddEntry | 203.708 | 125.228 | -38.5% | Informational |
| 50,000 | postRecurring | 185.132 | 159.598 | -13.8% | Informational |
| 50,000 | openStore | 2805.114 | 2652.149 | -5.5% | PASS |

Required mutation limits are 120% of the exact prior medians; opening must not exceed the prior median. Preview/recurring timing is informational. Failed limits: none.

| Entries | New query | Median ms |
| --- | --- | ---: |
| 10,000 | weekTargetStatus | 0.038 |
| 10,000 | monthTargetStatus | 0.481 |
| 10,000 | taxSummary | 0.041 |
| 50,000 | weekTargetStatus | 0.283 |
| 50,000 | monthTargetStatus | 3.098 |
| 50,000 | taxSummary | 0.191 |

Process physical-footprint growth over 20 additions at 10k: 20,873,240 bytes (19.91 MiB), versus 21,364,784 bytes (20.38 MiB) in Cycle 1.1. This includes persistence, allocator and history overhead, not isolated undo memory. Raw 20-sample JSON is retained locally. No optional phone performance run or live CloudKit synchronization was performed.

## App and unchanged verification

Commands:

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme Wealthy -destination 'id=CONNECTED_IPHONE_UDID' -derivedDataPath /private/tmp/wealthy-c1-2-device-build -allowProvisioningUpdates build
```

All three builds PASS. Existing app AppIntents metadata-extraction warning remains; Core warnings are zero. No settings/project/app sources were modified by this task.

| Existing command | Result | Checks | Duration |
| --- | --- | ---: | ---: |
| `python3 Verification/verify_receipt_ocr.py` | PASS | 91 | 8.286s |
| `sh Verification/verify_backup.sh` | PASS | 114 | 6.820s |
| `sh Verification/verify_localization.sh` | PASS | 6,634 | 3.356s |
| `sh Verification/verify_payments.sh` | PASS | 96 | 3.900s |
| `sh Verification/verify_migration.sh` | PASS | 11 | 2.776s |
| `sh Verification/verify_currency.sh` | PASS | 40 | 1.742s |
| `sh Verification/verify_policies.sh` | PASS | 73 | 2.626s |
| `sh Verification/verify_money_tip.sh` | PASS | 1,524 | 3.284s |

Total existing checks: 8,583 PASS, 0 FAIL. Scripts unchanged.

GUI testing: none requested/performed. Launch confirmation used xcrun devicectl to install the signed app over the existing paired iPhone 16 Pro Max installation, launch com.harrison.Wealthy, and query its running process (PID 24085 at verification). No uninstall, reset, preference override or data mutation was performed. Expected: unchanged app builds and launches. Actual: BUILD SUCCEEDED and launch successful; process alive. No simulator runtimes/devices were available, so physical device was used. Screen behavior and existing financial data were not re-tested in this cycle.

## Files, evidence, deviations and delivery

Changed: WealthyCore/Sources/WealthyCore Values, Schema, Store, PersistenceRecords, Changes, IncrementalValidation, Commands, Planning, Queries, Results; new Targets.swift, Tax.swift, Drafts.swift. All existing package test files adapted; new DomainV2Tests.swift. Verification/README.md, .ai/CURRENT_TASK.md and this report updated. Backup.swift/Files.swift retain their image transaction implementation and serialize the new LedgerState automatically. Package.swift and repository root README/license unchanged. No binary/log/cache/private screenshot is staged.

Local evidence: /private/tmp/wealthy-c1-2-logs/ contains core-final.log, benchmark.log/after.json, earlier integration logs, final-baseline.json and eight script logs, Simulator/Release/signed build logs and device install/launch/process logs. Cycle 1.1 comparator: /private/tmp/wealthy-c1-1-logs/after.json. Reproduce package tests and benchmark with Verification/README.md; launch commands substitute a paired device ID.

No product redesign, UI switch, live CloudKit synchronization, legacy migration, speculative tax-rate reference data or extra performance optimization was undertaken. Tax/target/week assumptions and benchmark workload limits are explicit above. Source commit 862a604fd1809c04739ea4ebf09038765a490e87 was pushed and matched the remote feature branch. PR #4 was created with base main. The final report-link commit is pushed separately and checked against both the remote branch and PR head. `git diff --stat origin/main...HEAD -- Wealthy/` is empty, confirming no committed app/project changes. Original three .DS_Store modifications and Xcode project three blank-line removals remain outside task commits. No main push/merge/force push is performed. Work stops after final push verification.
