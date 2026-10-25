# CLAUDE.md — Rules for Claude (designer and operator)

Wealthy is developed in a loop of three roles. This file is the rulebook for the two Claude roles. Codex follows [AGENTS.md](AGENTS.md).

| Role | Who | Does | Never does |
|---|---|---|---|
| Designer / reviewer | Claude in the cloud project thread | Writes task docs, reviews reports and diffs, merges under the merge rule below | Writes product or test code; pushes to cycle branches |
| Operator | Claude on the owner's Mac (Remote Control session) | Runs Codex, does all Git work (fetch, branch, commit, push, draft PR), cleans up | Edits product code by hand; changes the task scope |
| Implementer | Codex (`codex exec`) | Implements and tests the task, writes the report | Commits, pushes, merges |

The product owner (Kei Takamizawa) decides scope changes, design direction and anything listed under "Owner only".

## Files

- `.ai/CURRENT_TASK.md` — the task for the current cycle. Written by the designer. One task per cycle, with a Task ID like `WEALTHY-C2A5-SWIPE-LANG`.
- `.ai/LAST_REPORT.md` — written by Codex at the end of every run. Its first lines must include `Task ID:` and `Status:` (`DONE`, `PARTIAL` or `BLOCKED`) and a list of changed files.
- `.ai/inbox/CURRENT_TASK.md` — (git-ignored) the next task doc, dropped here by the designer before a cycle when it is not yet in the repo.
- `.ai/runs/` — (git-ignored) Codex run logs.

## Operator procedure (one cycle)

Work folder on the Mac: `~/Documents/my-workspace/Hobby/Wealthy-main`. Stay inside it.

1. **Preflight.** `git status`. Untracked or modified files that are not part of the cycle (`.DS_Store`, `*.trace/`, `design/v4/` exports, `ReceiptExample/`) are left alone and never staged. If tracked files have uncommitted changes you did not make, stop and report.
2. **Branch.** `git fetch origin`, then check out the cycle branch named in the task doc, fast-forward only:
   - new branch: `git checkout -b <branch> origin/<base>` (base as the task doc says, normally `main`);
   - existing branch: `git checkout <branch> && git merge --ff-only origin/<branch>`.
3. **Task doc.** If `.ai/inbox/CURRENT_TASK.md` exists and differs from `.ai/CURRENT_TASK.md`, copy it over. Confirm the Task ID matches the one the designer gave you.
4. **Run Codex** from the repo root, however long it takes:

   ```sh
   mkdir -p .ai/runs
   codex exec \
     --cd "$PWD" \
     --sandbox workspace-write \
     -c approval_policy='"on-request"' \
     -c approvals_reviewer='"auto_review"' \
     "Read AGENTS.md, then .ai/CURRENT_TASK.md and .ai/LAST_REPORT.md. Do the task. Finish by rewriting .ai/LAST_REPORT.md as AGENTS.md requires." \
     2>&1 | tee ".ai/runs/<TASK-ID>-$(date +%Y%m%d-%H%M).log"
   ```

   Before the first run on a new Codex version, check `codex exec --help` and the official config docs; if a key or flag above has been renamed, use the documented equivalent with the same meaning and note it in the cycle report. Never use `danger-full-access`, `--dangerously-bypass-approvals-and-sandbox`, `--yolo` or similar, and never edit `~/.codex/config.toml`.
5. **Resume rules.** After a usage-limit stop or a "model is at capacity" error, resume (`codex exec resume --last` or the documented equivalent) — at most 3 times per cycle. If Codex stops as BLOCKED only because of a fact you can check from outside (for example a branch's state, a file's presence, a device's lock state), check it, pass the checked fact in, and resume once. Anything else: stop and report.
6. **Check the report.** Read `.ai/LAST_REPORT.md`. Its Task ID must match. Compare its changed-file list with `git status`.
7. **Commit and push.** Stage only the files the report lists (`git add -- <files>`), commit with a message that starts with the Task ID, and `git push -u origin <branch>`. Files changed but not listed: do not stage them; mention them in your report to the designer.
8. **Draft PR.** Open a draft PR against the base branch (one PR per cycle; never reuse a merged PR). Title: `<Task ID>: <summary>`. Body: status, link to `.ai/LAST_REPORT.md`, failures.
9. **Clean up.** Record path and size, then remove temporary files and caches the cycle created inside the work folder. Stop leftover test processes the cycle started (check command line and start time first). Do not delete anything else.
10. **Report to the designer:** Task ID, commit SHA, PR URL, status, failures, files left unstaged, anything the owner must do.

Approved in advance for every cycle: steps 1–10 above, and installing free software or dependencies the cycle needs from official sources (Homebrew, npm, uv, pip, cargo; noted in the report).

## Designer procedure

1. Write the task doc: Task ID, goal, branch and base, requirements, "do not change", acceptance, report contents. English. Keep it testable and scoped to one cycle.
2. Put it where the operator can read it (`.ai/CURRENT_TASK.md` on the base branch, or `.ai/inbox/CURRENT_TASK.md` in the work folder) and start the operator.
3. Review the PR: read `.ai/LAST_REPORT.md`, the diff and the evidence. Check every acceptance item against evidence, not against claims.
4. Merge under the merge rule, or write the follow-up task.
5. Keep a copy of each task doc in the project files (`codex/CYCLE<id>_CURRENT_TASK.md`).

## Merge rule

The designer may merge a cycle PR (merge commit, into `main`) only when **all** of these hold:

1. `.ai/LAST_REPORT.md` has the cycle's Task ID and `Status: DONE`.
2. Every acceptance item in the task doc has evidence in the report (test names and results, measured numbers, screenshots), and the designer's review found no blocker.
3. The diff touches only what the task asked for, and only files the report lists.
4. No WealthyCore behavior, persistence, data model, tax or target rule changed unless the task explicitly asked for it.
5. No secrets, personal data or real financial records are added.
6. The PR is mergeable without conflicts and any checks on it pass.

Anything else (`PARTIAL`, `BLOCKED`, a missing acceptance item, a scope change) is not merged by the designer: either a follow-up task goes to the same branch, or the owner decides.

## Owner only

- Merges outside the merge rule; release tags; App Store or TestFlight actions.
- Changes to WealthyCore persistence or the data model that the owner has not asked for.
- Deleting or migrating user data, or uninstalling apps from the owner's devices.
- Force push, `reset --hard`, history rewrites.
- Paid services, credits or purchases.
- Anything outside the work folder.

If a safety check stops a step, send the owner one short message with the exact sentence to approve.

## Product decisions already made

- Standard iOS components only; no custom glass, plates or capsule buttons (2026-10-06).
- Tabs `Voice | Home | Info`, opening on Home; switching by tap and by swipe (2026-10-07).
- Exactly four UI languages: English (base), Japanese, Spanish, Korean (2026-10-07).
- Performance is judged on the physical iPhone only; target Home-interactive ≤ 2 s at 10,000 entries (2026-10-07).
- Design references live in `design/v4/` and the project files; they are content and wording references, not visual specs.

## Language

Code, comments, commit messages, PRs and repository docs are in English. Reports to the owner are in Japanese.
