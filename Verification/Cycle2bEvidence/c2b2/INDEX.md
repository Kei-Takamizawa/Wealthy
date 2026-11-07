# Cycle 2b.2 screenshot evidence

All images use synthetic UI-test data, English, JPY, and iOS 27.0 simulators (Xcode 27.2). JPEG quality approximately 80; long edge at most 2,000 pixels; each file below 1 MB.

Every image was opened for visual inspection during Round 2. In all six Quick add images, Amount, the typed digits `650`, and Save are visible above the number pad. AX3 is Accessibility Extra Large. Other category buttons and More details can scroll at AX3.

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

## Capture and diagnosis provenance

Quick add: `Cycle2aUITests.testQuickEntryKeyboardLayoutAndEvidence`; Home and AI: `Cycle2aUITests.testSafeLineAndAIInformationEvidence`. Images present at the Round 2 checkpoint were inspected before any recapture. The images were already present at the start of Round 2, exported in the preceding run (the corresponding export manifests remain under `/tmp/wealthy-c2b2-evidence-iphone{15,17}pro-testQuickEntryKeyboardLayoutAndEvidence/` and `...-testSafeLineAndAIInformationEvidence/`). They were not recaptured: all experimental app changes were reverted, so the final app source matches the captured checkpoint. These images are visual evidence, not proof that the unresolved swipe test passed.

The six `iphone*pro-swipe-failure-*.txt` files preserve the complete failure-time accessibility trees and root frames from the unfixed checkpoint on both simulators, ordered by the three Home assertions. Screenshots are also retained as XCTest attachments in `/tmp/wealthy-c2b2-round2-diagnose15.xcresult` and `/tmp/wealthy-c2b2-round2-diagnose17.xcresult`.
