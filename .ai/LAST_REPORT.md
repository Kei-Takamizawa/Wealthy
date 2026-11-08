# Cycle 2b.2 Round 6 Report

Task ID: WEALTHY-C2B2-QUICK-ENTRY
Status: PARTIAL

The required baseline comparisons and ordered follow-up runs are complete. The six reported interaction failures reproduce individually on both c937c63 and the current tree. The previous-week result sheet covers Home after fresh onboarding on November 9; the no-spend font/lineLimit changes are not necessary to reproduce them. The addEntry contrast correction is retained. Safe-line audit issues and the full-suite failures below prevent DONE. No tests or audit types were disabled, weakened or newly excluded.

Execution: November 8–9, 2026 JST; macOS; Xcode 27.2 (27B52); iPhone 15 Pro and iPhone 17 Pro simulators, iOS 27.0. Branch `codex/wealthy-c2b2-quick-entry`, HEAD `c937c637dfc6592cba0bad83528176dfdb9cbf14`. `git merge-base --is-ancestor fc74376 HEAD` returned 0. The supplied task was preserved and the owner's November 9 follow-up appended verbatim. No branch switch, staging, commit, push, reset or merge was performed. Existing unrelated .DS_Store modifications and the untracked design PDF were preserved.

## Changed files

Round 6 product changes are confined to HomeInfo.swift: explicit light/dark foreground and tint for addEntry; no-spend wrapping and loose standard body leading, with its existing 44-point minimum. Test changes in QuickEntryUITests.swift wait for stable Home cell frames before every scrolled audit, attach full/cropped issue images, check Home actions at default/AX3 in both appearances, and explicitly cover ordinary dark Home. The existing narrow SwiftUI Dynamic Type rule and bar-intersection/recheck policy are unchanged. No other-screen, Core, onboarding, weekly-result or generic tap-helper code changed this round.

Whole-cycle task files relative to fc74376, including retained previous-round implementation and all evidence (one path per line):

