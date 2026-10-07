# Cycle 2a.4 native screenshots

Captured from the iPhone 15 Pro Simulator (iOS 27.0) using `WealthyUITests` with synthetic seeded data. JPEG quality 80; long edge capped at 2000 px. Current set is 45 images / about 6 MB. Screens are captured directly from the running app, without design-board comparisons.

| Screen | Light | Dark |
|---|---|---|
| Voice | [native-voice-light.jpg](native-voice-light.jpg) | [native-voice-dark.jpg](native-voice-dark.jpg) |
| Home | [native-home-light.jpg](native-home-light.jpg) | [native-home-dark.jpg](native-home-dark.jpg) |
| Info, household | [native-info-household-light.jpg](native-info-household-light.jpg) | [native-info-household-dark.jpg](native-info-household-dark.jpg) |
| Info, child | [native-info-child-light.jpg](native-info-child-light.jpg) | [native-info-child-dark.jpg](native-info-child-dark.jpg) |
| Goals | [native-goals-light.jpg](native-goals-light.jpg) | [native-goals-dark.jpg](native-goals-dark.jpg) |
| Goals unset | [native-goals-unset-light.jpg](native-goals-unset-light.jpg) | [native-goals-unset-dark.jpg](native-goals-unset-dark.jpg) |
| Edit | [native-edit-light.jpg](native-edit-light.jpg) | [native-edit-dark.jpg](native-edit-dark.jpg) |
| Tax | [native-tax-light.jpg](native-tax-light.jpg) | [native-tax-dark.jpg](native-tax-dark.jpg) |
| Week result, achieved | [native-result-week-achieved-light.jpg](native-result-week-achieved-light.jpg) | [native-result-week-achieved-dark.jpg](native-result-week-achieved-dark.jpg) |
| Week result, over | [native-result-week-over-light.jpg](native-result-week-over-light.jpg) | [native-result-week-over-dark.jpg](native-result-week-over-dark.jpg) |
| Week result, few days | [native-result-week-few-light.jpg](native-result-week-few-light.jpg) | [native-result-week-few-dark.jpg](native-result-week-few-dark.jpg) |
| Month result, achieved | [native-result-month-achieved-light.jpg](native-result-month-achieved-light.jpg) | [native-result-month-achieved-dark.jpg](native-result-month-achieved-dark.jpg) |
| Month result, over | [native-result-month-over-light.jpg](native-result-month-over-light.jpg) | [native-result-month-over-dark.jpg](native-result-month-over-dark.jpg) |
| Month result, few days | [native-result-month-few-light.jpg](native-result-month-few-light.jpg) | [native-result-month-few-dark.jpg](native-result-month-few-dark.jpg) |
| Child setup | [native-child-setup-light.jpg](native-child-setup-light.jpg) | [native-child-setup-dark.jpg](native-child-setup-dark.jpg) |
| Child detail | [native-child-detail-light.jpg](native-child-detail-light.jpg) | [native-child-detail-dark.jpg](native-child-detail-dark.jpg) |
| Settings | [native-settings-light.jpg](native-settings-light.jpg) | [native-settings-dark.jpg](native-settings-dark.jpg) |

Additional Home captures are `native-home-en-light.jpg`, `native-home-ja-light.jpg`, `native-home-es-light.jpg`, `native-home-ko-light.jpg`, and `native-home-en-ax3.jpg`. These are the required locale and accessibility-size variants; they use the same device, iOS version, and synthetic fixture.



| OS setting state | Home | Voice | Info |
|---|---|---|---|
| Reduce Motion enabled | [reduce-motion-home.jpg](reduce-motion-home.jpg) | [reduce-motion-voice.jpg](reduce-motion-voice.jpg) | [reduce-motion-info.jpg](reduce-motion-info.jpg) |
| Reduce Transparency enabled | [reduce-transparency-home.jpg](reduce-transparency-home.jpg) | [reduce-transparency-voice.jpg](reduce-transparency-voice.jpg) | [reduce-transparency-info.jpg](reduce-transparency-info.jpg) |

The accessibility preference values were enabled through `simctl defaults` and read back as true before capture. The Settings app was launched separately; the switches were not changed by UI navigation within Settings. VoiceOver navigation was not performed because the Computer Use prerequisite CLI was unavailable (`orca not found`).
