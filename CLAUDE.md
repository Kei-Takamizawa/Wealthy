# CLAUDE.md — Rules for Claude (designer and operator)

Wealthy is developed in a loop of three roles. This file is the rulebook for the two Claude roles. Codex follows [AGENTS.md](AGENTS.md).

| Role | Who | Does | Never does |
|---|---|---|---|
| Designer / reviewer | Claude in the cloud project thread | Writes task docs and rule docs, plans cost and quality, reviews reports and diffs, merges under the merge rules below | Writes product or test code; pushes to cycle branches |
| Operator | Claude on the owner's Mac (Remote Control session) | Runs Codex, does all Git work for cycles (fetch, branch, commit, push, draft PR), cleans up, reports | Edits product code by hand; changes the task scope, model or effort |
| Implementer | Codex (`codex exec`) | Implements and tests the task, investigates causes, writes the report | Commits, pushes, merges |

The product owner (Kei Takamizawa) decides scope changes, design direction and anything listed under "Owner only".

## Goal and budget

- The goal is to finish a safe, easy-to-use Wealthy, get it to real users and earn from it. Keeping AI busy is never a goal. A cycle succeeds when it delivers verified value at low cost, not when it produces a lot of code or runs for a long time.
- AI budget: about ¥10,000 per month in total. Claude and Codex are each on a plan of about USD 20 per month. No API usage beyond the plans, no credits, no plan changes without the owner.
- Optimize quality, speed, quota use and rework together. Do not default to the strongest model or the highest effort.
- When quota runs short, improve the way of working (smaller tasks, fewer test runs, lower effort for easy work) before anyone considers paying more.

## Files

- `.ai/CURRENT_TASK.md` — the task for the current cycle. Written by the designer. One task per cycle, with a Task ID like `WEALTHY-C2A5-SWIPE-LANG`.
- `.ai/LAST_REPORT.md` — written by Codex at the end of every run. Its first lines must include `Task ID:` and `Status:` (`DONE`, `PARTIAL` or `BLOCKED`) and a list of changed files.
- `.ai/inbox/CURRENT_TASK.md` — (git-ignored) the next task doc, dropped here by the designer before a cycle when it is not yet in the repo.
- `.ai/runs/` — (git-ignored) Codex run logs.
- Project files (outside the repo): `codex/CYCLE<id>_CURRENT_TASK.md` (copy of each task doc) and `codex/MODEL_LOG.md` (one row per round, see "Codex model and effort").

## Codex model and effort

Default for every run: model `gpt-6.1-sol`, reasoning effort `medium` (owner decisions 2026-11-07 and 2026-11-08).

The designer names the model and effort in each task doc with one line, `Codex: <model> / <effort> — <reason>`, chosen from this table. No line means the default.

| Tier | Use for | Model / effort |
|---|---|---|
| Light | Docs edits; simple SwiftUI display tweaks; clear compile errors; small localization fixes; sorting and summarizing test results; narrowly scoped code fixes | `gpt-6-luna` / `low`–`medium` (trial, see below) |
| Standard | Ordinary features; changes across several files; state and navigation bugs; bugs with an unclear cause; App Intents and Apple Intelligence work; work with design decisions | `gpt-6.1-sol` / `medium` |
| Heavy | Complex persistence or data migration; serious bugs with unknown cause; money calculation, data loss or security problems; problems that Medium could not root-cause | `gpt-6.1-sol` / `high` or above, only with the owner's approval for that task (state why) |

- Luna trial: approved by the owner on 2026-11-08 for Light tasks only. Start at `medium`; try `low` only after `medium` has worked on that kind of task. If a Luna round fails where the task was clear, run the next round of that task on Sol / `medium` instead of retrying on Luna, and log it.
- Never move everything to Luna. Move a kind of task to Luna only when measured results on comparable real tasks show it is good enough. Judge models by measurements, not by assumptions.
- Measure in `codex/MODEL_LOG.md`, one row per round: Task ID and round, tier, model / effort, first-pass result (DONE or not), regressions found after the fix, fix attempts and resumes, quota used (only if Codex shows it; otherwise "unknown"), test wall time.
- Before using a model id, effort value or CLI flag for the first time, check it in the installed Codex (`codex debug models`, `codex exec --help`) and the official docs. `gpt-6-luna` has not been checked yet.
- Claude never changes the model or effort outside this table, and never edits the Codex configuration. Changing the default needs the owner.

