# Cycle 2a.1 — PR #5 fixes (same branch)

- Task ID: WEALTHY-C2A1-FIXES
- Status: PARTIAL — implementation, builds and most device flows pass; the Home contrast audit still reports 3 anonymous contrast issues. Item 1 (audit blocker) is not accepted. The full requested launch metric matrix and a current-code CPU before/after measurement are also incomplete.
- Branch: `codex/wealthy-c2a-shell`; starting PR head recorded in the prior report: `5a21b6d9bdf4c3840008787265dc7f24625fbd8e`.
- PR #5: https://github.com/Kei-Takamizawa/Wealthy/pull/5. Keep Draft; do not merge.
- Device: iPhone 16 Pro Max, iOS 27.2 (24B5089g), UDID `00008140-000C6164027B001C`.
- User-owned files excluded from this task commit: `.DS_Store` files, the whitespace-only `Wealthy/Wealthy.xcodeproj/project.pbxproj` edits, and `design/v4/引き渡しシート.pdf`.

## Results

| Item | Result | Evidence / limitation |
| --- | --- | --- |
| 1. Result sheet contrast | PASS | `testResultAccessibilityAudit` passed on the current signed device build, unchanged audit intent and no excluded elements. Its explanatory text remains in an opaque Plate with explicit ink colors. Home has a separate FAIL described below. |
| 2. Monthly result | PASS in prior device run | `testMonthResultStatesMatrix` covered achieved / over / too-few days in light, dark and AX3. Home final edits do not alter month result logic. Full set of requested month screenshot variants is as reported in compare index; absent dark board exports are noted there. |
| 3. Home envelope | PASS | Latest `testHomeAlwaysHousehold`: Home remains on household data while Info selects Child, in light and dark. |
| 4. Goals / amounts | PASS in prior device run | `testGoalsUnsetMatrix` covered 4 languages × light/dark/AX3; grouped amount fields test passed for Goals and Entry in en/ja/es/ko. |
| 5. Voice copy | PASS | Latest `testVoicePlaceholderIsShownOnce` passed light and dark. The localized neutral placeholder appears once; duplicate unavailable message is removed. |
| 6. Persisted onboarding | PASS | Latest `testPersistedOnboardingRelaunch` passed using a temporary disk store and isolated preferences; Spanish, KRW and 40,000 monthly target remained after process termination/relaunch to Home. |
| 7. Idle stall / animation | PASS for requested child flow; CPU incomplete | Latest normal-motion `testChildEnvelopeAndLicenseFlow` passed (148.619 s), saving a Child Food/Takeout 8% expense, confirming ¥266 tax, then opening font licenses. The prior stall was the test helper tapping Save while it was outside the visible region / under the keyboard. The updated tap helper checks the button center against app and keyboard bounds before tapping. Source inspection found no repeating animation, `TimelineView`, or continuous Canvas loop; the island is a static Canvas. Current-code 60 s CPU before/after numbers were not re-measured. Historical one-sample Activity Monitor numbers (0.306% vs 0.315% CPU; 54 vs 56 wakeups) are from the previous revision and are not evidence for this final source. |
| 8. Launch performance | PARTIAL | The existing `device-launch-metrics-current-home-2026-10-06.json` captures the prior Home revision, not the final spacing/layout. It records a 10k Home interactive median around 0.960 s (n=3) with store open 0.011 s, snapshot 0.370 s, query snapshot 0.024 s and render 0.480 s; 10k first-frame median 0.404 s (n=2). Required 1k/10k/50k first-frame and interactive medians, five warm runs each, were not remeasured against this final source. Do not use these prior-revision values as final acceptance evidence. Core persistence stayed unchanged and synchronous. |

## Home accessibility audit — unresolved blocker

`testHomeAccessibilityAudit` was run repeatedly on the final device build and still fails on contrast with 3 issues whose XCTest descriptions say `Contrast failed for element / No element`. The test’s audit callback continues to collect and reject the issues; no assertion was removed or weakened.

The first detailed audit identified a clipped `This month's allowance` label and `Remaining allowance` at the bottom edge of the ScrollView, partly behind the fixed footer. Home was tightened to match the approved board more closely: the seven-day state row now sits in the weekly card, the scroll viewport is separated from the fixed footer, the weekly island is 180 pt, and vertical section spacing is 12 pt. Explicit foreground colors were added for card and glass-chip text. The clipped labels no longer appeared by name in the latest audit output, but the audit still reports 3 anonymous contrast failures. Result attachments are at `/private/tmp/wealthy-c2a1-revision/home-audit-final8.xcresult`; final source result is also in `/private/tmp/wealthy-c2a1-revision/home-audit-final7.xcresult` before the last spacing change. The final full audit result is `home-audit-final8.xcresult`.

Do not mark this audit PASS. A next investigation needs a reproducible way to expose the offending anonymous elements or an OS/Xcode audit diagnostic that maps them to visible controls. Do not exclude the elements or weaken the audit.

## Final source checks