- .ai/CURRENT_TASK.md
- .ai/LAST_REPORT.md
- README.md
- Verification/Cycle2bEvidence/c2b2/INDEX.md
- Verification/Cycle2bEvidence/c2b2/iphone15pro-ai-detail-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-ai-row-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-home-actions-ax3.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-home-actions-dark-ax3.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-home-actions-dark.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-home-actions-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-home-safe-dark.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-home-safe-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-quick-ax3.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-quick-dark.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-quick-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-safe-scheduled-dark.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-safe-scheduled-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone15pro-swipe-failure-1.txt
- Verification/Cycle2bEvidence/c2b2/iphone15pro-swipe-failure-2.txt
- Verification/Cycle2bEvidence/c2b2/iphone15pro-swipe-failure-3.txt
- Verification/Cycle2bEvidence/c2b2/iphone17pro-ai-detail-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-ai-row-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-home-actions-ax3.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-home-actions-dark-ax3.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-home-actions-dark.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-home-actions-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-home-safe-dark.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-home-safe-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-quick-ax3.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-quick-dark.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-quick-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-safe-scheduled-dark.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-safe-scheduled-light.jpg
- Verification/Cycle2bEvidence/c2b2/iphone17pro-swipe-failure-1.txt
- Verification/Cycle2bEvidence/c2b2/iphone17pro-swipe-failure-2.txt
- Verification/Cycle2bEvidence/c2b2/iphone17pro-swipe-failure-3.txt
- Verification/Cycle2bEvidence/c2b2/round3-home-audit.txt
- Verification/Cycle2bEvidence/c2b2/round4-home-audit.txt
- Verification/Cycle2bEvidence/c2b2/round5-home-audit.txt
- Verification/Cycle2bEvidence/c2b2/round6-comparison/1-baseline15.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/1-current15.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/2-baseline15.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/2-current15.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/3-baseline15.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/3-current15.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/4-baseline15.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/4-current15.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/5-baseline17.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/5-current17.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/6-baseline17.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/6-current17.jpg
- Verification/Cycle2bEvidence/c2b2/round6-comparison/INDEX.md
- Verification/Cycle2bEvidence/c2b2/round6-comparison/results.json
- Verification/Cycle2bEvidence/c2b2/round6-contrast.json
- Verification/Cycle2bEvidence/c2b2/round6-crops/INDEX.md
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-000-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-001-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-002-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-003-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-004-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-005-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-006-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-final-000-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-final-001-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-final-002-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-final-003-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-final-004-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-final-005-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-final-006-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-final-manifest.json
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-full-000-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-full-001-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-full-002-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-full-003-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-full-004-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-full-005-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-full-006-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-full-manifest.json
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-manifest.json
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-000-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1---0-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-001-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1---0-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-002-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Spent-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-003-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Spent-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-004-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1---70-000-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-005-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1---70-000-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-006-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Allowance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-007-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Allowance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-008-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-009-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-010-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-011-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-012-round6-home-safe-line---dark-position4-XCUIAccessibilityAuditType-rawValue-1--I-spent-nothing-today-.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-013-round6-home-safe-line---dark-position4-XCUIAccessibilityAuditType-rawValue-1--I-spent-nothing-today-.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-014-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-2--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-015-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1---0-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-016-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1---0-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-017-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Spent-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-018-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Spent-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-019-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1---70-000-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-020-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1---70-000-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-021-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Allowance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-022-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Allowance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-023-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-024-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-025-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-026-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-027-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-028-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-029-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--This-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-030-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--This-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-031-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-032-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-033-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-034-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-035-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-036-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-037-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--I-spent-nothing-today-.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-038-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--I-spent-nothing-today-.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-039-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-040-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-041-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-042-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-043-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-044-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-045-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-046-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-manifest.json
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-000-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1---0-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-001-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1---0-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-002-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Spent-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-003-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Spent-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-004-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1---70-000-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-005-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1---70-000-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-006-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Allowance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-007-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Allowance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-008-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-009-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-010-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-011-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-012-round6-home-safe-line---dark-position4-XCUIAccessibilityAuditType-rawValue-1--I-spent-nothing-today-.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-013-round6-home-safe-line---dark-position4-XCUIAccessibilityAuditType-rawValue-1--I-spent-nothing-today-.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-014-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-2--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-015-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1---0-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-016-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1---0-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-017-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Spent-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-018-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Spent-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-019-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1---70-000-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-020-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1---70-000-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-021-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Allowance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-022-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Allowance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-023-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-024-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-025-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-026-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-027-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-028-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-029-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-030-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-031-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--after-1-scheduled-2-00.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-032-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--after-1-scheduled-2-00.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-033-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--This-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-034-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--This-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-035-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-036-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-037-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-038-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-039-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-040-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-041-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--I-spent-nothing-today-.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-042-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--I-spent-nothing-today-.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-043-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-044-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-045-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-046-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-047-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-048-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-049-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-050-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-manifest.json
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-000-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-001-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-002-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-003-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-004-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-005-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-006-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-131072--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-007-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-65536--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-008-round6-home-safe-line---dark-position4-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-009-round6-home-safe-line---dark-position4-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-010-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-2--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-011-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-012-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-013-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-014-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-015-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-016-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-017-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-018-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-019-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-020-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-021-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-022-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-023-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-024-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-025-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-026-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-027-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-028-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-029-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-030-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-031-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-032-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-033-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-034-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-035-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-036-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-037-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-038-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-000-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-2--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-001-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-002-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-003-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-004-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-005-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-006-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-007-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-008-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-009-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--This-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-010-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--This-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-011-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-012-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-013-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-014-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-015-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-016-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-017-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-018-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-019-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-020-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-021-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-022-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-023-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-024-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-025-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-026-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-candidate-manifest.json
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-manifest.json
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-000-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-2--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-001-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-002-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-003-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-004-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-005-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-006-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-007-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-008-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-009-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-010-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-011-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-012-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-013-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-014-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-015-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-016-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-017-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-018-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-019-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-020-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-021-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-022-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-023-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-024-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-025-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-026-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-manifest.json
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-000-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-2--no-element-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-001-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-002-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-003-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-004-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-005-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-006-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-007-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-008-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-009-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-010-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-011-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-012-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-013-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-014-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-015-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-016-round6-home-safe-line---dark-position2-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-017-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-018-round6-home-safe-line---dark-position1-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-019-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-020-round6-home-safe-line---dark-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-021-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-022-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-or.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-023-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-crop.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-024-round6-home-safe-line-light-position0-XCUIAccessibilityAuditType-rawValue-1--A-fresh-island-full.jpg
- Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-manifest.json
- Verification/Cycle2bEvidence/c2b2/round6-final-audit.json
- Verification/Cycle2bEvidence/c2b2/round6-final-audit.md
- Verification/Cycle2bEvidence/c2b2/round6-final-audit.txt
- Verification/Cycle2bEvidence/c2b2/round6-home-audit.txt
- Verification/Cycle2bEvidence/c2b2/round6-runtime-failures.txt
- Wealthy/Wealthy/AppShortcuts.xcstrings
- Wealthy/Wealthy/CalendarAnalysis.swift
- Wealthy/Wealthy/EntryEditor.swift
- Wealthy/Wealthy/ExpenseIntents.swift
- Wealthy/Wealthy/GoalsTaxSettings.swift
- Wealthy/Wealthy/HomeInfo.swift
- Wealthy/Wealthy/LedgerRoot.swift
- Wealthy/Wealthy/LedgerSession.swift
- Wealthy/Wealthy/Localizable.xcstrings
- Wealthy/Wealthy/QuickAdd.swift
- Wealthy/Wealthy/RecurringSession.swift
- Wealthy/Wealthy/WealthyApp.swift
- WealthyCore/Sources/WealthyCore/SafeLine.swift
- WealthyCore/Tests/WealthyCoreTests/SafeLineTests.swift
- WealthyUITests/Cycle2bUITests.swift
- WealthyUITests/QuickEntryUITests.swift
- WealthyUITests/WealthyUITests.swift

