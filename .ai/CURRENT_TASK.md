# Cycle 2a.5 - WEALTHY-C2A5-SWIPE-LANG

## Goal
1. Restore swipe switching between the tabs [Voice | Home | Info] (owner requirement), without breaking text selection, pickers, segmented controls or scrolling.
2. Reduce supported UI languages to exactly 4 (en base, ja, es, ko) everywhere, including verification scripts.
3. Re-measure on a physical device.

## Branch
New branch `codex/wealthy-c2a5-swipe` from latest `origin/main`. `main` must already contain PR #7 (`5d53828`) and the loop setup files (`CLAUDE.md`, `AGENTS.md`); if it does not, stop as BLOCKED and say which is missing. The operator opens a NEW draft PR. Never reuse a merged PR.

## Context
Owner decisions (2026-10-07): restore swipe switching; judge performance on the physical iPhone only (the simulator Mac was busy); keep exactly 4 languages. PR #7 removed the custom swipe because a text-selection drag switched tabs; that is the failure to avoid. Free provisioning on the iPhone 16 Pro Max allowed only 3 test apps and blocked the UI test runner last time.

## Requirements
### 1. Swipe
- Keep the standard system TabView/tab bar. Tapping a tab and swiping horizontally must both switch tabs and stay in sync.
- Prefer a mechanism that cannot hijack in-content gestures: e.g. SwiftUI TabView with a swipe-capable style only if it keeps the standard tab bar; otherwise a gesture on the tab root pages only. The entry editor, sheets, text fields, date pickers and segmented controls must never trigger a tab switch (the earlier failure was a text-selection drag).
- Require clear horizontal dominance and a minimum distance; disable the swipe while a text field is focused and while any sheet is presented; disable it when VoiceOver is running (tabs remain switchable via the tab bar).
- No wrap-around: swiping right on Voice or left on Info does nothing. Reduce Motion: no animated transition (instant switch).
- Re-enable and extend the existing UI tests: swipe left/right switches pages; vertical scroll, text-field selection drag, date-picker drag, segmented control drag, Info segmented control never switch tabs. If a conflict cannot be resolved, do NOT ship a flaky swipe: report the exact failing case and leave the swipe off.

### 2. Languages
- Remove every language other than en, ja, es, ko from the app resources, `Localizable` files, verification scripts (`verify_localization.sh`) and docs. The report said "196 keys in 11 languages"; explain where the extra 7 languages came from and delete them.
- Verification must report keys x 4 languages, with zero missing keys, and fonts unchanged (Patrick Hand en/es, Klee One ja, Poor Story ko).
- Do not change WealthyCore behavior.

### 3. Device measurement
Owner note: earlier numbers came from a simulator on a busy Mac, so judge only device numbers. On the physical iPhone, with Release build and synthetic data at 1k / 10k / 50k: measure first frame and Home-interactive, 5 warm launches each, report median and all samples. Target: Home-interactive <= 2 s at 10k. If the free-provisioning test-app limit blocks XCUITest on device, use app-level signposts/launch measurement via Instruments or an in-app debug timing path instead and say which. Do not uninstall the owner's apps without asking.
- If 10k exceeds 2 s on device, STOP and report the signpost split (StoreOpen/Snapshot/HomeRender); do not change Core persistence in this cycle.

## Do not change
WealthyCore behavior, tax/target rules, data model, fonts, the standard-UI decision (no custom glass/plates).

## Acceptance
Swipe + tap both work and all gesture/audit tests pass on iPhone 15 Pro and 17 Pro simulators; 4-language verification passes; device measurements reported (or exact blocker). Core tests still 117 passing.

## Report (`.ai/LAST_REPORT.md`, format in `AGENTS.md`)
Commands, test results, gesture failures if any, language cleanup explanation, device model + iOS version + raw samples. No claims without observation.