- `sh Verification/verify_core.sh`: PASS, 117 tests across 13 suites; opt-in disk benchmark skipped by its normal default.
- `python3 Verification/verify_shell.py`: PASS, 146 catalog keys × 4 languages, placeholder parity, isolation, font hashes and Hangul/Spanish subset checks.
- `git diff --check`: PASS.
- Signed iPhone `build-for-testing`: PASS, latest source signed with configured Apple Development identity.
- Generic iOS Simulator build: PASS on latest source.
- Generic iOS Release build: PASS on latest source (`CODE_SIGNING_ALLOWED=NO`; this is not a signed-device Release launch).
- Final focused iPhone tests on the latest source before the last spacing-only adjustment: 5/5 passed (`testChildEnvelopeAndLicenseFlow`, `testHomeAlwaysHousehold`, `testPersistedOnboardingRelaunch`, `testResultAccessibilityAudit`, `testVoicePlaceholderIsShownOnce`). Latest spacing source then passed `testHomeAlwaysHousehold` and `testHomeAX3LanguageMatrix` (4 languages at AX3, no clipped-text findings); Home contrast audit remains the recorded fail.
- Previous full broad device suite is documented in Git history; it was not rerun end-to-end in this cycle.
- Xcode printed transient `debugger version lookup failed` messages during device test launches. Tests continued and produced results. The runner also attempted device diagnostics after a failed audit and reported a `devicectl diagnose` failure; this did not affect test execution.

## Screenshots and design comparisons

`Verification/Cycle2aEvidence/compare/` contains 39 JPEG side-by-side comparisons. Home light/dark and Voice light/dark were refreshed from latest device captures; other panels use the earlier Cycle 2a.1 device run. The index lists 7 missing design/capture mappings and their reasons. Files remain below 2 MB each and below the 2,400 px long-edge cap; the directory is approximately 3.8 MB. Captures use synthetic data. No video, full image inventory, or `.xcresult` bundle was added.

Home differences still include a standalone rounded island rather than the board's full-bleed art. The island illustration is static and has the requested VoiceOver summary label. Missing design exports and dark variants are listed in `Verification/Cycle2aEvidence/compare/INDEX.md`.

## GUI and unverified items

- Physical GUI checked the child setup, typed expense, Child envelope selection, Food category, Takeout 8%, Save, ¥266 child tax summary, and font license screen.
- Physical UI tests checked persisted onboarding across process restart, Home household isolation from Info's Child selection, neutral Voice placeholder, result-sheet accessibility, and Home AX3 layouts in all four languages.
- Not manually verified: VoiceOver traversal, OS Reduce Motion / Reduce Transparency settings, iOS 26 hardware, signed Release installation/launch, current-source 1k/10k/50k launch metrics at n=5, current-source 60 s idle CPU, and a complete week of seeded reward behavior on device.
- Intentionally not started: Cycle 2b/3 work, Core persistence-boundary changes, and out-of-scope screens.

## Changed files

- `.ai/CURRENT_TASK.md` — full user-provided revised task, including the additional design-review fixes.
- `.ai/LAST_REPORT.md` — this report.
- `Wealthy/Wealthy/HomeInfo.swift` — household-only Home summary, remaining allowance hero, day states, month summary, fixed microphone/info footer, improved content layout and explicit text colors.
- `Wealthy/Wealthy/DesignSystem.swift` — explicit foreground ink on glass Pill text.
- `Wealthy/Wealthy/LedgerRoot.swift` — remove duplicate unavailable voice message.
- `Wealthy/Wealthy/Localizable.xcstrings` — translated allowance percentage and day-state labels for four languages.
- `WealthyCore/Sources/WealthyCore/Targets.swift` — overflow-safe spent percentage query value.
- `WealthyCore/Sources/WealthyCore/IslandQueries.swift` — deterministic per-day presentation states.
- `WealthyCore/Tests/WealthyCoreTests/IslandTests.swift` — tests for spent percentage and day states.
- `Verification/Cycle2aUI/Cycle2aUITests.swift` — visible-center tap helper, persisted-child flow assertion, Home household, voice placeholder and AX3 language tests.
- `Verification/compare_v4_design.py`, `Verification/Cycle2aEvidence/compare/INDEX.md`, and refreshed Home/Voice comparison JPEGs.
- `Verification/Cycle2aEvidence/device-launch-metrics-current-home-2026-10-06.json` — captured launch/signpost output from the earlier Home revision; clearly not final-source performance evidence.

## Expected / actual and repro

Expected: all Cycle 2a.1 blockers pass and evidence is current. Actual: result audit, child flow, persisted onboarding, household Home, neutral voice, AX3 language layouts and builds pass; Home contrast audit remains FAIL (3 anonymous issues); requested launch-metric and idle-CPU measurements are incomplete for the final source.

Reproduce Home audit: run `Cycle2aUITests/testHomeAccessibilityAudit` on the iPhone 16 Pro Max with the signed Cycle2a test runner. It asserts all contrast, text clipping, hit-region and description issues are empty. The three remaining issues are reported by XCTest without an element description. Result audit remains separately passing.

## Git delivery

Committed as `738531355c8e97523d86ccf3ad106b1e4a916d47` (`Fix Cycle 2a.1 home and device blockers`) and pushed to `origin/codex/wealthy-c2a-shell`. `git ls-remote` confirms the same remote SHA. GitHub reports PR #5 `OPEN`, `isDraft: true`, `mergedAt: null`; no merge was performed. User-owned uncommitted `.DS_Store`, project whitespace, and Japanese handoff PDF changes remain excluded and untouched.
