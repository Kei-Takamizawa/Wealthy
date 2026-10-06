# v4 design and device comparisons

Each available image places the selected design panel on the left and a synthetic-data XCTest device capture on the right. Both panels have the same displayed height. The captured implementation is `PR #5 base 39ae7d5 (pre-fix)`. Output JPEG quality is 80; the longest edge is at most 2,400 px.

Design panels are cropped from the local exported boards in `design/v4/`. Several exports are multi-screen canvases; crop boxes are explicitly recorded in `Verification/compare_v4_design.py`. A difference note describes visible known differences only; the images are review aids, not pixel-diff claims.

| File | Screen / mode | Known difference or source note |
|---|---|---|
| [compare-V4Home-light.jpg](compare-V4Home-light.jpg) | Home / light | Board illustration and stacked allowance cards differ from the implementation in this PR #5 baseline capture. |
| [compare-V4Home-dark.jpg](compare-V4Home-dark.jpg) | Home / dark | Board illustration and stacked allowance cards differ from the implementation in this PR #5 baseline capture. |
| [compare-V4Voice-light.jpg](compare-V4Voice-light.jpg) | Voice / light | Closest idle-state board panel. |
| [compare-V4Voice-dark.jpg](compare-V4Voice-dark.jpg) | Voice / dark | Closest idle-state board panel. |
| [compare-V4InfoHousehold-light.jpg](compare-V4InfoHousehold-light.jpg) | InfoHousehold / light | Board includes long overview sections; the device image shows the current scroll position. |
| [compare-V4InfoHousehold-dark.jpg](compare-V4InfoHousehold-dark.jpg) | InfoHousehold / dark | Board includes long overview sections; the device image shows the current scroll position. |
| [compare-V4InfoChild-light.jpg](compare-V4InfoChild-light.jpg) | InfoChild / light | Board includes more explanatory content; device values are synthetic test data. |
| [compare-V4InfoChild-dark.jpg](compare-V4InfoChild-dark.jpg) | InfoChild / dark | Board includes more explanatory content; device values are synthetic test data. |
| [compare-V4ChildSetup-light.jpg](compare-V4ChildSetup-light.jpg) | ChildSetup / light | Board includes category targets; device capture reflects the current setup controls. |
| [compare-V4ChildSetup-dark.jpg](compare-V4ChildSetup-dark.jpg) | ChildSetup / dark | Board includes category targets; device capture reflects the current setup controls. |
| [compare-V4ChildDetail-light.jpg](compare-V4ChildDetail-light.jpg) | ChildDetail / light | Board contains longer detail sections; device capture is viewport-limited. |
| [compare-V4ChildDetail-dark.jpg](compare-V4ChildDetail-dark.jpg) | ChildDetail / dark | Board contains longer detail sections; device capture is viewport-limited. |
| [compare-V4Goals-light.jpg](compare-V4Goals-light.jpg) | Goals / light | Board and device may differ in category list and month; values are synthetic. |
| [compare-V4Goals-dark.jpg](compare-V4Goals-dark.jpg) | Goals / dark | Board and device may differ in category list and month; values are synthetic. |
| [compare-V4GoalsUnset-light.jpg](compare-V4GoalsUnset-light.jpg) | GoalsUnset / light | Board's unset-target card is compared with the device's unset-month state. |
| [compare-V4GoalsUnset-dark.jpg](compare-V4GoalsUnset-dark.jpg) | GoalsUnset / dark | Board's unset-target card is compared with the device's unset-month state. |
| [compare-V4Edit-light.jpg](compare-V4Edit-light.jpg) | Edit / light | Board shows additional receipt and recurring controls outside this cycle's scope. |
| [compare-V4Edit-dark.jpg](compare-V4Edit-dark.jpg) | Edit / dark | Board shows additional receipt and recurring controls outside this cycle's scope. |
| [compare-V4Tax-light.jpg](compare-V4Tax-light.jpg) | Tax / light | Board uses sample Japanese entries; device values come from synthetic test fixtures. |
| [compare-V4Tax-dark.jpg](compare-V4Tax-dark.jpg) | Tax / dark | Board uses sample Japanese entries; device values come from synthetic test fixtures. |
| [compare-V4Settings-light.jpg](compare-V4Settings-light.jpg) | Settings / light | Board includes destinations outside this cycle; the device shows the current settings page. |
| [compare-V4Settings-dark.jpg](compare-V4Settings-dark.jpg) | Settings / dark | Board includes destinations outside this cycle; the device shows the current settings page. |
| [compare-V4EmptyDay-light.jpg](compare-V4EmptyDay-light.jpg) | EmptyDay / light | Board copy is Japanese; the device capture uses the selected test locale. |
| [compare-V4EmptyDay-dark.jpg](compare-V4EmptyDay-dark.jpg) | EmptyDay / dark | Board copy is Japanese; the device capture uses the selected test locale. |
| [compare-V4NoAI-light.jpg](compare-V4NoAI-light.jpg) | NoAI / light | Board includes multiple unavailable/preparation cases; the device shows the selected no-AI state. |
| [compare-V4NoAI-dark.jpg](compare-V4NoAI-dark.jpg) | NoAI / dark | Board includes multiple unavailable/preparation cases; the device shows the selected no-AI state. |
| [compare-V4OnboardLanguage-light.jpg](compare-V4OnboardLanguage-light.jpg) | OnboardLanguage / light | Board copy is Japanese; the device capture uses the selected test locale. |
| [compare-V4OnboardCurrency-light.jpg](compare-V4OnboardCurrency-light.jpg) | OnboardCurrency / light | Board copy is Japanese; the device capture uses the selected test locale. |
| [compare-V4OnboardTarget-light.jpg](compare-V4OnboardTarget-light.jpg) | OnboardTarget / light | Board value is a static example; device value is synthetic test data. |
| [compare-V4OnboardTarget-dark.jpg](compare-V4OnboardTarget-dark.jpg) | OnboardTarget / dark | Board value is a static example; device value is synthetic test data. |
| [compare-V4OnboardChild-light.jpg](compare-V4OnboardChild-light.jpg) | OnboardChild / light | Board copy is Japanese; the device capture uses the selected test locale. |
| [compare-V4WeekAchieved-light.jpg](compare-V4WeekAchieved-light.jpg) | WeekAchieved / light | Board uses a Japanese sample week; the device state uses synthetic test entries. |
| [compare-V4WeekAchieved-dark.jpg](compare-V4WeekAchieved-dark.jpg) | WeekAchieved / dark | Board uses a Japanese sample week; the device state uses synthetic test entries. |
| [compare-V4WeekOver-light.jpg](compare-V4WeekOver-light.jpg) | WeekOver / light | Board uses a Japanese sample week; the device state uses synthetic test entries. |
| [compare-V4WeekFew-light.jpg](compare-V4WeekFew-light.jpg) | WeekFew / light | Board uses a Japanese sample week; the device state uses synthetic test entries. |
| [compare-V4MonthFew-light.jpg](compare-V4MonthFew-light.jpg) | MonthFew / light | Board uses a fixed day-count example; the device should show the Core 70% threshold. |
| [compare-V4MonthFew-dark.jpg](compare-V4MonthFew-dark.jpg) | MonthFew / dark | Board uses a fixed day-count example; the device should show the Core 70% threshold. |

## Missing mappings

- OnboardLanguage dark: no local exported dark board panel was found.
- OnboardCurrency dark: no local exported dark board panel was found.
- OnboardChild dark: no local exported dark board panel was found.
- WeekOver dark: no device screenshot mapping found; expected a capture alias for `WeekOver-dark`.
- WeekFew dark: no device screenshot mapping found; expected a capture alias for `WeekFew-dark`.
- MonthAchieved light: no device screenshot mapping found; expected a capture alias for `MonthAchieved-light`.
- MonthAchieved dark: no local exported dark board panel was found.
- MonthOver light: no device screenshot mapping found; expected a capture alias for `MonthOver-light`.
- MonthOver dark: no local exported dark board panel was found.

## Rebuild

From the repository root, run `python3 Verification/compare_v4_design.py --manifest PATH/manifest.json --capture-dir PATH --source-dir /private/tmp/wealthy-v4-compare-source`. The manifest and capture folder come from an XCTest attachment export; aliases are configured in the script. Source captures are kept outside Git. Requires Pillow.

Synthetic test fixtures only. No real financial records are included.