## Requirements

### Baseline comparison and cause

Each case below ran alone on its originally failing simulator, baseline first then current, with no overlapping xcodebuild test runs. Baseline source was obtained with `git archive` into `/tmp/wealthy-c2b2-r6-baseline`, without switching or mutating Git. All twelve commands exited 65. Exact commands, minimal errors, resultSheet frames and image provenance: [comparison results](../Verification/Cycle2bEvidence/c2b2/round6-comparison/results.json); [comparison images and table](../Verification/Cycle2bEvidence/c2b2/round6-comparison/INDEX.md).

| Case / simulator | c937c63 | Current |
| --- | --- | --- |
| testNoSpendDayFromEmptyLedger / iPhone 15 Pro | FAIL, 76.732 seconds | FAIL, 72.875 seconds |
| testPersistedOnboardingRelaunch / iPhone 15 Pro | FAIL, 87.154 seconds | FAIL, 87.724 seconds |
| testOnboardingEntryTaxNoSpendTarget / iPhone 15 Pro | FAIL, 39.535 seconds | FAIL, 39.542 seconds |
| testQuickEntryWithoutAIFromOnboarding / iPhone 15 Pro | FAIL, 32.174 seconds | FAIL, 31.972 seconds |
| testAdditionalSetupMatrix / iPhone 17 Pro | FAIL, 247.543 seconds | FAIL, 245.057 seconds |
| testChildEnvelopeAndLicenseFlow / iPhone 17 Pro | FAIL, 38.902 seconds | FAIL, 38.990 seconds |

Observed: every failing hierarchy has resultSheet (0,59,393,793) on 15 Pro or (0,62,402,812) on 17 Pro, showing the previous week, November 2–8. NoSpend is absent; settings/addEntry taps cannot reach uncovered Home. The existing tap helper at WealthyUITests.swift:43–44 additionally queries a nonexistent keyboard while constructing its obscured-center diagnostic, producing the misleading “No matches found … Keyboard” error.

Unchanged code explains the calendar boundary: `IslandQueries.swift:93` returns a just-ended result through three days after its end; `LedgerSession.reload` populates recentResults; `LedgerRoot.swift:49–63` queues isSet results and presents them after onboarding. For these Monday-start fixtures, on Sunday November 8 the prior week ended November 1 and was outside that window; on Monday November 9 the November 2–8 week is eligible. The baseline/current comparison establishes these six failures without the new no-spend modifiers. It does not classify every other full-suite failure as baseline behavior. The conditional no-spend revert was therefore not triggered. Clipping remains reported separately. Changing result presentation or onboarding setup requires the designer's instruction and was outside the approved Home-only scope.

### Ordered follow-up verification