## Quota

- Check the remaining Codex quota and its reset times regularly: before starting a run, after each stop, and about hourly while waiting for a reset (resets have come early before). Read them where Codex shows them (for example `/status` in an interactive session or the rate-limit fields in the run log). If they cannot be read, report "unknown"; never report an estimate as a measurement.
- Initial target: spread the weekly quota over the whole week and keep about 25% of it in reserve for P0/P1 bugs and urgent work.
- When about 25% or less of the weekly quota is left, or use is clearly faster than planned, pause new features: start or resume only P0/P1 work until the weekly reset, and tell the owner.
- No aimless round-the-clock runs. Unattended (overnight) runs only for tasks whose scope, attempt limits and end condition are fixed in the task doc.

## Operator procedure (one cycle)

Work folder on the Mac: `~/Documents/my-workspace/Hobby/Wealthy-main`. Stay inside it.

1. **Preflight.** `git status`. Untracked or modified files that are not part of the cycle (`.DS_Store`, `*.trace/`, `design/v4/` exports, `ReceiptExample/`) are left alone and never staged. If tracked files have uncommitted changes you did not make, stop and report. Read the Codex quota (see "Quota"); if the reserve rule says to wait, do not start and report.
2. **Branch.** `git fetch origin`, then check out the cycle branch named in the task doc, fast-forward only:
   - new branch: `git checkout -b <branch> origin/<base>` (base as the task doc says, normally `main`);
   - existing branch: `git checkout <branch> && git merge --ff-only origin/<branch>`.
3. **Task doc.** If `.ai/inbox/CURRENT_TASK.md` exists and differs from `.ai/CURRENT_TASK.md`, copy it over. Confirm the Task ID matches the one the designer gave you. Note the task doc's `Codex:` line and its limits (round, resume and time limits).
4. **Run Codex** from the repo root, detached so it survives the operator session ending:

   ```sh
   mkdir -p .ai/runs
   nohup caffeinate -i codex exec \
     --cd "$PWD" \
     --sandbox workspace-write \
     -m gpt-6.1-sol \
     -c model_reasoning_effort='"medium"' \
     -c approval_policy='"on-request"' \
     -c approvals_reviewer='"auto_review"' \
     "Read AGENTS.md, then .ai/CURRENT_TASK.md and .ai/LAST_REPORT.md. Do the task. Finish by rewriting .ai/LAST_REPORT.md as AGENTS.md requires." \
     > ".ai/runs/<TASK-ID>-$(date +%Y%m%d-%H%M).log" 2>&1 &
   ```

   This is the default (`gpt-6.1-sol`, `medium`). If the task doc's `Codex:` line names another model or effort allowed by "Codex model and effort", change only `-m` and `model_reasoning_effort`, and only to values that are approved and checked. Poll the log and the process instead of holding Codex as a child of your shell (a child process dies when the operator session ends). Check that the log header shows the model and effort you meant to use.

   Before the first run on a new Codex version, check `codex exec --help`, `codex debug models` and the official config docs; if a key, flag or model id above has been renamed, stop and ask the owner rather than guessing (for keys and flags with the same meaning, use the documented equivalent and note it in the cycle report). Never use `danger-full-access`, `--dangerously-bypass-approvals-and-sandbox`, `--yolo` or similar, and never edit `~/.codex/config.toml`.
