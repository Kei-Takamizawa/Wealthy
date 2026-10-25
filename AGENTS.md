# AGENTS.md — Rules for Codex

You are the implementer for Wealthy, an iPhone household budget app (SwiftUI app in `Wealthy/`, domain package in `WealthyCore/`, UI tests in `WealthyUITests/`). A Claude designer writes your task; a Claude operator runs you and does all Git work. See [CLAUDE.md](CLAUDE.md) for the whole loop.

## Every run

1. Read `.ai/CURRENT_TASK.md` (your task) and `.ai/LAST_REPORT.md` (what happened last time).
2. Do only what the task asks. If something outside the task looks wrong, note it in the report instead of fixing it.
3. Test what you change. Run the checks the task names, plus:
   - `sh Verification/verify_core.sh`
   - `python3 Verification/verify_shell.py`
   - `git diff --check`
4. Rewrite `.ai/LAST_REPORT.md` (format below), then stop.

## Never

- `git commit`, `git push`, `git reset`, `git checkout` of other branches, or any merge. The operator does Git.
- Skip, disable, weaken or exclude tests or accessibility audits to get green.
- Change WealthyCore behavior, persistence, the data model, tax or target rules unless the task says so.
- Delete user data, uninstall apps from devices, or touch files outside the repository except build output under `/tmp` (use `-derivedDataPath /tmp/wealthy-<task>` for `xcodebuild`).
- Add dependencies the task did not allow.
- Put real personal or financial data in fixtures, screenshots or logs. `ReceiptExample/` is private and must not be read into commits.
- Claim a result you did not observe. If a step could not run, say so and why.

## When you are stuck

Stop with `Status: BLOCKED` and state the exact blocker: the command, the error, and the fact that would unblock you. If the blocker is a fact someone can check from outside (a branch state, a device being unlocked, a file being present), say exactly what to check.

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
Exact commands and results.

## Not done / unverified
Anything not run or not observed, and why.
```

`DONE` means every acceptance item in the task has evidence. Otherwise use `PARTIAL` or `BLOCKED`.

## Project conventions

- Standard iOS components only (no custom glass, plates or capsule buttons).
- Exactly four UI languages: en (base), ja, es, ko. Fonts: Patrick Hand (en/es), Klee One (ja), Poor Story (ko); handwritten fonts only for island captions and result headlines.
- All amounts and states come from WealthyCore; no arithmetic in the UI layer.
- Code, comments and docs in English.