Safe-line on both -> ordinary Home light/dark audits and horizontal/vertical swipe on both -> complete full suite on 15 Pro, then 17 Pro. Every invocation uses `-parallel-testing-enabled NO`. Each full scheme now contains 76 cases (one Home action case and one explicit dark Home audit added since c937c63's 74). No run was represented by a partial log.

| Invocation | PASS | FAIL | Process exit / wall seconds |
| --- | --- | --- | --- |
| safe15 | 0 | 1 | 65 / 226.736 |
| safe17 | 0 | 1 | 65 / 183.947 |
| home15 | 3 | 0 | 0 / 70.372 |
| home17 | 3 | 0 | 0 / 69.612 |
| full15 | 68 | 8 | 65 / 4840.603 |
| full17 | 68 | 8 | 65 / 5360.673 |

Targeted cases (observed XCTest duration):

| Invocation | Case | Result / seconds |
| --- | --- | --- |
| safe15 | testSafeLineAndAIInformationEvidence | FAIL / 208.889 seconds |
| safe17 | testSafeLineAndAIInformationEvidence | FAIL / 167.837 seconds |
| home15 | testHomeAccessibilityAudit | PASS / 18.225 seconds |
| home15 | testHomeDarkAccessibilityAudit | PASS / 17.622 seconds |
| home15 | testHorizontalTabSwipeAndVerticalScroll | PASS / 29.316 seconds |
| home17 | testHomeAccessibilityAudit | PASS / 18.073 seconds |
| home17 | testHomeDarkAccessibilityAudit | PASS / 17.647 seconds |
| home17 | testHorizontalTabSwipeAndVerticalScroll | PASS / 29.330 seconds |

Complete xcresult summaries:


- iPhone 15 Pro: 76 cases, 68 PASS, 8 FAIL, 0 skipped; result Failed.

| Failing case | Minimal error |
| --- | --- |
| testAdditionalSetupMatrix() | XCTAssertTrue failed |
| testChildEnvelopeAndLicenseFlow() | Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Keyboard` |
| testManualTaxAndMetadataSurviveReopening() | Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Keyboard` |
| testNoSpendDayFromEmptyLedger() | XCTAssertTrue failed |
| testOnboardingEntryTaxNoSpendTarget() | Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Keyboard` |
| testPersistedOnboardingRelaunch() | XCTAssertTrue failed |
| testQuickEntryWithoutAIFromOnboarding() | Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Keyboard` |
| testSafeLineAndAIInformationEvidence() | Text clipped |

- iPhone 17 Pro: 76 cases, 68 PASS, 8 FAIL, 0 skipped; result Failed.

| Failing case | Minimal error |
| --- | --- |
| testAdditionalSetupMatrix() | XCTAssertTrue failed |
| testChildEnvelopeAndLicenseFlow() | Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Keyboard` |
| testManualTaxAndMetadataSurviveReopening() | Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Keyboard` |
| testNoSpendDayFromEmptyLedger() | Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Keyboard` |
| testOnboardingEntryTaxNoSpendTarget() | Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Keyboard` |
| testPersistedOnboardingRelaunch() | XCTAssertTrue failed |
| testQuickEntryWithoutAIFromOnboarding() | Failed to get matching snapshot: No matches found for first query match sequence: `Descendants matching type Keyboard` |
| testSafeLineAndAIInformationEvidence() | Text clipped |

testManualTaxAndMetadataSurviveReopening fails at the existing Keyboard query in WealthyUITests.swift:44 on both simulators. This additional case was not baseline-compared and remains unclassified.

Expected: zero failures, all named feature/audit checks pass. Actual: failures above remain. The November 9 targeted Home light, dark and swipe cases pass on both simulators. Safe-line fixture audits remain FAIL; their color measurements do not count as audit passes.

Earlier Round 6 history is not the authoritative final result: the first 15 Pro full run had 75 cases, 70 PASS/5 FAIL; the first 17 Pro full run stopped without a completed result. A prior 17 Pro keyboard-layout targeted case timed out evaluating quickAmount after an app-animation-completion warning; the following three-interaction case passed. The completed follow-up results above supersede these incomplete/earlier runs without hiding their failures. [Runtime evidence](../Verification/Cycle2bEvidence/c2b2/round6-runtime-failures.txt) distinguishes these runs.

### Every remaining audit issue

All remaining rows below are dark Home with the safe-line fixture. Navigation/tab frames: 15 Pro (0,59,393,54) / (0,769,393,83); 17 Pro (0,62,402,54) / (0,791,402,83). Light Home visible rechecks, the separate scheduled-page audits in both appearances, and the AI-detail audit completed without failing assertions in these runs.

The table below includes every remaining named/nil issue from the ordered Safe-line and final full runs. Positions and repeats are retained. Frames are in points. Ratios are measured from original lossless sRGB PNG solid foreground/background pixels, excluding antialiased edges; formula `(Llighter + .05) / (Ldarker + .05)`. JPEG crops are evidence copies. A nil audit node supplies no measurable target, and a status-bar-obscured frame does not expose the reported glyphs; those ratios are explicitly unmeasurable rather than fabricated. Full images are supplied when a crop cannot be associated.

| Run / position | Type | Label / frame (pt) | Measured ratio | Crop / full |
| --- | --- | --- | --- | --- |
| safe15 / 3 | Text clipped | I spent nothing today; (130, 730.833, 160.667, 20.333) | 5.247:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-035-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-036-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) |
| safe15 / 3 | Contrast | This week; (16, 359, 361, 52) | 17.015:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-033-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--This-week-crop.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-034-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--This-week-full.jpg) |
| safe15 / 3 | Contrast | after 1 scheduled (¥2,000); (48, 198, 202, 20.333) | 9.286:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-031-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--after-1-scheduled-2-00.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-032-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--after-1-scheduled-2-00.jpg) |
| safe15 / 3 | Contrast | Add your first entry, or mark a day with no spending.; (32, 575.333, 297.667, 42.333) | 17.015:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-029-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-030-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg) |
| safe15 / 3 | Contrast | Quick add; (32, 647.667, 141.333, 34.333) | 11.461:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-027-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-028-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg) |
| safe15 / 3 | Contrast | Left this week; (48, 27, 105.667, 20.333) | N/A — Reported frame is outside the fully visible content between navigation/tab bars; the crop is occluded and does not reliably expose the reported glyphs. Underlying text contrast cannot be measured here. | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-025-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-crop.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-026-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Left-this-week-full.jpg) |
| safe15 / 3 | Potentially inaccessible text | Not supplied; N/A | N/A — Audit supplies no element/frame; no defensible glyph or background can be assigned. Full screenshot supplied; crop unavailable. | [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-014-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-2--no-element-full.jpg) |
| safe15 / 5 | Text clipped | I spent nothing today; (130, 730.833, 160.667, 20.333) | 5.247:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-010-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-safe-011-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) |
| safe17 / 3 | Text clipped | I spent nothing today; (134.5, 752.833, 160.667, 20.333) | 5.247:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-009-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-010-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) |
| safe17 / 3 | Contrast | Add your first entry, or mark a day with no spending.; (32, 597.333, 297.667, 42.333) | 17.015:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-007-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-008-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg) |
| safe17 / 3 | Contrast | Quick add; (32, 669.667, 141.333, 34.333) | 11.461:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-005-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-006-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg) |
| safe17 / 3 | Potentially inaccessible text | Not supplied; N/A | N/A — Audit supplies no element/frame; no defensible glyph or background can be assigned. Full screenshot supplied; crop unavailable. | [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-safe-000-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-2--no-element-full.jpg) |
| full15 / 3 | Text clipped | I spent nothing today; (130, 730.833, 160.667, 20.333) | 5.247:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-031-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-032-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) |
| full15 / 3 | Contrast | This week; (16, 359, 361, 52) | 17.015:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-029-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--This-week-crop.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-030-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--This-week-full.jpg) |
| full15 / 3 | Contrast | Add your first entry, or mark a day with no spending.; (32, 575.333, 297.667, 42.333) | 17.015:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-027-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-028-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg) |
| full15 / 3 | Contrast | Quick add; (32, 647.667, 141.333, 34.333) | 11.461:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-025-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-026-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg) |
| full15 / 3 | Potentially inaccessible text | Not supplied; N/A | N/A — Audit supplies no element/frame; no defensible glyph or background can be assigned. Full screenshot supplied; crop unavailable. | [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-014-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-2--no-element-full.jpg) |
| full15 / 5 | Text clipped | I spent nothing today; (130, 730.833, 160.667, 20.333) | 5.247:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-010-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone15pro-post-full-011-round6-home-safe-line---dark-position5-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) |
| full17 / 3 | Text clipped | I spent nothing today; (134.5, 752.833, 160.667, 20.333) | 5.247:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-011-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-012-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-131072--I-spent-nothing-t.jpg) |
| full17 / 3 | Contrast | Not a balance; (59.667, 286.333, 105, 20.333) | 17.015:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-009-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-crop.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-010-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Not-a-balance-full.jpg) |
| full17 / 3 | Contrast | Add your first entry, or mark a day with no spending.; (32, 597.333, 297.667, 42.333) | 17.015:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-007-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-008-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Add-your-first-entry-o.jpg) |
| full17 / 3 | Contrast | Quick add; (32, 669.667, 141.333, 34.333) | 11.461:1 | [crop](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-005-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-crop.jpg) / [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-006-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-1--Quick-add-full.jpg) |
| full17 / 3 | Potentially inaccessible text | Not supplied; N/A | N/A — Audit supplies no element/frame; no defensible glyph or background can be assigned. Full screenshot supplied; crop unavailable. | [full](../Verification/Cycle2bEvidence/c2b2/round6-crops/iphone17pro-post-full-000-round6-home-safe-line---dark-position3-XCUIAccessibilityAuditType-rawValue-2--no-element-full.jpg) |