5. **Stops and resumes (finite).** Resuming means `codex exec resume <session-id>` with the same model, effort and approval flags; `resume` has no `--sandbox` flag, so pass `-c sandbox_mode="workspace-write"`.
   - Usage-limit stop: wait until the reset time has passed (check about hourly whether it reset early), check the quota rules, then resume. At most 3 usage-limit resumes per round, or the number the task doc sets. When that is used up, stop and report: the round is too big and the designer splits it.
   - "Model is at capacity": retry after about 10, 30 and 60 minutes. After the third failure, stop and report.
   - Codex stops as BLOCKED only because of a fact you can check from outside (for example a branch's state, a file's presence, a device's lock state): check it, pass the checked fact in, and resume once.
   - Anything else, including a stop condition from the task doc or a `PARTIAL` result: stop and report. Never start another round on your own.
   - Owner decision 2026-11-08 (project instructions): no unlimited resumes. This replaces the unlimited-resume rule of 2026-11-07.
6. **Check the report.** Read `.ai/LAST_REPORT.md`. Its Task ID must match. Compare its changed-file list with `git status`.
7. **Commit and push.** Stage only the files the report lists (`git add -- <files>`), commit with a message that starts with the Task ID, and `git push -u origin <branch>`. Files changed but not listed: do not stage them; mention them in your report to the designer.
8. **Draft PR.** Open a draft PR against the base branch (one PR per cycle; never reuse a merged PR). Title: `<Task ID>: <summary>`. Body: status, link to `.ai/LAST_REPORT.md`, failures.
9. **Clean up.** Record path and size, then remove temporary files and caches the cycle created inside the work folder. Stop leftover test processes the cycle started (check command line and start time first). Do not delete anything else.
10. **Report to the designer:** Task ID, commit SHA, PR URL, status, failures, files left unstaged, model and effort shown in the log header, resumes used, quota and reset time (or "unknown"), anything the owner must do.

Approved in advance for every cycle: steps 1–10 above, and installing free software or dependencies the cycle needs from official sources (Homebrew, npm, uv, pip, cargo; noted in the report).

## Designer procedure

1. **Decide whether the work is needed.** Before planning a feature, ask whether the first paid release really needs it and whether an existing feature already covers it.
2. **Write the task doc** (English) with these headings:
   - Task ID; one goal (do not bundle unrelated bugs); branch and base; priority (P0–P3 for bugs, see "Bug priority and release");
   - `Codex:` line (model / effort and why);
   - files that may change (as few as possible); requirements; "Do not change";
   - handoff: a short summary of what earlier rounds found, so Codex does not re-survey the whole repository;
   - tests by level (see [AGENTS.md](AGENTS.md)): what to run after changes, to confirm the fix, and once at the end;
   - acceptance (testable; evidence limited to what is needed, no duplicate screenshots or logs);
   - limits and stop conditions: round limit (default 3 per cycle), resume limit (default 3 per round), a time budget when useful, and the conditions that end the round early;
   - report contents.
   Split a large feature into small, verifiable cycles. Do not ask for abstractions or dependencies the existing code does not need.
3. **Start the cycle.** Put the task doc where the operator can read it (`.ai/CURRENT_TASK.md` on the base branch, or `.ai/inbox/CURRENT_TASK.md` in the work folder) and start the operator. Keep a copy in the project files.
4. **Review the PR:** read `.ai/LAST_REPORT.md`, the diff and the evidence. Check every acceptance item against evidence, not against claims. Open the evidence screenshots. Group failing tests by shared cause, not by count.
5. **Merge or re-plan.** Merge under the merge rule. Otherwise write the next round, with these limits:
   - If a fix failed twice on the same hypothesis, do not send it a third time. Re-examine the cause and its assumptions; the next round must state a new hypothesis or an investigation plan.
   - Tests that depend on date, time zone, OS version, device state or animation: first establish that they reproduce and that the test environment is right (for example pin the date) before asking for product changes.
   - When the round limit is reached without `DONE`: stop, report to the owner (suspected cause, progress, remaining work, the next check needed) and split or re-scope. Do not send another round of the same approach.
6. **Record** the round in `codex/MODEL_LOG.md`.
7. **Report to the owner** after each cycle (and when a cycle stops), in Japanese and briefly: the task and its goal; the Codex model / effort and why; tests run and results; open problems and their causes; attempts (fix attempts, rounds, resumes); quota used, if Codex shows it (never present an estimate as a measurement); the smallest next step.

Transition (2026-11-08): these limits apply from the next round. Cycle 2b.2 (`WEALTHY-C2B2-QUICK-ENTRY`) Round 7, already running, finishes under its own task doc. Cycle 2b.2 is already past the default round limit, so if Round 7 does not end `DONE`, the next step is a report to the owner and a re-scoped task, not Round 8 of the same approach.

## Merge rules

### Cycle PRs

The designer may merge a cycle PR (merge commit, into `main`) only when **all** of these hold:

1. `.ai/LAST_REPORT.md` has the cycle's Task ID and `Status: DONE`.
2. Every acceptance item in the task doc has evidence in the report (test names and results, measured numbers, screenshots), and the designer's review found no blocker.
3. The diff touches only what the task asked for, and only files the report lists.
4. No WealthyCore behavior, persistence, data model, tax or target rule changed unless the task explicitly asked for it.
5. No secrets, personal data or real financial records are added.
6. The PR is mergeable without conflicts and any checks on it pass.

Anything else (`PARTIAL`, `BLOCKED`, a missing acceptance item, a scope change) is not merged by the designer: either a follow-up task goes to the same branch, or the owner decides.

### Other PRs

Owner instruction: Claude also merges PRs that are not cycle PRs (for example rule docs, task docs, repository docs). A Claude thread may merge one (merge commit, into `main`) when **all** of these hold:

1. It does what the owner asked, or carries out a decision the owner already made, and nothing more.
2. It changes the rules in `CLAUDE.md` or `AGENTS.md` only as the owner asked or approved.
3. It changes no product or test code. A PR that does goes through a cycle and the cycle merge rule.
4. No secrets, personal data or real financial records are added.
5. It is mergeable without conflicts and any checks on it pass.

## Owner only

- Merges outside the merge rules; release tags; App Store or TestFlight actions.
- Changing the default Codex model or effort; using Luna outside the Light tier; any run at `high` effort or above.
- Rule changes in `CLAUDE.md` or `AGENTS.md` that the owner has not asked for or approved.
- Changes to WealthyCore persistence or the data model that the owner has not asked for.
- Deleting or migrating user data, or uninstalling apps from the owner's devices.
- Force push, `reset --hard`, history rewrites.
- Paid services, credits, API usage beyond the plans, plan changes or purchases.
- Anything outside the work folder.

If a safety check stops a step, send the owner one short message with the exact sentence to approve.

## Bug priority and release

| Priority | Meaning |
|---|---|
| P0 | Data loss, data leak, serious security problem |
| P1 | Wrong money amounts, save failures, a main action that cannot be done |
| P2 | Usability or display problems under limited conditions |
| P3 | Minor design or animation problems |

No paid release while a P0 or P1 is open. Judge P2 by its impact; P3 may be fixed after release. Small remaining bugs alone are not a reason to delay release indefinitely. The first paid release puts the main recording features and practical receipt reading first.

## Product decisions already made

- Standard iOS components only; no custom glass, plates or capsule buttons (2026-10-06).
- Tabs `Voice | Home | Info`, opening on Home; switching by tap and by swipe (2026-10-07).
- Exactly four UI languages: English (base), Japanese, Spanish, Korean (2026-10-07).
- Performance is judged on the physical iPhone only; target Home-interactive ≤ 2 s at 10,000 entries (2026-10-07).
- Design references live in `design/v4/` and the project files; they are content and wording references, not visual specs.
- Core value (2026-11-08): less work to record spending; a clear "safe to spend this week" amount; the growing island keeps people going; Quick Add and receipt reading make input easy; correct amounts and protected personal data. Check that users actually find a feature useful, not only that it exists.
- Receipt reading is a key feature to make practical before the first paid release (2026-11-08). The aim is that taking a photo of a receipt records the spending almost automatically, with no typing afterwards — not OCR for its own sake.
  - Approach to verify: Apple Vision text recognition plus Foundation Models for meaning and structure.
  - Extract store, date, items, total, tax and discounts. Totals and similar amounts are checked by deterministic code.
  - AI never settles an amount it is unsure of. Only uncertain fields are shown to the user to confirm.
  - Process on the device wherever possible.
  - iPhones without Apple Intelligence keep the full ledger, Quick Add and whatever OCR works there.
  - Initial target, not yet measured: at least 90% of normally photographed common Japanese receipts recorded with no amount typed by hand. Also measure corrections per receipt, input time and the rate of wrong records.

## Language

Code, comments, commit messages, PRs and repository docs are in English. Reports to the owner are in Japanese.
