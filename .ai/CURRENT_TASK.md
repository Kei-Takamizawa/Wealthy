# CURRENT TASK — Cycle 2a.2: Switch the whole UI to standard iOS components (same branch `codex/wealthy-c2a-shell`)

Task ID: WEALTHY-C2A2-NATIVE-UI
Base: current head of PR #5. Push to the same branch; PR stays draft. This task REPLACES section 7 items 1-2 of `CYCLE2A_1_CURRENT_TASK.md` where they conflict (bottom bar, mic button, custom plates); items 7.3 (identify audit failures), 7.4 (measurements on final source) and 7.5 (signed Release install/launch) still apply AFTER this conversion.

## 1. Decision (product owner, 2026-10-06)
Use standard iOS components everywhere. Do NOT build custom Liquid-Glass-like surfaces. Whatever Liquid Glass the system applies automatically in iOS 26 to standard controls is fine; do not add custom glass, blur, plates or capsule buttons.

## 2. Requirements
1. **Tabs instead of the custom pager and the bottom dots.** Use the system tab bar (`TabView` with `Tab`, iOS 26 style) with three tabs in this order: Voice | Home | Info. The app opens on Home. SF Symbols + short localized labels. Remove the page dots and the custom bottom bar completely. Remove the microphone button from Home (the Voice tab replaces it).
2. **Switching by tap AND by swipe.** The system tab bar does not swipe between tabs by itself. Add horizontal swipe between adjacent tabs (Voice <-> Home <-> Info) with a minimal, standard approach (e.g. a horizontal drag gesture on the content that only triggers when the horizontal movement clearly dominates and does not interfere with vertical scrolling, List swipe actions, text fields, sliders or pickers; or a paging container if you can keep the standard tab bar). Respect Reduce Motion (no animation). Report honestly what conflicts you found and how they are handled. If a clean swipe cannot be achieved without breaking standard behavior, say so and stop at tap switching plus the best partial option; do not hack around system behavior.
3. **Standard layout containers.** Use `NavigationStack` with system large/inline titles, `List`/`Form` (inset grouped) or `Section`/`GroupBox` for content, `Picker` (segmented/menu), `Toggle`, `Stepper`, `DatePicker`, `TextField`, system `sheet` with detents, `alert`/`confirmationDialog`. Amounts sit in system-opaque rows, so the "amount on opaque surface" rule is satisfied by the standard grouped backgrounds.
4. **Standard buttons only.** `Button` with system styles (`.borderedProminent`, `.bordered`, `.plain` in lists, toolbar items, `.glass`/`.glassProminent` only if you use the iOS 26 system styles as-is). No custom capsule/pill buttons, no custom hit-area hacks unless needed for >= 44 pt. Status chips ("Within allowance", "Not a balance") become plain `Label`/text with SF Symbols and semantic colors, not custom capsules.
5. **Colors and type.** System semantic colors and system fonts (Dynamic Type) for UI chrome and body. Keep: the app accent color (navy, from the design tokens), status colors (ok/watch/over) always with icon + word, the island artwork, and the handwritten fonts ONLY for island captions and result-sheet headlines (short text). Navigation titles, tab labels, buttons and list text use the system font. Amounts use the system rounded design with monospaced digits.
6. **Remove the custom design system** that is no longer used (custom Plate, GlassChip/GlassBar, FrostLayer, custom Row/Pill/PrimaryButton, custom Reduce-Transparency branches). The system handles Reduce Transparency/Motion automatically; keep Reduce Motion handling only for the island animation and the swipe animation.
7. **Content stays as already decided.** Home: remaining amount is the hero with the label "Left this week" (ja 今週あと), "Not a balance", progress, "of allowance X, spent Y (Z%)", seven day states, month summary; household envelope only. Info: household/child segment, targets, tax. Voice tab: placeholder message shown once. All data from WealthyCore; no UI-side arithmetic.
8. Keep all 4 languages, the String Catalog, fonts and licenses screen, onboarding (use standard navigation/`Form`/buttons), result sheet, goals, edit entry, tax, child setup/detail, settings, with standard components.
9. Accessibility: VoiceOver labels for tabs and the swipe behavior (tabs remain operable via standard VoiceOver tab navigation), contrast and hit areas via standard controls, AX sizes up to AX3 must not clip.

## 3. Constraints
No WealthyCore changes except if strictly needed for the above (none expected). No new dependencies. No audit exclusions or weakened tests; update UI tests to the new structure (tab selection by tab bar, swipe test, existing workflow tests). Do not delete legacy user data. Do not merge.

## 4. Design references
The v4 boards in `design/v4/` are now an information/content and wording reference only; the visuals (glass chips, plates, capsule buttons, bottom bar, paper-colored cards) are intentionally replaced by standard iOS components. Do not try to reproduce those visuals. The island artwork and its states remain as built.

## 5. Acceptance
- No custom glass/plate/capsule-button code remains; searching the app target for the removed design-system types finds nothing.
- Tab bar with three tabs works by tap and (if feasible, see 2.2) by swipe; no dots at the bottom; no mic button on Home.
- Existing workflow tests pass on device in the new structure; new tests: tab selection, swipe left/right between tabs, swipe does not trigger while scrolling vertically or inside a text field/picker.
- Accessibility audit on Home/Info/Edit/Result: report results; the earlier 3 unidentified contrast failures must be identified and resolved or explained with evidence (element, frame, crop).
- Build: Core tests, localization/font validation, Simulator, Release, signed device build pass.

## 6. Report
Per-requirement status; what changed in the structure (files removed/added); swipe behavior details and conflicts found; screenshots of Voice, Home, Info, Goals, Edit, Tax, Result sheet, Onboarding (light, dark, AX3, one language each is enough; all 4 languages for Home); remaining unverified items.

## User follow-up during implementation (2026-10-07)

「iosのシミュレータで起動できるデバイスを追加してください」
「iphone mirroringにはテストビルド入っていると思います。ただiphoneをミラーリングしてるだけなので。最低要件のiphone 15 proでもちゃんと動くか確かめるために、シミュレータに15 proも入れてください。」

Create bootable iPhone simulator devices, including iPhone 15 Pro, and verify the app can build, install and launch there. User also instructed: 「claudeアプリにも画面録画があるので、これは止めて、iphone mirroringだけにしてください。」 Do not use Claude app recording; use only iPhone Mirroring for computer UI inspection.
