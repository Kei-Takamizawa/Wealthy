# Cycle 2b.2 screenshot evidence

All images use synthetic UI-test data, English, JPY, and iOS 27.0 simulators (Xcode 27.2). JPEG quality approximately 80; long edge at most 2,000 pixels; each file below 1 MB.

Every image was opened for visual inspection during Round 3. In all six Quick add images, Amount, the typed digits `650`, and Save are visible above the number pad. AX3 is Accessibility Extra Large. Other category buttons and More details can scroll at AX3.

| Screenshot | Device | Appearance / content |
| --- | --- | --- |
| [iphone15pro-quick-light.jpg](iphone15pro-quick-light.jpg) | iPhone 15 Pro | Quick add, light, default type |
| [iphone15pro-quick-dark.jpg](iphone15pro-quick-dark.jpg) | iPhone 15 Pro | Quick add, dark, default type |
| [iphone15pro-quick-ax3.jpg](iphone15pro-quick-ax3.jpg) | iPhone 15 Pro | Quick add, light, AX3 |
| [iphone15pro-home-safe-light.jpg](iphone15pro-home-safe-light.jpg) | iPhone 15 Pro | Home, expanded Safe to spend, light |
| [iphone15pro-home-safe-dark.jpg](iphone15pro-home-safe-dark.jpg) | iPhone 15 Pro | Home, expanded Safe to spend, dark |
| [iphone15pro-ai-row-light.jpg](iphone15pro-ai-row-light.jpg) | iPhone 15 Pro | Settings AI row, forced unavailable, light |
| [iphone15pro-ai-detail-light.jpg](iphone15pro-ai-detail-light.jpg) | iPhone 15 Pro | AI information, forced unavailable, light |
| [iphone17pro-quick-light.jpg](iphone17pro-quick-light.jpg) | iPhone 17 Pro | Quick add, light, default type |
| [iphone17pro-quick-dark.jpg](iphone17pro-quick-dark.jpg) | iPhone 17 Pro | Quick add, dark, default type |
| [iphone17pro-quick-ax3.jpg](iphone17pro-quick-ax3.jpg) | iPhone 17 Pro | Quick add, light, AX3 |
| [iphone17pro-home-safe-light.jpg](iphone17pro-home-safe-light.jpg) | iPhone 17 Pro | Home, expanded Safe to spend, light |
| [iphone17pro-home-safe-dark.jpg](iphone17pro-home-safe-dark.jpg) | iPhone 17 Pro | Home, expanded Safe to spend, dark |
| [iphone17pro-ai-row-light.jpg](iphone17pro-ai-row-light.jpg) | iPhone 17 Pro | Settings AI row, forced unavailable, light |
| [iphone17pro-ai-detail-light.jpg](iphone17pro-ai-detail-light.jpg) | iPhone 17 Pro | AI information, forced unavailable, light |

## Round 3 capture and audit provenance

All 14 JPEGs were recaptured from final-source targeted tests in Round 3 and opened individually. Home now shows the leading plus toolbar button and no footer. The six Quick add images show Amount, typed `650`, and Save above the keyboard; AX3 lower category rows and More details may need scrolling.

Quick add: `Cycle2aUITests.testQuickEntryKeyboardLayoutAndEvidence`, result bundles `/tmp/wealthy-c2b2-r3-quick15.xcresult` and `...-quick17.xcresult` (PASS). Home and AI: `testSafeLineAndAIInformationEvidence`, `/tmp/wealthy-c2b2-r3-home15b.xcresult` and `...-home17b.xcresult`. **The Home safe-line audits fail**: weekday text is behind the floating tab bar in both light and dark. These screenshots document that remaining defect; they do not establish acceptance. The AI-information audit passed within that test (no AI-screen audit failures).

Exported with `xcrun xcresulttool export attachments --path <bundle> --output-path <directory>`; converted with `sips -Z 2000 -s format jpeg -s formatOptions 80 <attachment.png> --out <image.jpg>`.

[round3-home-audit.txt](round3-home-audit.txt) records current and baseline Home frames and contrast failures. The restored-source swipe test passes on both simulators. Baseline `fc74376` Home passes the same full audit in light and dark; it has no safe-line feature, so it cannot reproduce the expanded-safe-line fixture. Temporary baseline worktree was removed.

The six `iphone*pro-swipe-failure-*.txt` files are historical Round 2 failure evidence from the old bounded container. They are retained, not results of the restored Form.
