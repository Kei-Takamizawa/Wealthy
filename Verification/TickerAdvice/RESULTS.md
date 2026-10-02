# Money-tip generation — 2026-10-02

The app's actual `LocalLLMService.generateAdvice` and `FinancialDataSummary.moneyTipContext` were compiled into a native Mac CLI. Inputs were synthetic empty, deficit, and surplus records, each in English and Japanese. No app database was read.

The model generates a short playful opening from a situation-specific creative theme. A deterministic action is appended from the recorded month and asset balances. This keeps the action factual even if the model interprets a total incorrectly. Guardrail failures, unsupported language, and invalid opening length or content use a local, situation-appropriate fallback. The framework's default guardrails remain enabled.

| Check | Final result |
| --- | ---: |
| Completed captions | 6/6 |
| Correct requested language on manual review | 6/6 |
| Below 30 English words / 70 Japanese characters | 6/6 |
| Actual model opening, without fallback | 6/6 |

The earlier unrestricted full-tip prompt produced an incorrect-language answer and a guardrail rejection. A later attempt to generate an opening from raw financial totals triggered guardrails in all six cases. The final implementation sends only a creative theme to the model and appends the record-based action locally. Those failed runs are not counted as successful model generations.

Examples from the final native run:

| Situation | Caption |
| --- | --- |
| empty (en) | Wallet yawns, pages trembling with quiet hope. No transactions recorded this month. Start by recording one. |
| spending_exceeds_income (en) | Wallet sighs, clutching coins for a breath. Recorded spending exceeds income. Review one optional expense. |
| surplus (en) | Wallet bows, shiny and slightly nervous. Records show a surplus. Set a little aside if affordable. |
| empty (ja) | 小銭が今日も笑ってる。今月の取引は未記録。まず一件記録しましょう。 |
| spending_exceeds_income (ja) | ちょっと一息、コインでごめんね。記録上は支出超過。任意の出費を一つ見直しましょう。 |
| surplus (ja) | ぴかっとお辞儀、小さなお財布。記録上は黒字。余裕があれば少し取り分けましょう。 |

These six development cases do not establish future generation reliability or humor quality. Apple model versions and output may vary. The fixed policy is separately checked by 204 assertions across 13 fixtures, including income not recorded, equal income/spending, and negative recorded asset balances. See [verification commands](../README.md).

The actual SwiftUI ticker component was also rendered on macOS at a fixed elapsed time. A separate `NSHostingView` runtime check forced the animation path, changed a long sentence to a short one, and observed exactly one completion callback for the replacement at 7.85 seconds; the old task was cancelled. The Mac's system Reduce Motion was enabled, so a test-only override was used for that animation check. Neither check is an iPhone screenshot or end-to-end device validation.
