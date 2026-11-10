# Development records

As of 2026-11-10, Claude develops Wealthy directly under [CLAUDE.md](../CLAUDE.md). The former designer/operator/implementer loop is retired. These files are optional records; there is no task inbox to process or automatic task to resume.

## Transition

- [Current task](CURRENT_TASK.md): the owner's request to move to Claude-only development.
- [Latest report](LAST_REPORT.md): the cleanup and its verification. Completion of this transition does not mean the product cycle below is complete.

## Previous product cycle

The previous task and report were preserved byte-for-byte before the transition:

- [Cycle 2b.2 task, through Round 7](archive/2026-11-10-claude-only/CURRENT_TASK.md)
- [Cycle 2b.2 Round 7 report](archive/2026-11-10-claude-only/LAST_REPORT.md), `Task ID: WEALTHY-C2B2-QUICK-ENTRY`, `Status: PARTIAL`
- [Cycle 2b.2 evidence on its unmerged branch](https://github.com/Kei-Takamizawa/Wealthy/blob/codex/wealthy-c2b2-quick-entry/Verification/Cycle2bEvidence/c2b2/INDEX.md)

The archived report records unresolved dark-mode contrast audit issues with no identified element on both simulators, missing CoreSimulator runtimes, and incomplete final Home/swipe checks and full UI suites. Final-tree device installation and App Intents metadata verification were also unverified. These are historical findings, not rechecked during the documentation transition. Claude should read the archived task and report before working on that cycle again; the owner's next request determines what to do.

Paths inside the archived documents retain their original repository-root context, including `.ai/LAST_REPORT.md`. Reports for older cycles remain in Git history; older evidence referring to a “latest report” describes the report available at the time.

## Local historical files

`.ai/runs/` contains ignored historical run logs. Keep them local and private; they are not a queue or a source of current instructions. In the original development checkout, the duplicate `.ai/inbox/CURRENT_TASK.md` was removed after its bytes were verified against the archived task. The ignore rules for old inbox files and run logs remain to prevent accidental publication.

## Main integration

The task and report previously on main are preserved in [main task](archive/2026-11-10-main-before-transition/CURRENT_TASK.md) and [main report](archive/2026-11-10-main-before-transition/LAST_REPORT.md). Only development documentation is integrated; Cycle 2b.2 product changes remain unmerged. Product priorities, receipt goals, budget and release criteria from main remain in CLAUDE.md.
