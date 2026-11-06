# Cycle 2b.1 Simulator Evidence

Task ID: WEALTHY-C2B1-FIXED-CALENDAR

Synthetic data only. Captured on iOS 27.0 with Xcode 27.2. Images come from the resumed `testC2bAccessibilityAndEvidence` runs; each complete test case failed because of the rule-form issues below. Screenshots are not proof that the test case passed.

JPEG quality was set to 80 with `sips`; all long edges are at most 2,000 px and every image is below 1 MB.

## Audit results

| Screen | iPhone 15 Pro | iPhone 17 Pro |
| --- | --- | --- |
| Fixed costs list | PASS: light, dark, AX3 | PASS: light, dark, AX3 |
| Calendar | PASS: light, dark, AX3 | PASS: light, dark, AX3 |
| Analysis | PASS: light, dark, AX3 | PASS: light, dark, AX3 |
| Rule form | FAIL: Category and Day of month, Dynamic Type partially unsupported | FAIL: Day of month, Dynamic Type partially unsupported |
| Day detail / catch-up notice | Captured; no separate audit requested | Captured; no separate audit requested |

The three required screens used the default full accessibility audit with no handler or exclusions. The optional rule-form audit also remains enabled and failing. AX3 uses the native `UICTContentSizeCategoryAccessibilityXL` launch preference.

## iPhone 15 Pro

| Screen | Light | Dark | AX3 |
| --- | --- | --- | --- |
| Fixed costs | [Light](iphone15pro-fixed-costs-light.jpg) | [Dark](iphone15pro-fixed-costs-dark.jpg) | [AX3](iphone15pro-fixed-costs-ax3.jpg) |
| Rule form | [Light](iphone15pro-rule-form-light.jpg) | [Dark](iphone15pro-rule-form-dark.jpg) | [AX3](iphone15pro-rule-form-ax3.jpg) |
| Catch-up notice | [Light](iphone15pro-catch-up-light.jpg) | [Dark](iphone15pro-catch-up-dark.jpg) | [AX3](iphone15pro-catch-up-ax3.jpg) |
| Calendar | [Light](iphone15pro-calendar-light.jpg) | [Dark](iphone15pro-calendar-dark.jpg) | [AX3](iphone15pro-calendar-ax3.jpg) |
| Day detail | [Light](iphone15pro-day-detail-light.jpg) | [Dark](iphone15pro-day-detail-dark.jpg) | [AX3](iphone15pro-day-detail-ax3.jpg) |
| Analysis | [Light](iphone15pro-analysis-light.jpg) | [Dark](iphone15pro-analysis-dark.jpg) | [AX3](iphone15pro-analysis-ax3.jpg) |

## iPhone 17 Pro

| Screen | Light | Dark | AX3 |
| --- | --- | --- | --- |
| Fixed costs | [Light](iphone17pro-fixed-costs-light.jpg) | [Dark](iphone17pro-fixed-costs-dark.jpg) | [AX3](iphone17pro-fixed-costs-ax3.jpg) |
| Rule form | [Light](iphone17pro-rule-form-light.jpg) | [Dark](iphone17pro-rule-form-dark.jpg) | [AX3](iphone17pro-rule-form-ax3.jpg) |
| Catch-up notice | [Light](iphone17pro-catch-up-light.jpg) | [Dark](iphone17pro-catch-up-dark.jpg) | [AX3](iphone17pro-catch-up-ax3.jpg) |
| Calendar | [Light](iphone17pro-calendar-light.jpg) | [Dark](iphone17pro-calendar-dark.jpg) | [AX3](iphone17pro-calendar-ax3.jpg) |
| Day detail | [Light](iphone17pro-day-detail-light.jpg) | [Dark](iphone17pro-day-detail-dark.jpg) | [AX3](iphone17pro-day-detail-ax3.jpg) |
| Analysis | [Light](iphone17pro-analysis-light.jpg) | [Dark](iphone17pro-analysis-dark.jpg) | [AX3](iphone17pro-analysis-ax3.jpg) |

36 JPEGs; 4,417,197 bytes total; largest image 181,161 bytes.

Raw result bundles remain under `/tmp/wealthy-c2b1-resume-15.xcresult` and `/tmp/wealthy-c2b1-resume-17.xcresult`. Physical-device startup is reported separately in `.ai/LAST_REPORT.md`; these images do not represent physical-device UI or VoiceOver operation.
