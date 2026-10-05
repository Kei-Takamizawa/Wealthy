# CURRENT TASK — Cycle 2a: New app shell on WealthyCore (design v4 foundation + core screens)

Task ID: WEALTHY-C2A-SHELL
Base: latest `main` (WealthyCore through PR #4). Work on a new branch, open a PR. Report in `.ai/LAST_REPORT.md`.

## 1. Goal
This is an UPDATE of the existing app, not a second app: same Xcode project, same target and scheme (`Wealthy`), same bundle identifier, installed over the existing installation. The legacy screens and legacy SwiftData models are deleted from the target in this cycle (all of them, including calendar/analysis/receipt/wallet screens); WealthyCore stays a separate local Swift package used by the app. Nothing is kept running side by side.

Replace the legacy app UI and data layer with a new SwiftUI app that runs on WealthyCore (domain v2) and follows the approved design "v4". This cycle delivers the design system and the core screens with manual (typed) input. Voice, speech and Apple Intelligence interpretation are Cycle 3. The remaining screens listed in section 3.2 are Cycle 2b.

## 2. Background and decisions (already made by the product owner)
- Product: household budget app. Wallets/assets are gone. The user sets a monthly overall target and optional per-category targets. The "island" shows the weekly allowance; fewer-than-daily-allowance days add things to the island, a week within target AND logged on at least 5 of 7 days earns a festival and a free sticker, a month earns island areas. Exceeding is never punished (dusk colors only). The number shown is a "usable allowance", never a balance: the words "Not a balance" (localized) must be visible wherever an allowance is shown.
- Child envelope: separate envelope and separate evaluation; covers spending on the child and child-support payments paid out (preset category "child support payment", tax-exempt, fixed cost).
- Consumption tax (Japan, JPY only): shown per entry, monthly total, per-rate breakdown, unknown-rate count, takeout saving estimate (labeled "estimate").
- Apple Intelligence stays REQUIRED: keep the launch gate and add the "no Apple Intelligence" guidance screen.
- No migration from the legacy store. The legacy app data and receipt images stay on disk untouched and are never opened by the new app. The new app starts empty with a new store file (`WealthyLedger.store` under Application Support). Features not yet ported (see 3.2) are simply absent until Cycle 2b; this is acceptable because the app is not released.
- Languages: English (base), Japanese, Spanish, Korean. Handwritten-style fonts for headings and short labels only: en/es Patrick Hand, ja Klee One (400, 600), ko Poor Story. Amounts and long text use system fonts (SF Pro Rounded + monospaced digits for amounts; system body font for long text).
- iOS 26+ only. Use real Liquid Glass (`glassEffect`, `GlassEffectContainer`) for chips, bars and sheets; amounts always sit on opaque "plates", never directly on glass; glass is never stacked on glass. The browser mockups only approximate glass.
- Product owner decisions this cycle: month reward eligibility = logged on at least 70% of the month's days (ceil(0.7 x days), e.g. 22 of 31); week = 5 of 7 (unchanged). Adding forgotten days after a week/month ended is allowed for 3 days; results are computed from entries, so late entries change the result (see 4.3).

## 3. Requirements

### 3.1 In scope (this cycle)
1. Design system module: color tokens (light/dark), type, radii, shadows, glass levels, Plate, Row, Pill, Sticker, PrimaryButton, motion ("jelly" 300–500 ms, none when Reduce Motion). Values: see the design handoff board `V4Handoff` (section 3 and 4 tables) and the exported design files (section 7). Reduce Transparency: glass becomes opaque cards with a 1.5 pt line. Dynamic Type must not break layouts up to the accessibility sizes; verify at least AX3.
2. App shell (FINAL page structure): a horizontal pager with THREE pages in this order: [Voice] | [Home] | [Info]. The app opens on Home. Swipe right from Home reveals Voice; swipe left from Home reveals Info. Voice <-> Info is not adjacent: use the "to Info" control drawn on the voice board (animated jump over Home) and swipe/back via the "to island" control on the info board. Tapping the microphone on Home also moves to the Voice page. Voice page in this cycle = idle state only; its microphone control is a clearly non-functional placeholder (Cycle 3), no fake behavior. Info = V4Info (household / child envelope segment). Information is reachable from Home with one swipe or one tap (the "Info" chip on V4Home). Do not add a tab bar for these three pages; other destinations (goals, edit entry, tax, child setup, settings) are pushed or presented from Home/Info as in the boards. Implement with a native paging container (e.g. `TabView` page style or a scroll-view paging layout) that respects Reduce Motion (no bounce animation, instant or cross-fade switch) and exposes all three pages to VoiceOver with clear labels and rotor/escape actions. Later cycles (Cycle 3): Action Button / Siri / a setting can open the app directly on the Voice page; not in this cycle.
3. First launch flow V4Onboard1–4 (language, currency, monthly target, child envelope yes/no) and the empty day (V4EmptyDay); Apple Intelligence gate (V4NoAI).
4. Home with the island (V4Home) bound to real data: weekly allowance status, daily growth, week/month result sheets (V4Result: achieved, over, too few logged days).
5. Information page (V4Info) for household and child envelope (V4InfoChild), child setup/detail (V4ChildSetup, V4ChildDetail).
6. Goals/targets (V4Goals, V4GoalsUnset): overall + per-category, versions by month, "include fixed costs" switch (default off), week start (default Monday).
7. Add/edit entry (V4Edit): expense/income, amount, date, category, envelope, how eaten (dine-in 10% / takeout 8% / delivery 8%), manual tax rate (10, 8, none, unknown), note, fixed-cost flag, needs-review state; "I spent nothing today" mark. Receipt image attach is Cycle 2b.
8. Tax screen (V4Tax) using WealthyCore tax queries.
9. Localization for the 4 languages (String Catalog), handwritten font bundling (subset), in-app OFL license screen (Settings entry may be minimal in this cycle: language, currency, licenses, About).
10. Remove legacy UI/models from the app target once replaced (keep the legacy data files on disk; do not delete user data).

### 3.2 Out of scope (Cycle 2b / 3)
Calendar and analysis, fixed-cost list/edit/catch-up notice, receipt scan/result, category management, backup/restore UI, undo history screen, iPad layout, voice/speech/AI interpretation, App Intents. Do not implement them and do not leave dead entry points to them.

### 3.3 Where the design and WealthyCore differ: WealthyCore and these rules win
- Unknown tax rate: WealthyCore excludes unknown-rate entries from tax totals and counts them. The V4Tax mock says they are included at a tentative 10%; do NOT do that. Show "N entries have an unknown rate; not included in the totals".
- Takeout saving: WealthyCore compares tax portions of the same tax-inclusive amount (e.g. 2,400 inclusive: 218 at 10% vs 177 at 8% = 41). The mock shows a different formula (44). Use WealthyCore's number and describe the calculation accordingly, always labeled as an estimate.
- Tax totals include fixed costs unless the entry is tax-exempt; ignore the mock sentence "fixed costs are not included" for the tax screen. Targets still follow `includeFixedCostsInTargets`.
- Undo list is Cycle 2b. When it is built, recurring auto-posting is not an undo step in WealthyCore (remove that mock row then).

## 4. Technical constraints
- SwiftUI only, Swift 6 language mode for new code where feasible; if the app target must stay in Swift 5 mode, keep WealthyCore Swift 6 and say so.
- All state flows through `LedgerCore` (observable, `revision`, `reload()`); no business logic, tax math, allowance math or validation in views. Views call commands and queries only.
- Money is integer minor units; JPY has no decimals; display with locale-appropriate grouping (the mock formats: ja `¥1,234`, ko `JP¥1,234`, es `1.234 ¥`).
- Accessibility: contrast >= 4.5:1 for text, >= 3:1 for meaningful non-text; status (ok/watch/over) always icon + word, never color alone; every control >= 44 pt; VoiceOver labels for the island (e.g. "Island, festival open, 6 of 7 days under allowance") and results; no time-limited controls when VoiceOver is on.
- Performance: no regression of the WealthyCore benchmarks; home must render with a 50,000-entry store without visible stall (report measured time-to-first-render on device if you can measure it; do not claim without measuring).
- Fonts: download only from the OFL sources below, verify SHA-256, subset (Klee One: Joyo kanji + kana + Latin; Poor Story: all Hangul; Patrick Hand: Latin incl. Spanish accents), keep the OFL texts, and show license and copyright in-app. Sources: https://raw.githubusercontent.com/google/fonts/main/ofl/kleeone/KleeOne-Regular.ttf (sha256 bf4063f030cc2ae6adf0a11424a1888e5c0eb4438f1f6d02f52294af868e9b3a), .../KleeOne-SemiBold.ttf (b031ec426c23ca1143ef1f7d58bee7a79efe119ed654152f121c922202b303fd), .../poorstory/PoorStory-Regular.ttf (831ab87f7b5463f9cd83ac249bf386816f3a478f1d226427c88cac907adb7ee2), .../patrickhand/PatrickHand-Regular.ttf (0f173b3e6cb6d1af25babf7f0057c5ac4ee11f9992b0469bb817e967ef4ad0fc); license files at the same folders as OFL.txt. Expected subset total about 7 MB raw. Use `Font.custom(_:size:relativeTo:)` so Dynamic Type applies. Characters missing from a subset fall back to the system font.
- No new third-party dependencies.

### 4.1 Core changes allowed in this cycle (WealthyCore)
- Month reward eligibility becomes ceil(0.7 x days in month) logged days (was 0.8). Update tests.
- Any small query/API addition the UI strictly needs (e.g. island state per day, result summaries). Keep them deterministic and tested; do not change persistence internals.
### 4.2 Island/reward state
Derive everything from WealthyCore queries: per-day under/over daily allowance, no-spend marks, week/month eligibility, number of festivals in the month (areas = festivals, max 4 in design). Do not store rewards yet except as derived values; sticker album persistence is Cycle 2b unless trivial.
### 4.3 Late entries
Results are recomputed from entries, so adding a forgotten day within 3 days after the period ends changes the result. Show the result sheet again with updated state; do not store a past result as a fixed fact in this cycle.

## 5. Files to change
App target (new UI, design system, localization, fonts, assets), WealthyCore (4.1 only), tests, Verification scripts if they reference removed legacy code (do not weaken them: update intent-preserving). Keep the legacy app's data on disk.

## 6. Do not change
WealthyCore persistence internals, change-set undo, backup format, tax/target rules beyond 4.1, user data on disk, bundle identifier and signing settings, Apple Intelligence launch gate behavior.

## 7. Design source files
Source of truth is the exported v4 boards (PNG/PDF from the Claude Design canvas, light/dark, standard/AX where available) placed by the product owner in the repo under `design/v4/`. Boards: V4Home, V4Voice (idle), V4Info, V4InfoChild, V4Result (week/month, achieved/missed/few), V4Goals, V4GoalsUnset, V4Edit, V4Tax, V4ChildSetup, V4ChildDetail, V4Onboard1–4, V4EmptyDay, V4NoAI, V4Handoff. Public canvas: https://claude.ai/artifact/TLRvuTMJnqSaAv4BGpR3YB (may not be readable by you). If `design/v4/` is missing, stop and report that instead of guessing the visuals.

## 8. Acceptance criteria
- App builds (Simulator, Release, signed device) and launches on a fresh install into onboarding; completing it yields an empty home on the new store.
- All 4 languages render every in-scope screen with correct fonts; no truncation of buttons/headings in Spanish at default and AX3 sizes.
- Adding a household expense, a child expense, a takeout vs dine-in food expense, a no-spend day and a target change updates home, info, tax screens correctly (verified against WealthyCore values, not recomputed in the UI).
- "Not a balance" wording present wherever allowance is shown.
- Reduce Transparency and Reduce Motion variants behave as specified.
- No wallet/transfer/balance wording anywhere in UI or strings.
- All previous WealthyCore tests plus new ones pass; existing verification scripts still pass or are updated with intent preserved and listed in the report.

## 9. Build and test
`sh Verification/verify_core.sh`; Simulator and Release builds; signed device build and launch; UI tests (XCUITest) for onboarding, add expense, take-out tax, no-spend mark, target edit; snapshot or screenshot comparison against `design/v4/` for each in-scope screen in light, dark and AX3 (attach screenshots to the report; they may contain only test data).

## 10. GUI check
On a real device (iPhone 15 Pro class or newer) run: fresh install flow; one full week of seeded entries to see festival / over / too-few-days results; dark mode; Reduce Transparency; Reduce Motion; AX3 text; VoiceOver pass over home, result sheet and entry form. Report what was and wasn't verified.

## 11. Report back
Branch and PR link; per-requirement status; list of screens with screenshots vs design (differences and why); tests/commands and results; measured performance numbers; decisions you had to make; anything in the design that could not be built as drawn (especially Liquid Glass differences); open questions.
