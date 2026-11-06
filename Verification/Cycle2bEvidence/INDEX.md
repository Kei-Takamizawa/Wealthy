# Cycle 2b.1 Simulator Evidence

Task ID: WEALTHY-C2B1-FIXED-CALENDAR

Synthetic data only. Both simulators used iOS 27.0 and Xcode 27.2. Round 2 refreshed the rule-form images after the NavigationLink change. Home images are from the previous Round 2 checkpoint; other images are from the earlier Round 1 runs. JPEG quality is 80, long edges are at most 2,000 pixels, and each image is under 1 MB.

## Audit results

The full resumed 59-test runs failed on both devices. Images do not establish test acceptance.

| Screen or audit | iPhone 15 Pro | iPhone 17 Pro |
| --- | --- | --- |
| Fixed costs list, Calendar, Analysis | Default audits passed without a pinned content size | Default audits passed without a pinned content size |
| Rule form | Full default audit failed: Category and Day of month, Dynamic Type partially unsupported | Full default audit failed: Day of month, Dynamic Type partially unsupported |
| Home, existing four-type audit | Passed in the full suite | Passed in the full suite |
| Home, additional default full audit | Failed: multiple Dynamic Type partially unsupported issues | Failed: multiple Dynamic Type partially unsupported issues |
| Home AX3 multilingual text clipping | Follow-up passed in en/ja/es/ko, top and scrolled | Follow-up passed in en/ja/es/ko, top and scrolled |
| Day detail / catch-up notice | Round 1 images; no separate audit | Round 1 images; no separate audit |

Audits ran without a content-size launch argument; AX3 screenshot captures used the system content-size launch preference in separate launches. Home uses the system content size rather than an in-app environment override. The four-type Home audit covers contrast, text clipping, hit region and sufficient element description. The additional default audit uses all types and no issue handler. Simulator images do not establish physical-device UI or VoiceOver behavior.

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

42 JPEGs; 5,442,181 bytes total; largest 181,161 bytes.

Final-source full-suite results are under `/tmp/wealthy-c2b1-r2-k-full15.xcresult` and `/tmp/wealthy-c2b1-r2-k-full17.xcresult`. See `.ai/LAST_REPORT.md` for all failures and follow-up results.
