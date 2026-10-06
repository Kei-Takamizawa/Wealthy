# CURRENT TASK — Cycle 2a.3: Close the remaining native-UI gaps (NEW branch and NEW PR from `main`)

Task ID: WEALTHY-C2A3-CLOSE
Context: PR #5 was merged by the product owner on 2026-10-06 21:04Z (head fb11c13). The Cycle 2a.2 native-UI work was pushed to `codex/wealthy-c2a-shell` AFTER that merge and is not in `main`. Start from latest `main`, bring in the post-merge 2a.2 commits (cherry-pick or merge `codex/wealthy-c2a-shell` into a new branch `codex/wealthy-c2a3-close`), and open a NEW PR (draft until the owner approves). Never reuse the merged PR.

## Requirements
1. **Home contrast audit failure.** `testHomeAccessibilityAudit` fails on "Not a balance" at frame {{16,794},{370,52}} (iOS 27.0 simulators). That frame is in the bottom area where the system tab bar sits, so a likely cause is footer/secondary text scrolling under the translucent tab bar (hypothesis, unverified). Investigate (attach crop + element dump) and fix with standard means: put "Not a balance" in the section header/top of the plate area (not at the bottom edge), make sure scroll content ends above the tab bar via the standard safe-area behavior, use primary/secondary system label styles. Do not exclude elements or weaken the audit. All four audits (Home, Entry, Result, plus Info) must pass on the iPhone 15 Pro simulator, the iPhone 17 Pro simulator and the physical device.
2. **Swipe between tabs: tests.** Add UI tests proving: a horizontal swipe on Home goes to the adjacent tab; a vertical scroll in Home/Info/Edit does not change tabs; swiping inside a text field, a date picker, a segmented control and a List swipe action does not change tabs; the gesture is disabled with VoiceOver. If any conflict cannot be resolved with standard means, remove the swipe (keep standard tap switching) and report that; do not leave a flaky gesture.
3. **Screenshots for review (commit to the branch).** Under `Verification/Cycle2aEvidence/native/`: Voice, Home, Info (household and child), Goals, Goals unset, Edit, Tax, Result sheet (week achieved/over/few, month achieved/over/few), Child setup/detail, Onboarding steps, Settings: light and dark; plus Home in all 4 languages and Home at AX3. Synthetic data only; JPEG about q80, long edge <= 2000 px, each < 1 MB, total < 25 MB; one `INDEX.md` listing files. Take them on the iPhone 15 Pro simulator or device (state which).
4. **Performance measurements on the final source** (physical device preferred): first frame and Home-interactive at 1k/10k/50k entries (median of 5 warm launches, signposts), and idle CPU on Home over 60 s. If XCTest omits metrics, use `os_signpost` with Instruments / `xctrace` or `XCTOSSignpostMetric` and report what you used. Report numbers as measured; do not claim acceptance without them.
5. **Housekeeping.** Update `.ai/CURRENT_TASK.md` and `.ai/LAST_REPORT.md` for this task. Do not touch WealthyCore behavior. No new dependencies.

## Acceptance
- Four audits pass (simulators + device) with no exclusions.
- Swipe tests pass, or the swipe is removed and documented.
- Screenshots committed per item 3; measurements reported per item 4.
- Core tests, localization/font checks, Simulator/Release/signed-device builds pass.

## Not in scope
Cycle 2b screens (calendar, analysis, fixed costs, receipts, categories management, backup/restore UI, undo history, iPad) and Cycle 3 (voice).

## Report
Per-item status with evidence and exact commands; list of anything still unverified (manual VoiceOver, OS Reduce Motion/Transparency, iOS 26 hardware).