Exact palettes, pixel counts, PNG provenance and notes: [final audit JSON](../Verification/Cycle2bEvidence/c2b2/round6-final-audit.json). Full settle/defer/recheck records: [final audit log](../Verification/Cycle2bEvidence/c2b2/round6-final-audit.txt). The audit reports noSpend clipping despite fitting frame/visual checks; no fixed text height was added. Nil-node issues remain failures. No new exclusion or speculative other-screen fix was introduced.

The original dark Home button was white on #A9C0EE: 1.832:1. The retained correction is black on #A9C0EE: 11.461:1; light mode white on #2E4A7D: 8.780:1. Actual Quick save PNGs use the same palette. Visible ordinary dark text measures 17.015:1, scheduled-link text 9.286:1, and no-spend text 5.247:1. None of these visible ordinary-text measurements meets the task's below-4.5:1 condition for changing ordinary text. A numeric pass does not override the remaining XCTest audit failure. All bar-overlapped issues that passed a later full-audit visible recheck remain in the raw log. An element above the navigation bar is not silently treated as an intersecting-bar exception.

### Whole-cycle implementation

- E3: PARTIAL acceptance. Ledger opening no longer depends on AI availability. Availability detection, informational Settings row/detail and DEBUG overrides remain; README says iOS 26 or later and Apple Intelligence is not required. Voice is unchanged. Fresh-onboarding-to-Quick-add currently fails behind the result modal described above.
- Quick add: expense/today/household/app-currency defaults; optional category; ranked category shortcuts; normal undoable Core command; invalid amount keeps the sheet/error; More details carries the amount; localized Uncategorized in lists/day/analysis. The toolbar interaction path is tap/type/tap, with row-button coverage. VoiceOver confirmation is implemented; physical listening and three-second timing are NOT_RUN.
- App Intents: LedgerSession.shared with a private initializer owns one process-wide store, and open() exits if Core is already open. UI and RecordExpenseIntent use the same recordExpense path, including late-entry validation, catch-up and undoable command. Active-scene reload and the real-perform isolated-store DEBUG hooks are retained. No new dependency, target, extension, App Group, capability or entitlement.
- Safe line Core: PASS, 123 tests in 14 suites (117 previous plus six new functions/parameterized cases). Coverage includes no target/rules; today/later this week/next week; paused/ended/income; fixed-cost inclusion both ways; envelope/currency; Sunday/Monday boundary; negative values and checked overflow. Home uses the Core-derived safe amount only when a target and scheduled expenses exist, retains Not a balance and negative/over wording, and includes safe-line information in the week-card accessibility label. Only one read-only query was added this cycle. No persistence, data-model, target or tax policy changed. The scheduled breakdown uses the designer-approved separate standard navigation screen from Round 4.
- Languages: PASS, 213 shipping keys in en/ja/es/ko, zero missing keys; fonts/placeholders pass; localization script also reports 2,420 archived checks. Retained Japanese wording: クイック記録, 未分類, 今週あと安心して使える額, 今週の予定支出. No new wording or bundled font/tab/deployment-target change in Round 6; only no-spend standard body leading changed.

