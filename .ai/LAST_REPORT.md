# Cycle 2a.2 — Native iOS UI conversion

- Task ID: WEALTHY-C2A2-NATIVE-UI
- Status: PARTIAL
- Branch: `codex/wealthy-c2a-shell`
- PR #5: GitHub reports `MERGED`, head `fb11c1361601f048dc7738dfea71861d4285462b`. The task's instruction to keep it draft cannot apply to an already merged PR. No merge or new PR was performed.
- Simulator devices added at user request: `Wealthy iPhone 17 Pro` and `Wealthy iPhone 15 Pro`, both iOS 27.0, booted. IDs: `DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0` and `870430A8-E557-4CED-8A8E-079801D804B9`.

## Implemented

- Replaced the custom page pager/bottom bar with native `TabView` tabs in Voice | Home | Info order. Home is initially selected. Removed the home microphone control.
- Converted onboarding and Voice to `Form`, Home to grouped `Form` sections, and secondary information/result layouts to standard `GroupBox`, system navigation, controls and sheets.
- Removed app-target custom glass, Plate, Pill, Row, Sticker and custom PrimaryButton components. Kept only semantic accent/status color tokens, island illustration and short-font decisions.
- Kept a constrained adjacent-tab horizontal gesture alongside native tabs, gated by horizontal dominance and distance and disabled under VoiceOver; respects Reduce Motion for tab transition. Vertical swipe UI test is not present, so scroll/picker/text-field gesture non-interference was not established.
- Preserved four-language copy and the Voice placeholder. No user-visible cycle/task terminology was added.
- `LedgerSession` includes isolated UI-test preferences reset handling; UI tests target standard tab labels.
- No WealthyCore changes.

## Files changed by this cycle

- `.ai/CURRENT_TASK.md`
- `.ai/LAST_REPORT.md`
- `Verification/Cycle2aUI/Cycle2aUITests.swift`
- `Wealthy/Wealthy/DesignSystem.swift`
- `Wealthy/Wealthy/EntryEditor.swift`
- `Wealthy/Wealthy/GoalsTaxSettings.swift`
- `Wealthy/Wealthy/HomeInfo.swift`
- `Wealthy/Wealthy/LedgerRoot.swift`
- `Wealthy/Wealthy/LedgerSession.swift`

## Build and test results

- `sh Verification/verify_core.sh`: PASS, 117 tests / 13 suites.
- `python3 Verification/verify_shell.py`: PASS, 149 localization keys × 4 languages, placeholder parity and bundled font/hash checks.
- `git diff --check`: PASS before the latest report write; rerun before commit.
- iOS Simulator Debug, iOS 27.0 generic: PASS.
- iOS Simulator Debug, iPhone 17 Pro (iOS 27.0): PASS; installed and launched. `launchctl` confirmed the app process running.
- iOS Simulator Debug, iPhone 15 Pro (iOS 27.0): PASS; installed and launched. `launchctl` confirmed the app process running.
- Generic iOS Release (`CODE_SIGNING_ALLOWED=NO`): PASS.
- Signed iPhone device Debug build: PASS; signing used the configured development team/profile.
- Simulator UI tests: `testEntryAccessibilityAudit` PASS; `testPagerNavigation` PASS; `testResultAccessibilityAudit` PASS; `testHomeAccessibilityAudit` FAIL. Home failure is an unmodified contrast audit assertion for `Not a balance` at frame `{{16, 794}, {370, 52}}`. Explicit `.primary` styling did not change the failure and was reverted. No audit was weakened or excluded.
- Full simulator UI run: 4 tests, 3 passed, 1 failed. Log: `/private/tmp/wealthy-c2a2-final-simulator-ui.log`; Home audit retry: `/private/tmp/wealthy-c2a2-home-audit-retry.log`.
- A later signed-device UI run (before current simulator request) passed Home, Edit, Result audits and tab navigation on device, but simulator audit shows the Home contrast issue reproduces on iOS 27.0 simulator. Therefore acceptance is not fully met.

## GUI / device evidence

- Created and booted the iPhone 17 Pro and iPhone 15 Pro iOS 27.0 simulators. Installed and launched the app on both; process presence confirmed with `simctl spawn ... launchctl list`.
- iPhone Mirroring showed the physical iPhone home screen. I did not complete manual app launch or a visual walkthrough in Mirroring, and did not save comparison screenshots to the repository. Earlier XCUITest runs contain temporary result attachments outside the repository; no screenshot board comparisons were refreshed.
- No Xcode simulator runtime other than iOS 27.0 was installed; iOS 26 runtime behavior remains unverified.
- No manual VoiceOver walkthrough, AX3 visual clipping walkthrough, Reduce Transparency/Reduce Motion OS-setting walkthrough, or swipe-conflict test was completed in this cycle.

## Expected / actual

- Expected: standard iOS UI, working native tabs plus safe adjacent swipes, all accessibility audits pass, and verified screen evidence.
- Actual: native tab navigation and core screens compile and launch on iPhone 15 Pro and 17 Pro simulators; selected tab navigation and three audits pass. Home audit still flags the `Not a balance` text's contrast. The swipe gesture has not been tested against scrolls or interactive controls. Requested comparison screenshots and manual accessibility walkthroughs are absent.

## Errors, warnings and reproduction

- Reproduce Home audit: prepare temporary UI-test project with `python3 Verification/prepare_cycle2a_tests.py /private/tmp/wealthy-c2a2-tests-final`, then run `xcodebuild -project /private/tmp/wealthy-c2a2-tests-final/Wealthy.xcodeproj -scheme Wealthy -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /private/tmp/wealthy-c2a2-final-sim-tests -only-testing:Cycle2aUITests/Cycle2aUITests/testHomeAccessibilityAudit test`.
- Xcode logged a duplicate Simulator accessibility bundle class warning and an AppIntents metadata warning because the app has no AppIntents dependency; builds succeeded.
- GUI target launch through iPhone Mirroring was not verified; simulator process launch succeeded instead.

## Unresolved / decisions needed

- Home `Not a balance` contrast audit requires a visual/style decision to preserve standard components and meet contrast without changing the audit.
- The standard tab content swipe gesture needs interaction tests for vertical scrolling and controls; decide whether to keep it if conflicts are found.
- Required screenshots across screens/modes and manual accessibility checks are not complete.
- PR #5 is already merged on GitHub, contrary to the pasted draft-state assumption. Changes can be pushed to the existing branch, but this cannot turn the merged PR back into a draft. No new PR was created.

## Intentionally not performed

- No merge, new PR, Cycle 2b/3 work, WealthyCore behavior change, legacy data deletion, or subagent use.
- Did not modify the pre-existing user changes in `.DS_Store` files, `Wealthy/Wealthy.xcodeproj/project.pbxproj`, the untracked Japanese design PDF, or the two launch trace directories.
