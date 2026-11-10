# CLAUDE.md — Development guide

Wealthy is an iPhone household budget app. Claude handles development directly: implementation, testing, review and Git work. The owner decides product scope and design direction. The former Claude–Codex loop is retired; do not launch or resume Codex for repository tasks.

## Working on a task

1. Read the owner's current request. Inspect the branch, HEAD and working tree before editing. Preserve unrelated local changes, including `.DS_Store`, design exports and traces.
2. Read the relevant specification and code. Implement the requested scope; ask the owner when an important product or architecture decision is missing or contradictory. Routine implementation details are Claude's responsibility.
3. Implement and test directly. Keep application code in `Wealthy/`, domain logic in `WealthyCore/` and UI tests in `WealthyUITests/`.
4. Review the diff against the request. Report changed files, observed test results, remaining failures and anything not verified. A build, simulator check and physical-device check are separate evidence.
5. Perform the task's Git work directly under the rules below, then stop when the requested work is complete. Further product work follows the owner's next request.

Task and report files under `.ai/` are optional records, not a dispatch queue. A new request does not require a designer-written task, an operator handoff or a separate agent. See [.ai/README.md](.ai/README.md) for the transition record and the previous product cycle's unresolved work. Historical instructions are reference material, not current authorization to resume work.

## Verification

Test what changes. Run the checks required by the task, plus:

```sh
sh Verification/verify_core.sh
python3 Verification/verify_shell.py
git diff --check
```

Use [Verification/README.md](Verification/README.md) for other checks. Run relevant builds and UI tests for app changes, with Xcode build output under `/tmp` (`-derivedDataPath /tmp/wealthy-<task>`). Use synthetic data for tests, screenshots and logs.

- Keep existing tests and accessibility audits intact; do not skip, weaken or exclude them to get a pass.
- Report an unrun check as unverified, with its reason. Claim only results observed in the current run; label historical evidence explicitly.
- Keep simulator, physical-device, Settings UI, VoiceOver and performance evidence distinct. Judge performance on the physical iPhone only: Home interactive must be at most 2 seconds at 10,000 entries.
- When blocked, report the exact command, error, confirmed facts and what would unblock the task. Do not repeatedly retry a usage limit or an unresolved environment failure.

## Git

- Fetch when remote state is needed. Use the branch and base authorized for the task; preserve unrelated working-tree changes.
- Stage only task files, inspect the staged diff, and use meaningful English commit messages. Push only to the authorized branch and verify the result. If the push destination is unclear, ask the owner.
- Open a draft PR when the task calls for one. Include the scope, verification evidence and remaining limits. Use a new PR after an earlier one has merged.
- Stop on conflicts or authentication errors that need a decision; report the exact problem.

Claude may merge a task PR into `main` with a merge commit only when all of these hold:

1. Every acceptance item has evidence and the task is complete; any task report has `Status: DONE`.
2. Review finds no blocker, the diff stays within the requested scope, and all required checks pass.
3. WealthyCore behavior, persistence, data model, tax and target rules changed only where the task explicitly allowed them.
4. No secrets, personal information or real financial records are included.
5. The PR is mergeable without conflicts.

Otherwise, report the remaining work or ask for the owner's decision. A partial or blocked task does not qualify for merging.

## Owner decisions and protected boundaries

- Use standard iOS components only; no custom glass, plates or capsule buttons.
- Tabs are `Voice | Home | Info`, opening on Home, with tap and swipe navigation.
- Exactly four UI languages: English (base), Japanese, Spanish and Korean. Fonts are Patrick Hand (en/es), Klee One (ja) and Poor Story (ko); handwritten fonts are only for island captions and result headlines.
- All amounts and states come from WealthyCore; keep money arithmetic out of views.
- Preserve WealthyCore behavior, persistence, the data model, tax and target rules unless the task explicitly requests a change.
- `design/v4/` contains content and wording references, not visual specifications.
- Add dependencies only when the task permits them. Use official sources and record what was installed.
- Preserve user data and existing device installations. `ReceiptExample/` is private; keep its contents out of commits, screenshots and public logs.
- Keep work inside the repository except temporary build/test output under `/tmp`. Changes outside it require the owner's instruction.

The owner must authorize merges outside the merge rule, release tags, App Store or TestFlight actions, deletion or migration of user data, uninstalling device apps, force pushes, destructive resets, history rewrites and paid services or purchases. Do not bypass authentication or safety checks.

## Language

Code, comments, commit messages, PRs and repository documents are in English. Direct reports to the owner are in Japanese. Keep the product README short and understandable to non-engineers.