Final full-suite feature results:

| Case | 15 Pro | 17 Pro |
| --- | --- | --- |
| testAvailableAIInformation | PASS | PASS |
| testQuickEntryWithoutAIFromOnboarding | FAIL | FAIL |
| testLocalizedQuickEntryAndSafeLine | PASS | PASS |
| testQuickCategoryRankingAndPresets | PASS | PASS |
| testQuickEntryCategoryDetailsAndInvalidAmount | PASS | PASS |
| testQuickEntryKeyboardLayoutAndEvidence | PASS | PASS |
| testQuickEntryThreeInteractionsAndUncategorized | PASS | PASS |
| testRecordExpenseIntentAndRelaunch | PASS | PASS |
| testIntentIncludesTodaysRecurringExpense | PASS | PASS |
| testIntentWithoutTargetAndInvalidAmount | PASS | PASS |
| testOpenQuickAddIntentAndPendingNotice | PASS | PASS |
| testHomeAccessibilityAudit | PASS | PASS |
| testHomeDarkAccessibilityAudit | PASS | PASS |
| testHomeActionLabelsAtDefaultAndAX3 | PASS | PASS |
| testHorizontalTabSwipeAndVerticalScroll | PASS | PASS |
| testSafeLineAndAIInformationEvidence | FAIL | FAIL |

### GUI and image review

All 26 main JPEGs were opened individually in Round 6. All six Quick add images show Amount, typed 650 and Save above the number pad, at default/light/dark and AX3 on both simulators; lower options scroll at AX3. Four Home safe images were recaptured in Round 6; eight Home action images were added for light/dark/default/AX3. Their no-spend label is readable, inside its button and above the tab bar (default button height 88 pt; AX3 142 pt, text 98 pt). This does not override clipping audit failures. Four scheduled images show date/title/¥2,000. AI row/detail are readable. Lower empty-state overlap in initial Home captures is documented and tested through the scrolled-audit policy.

The designer-approved plain Home Form from fc74376 remains restored, without GeometryReader/manual frame/clipping/footer; Quick add has a standard row button and leading toolbar action. The DEBUG intent dialog is a conditional overlay. Fresh swipe logs report Home root (0,0,393,852) on 15 Pro and (0,0,402,874) on 17 Pro; these match the retained fc74376 baseline frames measured in Round 2/3. That fc74376 baseline was not rerun in Round 6.

Capture provenance: unchanged Quick add/AI images Round 3; scheduled page Round 4; Home and actions Round 6. The 12 comparison images and all newly exported audit images were inspected in contact sheets, with relevant full images/crops opened individually. All data is synthetic. [Evidence index](../Verification/Cycle2bEvidence/c2b2/INDEX.md) and crop manifests distinguish historical captures from fresh tests.

Image bounds verified: 275 JPEGs; maximum long edge 2000 px; file sizes 883–141,857 bytes, all below 1 MB. Export used JPEG quality 80. Numeric measurements use original PNGs, not JPEG samples.

### Builds, metadata and physical device

PASS: Simulator Release, signed generic iOS Release with the existing team, and strict codesign verification. No new capabilities. Metadata.appintents/extract.actionsdata contains:

```text
OpenQuickAddIntent openAppWhenRun=True parameters=[]
RecordExpenseIntent openAppWhenRun=False parameters=[('amount', False), ('category', True)]
```

Both appear in autoShortcuts. Built AppShortcuts.strings contains both phrases in all four languages:

