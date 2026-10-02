# Native model verification

`NativeModelChecks.swift` is a deterministic, tiny Swift harness using the actual app implementations. It does not download model weights or execute Hugging Face Python code.

Implemented checks:

- Two-group RMS normalization against an independent Double scalar formula: FP32 tolerance 2e-6; FP16-cast tolerance 2e-3.
- K2 native configuration decoding, 21 named weight tensors, strict weight updates, and full-sequence versus incremental KV-cache output (maximum absolute tolerance 1e-5).
- Bonsai native configuration decoding, 25 named tensors including Q/K norms, YaRN factor 4 / original positions 16384, and full/cache consistency (tolerance 1e-5).

## Evidence on 2026-10-02

The harness and both app model sources passed Swift 5 type checking with MainActor default isolation and warnings treated as errors. This is **not numerical execution**.

Numerical execution was not performed: permission-authorized `xcrun simctl list devices booted` and `xcrun simctl list devices available` both returned only `== Devices ==`, with no available or booted Simulator. No runtime was downloaded. The Simulator executable link/run script has not yet been exercised in this environment.

To run when an existing Simulator is booted:

```sh
# プロジェクトルートから、起動済みSimulator UUIDを明示して小さいCPU数値検証を実行します。
zsh Verification/AIModels/run_native_model_checks.sh EXISTING_BOOTED_SIMULATOR_UUID
```

Optional arguments 2 and 3 select an existing Simulator Products directory and dependency checkouts directory. Defaults match the current verification checkout. The script deliberately does not create or download a Simulator runtime.

## Reference comparison

Read-only source: `mlx-community/K2-Horizon-3.7B-4bit` revision `3b453d026bd4f433c0bc9a532706f87488269e4d`, preserved for investigation as `/private/tmp/wealthy-ai-research/k2_reference.py`.

- Grouped normalization: FP32 cast → reshape into two groups → per-group mean square and reciprocal square root → original shape → full-width learned weight → original dtype. Swift uses explicit arithmetic where Python uses a fused RMS kernel; numerical rounding equivalence remains unverified.
- Dense attention: q/k/v/o projections, GQA query/KV ratio, head dimension, rotate-half RoPE (`traditional=false`), cache position offsets, cache updates and causal masking follow the reference.
- Dense MLP: `down_proj(silu(gate_proj(x)) * up_proj(x))`; two pre-norm residual additions.
- Matching names: `model.embed_tokens`, `model.layers.N.self_attn.{q,k,v,o}_proj`, `model.layers.N.mlp.{gate,up,down}_proj`, `model.layers.N.{input_layernorm,post_attention_layernorm}`, `model.norm`, `lm_head`.
- K2 3.7B-specific restrictions reject MoE, MoVA, attention gating, Q/K norm, partial RoPE and sliding attention rather than silently accepting unimplemented configurations.

Real pretrained-weight numerical agreement, iPhone GPU execution, memory peaks, latency, response quality and long-context stability remain unverified even after the tiny harness passes.
