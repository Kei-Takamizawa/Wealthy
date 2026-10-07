# Cycle 2a.4 - WEALTHY-C2A4-UITEST-TARGET

## Goal
Close the verification gap left by PR #6: the Xcode project has no UI test target and no shared test scheme, so accessibility audits, swipe tests, screenshots and measurements could not run. Create the target and run the checks from CYCLE2A_3_CURRENT_TASK.md.

## Branch
New branch `codex/wealthy-c2a4-uitest` from latest `main` (after PR #6 is merged, or from the PR #6 head if it is not merged yet; say which). Open a NEW draft PR. Never reuse a merged PR.

## Requirements
1. Add a UI test target `WealthyUITests` and a shared scheme that runs it, committed to the repo, so `xcodebuild test` works from a clean checkout.
2. Implement the items of CYCLE2A_3 that were blocked: `performAccessibilityAudit` on Home, Voice, Info (no excluded elements, no weakened audits); swipe-vs-control tests (vertical scroll, text field, date picker, segmented control, List swipe action); screenshots to `Verification/Cycle2aEvidence/native/` per CYCLE2A_3 limits; first-frame / Home-interactive measurements at 1k/10k/50k and 60 s idle CPU.
3. If the Home audit still fails, fix the layout (standard safe area, no custom overlays). If swipe conflicts are unresolved, remove the swipe gesture and report it.
4. Do not change WealthyCore behavior.
5. Accessibility settings: on the simulator, drive the Settings app (XCUITest on com.apple.Preferences, or computer use if available) to turn ON Reduce Motion and Reduce Transparency, then capture Home, Voice and Info screenshots in each state (add to `Verification/Cycle2aEvidence/native/`). If this cannot be automated, report exactly why. Also attempt a VoiceOver pass over the three tabs via computer use on the simulator if available; otherwise state that it was not run (the owner will check on a device). Never claim a result that was not observed.

## Report (`.ai/LAST_REPORT.md`)
Exact commands, per-screen audit result (element-level on failure), swipe test results, measurements with device/simulator names, anything not run and why. No claims without evidence.
