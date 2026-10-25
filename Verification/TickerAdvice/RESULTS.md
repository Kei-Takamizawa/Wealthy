# Money-tip generation — October 2, 2026

The app's actual `LocalLLMService.generateAdvice` and `FinancialDataSummary.moneyTipContext` were compiled into a native Mac CLI. Inputs were synthetic empty, deficit, and surplus records in the former display-language set (superseded; current UI languages are en, ja, es, ko). No app database or bank account was read.

The model generates only a short playful opening from a situation-specific creative theme. The app appends a deterministic action derived from the recorded month and asset balances. Guardrail failures, unsupported language, and invalid opening language, length or content use a localized fallback. Apple's default guardrails remain enabled.

## Final multilingual run

| Check | Observed result |
| --- | ---: |
| Completed captions, including fallback | 33/33 |
| Automatic language identification matched the requested language | 33/33 |
| Within the app's whole-caption length limits | 33/33 |
| Actual model openings accepted | 15/21 supported-language calls |
| Local fallback captions | 18/33 |
| Total service-call time on this Mac | 14.17 seconds |

Twelve fallbacks came from four unsupported locales, three calls each. Six came from openings that failed language, length or content validation. They are not counted as successful model generations.

| Display language | Runtime model support on this Mac | Accepted AI openings / 3 | Fallbacks / 3 |
| --- | --- | ---: | ---: |
| English | Yes | 3 | 0 |
| Japanese | Yes | 1 | 2 |
| Spanish | Yes | 2 | 1 |
| Korean | Yes | 3 | 0 |

Support is checked with `SystemLanguageModel.supportsLocale` at runtime. This table describes the tested Mac's installed model; it is not a hardcoded support list or a promise about another OS/model version. The table now shows only the four supported UI languages; the historical aggregate counts above include the former language set and were not remeasured in Cycle 2a.5.

The length limits are below 70 characters for Japanese, below 100 for Korean, and below 30 whitespace-separated words for other languages. Language recognition is an automated check, not native-speaker review of fluency, translation or humor. These 33 development cases do not establish future model reliability or iPhone performance.

Example surplus captions from this run:

- English, AI opening: “Wallet bows, shiny and slightly nervous. Records show a surplus. Set a little aside if affordable.”
- Japanese, fallback: “財布がちょっと得意げですね。記録上は黒字。余裕があれば少し取り分けましょう。”

The fixed context, factual actions and fallback wording are separately checked by **1,166 assertions across 13 fixtures and the former language set**, including income not recorded, equal income/spending, and negative recorded asset balances. See [reproduction commands](../README.md).

## Earlier development observations

An earlier English/Japanese run accepted 6/6 model openings. Earlier unrestricted prompts also produced a wrong-language response and guardrail rejections. Those results explain the narrower creative prompt and local factual action; they are not the final multilingual result.

The legacy SwiftUI ticker was rendered on macOS in the former language set, alongside system-rendered text references. It uses system-shaped glyphs rather than separate character views. The projection remains transparent, with gradual scale, edge blur and fade; Reduce Motion uses stationary text. Component rendering is not an iPhone screenshot, native-speaker review or end-to-end device validation. Current supported UI languages are exactly en, ja, es and ko.

A separate native `NSHostingView` check forced the animation path despite the Mac's enabled Reduce Motion setting. Replacing a long sentence with a short one cancelled the old task and produced exactly one completion callback after 4.39 seconds. This checks component timing, not physical-device interaction.
