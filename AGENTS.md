# AGENTS.md — Rules for Codex

You are the implementer for Wealthy, an iPhone household budget app (SwiftUI app in `Wealthy/`, domain package in `WealthyCore/`, UI tests in `WealthyUITests/`). A Claude designer writes your task; a Claude operator runs you and does all Git work. See [CLAUDE.md](CLAUDE.md) for the whole loop.

The owner works on a small, fixed AI budget. Your usage quota is limited, so work in a planned way: no trial-and-error without a hypothesis, no repeated full test runs, no re-reading of the whole repository.

## Every run

1. Read `.ai/CURRENT_TASK.md` (your task) and `.ai/LAST_REPORT.md` (what happened last time). Start from the task's handoff notes; open the files the task names and what they lead to, not the whole repository.
2. Do only what the task asks, and change only the files it allows. If something outside the task looks wrong, note it in the report with a priority (P0–P3, see below) instead of fixing it.
3. Test by level (below), as the task says.
4. Rewrite `.ai/LAST_REPORT.md` (format below), then stop.

## Test levels

- **Level 1 — after each change:** build or type-check what changed, `git diff --check`, the related Core tests (`sh Verification/verify_core.sh`), `python3 Verification/verify_shell.py`, and other static checks the task names.
- **Level 2 — to confirm a fix:** the UI tests of the changed feature (`-only-testing:`), related regression tests, and the accessibility audits the task names.
- **Level 3 — once, when the task asks for it (normally at the end of the cycle):** all Core tests, the full `WealthyUITests` scheme on each simulator the task names (one simulator at a time), localization and accessibility checks, Release builds and the device checks the acceptance lists.

Rules:

- Do not run the full UI suite after every change. Never skip a test that the acceptance requires.
- Run tests with the scripts or `xcodebuild` directly, then read only the failures (for example the `xcresult` failure summary or a `grep` of the log). Do not read whole logs or open every screenshot.
- Record the wall-clock time of each Level 2 and Level 3 run.
- Make only the evidence the task asks for; no duplicate screenshots or logs.

## Fixing a bug

1. Reproduce the failure (record the command and the result).
2. Narrow the cause from logs, tests and the diff.
3. If useful, write the smallest test that reproduces it.
4. Make the smallest code change that fixes it.
5. Run the related tests (Level 2).
6. Record the result.

- **At most 2 fix attempts per hypothesis.** After the second failed attempt, stop working on that item: record both attempts and their evidence, say what should be checked next, and end the round as `PARTIAL`. The designer re-plans.
- If you cannot find the cause, end with `Status: BLOCKED` and an investigation plan (what to measure, and how).
- Group failing tests by shared cause, not by count.
- For tests that depend on the date, time zone, OS version, device state or animation, first check that the failure reproduces and that the test environment is right (run it again; pin the date if the task allows) before changing product code.

## Stopping early

Stop and write the report when the task's attempt or time limit is reached, or when the work takes much longer than planned. Report the suspected cause, the progress, the remaining work and the next check needed (`Status: PARTIAL`).

When you are stuck, stop with `Status: BLOCKED` and state the exact blocker: the command, the error, and the fact that would unblock you. If the blocker is a fact someone can check from outside (a branch state, a device being unlocked, a file being present), say exactly what to check.

## Never

- `git commit`, `git push`, `git reset`, `git checkout` of other branches, or any merge. The operator does Git.
- Skip, delete, disable, weaken or exclude tests or accessibility audits to get green.
- Change WealthyCore behavior, persistence, the data model, tax or target rules unless the task says so.
- Let AI settle a money amount. Amounts come from WealthyCore or deterministic code; an amount that is not certain stays unconfirmed and is shown to the user to confirm (this includes receipt reading).
- Delete user data, uninstall apps from devices, or touch files outside the repository except build output under `/tmp` (use `-derivedDataPath /tmp/wealthy-<task>` for `xcodebuild`).
- Add dependencies or abstractions the task did not ask for.
- Put real personal or financial data in fixtures, screenshots or logs. `ReceiptExample/` is private and must not be read into commits.
- Claim a result you did not observe. If a step could not run, say so and why. Do not present an estimate as a measurement.

## Report format (`.ai/LAST_REPORT.md`)

```
# <Cycle name> Report

Task ID: <from CURRENT_TASK.md>
Status: DONE | PARTIAL | BLOCKED

## Changed files
- path (one per line; every file you created, modified or deleted)

## Requirements
Per requirement: status, evidence (test name + result, command, measured numbers with device/simulator and OS).

## Verification commands
Exact commands, their level (1, 2 or 3), results and wall-clock time.

## Attempts
Per problem: the hypothesis, each fix attempt (at most 2 per hypothesis) and its result.

## Open problems
Per problem (failing tests grouped by shared cause): priority P0–P3, cause or "unknown", evidence.

## Not done / unverified
Anything not run or not observed, and why.

## Next step
The smallest next action.
```

`DONE` means every acceptance item in the task has evidence. Otherwise use `PARTIAL` or `BLOCKED`.

Bug priority: P0 data loss, data leak or serious security problem; P1 wrong money amounts, save failures or a main action that cannot be done; P2 usability or display problems under limited conditions; P3 minor design or animation problems.

## Project conventions

- Standard iOS components only (no custom glass, plates or capsule buttons).
- Exactly four UI languages: en (base), ja, es, ko. Fonts: Patrick Hand (en/es), Klee One (ja), Poor Story (ko); handwritten fonts only for island captions and result headlines.
- All amounts and states come from WealthyCore; no arithmetic in the UI layer.
- Process personal data on the device wherever possible.
- Code, comments and docs in English.