| Language | Quick add | Record expense |
| --- | --- | --- |
| en | Quick add in ${applicationName} | Record an expense in ${applicationName} |
| ja | ${applicationName}でクイック記録 | ${applicationName}で支出を記録 |
| es | Registro rápido en ${applicationName} | Registrar un gasto en ${applicationName} |
| ko | ${applicationName}에서 빠른 기록 | ${applicationName}에서 지출 기록 |

PASS: the same production-source signed Release was installed and normally launched once on the paired iPhone 16 Pro Max, iOS 27.3. Install exit 0, 14.575 s; process launch exit 0, 2.006 s. Initial disconnected-tunnel information was superseded by a successful lock-state query with passcodeRequired=false. No taps, entries, real Shortcuts execution, DEBUG flags, uninstall or device screenshots were used. This proves install/process launch only. Device identifiers and real ledger details are excluded. Optional owner check: run Record expense once from Shortcuts only for an expense the owner intends to record.

## Verification commands

All follow-up test commands ran from the repository root in this exact order, with their completed exit codes above:

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-15 -resultBundlePath /tmp/wealthy-c2b2-r6-followup-safe15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testSafeLineAndAIInformationEvidence test > /tmp/wealthy-c2b2-r6-followup-safe15.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b2-r6-17 -resultBundlePath /tmp/wealthy-c2b2-r6-followup-safe17.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testSafeLineAndAIInformationEvidence test > /tmp/wealthy-c2b2-r6-followup-safe17.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-15 -resultBundlePath /tmp/wealthy-c2b2-r6-followup-home15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testHomeDarkAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll test > /tmp/wealthy-c2b2-r6-followup-home15.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b2-r6-17 -resultBundlePath /tmp/wealthy-c2b2-r6-followup-home17.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testHomeAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testHomeDarkAccessibilityAudit -only-testing:WealthyUITests/Cycle2aUITests/testHorizontalTabSwipeAndVerticalScroll test > /tmp/wealthy-c2b2-r6-followup-home17.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-15 -resultBundlePath /tmp/wealthy-c2b2-r6-followup-full15.xcresult -parallel-testing-enabled NO test > /tmp/wealthy-c2b2-r6-followup-full15.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b2-r6-17 -resultBundlePath /tmp/wealthy-c2b2-r6-followup-full17.xcresult -parallel-testing-enabled NO test > /tmp/wealthy-c2b2-r6-followup-full17.log 2>&1
```

Baseline comparison exact commands (cwd as shown; each exit 65):

```sh
# cwd: /tmp/wealthy-c2b2-r6-baseline
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-compare-base15 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-1-baseline15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testNoSpendDayFromEmptyLedger test
```

```sh
# cwd: repository root
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-15 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-1-current15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testNoSpendDayFromEmptyLedger test
```

```sh
# cwd: /tmp/wealthy-c2b2-r6-baseline
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-compare-base15 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-2-baseline15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testPersistedOnboardingRelaunch test
```

```sh
# cwd: repository root
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-15 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-2-current15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testPersistedOnboardingRelaunch test
```

```sh
# cwd: /tmp/wealthy-c2b2-r6-baseline
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-compare-base15 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-3-baseline15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testOnboardingEntryTaxNoSpendTarget test
```

```sh
# cwd: repository root
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-15 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-3-current15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testOnboardingEntryTaxNoSpendTarget test
```

```sh
# cwd: /tmp/wealthy-c2b2-r6-baseline
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-compare-base15 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-4-baseline15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testQuickEntryWithoutAIFromOnboarding test
```

```sh
# cwd: repository root
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=870430A8-E557-4CED-8A8E-079801D804B9' -derivedDataPath /tmp/wealthy-c2b2-r6-15 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-4-current15.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testQuickEntryWithoutAIFromOnboarding test
```

```sh
# cwd: /tmp/wealthy-c2b2-r6-baseline
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b2-r6-compare-base17 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-5-baseline17.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testAdditionalSetupMatrix test
```

```sh
# cwd: repository root
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b2-r6-17 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-5-current17.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testAdditionalSetupMatrix test
```

```sh
# cwd: /tmp/wealthy-c2b2-r6-baseline
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b2-r6-compare-base17 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-6-baseline17.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testChildEnvelopeAndLicenseFlow test
```

```sh
# cwd: repository root
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -destination 'platform=iOS Simulator,id=DEA8D0DF-8BA2-4F70-B19C-BACAC400EAE0' -derivedDataPath /tmp/wealthy-c2b2-r6-17 -resultBundlePath /tmp/wealthy-c2b2-r6-compare-6-current17.xcresult -parallel-testing-enabled NO -only-testing:WealthyUITests/Cycle2aUITests/testChildEnvelopeAndLicenseFlow test
```

Required checks and builds, all exit 0:

```sh
sh Verification/verify_core.sh > /tmp/wealthy-c2b2-r6-followup-core.log 2>&1
```

```sh
PYTHONPATH="$HOME/Library/Python/3.14/lib/python/site-packages" python3 Verification/verify_shell.py > /tmp/wealthy-c2b2-r6-followup-shell.log 2>&1
```

```sh
sh Verification/verify_localization.sh > /tmp/wealthy-c2b2-r6-followup-localization.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/wealthy-c2b2-r6-release-sim build > /tmp/wealthy-c2b2-r6-followup-release-sim.log 2>&1
```

```sh
xcodebuild -project Wealthy/Wealthy.xcodeproj -scheme WealthyUITests -configuration Release -destination generic/platform=iOS -derivedDataPath /tmp/wealthy-c2b2-r6-release-device -allowProvisioningUpdates build > /tmp/wealthy-c2b2-r6-followup-release-device.log 2>&1
```

```sh
codesign --verify --deep --strict --verbose=2 /tmp/wealthy-c2b2-r6-release-device/Build/Products/Release-iphoneos/Wealthy.app > /tmp/wealthy-c2b2-r6-followup-signature.log 2>&1
```


```sh
git diff --check
xcrun xcresulttool get test-results summary --path /tmp/wealthy-c2b2-r6-followup-full15.xcresult
xcrun xcresulttool get test-results summary --path /tmp/wealthy-c2b2-r6-followup-full17.xcresult
```

Metadata inspection (exit 0; relevant output above):

```python
import json, subprocess
from pathlib import Path
app = Path('/tmp/wealthy-c2b2-r6-release-device/Build/Products/Release-iphoneos/Wealthy.app')
data = json.loads((app/'Metadata.appintents/extract.actionsdata').read_text())
for name, action in sorted(data['actions'].items()):
    print(name, action.get('openAppWhenRun'), [(p.get('name'), p.get('isOptional')) for p in action.get('parameters', [])])
