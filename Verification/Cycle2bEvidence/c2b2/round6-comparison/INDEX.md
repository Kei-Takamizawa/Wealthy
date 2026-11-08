# Round 6 comparison with c937c63

Twelve individual xcodebuild invocations, sequential, on iOS 27.0 simulators on November 9 JST. Each case ran on the same simulator first from a read-only archive of c937c637dfc6592cba0bad83528176dfdb9cbf14, then from the current tree. No source was changed between these runs. All twelve commands exited 65.

| Case / device | c937c63 | Current |
| --- | --- | --- |
| testNoSpendDayFromEmptyLedger / iPhone 15 Pro | [FAIL, 76.732 seconds](1-baseline15.jpg) | [FAIL, 72.875 seconds](1-current15.jpg) |
| testPersistedOnboardingRelaunch / iPhone 15 Pro | [FAIL, 87.154 seconds](2-baseline15.jpg) | [FAIL, 87.724 seconds](2-current15.jpg) |
| testOnboardingEntryTaxNoSpendTarget / iPhone 15 Pro | [FAIL, 39.535 seconds](3-baseline15.jpg) | [FAIL, 39.542 seconds](3-current15.jpg) |
| testQuickEntryWithoutAIFromOnboarding / iPhone 15 Pro | [FAIL, 32.174 seconds](4-baseline15.jpg) | [FAIL, 31.972 seconds](4-current15.jpg) |
| testAdditionalSetupMatrix / iPhone 17 Pro | [FAIL, 247.543 seconds](5-baseline17.jpg) | [FAIL, 245.057 seconds](5-current17.jpg) |
| testChildEnvelopeAndLicenseFlow / iPhone 17 Pro | [FAIL, 38.902 seconds](6-baseline17.jpg) | [FAIL, 38.990 seconds](6-current17.jpg) |

Images use the first automatic failure PNG or the last captured empty-Home setup PNG when available; for the two invocations without a PNG, they use a frame one second before the end of the recorded test video, exported from the completed xcresult; synthetic data only. JPEG quality 80, long edge <=2,000 px, below 1 MB. results.json records exact commands, working directories, failure messages, any resultSheet frame supplied by XCTest, and attachment provenance.

## Finding

All six cases fail on both sources with the same missing-control/query errors. Every exported app hierarchy contains the previous-week `resultSheet`: (0,59,393,793) on 15 Pro or (0,62,402,812) on 17 Pro. The images show the same week, November 2–8, over Home in both sources. This reproduces without the new no-spend font/lineLimit modifiers.

The unchanged chain is `LedgerQueries.recentlyEndedResults` in `WealthyCore/Sources/WealthyCore/IslandQueries.swift:93` (closed-period results within three days), `LedgerSession.reload` in `Wealthy/Wealthy/LedgerSession.swift:271`, and the queue/presentation in `Wealthy/Wealthy/LedgerRoot.swift:49–63`. For these Monday-start fixtures, on Monday November 9 the just-ended week is eligible; on Sunday November 8, the previous week ended November 1 and was outside that three-day window. The existing onboarding test setup assumes uncovered Home, while this modal intercepts its swipes/taps. The generic tap helper additionally queries a nonexistent keyboard frame in its failure-message expression.

No result-presentation, onboarding, Core, generic tap-helper or other-screen code was changed. The no-spend modifiers were retained because these six failures also reproduce without them; the addEntry contrast correction was retained. Clipping/contrast audit issues remain separate acceptance failures, not exemptions.
