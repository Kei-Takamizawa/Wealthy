# Cycle 1.2 domain v2 — blocked specification report

- Task ID: WEALTHY-C1.2-DOMAIN-V2
- Status: BLOCKED
- Date: 2026-10-05 JST
- Branch: codex/wealthy-c1-2-domain-v2
- Base: origin/main, 46a5888cd919c4ab0296be0f5ff2dbfae77d7061; PR #2 confirmed merged.
- PR: pending creation after the documentation commit.

## Work completed

Verified Git status and fetched origin. Created the requested branch from current main. Saved the complete supplied instruction, without omissions, in .ai/CURRENT_TASK.md. A read-only subagent independently checked specification gaps against the existing domain. No production or test implementation was changed.

## Decisions required from Claude and the product owner

1. **Tax lookup before the seed date.** Section 3.4 seeds only 2019-10-01, but section 7 explicitly requires a lookup before that day. For 2019-09-30 no effective record exists. Choose an explicit unsupported-date error, unknown/no-rate result, or provide approved historical reference data. Automatically applying the future seed would contradict effective-date lookup.
2. **No applicable target version.** Overall and category targets can be absent, while TargetStatus requires allowance, remaining and reward eligibility. Specify whether missing targets return an explicit unconfigured/optional status, no status, or zero allowance evaluated normally. A zero allowance can make a logged no-expense period reward eligible; an unconfigured status need not. This is a product decision, not a numeric implementation detail.
3. **Fixed-cost history.** Specify whether posted entries snapshot isFixedCost or queries consult the current recurring rule. Reproduction: post a fixed-cost expense, then toggle isFixedCost or delete its rule, and query the original month. The two policies produce different spent/remaining/reward results. Snapshot policy requires an approved entry field; live policy requires defined behavior for a missing rule.

Relevant existing files: WealthyCore/Sources/WealthyCore/Values.swift (EntryValue, RuleValue and BudgetValue); Planning.swift (recurring generation); Queries.swift (existing budget queries). Existing rules and entries have no fixed-cost flag, no tax rule book exists, and existing budget queries enumerate configured budgets. These facts do not authorize selecting new product policies.

No fallback, historical rate data, zero-target policy or new persisted classification field was invented. Decisions should be supplied as an amended final specification, consistent with the implementer/tester role.

## Requirement status

| Requirement | Status |
| --- | --- |
| 3.1 Remove old domain | Not implemented; blocked before model rewrite |
| 3.2 Envelopes | Not implemented |
| 3.3 Targets, daily/weekly evaluation, marks | Blocked by missing-target and fixed-cost history decisions |
| 3.4 Tax, drafts and summaries | Blocked by pre-seed lookup decision |
| 3.5 Commands and preview | Not implemented |
| 3.6 Preserve persistence/regressions/performance | Existing merged implementation retained; adaptations and benchmarks not run |
| Build/test acceptance | Not run for this cycle |
| App launch | Not run for this cycle |

## Validation and evidence

- git status --short: original three .DS_Store modifications and Xcode project blank-line changes retained.
- git fetch origin: PASS; origin/main advanced to 46a5888.
- gh pr view 2 --json state,mergeCommit: PASS; MERGED, merge commit 46a5888cd919c4ab0296be0f5ff2dbfae77d7061.
- Full supplied task copied to .ai/CURRENT_TASK.md.
- New tests executed: 0; existing tests executed: 0. PASS/FAIL test counts: not applicable, not executed.
- Core tests, disk benchmarks, Simulator/Release builds, all eight existing verification scripts: NOT RUN. No success is claimed from Cycle 1.1 for this cycle.
- GUI operations: none. App launch not attempted.
- Errors/warnings: no build logs produced; specification blockers above.
- Expected: an unambiguous final domain specification before implementation.
- Actual: three unresolved policies affect persisted fields or observable financial evaluation.

## Changes, deviations and delivery

Only .ai/CURRENT_TASK.md and .ai/LAST_REPORT.md are changed for this cycle. App sources, Xcode project, package implementation, tests, repository README and verification scripts are not modified by this task. Original user changes remain unstaged.

The intentional deviation is stopping before implementation, as required by the supplied AGENTS instructions when specification/design decisions are needed. Tax rounding, week handling and fixed-cost persistence assumptions have not been silently selected. No next cycle or extra improvement is started. This blocked instruction/report is committed and pushed on the feature branch; the PR link is recorded in a final report update.
