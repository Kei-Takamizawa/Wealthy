# CURRENT TASK — Cycle 2a.1: Fix the blockers of PR #5 (same branch `codex/wealthy-c2a-shell`)

Task ID: WEALTHY-C2A1-FIXES
Base: PR #5 head `39ae7d5`. Push to the same branch; keep the PR as draft until the product owner approves. Read `.ai/LAST_REPORT.md` first; update it at the end. Scope is limited to the items below. Do not start Cycle 2b or 3 work.

## 1. Fixes required

1. **Result sheet contrast audit (blocker).** `Cycle2aUITests/testResultAccessibilityAudit` flags the late-entry explanation text. Put that text (and any other explanatory text in the result sheet) on an opaque Plate with the design `ink`/`ink2` colors. If the audit still fails, bisect by removing modifiers one by one (opacity, hierarchical/secondary styles, blend modes, material backgrounds) and report which one causes it. Do NOT exclude the element or weaken the audit.
2. **Monthly result (blocker).** Implement the month achieved / over / too-few-days presentations as in boards `V4ResultMonth` / `V4Result` (kind=month): headline per state, island with the month's earned areas (festival count, max 4), month decoration reward line for achieved, "over" wording without punishment, too-few-days wording. Replace design copy that says "20 days or more" with the real rule from Core: logged on at least 70% of the month's days (show the actual number of days required, e.g. "22 of 31"). Weekly captions must not appear on month results.
3. **Home envelope.** Home always shows the household envelope (island = household weekly allowance). It must NOT follow the envelope selected on Info. The child envelope is shown on Info and its detail screens only.
4. **Goals.** Build the distinct `V4GoalsUnset` presentation for a month with no target set (not the same empty form). Amount fields in Goals and Edit must display grouped digits and the currency symbol per locale (currently raw "310000", "2400"); input must still accept plain digits.
5. **No internal jargon in UI text.** Remove "Cycle 3" (or any cycle/task wording) from user-visible strings (e.g. the voice-page placeholder). Use a neutral localized message such as "Voice input is coming soon. For now, add entries by typing." in all 4 languages.
6. **Persisted onboarding.** Verify on a real device with the real disk store: complete onboarding, force-quit, relaunch: the app opens on Home (not onboarding) with the chosen language, currency and target retained. Add a UI test (disk store in a temp location) and report the result.
7. **Idle stall / continuous animation.** The normal-motion child-envelope UI test stalled in XCTest waiting for animation idle (repeated 60 s waits). Find the cause (likely a repeating animation or `TimelineView`/`Canvas` redraw loop on the island or elsewhere). Fix so that: ambient animations stop when the view is off-screen, when the app is not active, when Low Power Mode is on, and when Reduce Motion is on; the island redraw loop does not run continuously at full frame rate; the normal-motion child-envelope test passes without special-casing. Report battery-relevant measures you can actually measure (e.g. CPU % idle on Home over 60 s on device, before/after). Do not claim battery numbers you did not measure.
8. **Launch performance (scope clarified).** Do not change the Core persistence boundary in this cycle: `LedgerStore`/`LedgerCore` stay `@MainActor` with synchronous reads. Instead: render the first frame (loading state) BEFORE the synchronous ledger open starts (e.g. start the open from a `.task` after the first render, yielding once so the frame is committed), keep the loading state minimal and accessible (VoiceOver announces loading), and measure on device with signposts / `XCTApplicationLaunchMetric` (not "accessibility element exists") at 1,000 / 10,000 / 50,000 entries, median of 5 warm launches each. Report two numbers per size: time to first frame, and time until Home is interactive. Targets: first frame under 1 s at all sizes; Home interactive under 2 s at 10,000 entries. If the interactive target is missed at 10,000, report the numbers and the cost split (store open vs. snapshot vs. first render); that result will trigger a separate Core task (async persistence boundary). Truly asynchronous loading is NOT blocked-by-you work in this cycle and is not required for acceptance.

## 2. Constraints
Keep WealthyCore persistence, undo, backup and tax/target rules unchanged (small query additions allowed if strictly needed, tested). No new dependencies. No audit exclusions, no weakened assertions, no skipped tests. Do not merge; do not delete legacy user data.

## 3. Acceptance
- All previously passing tests still pass; `testResultAccessibilityAudit` passes unmodified in intent; the normal-motion child test passes.
- Items 1–8 each have evidence in the report (test names, screenshots for 2, 3, 4, 5, measured numbers for 7 and 8).
- Core tests and historical checks still pass; Simulator, Release and signed-device builds pass.

## 4. Report
Per-item status with evidence; measured numbers (first frame at 3 sizes, idle CPU before/after); what remains unverified (manual VoiceOver traversal, OS Reduce Motion/Transparency settings, iOS 26 hardware) stated explicitly; screenshots of month results (3 states, light/dark/AX3) and Goals unset.

## 5. Design-vs-implementation comparison images (add to this cycle)
Commit comparison material to the PR branch so the reviewer can read it from GitHub:
- `design/v4/`: the exported v4 design boards (PNG or JPEG) if the product owner has placed them locally; do not generate them yourself. Name files by board (e.g. `V4Home-light.png`, `V4Home-dark.png`). If they are missing locally, say so in the report.
- `Verification/Cycle2aEvidence/compare/`: for each in-scope screen, light and dark (AX3 optional), ONE side-by-side image: design board on the left, device screenshot on the right, same height, label on top (screen id, mode). JPEG quality about 80, long edge at most 2400 px, each file under 2 MB, total added under 30 MB. Names like `compare-V4Home-light.jpg`. Add `compare/INDEX.md` listing every file, the screen, and one line on known differences.
- Synthetic data only; no real financial records or personal data in any image.
- Do not commit the full 251-image inventory, videos or xcresult bundles.

## 6. Additional fixes from design review of the PR #5 comparison images (Home, Voice)
Reviewed from `Verification/Cycle2aEvidence/compare/` (base-revision captures). Apply in this cycle, using Core values (no UI-side arithmetic):
1. **Home hero = remaining.** Board V4Home shows "This week left: ¥5,798" ("今週あと") as the big number with the "Not a balance" pill, a progress bar, and a line "of allowance ¥X, spent ¥Y (Z%)". The implementation shows the allowance as the big number and "spent" below; the remaining amount is missing. Make remaining the hero. If remaining is negative, show it with the "over" icon + word (never red alone, no punishing wording). If no target is set, show the unset state, not 0.
2. **Seven-day row.** Use the board's per-day states (under allowance: check; over: moon/dusk; no-spend marked; today: outlined plus; future: dash) with weekday labels, not all green checks. Derive from Core.
3. **Month card on Home** (this month spent / remaining target + state pill) as in the board, household envelope only.
4. **Microphone on Home.** The board has a bottom bar with the centered microphone (info / mic / history). The mic must exist on Home and move to the Voice page (placeholder behavior unchanged). "History" can be omitted in 2a (no dead entry point); do not add a dead button.
5. **Island framing (recommended, not blocking).** The board shows the island full-bleed behind translucent cards; the implementation puts it in a rounded card. If feasible with native glass, move toward the board; otherwise report as a known difference.
6. Voice page placeholder copy is acceptable ("Voice input is coming soon...") but also shows a second pill "voice input is not available now": keep only one message.
