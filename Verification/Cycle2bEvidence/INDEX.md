# Cycle 2b.1 Simulator Evidence

Task ID: WEALTHY-C2B1-FIXED-CALENDAR

Synthetic data only. Both simulators used iOS 27.0 and Xcode 27.2. Round 5 refreshes the onboarding captures; target captures show the typed amount and keyboard. The other images are from earlier rounds. JPEG quality is 80, long edges are at most 2,000 pixels, and each image is under 1 MB.

## Round 3 audit results

The full WealthyUITests suite passed on both simulators: 60 tests, zero failures each. The full Dynamic Type audit uses only the owner-approved exception for existing SwiftUI.AccessibilityNode elements. Every other finding remains a failure. The compensating Dynamic Type growth test passed on both devices.

| Screen or audit | iPhone 15 Pro ignored issues | iPhone 17 Pro ignored issues |
| --- | ---: | ---: |
| Fixed costs, Calendar, Analysis (light / dark / AX3) | 0 / 0 / 0 each | 0 / 0 / 0 each |
| Rule form (light / dark / AX3) | 2 / 2 / 2 | 1 / 1 / 1 |
| Home | 15 | 15 |
| Total | 21 | 18 |

Simulator screenshots do not establish physical-device UI or VoiceOver behavior.

## Round 5 onboarding screenshots

Images come from `testNativeOnboardingEvidenceLightAndDark` in the full suite. The target screen has a synthetic amount and the software keyboard open.

| Screen | 15 Pro light | 15 Pro dark | 17 Pro light | 17 Pro dark |
| --- | --- | --- | --- | --- |
| Language | [Light](iphone15pro-onboarding-language-light.jpg) | [Dark](iphone15pro-onboarding-language-dark.jpg) | [Light](iphone17pro-onboarding-language-light.jpg) | [Dark](iphone17pro-onboarding-language-dark.jpg) |
| Currency | [Light](iphone15pro-onboarding-currency-light.jpg) | [Dark](iphone15pro-onboarding-currency-dark.jpg) | [Light](iphone17pro-onboarding-currency-light.jpg) | [Dark](iphone17pro-onboarding-currency-dark.jpg) |
| Monthly target | [Light](iphone15pro-onboarding-target-light.jpg) | [Dark](iphone15pro-onboarding-target-dark.jpg) | [Light](iphone17pro-onboarding-target-light.jpg) | [Dark](iphone17pro-onboarding-target-dark.jpg) |
| Child | [Light](iphone15pro-onboarding-child-light.jpg) | [Dark](iphone15pro-onboarding-child-dark.jpg) | [Light](iphone17pro-onboarding-child-light.jpg) | [Dark](iphone17pro-onboarding-child-dark.jpg) |

## iPhone 15 Pro

| Screen | Light | Dark | AX3 |
| --- | --- | --- | --- |
| Home | [Light](iphone15pro-home-light.jpg) | [Dark](iphone15pro-home-dark.jpg) | [AX3](iphone15pro-home-ax3.jpg) |
| Fixed costs | [Light](iphone15pro-fixed-costs-light.jpg) | [Dark](iphone15pro-fixed-costs-dark.jpg) | [AX3](iphone15pro-fixed-costs-ax3.jpg) |
| Rule form | [Light](iphone15pro-rule-form-light.jpg) | [Dark](iphone15pro-rule-form-dark.jpg) | [AX3](iphone15pro-rule-form-ax3.jpg) |
| Catch-up notice | [Light](iphone15pro-catch-up-light.jpg) | [Dark](iphone15pro-catch-up-dark.jpg) | [AX3](iphone15pro-catch-up-ax3.jpg) |
| Calendar | [Light](iphone15pro-calendar-light.jpg) | [Dark](iphone15pro-calendar-dark.jpg) | [AX3](iphone15pro-calendar-ax3.jpg) |
| Day detail | [Light](iphone15pro-day-detail-light.jpg) | [Dark](iphone15pro-day-detail-dark.jpg) | [AX3](iphone15pro-day-detail-ax3.jpg) |
| Analysis | [Light](iphone15pro-analysis-light.jpg) | [Dark](iphone15pro-analysis-dark.jpg) | [AX3](iphone15pro-analysis-ax3.jpg) |

## iPhone 17 Pro

| Screen | Light | Dark | AX3 |
| --- | --- | --- | --- |
| Home | [Light](iphone17pro-home-light.jpg) | [Dark](iphone17pro-home-dark.jpg) | [AX3](iphone17pro-home-ax3.jpg) |
| Fixed costs | [Light](iphone17pro-fixed-costs-light.jpg) | [Dark](iphone17pro-fixed-costs-dark.jpg) | [AX3](iphone17pro-fixed-costs-ax3.jpg) |
| Rule form | [Light](iphone17pro-rule-form-light.jpg) | [Dark](iphone17pro-rule-form-dark.jpg) | [AX3](iphone17pro-rule-form-ax3.jpg) |
| Catch-up notice | [Light](iphone17pro-catch-up-light.jpg) | [Dark](iphone17pro-catch-up-dark.jpg) | [AX3](iphone17pro-catch-up-ax3.jpg) |
| Calendar | [Light](iphone17pro-calendar-light.jpg) | [Dark](iphone17pro-calendar-dark.jpg) | [AX3](iphone17pro-calendar-ax3.jpg) |
| Day detail | [Light](iphone17pro-day-detail-light.jpg) | [Dark](iphone17pro-day-detail-dark.jpg) | [AX3](iphone17pro-day-detail-ax3.jpg) |
| Analysis | [Light](iphone17pro-analysis-light.jpg) | [Dark](iphone17pro-analysis-dark.jpg) | [AX3](iphone17pro-analysis-ax3.jpg) |

The 42 earlier screenshots are retained; Round 5 refreshes the 16 onboarding screenshots. The Round 5 full-suite result bundles are `/tmp/wealthy-c2b1-r5-full15.xcresult` and `/tmp/wealthy-c2b1-r5-full17.xcresult`. The 15 Pro suite has one result-screen contrast audit failure; the 17 Pro suite passed. See `.ai/LAST_REPORT.md` for commands and remaining limits.