print(data['autoShortcuts'])
for language in ['en', 'ja', 'es', 'ko']:
    subprocess.run(['plutil', '-convert', 'json', '-o', '-', str(app/(language+'.lproj/AppShortcuts.strings'))], check=True)
```

Physical commands used the paired device identifier privately (redacted here); exact private logs/results remain under /tmp/wealthy-c2b2-r6-device-*:

```sh
xcrun devicectl device install app --device <paired-device> /tmp/wealthy-c2b2-r6-release-device/Build/Products/Release-iphoneos/Wealthy.app --json-output /tmp/wealthy-c2b2-r6-device-install.json
xcrun devicectl device process launch --device <paired-device> <built-bundle-identifier> --json-output /tmp/wealthy-c2b2-r6-device-launch.json
```

## Not done / unverified

- FAIL, unresolved: audit issues and full-suite failures listed above. The six individually compared cases are baseline-reproducible; any additional failed case without a baseline pair remains unclassified. No pass is inferred from a previous day or other simulator.
- Designer decision needed: how the onboarding test fixture should handle newly eligible result sheets, and how to resolve high-ratio/nil-node audit findings and no-spend clipping without new exclusions or other-screen changes. Options for the designer are an explicit result-sheet acknowledgment in the onboarding test setup, a deterministic fixture clock, or a product presentation-policy change. None was implemented; the current scope does not authorize a weekly-result policy change. Further Home-only layout/platform diagnosis is needed for the audit findings; no exclusion is proposed as a pass.
- NOT_RUN: physical VoiceOver listening, actual three-second entry timing, 10,000-entry Home <=2-second measurement, and real Shortcuts/Spotlight/Action Button/Control Center execution, to avoid writing an unintended expense to the owner's ledger. Simulator frame checks are not physical performance evidence.
- NOT_RUN: iOS 26 runtime validation; installed simulators use iOS 27.0. Deployment target remains unchanged.
- Intentionally not done: other-screen changes, generic tap-helper fixes, result-sheet dismissal/test clock changes, audit exemptions, dependencies, app extensions/capabilities, real-data access, uninstall, Git staging/commit/push/merge, or a next cycle.
- Final 17 Pro xcresult runtime warning: the first iteration did not measure `com.apple.dt.XCTMetric_ApplicationLaunch-ApplicationFirstFramePresentationResponsive.duration`. This limits the launch-metric evidence; no missing metric is reported as a measured pass. The completed test counts remain 68 PASS/8 FAIL on each simulator.
- Build logs contained no warning lines in the final Release builds. During the final 17 Pro run, testFocusedSelectionAndEditorSwipeIsolation repeatedly logged `App animations complete notification not received` while waiting for entryNote/gesture actions; it subsequently passed in 559.009 seconds. This is simulator behavior, not a physical performance result. Simulator launches also emit IDELaunchParametersSnapshot diagnostics (`debugger version lookup failed ... noURL` / `no debugger version`) and continue; no causal link to a failure was established. Runtime query errors and accessibility warnings are retained as failures; minimal reproduction is each individual comparison command or the Safe-line command above.
