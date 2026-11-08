# Cycle 2b.2 screenshot evidence

All images use synthetic UI-test data, English, JPY, and iOS 27.0 simulators (Xcode 27.2). JPEG quality approximately 80; long edge at most 2,000 pixels; each file below 1 MB.

All 18 current images were opened individually in Round 4. The six unchanged Quick add images and four unchanged AI images retain their Round 3 capture provenance. Eight Home and scheduled-screen images were captured in Round 4. In all six Quick add images, Amount, the typed digits `650`, and Save are visible above the number pad. AX3 is Accessibility Extra Large. Other category buttons and More details can scroll at AX3.

| Screenshot | Device | Appearance / content |
| --- | --- | --- |
| [iphone15pro-quick-light.jpg](iphone15pro-quick-light.jpg) | iPhone 15 Pro | Quick add, light, default type |
| [iphone15pro-quick-dark.jpg](iphone15pro-quick-dark.jpg) | iPhone 15 Pro | Quick add, dark, default type |
| [iphone15pro-quick-ax3.jpg](iphone15pro-quick-ax3.jpg) | iPhone 15 Pro | Quick add, light, AX3 |
| [iphone15pro-home-safe-light.jpg](iphone15pro-home-safe-light.jpg) | iPhone 15 Pro | Home, Safe to spend with navigation row, light |
| [iphone15pro-home-safe-dark.jpg](iphone15pro-home-safe-dark.jpg) | iPhone 15 Pro | Home, Safe to spend with navigation row, dark |
| [iphone15pro-safe-scheduled-light.jpg](iphone15pro-safe-scheduled-light.jpg) | iPhone 15 Pro | Scheduled this week, light, October 8 / Synthetic Thursday / ¥2,000 |
| [iphone15pro-safe-scheduled-dark.jpg](iphone15pro-safe-scheduled-dark.jpg) | iPhone 15 Pro | Scheduled this week, dark, October 8 / Synthetic Thursday / ¥2,000 |
| [iphone15pro-ai-row-light.jpg](iphone15pro-ai-row-light.jpg) | iPhone 15 Pro | Settings AI row, forced unavailable, light |
| [iphone15pro-ai-detail-light.jpg](iphone15pro-ai-detail-light.jpg) | iPhone 15 Pro | AI information, forced unavailable, light |
| [iphone17pro-quick-light.jpg](iphone17pro-quick-light.jpg) | iPhone 17 Pro | Quick add, light, default type |
| [iphone17pro-quick-dark.jpg](iphone17pro-quick-dark.jpg) | iPhone 17 Pro | Quick add, dark, default type |
| [iphone17pro-quick-ax3.jpg](iphone17pro-quick-ax3.jpg) | iPhone 17 Pro | Quick add, light, AX3 |
| [iphone17pro-home-safe-light.jpg](iphone17pro-home-safe-light.jpg) | iPhone 17 Pro | Home, Safe to spend with navigation row, light |
| [iphone17pro-home-safe-dark.jpg](iphone17pro-home-safe-dark.jpg) | iPhone 17 Pro | Home, Safe to spend with navigation row, dark |
| [iphone17pro-safe-scheduled-light.jpg](iphone17pro-safe-scheduled-light.jpg) | iPhone 17 Pro | Scheduled this week, light, October 8 / Synthetic Thursday / ¥2,000 |
| [iphone17pro-safe-scheduled-dark.jpg](iphone17pro-safe-scheduled-dark.jpg) | iPhone 17 Pro | Scheduled this week, dark, October 8 / Synthetic Thursday / ¥2,000 |
| [iphone17pro-ai-row-light.jpg](iphone17pro-ai-row-light.jpg) | iPhone 17 Pro | Settings AI row, forced unavailable, light |
| [iphone17pro-ai-detail-light.jpg](iphone17pro-ai-detail-light.jpg) | iPhone 17 Pro | AI information, forced unavailable, light |

## Round 5 scrolled audit decision and evidence

The designer decided to audit bar-overlapped Home text after scrolling it fully between the navigation and tab bars. Product UI is unchanged. Only Home in `testSafeLineAndAIInformationEvidence` uses the new helper; all audit types and the existing narrow SwiftUI Dynamic Type rule remain. Every other audit is unchanged. Each full audit can defer only an existing element whose frame intersects a bar. The helper checks at most eight positions, uses slow 120-point drags with a hold to avoid inertia, and fails visible issues, unidentifiable issues, and unresolved deferrals. Elements are resolved afresh after SwiftUI rebuilds. A successful full-audit visible recheck is retained within this helper call so revisiting its bar-overlapped position does not create a scroll cycle; visible failures are never waived.

