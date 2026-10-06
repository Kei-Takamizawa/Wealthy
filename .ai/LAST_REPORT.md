# Cycle 2a.1 — PR #5 Round 2 update

- Task ID: WEALTHY-C2A1-FIXES
- Status: PARTIAL — requested Home labeling/footer changes are implemented, signed Release installation and normal launch succeeded, but the required Home contrast audit still fails and the full 1k/10k/50k performance matrix was not obtained.
- Branch: `codex/wealthy-c2a-shell`; PR #5 remains OPEN, Draft, unmerged.
- Device: iPhone 16 Pro Max, iOS 27.2 (24B5089g), UDID `00008140-000C6164027B001C`; lockState showed `unlockedSinceBoot: true` during device work.

## Round 2 items

1. **Labels and allowance distinction — implemented.** Home week hero says “Left this week”; month uses “Left this month”; Info uses matching “Left” labels and shows total as “Allowance”. Four-language catalog additions: en/ja/es/ko. `verify_shell.py` validates 149 keys × 4 languages.
2. **Bottom bar — implemented.** One Info control and one centered 66 pt primary microphone occupy a single regular-glass bar; Home content is a scroll view with bottom safe-area inset. UI test references updated from removed `homeInfo` to `homeInfoBottom`. Real device build and normal Home launch succeeded. Manual visual review against board not newly captured.
3. **Audit diagnostics — implemented, audit remains FAIL.** `testHomeAccessibilityAudit` now prints audit type, label, identifier, frame and debugDescription and attaches a crop/full-screen image per issue. Results: initial run exposed 7 contrast issues (Info, weekly header, weekly hero, month header and 3 month card texts). After making Info opaque and changing specified secondary label colors, later runs still report contrast issues for weekly card heading/value and month spent/remaining labels; an additional day-label issue can occur. Removing/changing styles did not establish a single root modifier. Audit callback still collects all issues and the unmodified `XCTAssertTrue(issues.isEmpty)` rejects them. Latest failed result: `/private/tmp/wealthy-c2a1-round2-home-audit-fix8.xcresult`; diagnostic crops are in that result bundle. No element exclusions or weakened assertions.
4. **Final-source signed Release, CPU and launch measurements — partial.** Signed Release app installed over existing app and launched normally on device (`devicectl` returned PID; no launch args). Activity Monitor trace `Launch_Wealthy.app_2026-10-06_21.43.52_0D3F4E3A.trace` shows a single 88.797 s observation interval (the capture was intended as 60 s but Instruments stopped only after manual stop), 210.75 ms process CPU (~0.237% of elapsed interval), 68 idle wakeups, and 1.92 MiB read. This interval includes launch; it is not a controlled 60 s steady-idle sample and there is no comparable new baseline. A separate 59.309 s interval had 203.81 ms CPU (~0.344%) / 60 idle wakeups but similarly begins at launch. Treat these as single launch-plus-observation samples, not a before/after battery comparison. The required exact five-warm-launch medians at 1k/10k/50k were not obtained.
   - Initial 1k attempt used an extra warm-up and failed to save usable results. The test was corrected to remove that extra launch and rerun. In the corrected run `testHomeInteractiveMetric1000` passed; Xcode 27 omitted `XCTApplicationLaunchMetric` values and warned it was missing in later iterations, while signposts were recorded for only 3 iterations despite `iterationCount = 5`. HomeInteractive was 0.172525, 0.171044, 0.193915 seconds (n=3; median 0.172525 s); HomeRender 0.106113, 0.104966, 0.106297 s (n=3; median 0.106113 s); QuerySnapshot 0.000517, 0.000502, 0.000467 s (n=3; median 0.000502 s). These are interim 1k reference measurements, not five-launch acceptance medians. StoreOpen/Snapshot and first-frame values were not present in the result.
   - `testLaunchMetric1000` passed its UI test method but the result bundle contained no launch metric object. No 10k/50k measures were run after this instrumentation inconsistency.
5. **Signed Release device install/normal launch — PASS.** `devicectl device install app` replaced installed `com.harrison.Wealthy`; `devicectl device process launch ... --terminate-existing` succeeded, PID observed. This was a normal launch with no arguments. Existing app data was not explicitly removed.

## Validation

- `sh Verification/verify_core.sh`: PASS, 117 tests / 13 suites.
- `python3 Verification/verify_shell.py`: PASS, 149 localization keys × 4 languages, placeholder parity and bundled font checks.
- `git diff --check`: PASS.
- Signed iPhone Release `build-for-testing`: PASS on final source (`/private/tmp/wealthy-c2a1-round2-final-build.log`).
- Generic iOS Simulator Release build: PASS after Home content cleanup and label changes.
- Signed Release install and normal launch: PASS after final source build and style cleanup. No user data was erased.
- `testHomeAccessibilityAudit`: FAIL, diagnostic data listed above.
- `testHomeInteractiveMetric1000`: PASS test method; metric collection partial, n=3 and launch metric missing.
- `testLaunchMetric1000`: PASS test method; no metrics persisted in result.
- Other prior Cycle 2a.1 results are recorded in earlier report history; not rerun in this round.

## Expected / Actual

Expected: single glass Info/mic bar and consistent remaining labels; named contrast issues fixed; five warm runs at each store size and current-device measurements.
Actual: label/footer code is updated. The audit is still failing. Signed Release launches on iPhone. One 1k interactive signpost sample set (n=3) and two launch-plus-observation Activity Monitor samples were extracted; required metric matrix/true idle comparison is incomplete.

## Open / unverified

- Home contrast audit root cause and PASS.
- 1k first-frame measurement; five values per metric.
- 10k and 50k first-frame and Home-interactive five-run medians.
- Device steady-state 60 second CPU comparison against a comparable base.
- Manual VoiceOver, Reduce Motion, Reduce Transparency, iOS 26 hardware.
- Current-source screenshot comparison images have not been refreshed for this round.
- Final signed Release rebuild/install/normal launch was repeated after source cleanup and succeeded.

No Cycle 2b/3 work was started. No changes to WealthyCore persistence/domain rules. This report intentionally does not claim blockers passed.
