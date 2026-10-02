# Model management

The default provider is Apple Foundation Models. Unknown or retired model IDs migrate to this default; valid selections in the current catalog are preserved. Changing the display language does not change the model selection.

## Download integrity

Each optional model is pinned to a 40-character revision. The downloader checks file sizes and published LFS SHA-256 hashes, then marks a model as installed only after all required files have arrived.

| Model | Revision | Download bytes |
| --- | --- | ---: |
| Bonsai 8B | `2fa829d190a9d2a0c3d8850ea2d62ebfd06019f4` | 2,315,156,449 |
| MiniCPM5-1B (Reasoning) | `36447e84d28c57588a6e91907675e44afe54ab00` | 617,970,893 |
| MiniCPM5-2B | `86ad5182c5a8532a4681ab972011d34c3b89477a` | 1,426,009,037 |
| K2 Horizon 3.7B | `3b453d026bd4f433c0bc9a532706f87488269e4d` | 4,156,855,917 |

Required free storage includes the download size plus the larger of 5% or 64 MiB. Transfers run while the app is active; background completion after app termination is not implemented. Retrying starts a new download. Known temporary download directories left by a stopped app are cleaned up on the next launch.

Swipe left on an installed model to delete it. Deleting the selected model returns the selection to Apple. Switching and deletion are disabled while a model is loading or generating a response.

## Memory and inference

Optional models are checked against total device RAM, Metal availability, and current process memory headroom. These checks are estimates until the installed model loads and generates one token successfully. That confirmation lasts for the current app session and does not certify response quality or sustained performance.

Memory estimates assume at most 2,048 input tokens. Normal models generate up to 1,024 output tokens; MiniCPM5-1B Reasoning and K2 generate up to 2,048. K2 uses `reasoning_effort=low`. An unfinished reasoning section produces an error rather than being stored as the final answer. Generation is blocked when the memory guard fails.

Bonsai uses the independently published MLX 2-bit conversion, not the official 1-bit kernels. K2 uses the Swift model implementation in this repository, including its mixed 4/8-bit weights. The app does not execute Python code from model repositories.

Real-device inference with the four pretrained models, memory peaks, latency, numerical agreement, and long-context stability remain unverified. See [native model verification](NativeModelVerification.md) for the distinction between type checking and numerical execution.