[round5-home-audit.txt](round5-home-audit.txt) records deferred labels, identifiers, issue types, bar frames, original element frames and visible rechecks from both simulators. Targeted results: 15 Pro FAIL (7 assertions, 188.632 s); 17 Pro FAIL (one assertion, 101.890 s). Light-mode empty-state text passes at the visible position on both devices. Dark-mode checks still fail: visible Quick add/empty-state contrast issues, no-spend text clipping and an unidentifiable issue on 15 Pro; a contrast issue with `element=nil` on 17 Pro. An issue with no element cannot qualify for frame-based deferral. These results do not establish acceptance.

All 18 retained JPEGs were opened individually again in Round 5. All six Quick add images show Amount, typed `650`, and Save above the keyboard. All Home images show the safe amount and scheduled link above the tab bar, and all scheduled-page images show date/title/amount fully above it. Home's lower empty-state overlap is still visible in the starting-position images. AI row/detail content is readable. No screenshots were replaced because no UI changed; capture provenance remains Round 3 (Quick add/AI) and Round 4 (Home/scheduled). Visual reinspection is fresh; capture is historical. Full-suite results are recorded in `.ai/LAST_REPORT.md` after the required runs.

## Round 4 capture and audit provenance

Home and scheduled-screen images come from `Cycle2aUITests.testSafeLineAndAIInformationEvidence`, `/tmp/wealthy-c2b2-r4-safe15.xcresult` and `/tmp/wealthy-c2b2-r4-safe17.xcresult`. All eight images were opened individually. Safe to spend (¥68,000), the navigation row (one scheduled expense, ¥2,000), and the separate screen's date/title/amount are fully visible above the tab bar in both appearances on both simulators. The new screen passes the unchanged full accessibility audit in both appearances on both simulators.

**Home acceptance still fails:** empty-state text in the third section is behind the floating tab bar. Each simulator reports three contrast assertions across light/dark. These images document the remaining defect, not an audit pass. Weekday letters no longer overlap the bar. See [round4-home-audit.txt](round4-home-audit.txt) for exact elements and frames. No audit filter or exclusion changed.

Export and conversion:

```sh
xcrun xcresulttool export attachments --path /tmp/wealthy-c2b2-r4-safe15.xcresult --output-path /tmp/wealthy-c2b2-r4-attachments15
xcrun xcresulttool export attachments --path /tmp/wealthy-c2b2-r4-safe17.xcresult --output-path /tmp/wealthy-c2b2-r4-attachments17
sips -Z 2000 -s format jpeg -s formatOptions 80 <exported-attachment.png> --out <indexed-image.jpg>
```

Attachment names: `c2b2-home-safe-light`, `c2b2-home-safe---dark`, `c2b2-safe-scheduled-light`, `c2b2-safe-scheduled---dark`. The export manifest maps these names to PNG UUIDs.

## Round 3 historical capture and audit provenance


The original 14 JPEGs were recaptured from Round 3 final-source targeted tests and opened individually then. Round 4 replaces the four Home images and adds four scheduled-screen images; other Round 3 images are unchanged. Home now shows the leading plus toolbar button and no footer. The six Quick add images show Amount, typed `650`, and Save above the keyboard; AX3 lower category rows and More details may need scrolling.

Quick add: `Cycle2aUITests.testQuickEntryKeyboardLayoutAndEvidence`, result bundles `/tmp/wealthy-c2b2-r3-quick15.xcresult` and `...-quick17.xcresult` (PASS). Home and AI: `testSafeLineAndAIInformationEvidence`, `/tmp/wealthy-c2b2-r3-home15b.xcresult` and `...-home17b.xcresult`. **The Home safe-line audits fail**: weekday text is behind the floating tab bar in both light and dark. These screenshots document that remaining defect; they do not establish acceptance. The AI-information audit passed within that test (no AI-screen audit failures).

Exported with `xcrun xcresulttool export attachments --path <bundle> --output-path <directory>`; converted with `sips -Z 2000 -s format jpeg -s formatOptions 80 <attachment.png> --out <image.jpg>`.

[round3-home-audit.txt](round3-home-audit.txt) records current and baseline Home frames and contrast failures. The restored-source swipe test passes on both simulators. Baseline `fc74376` Home passes the same full audit in light and dark; it has no safe-line feature, so it cannot reproduce the expanded-safe-line fixture. Temporary baseline worktree was removed.

The six `iphone*pro-swipe-failure-*.txt` files are historical Round 2 failure evidence from the old bounded container. They are retained, not results of the restored Form.
