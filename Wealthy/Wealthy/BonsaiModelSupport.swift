// Bonsai Q2を独自typeで読み、通常Qwen3の登録を変更せずYaRNを適用します。
// 構成: https://huggingface.co/inferencerlabs/Bonsai-8B-MLX-Q2/blob/2fa829d190a9d2a0c3d8850ea2d62ebfd06019f4/config.json
// Q2配布のquantization_configはダウンロード処理でquantizationへコピーしてから読み込みます。
// 2-bit変換版です。公式1-bitと同じディスク容量・速度であるとは主張しません。
// JSONを安全に読み込み、YaRN振幅の対数を計算する標準機能を読み込みます。
import Foundation
// ネイティブ言語モデルを登録する共通登録簿を読み込みます。
import MLXLLM
// LanguageModel型をcreatorの返却値として使用する宣言元のモジュールを読み込みます。
import MLXLMCommon

// K2とBonsaiのRoPE設定を型付きで読み取ります。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated struct WealthyRopeConfiguration: Decodable {
    // defaultまたはyarnなどの回転方式を保持します。
    let ropeType: String?
    // 入れ子の設定にあるRoPE周波数基数を保持します。
    let theta: Float?
    // YaRNが位置範囲を拡張する倍率を保持します。
    let factor: Float?
    // YaRNが基準とする学習時の位置範囲を保持します。
    let originalMaxPositions: Int?
    // YaRN周波数の高速側の切替回転数を保持します。
    let betaFast: Float
    // YaRN周波数の低速側の切替回転数を保持します。
    let betaSlow: Float
    // YaRNの振幅倍率の分子側係数を保持します。
    let mscale: Float
    // YaRNの振幅倍率の分母側係数を保持します。
    let mscaleAllDim: Float
    // 明示された注意振幅があれば、一般式より優先します。
    let attentionFactor: Float?
    // 補正範囲を整数に丸めるかを保持します。
    let truncate: Bool
    // JSON中のRoPE設定を読み込みます。
    init(from decoder: Decoder) throws {
        // 文字列キーで値を取り出す容器を用意します。
        let values = try decoder.container(keyedBy: WealthyJSONKey.self)
        // 新旧両方の方式名キーを扱い、新しいrope_typeを優先します。
        self.ropeType = try values.decodeIfPresent(String.self, forKey: WealthyJSONKey("rope_type")) ?? values.decodeIfPresent(String.self, forKey: WealthyJSONKey("type"))
        // 入れ子の周波数基数を省略可能な値として読みます。
        self.theta = try values.decodeIfPresent(Float.self, forKey: WealthyJSONKey("rope_theta"))
        // YaRNの拡張倍率を読みます。
        self.factor = try values.decodeIfPresent(Float.self, forKey: WealthyJSONKey("factor"))
        // YaRNの元の位置範囲を読みます。
        self.originalMaxPositions = try values.decodeIfPresent(Int.self, forKey: WealthyJSONKey("original_max_position_embeddings"))
        // 指定がない高速側回転数にはTransformersと同じ32を使います。
        self.betaFast = try values.read(Float.self, "beta_fast", default: 32)
        // 指定がない低速側回転数にはTransformersと同じ1を使います。
        self.betaSlow = try values.read(Float.self, "beta_slow", default: 1)
        // 指定がない分子側振幅係数には1を使います。
        self.mscale = try values.read(Float.self, "mscale", default: 1)
        // 指定がない分母側振幅係数には0を使います。
        self.mscaleAllDim = try values.read(Float.self, "mscale_all_dim", default: 0)
        // 明示された注意振幅を読みます。
        self.attentionFactor = try values.decodeIfPresent(Float.self, forKey: WealthyJSONKey("attention_factor"))
        // 既存YarnRoPEと同じ整数切替を既定にします。
        self.truncate = try values.read(Bool.self, "truncate", default: true)
    // RoPE設定の読み込みを終了します。
    }
    // 明示された注意振幅を既存YarnRoPEの係数へ正確に変換します。
    func validatedYarnMscale(factor: Float) throws -> Float {
        // 既存YaRNが安全に扱える数値と丸め方式か確認します。
        guard factor >= 1, factor.isFinite, betaFast > 0, betaSlow > 0, betaFast.isFinite, betaSlow.isFinite, mscale.isFinite, mscaleAllDim.isFinite, truncate else {
            // 不正な設定のまま位置回転を生成することを防ぎます。
            throw WealthyModelConfigurationError(detail: "BonsaiのYaRN倍率・周波数・丸め設定には未対応の値が含まれています。")
        // YaRNの設定検査を終了します。
        }
        // 明示的な振幅がない場合は通常のmscale係数をそのまま使います。
        guard let attentionFactor else { return mscale }
        // 明示的な注意振幅が有限の正数か確認します。
        guard attentionFactor > 0, attentionFactor.isFinite else {
            // 不正な注意振幅では停止します。
            throw WealthyModelConfigurationError(detail: "Bonsaiのattention_factorは有限の正数が必要です。")
        // 注意振幅の数値検査を終了します。
        }
        // 拡張しない場合は既存YaRNが振幅を必ず1にする点を確認します。
        if factor == 1 {
            // 表現できない振幅を黙って無視せず拒否します。
            guard attentionFactor == 1 else { throw WealthyModelConfigurationError(detail: "倍率1のYaRNで振幅1以外は未対応です。") }
            // 振幅1であれば変更前の係数を返します。
            return mscale
        // 拡張しない場合の処理を終了します。
        }
        // 既存YaRNの振幅比の分母を計算します。
        let denominator = 1 + 0.1 * mscaleAllDim * log(factor)
        // ゼロ除算や負の振幅になる設定を拒否します。
        guard denominator > 0 else { throw WealthyModelConfigurationError(detail: "YaRN振幅の分母が正数ではありません。") }
        // 既存YaRNの振幅比が指定attention_factorに一致するmscaleを逆算します。
        return (attentionFactor * denominator - 1) / (0.1 * log(factor))
    // YaRN係数の検証と変換を終了します。
    }
// RoPE設定型の定義を終了します。
}

// Qwen3構造のBonsai設定をYaRN対応の共通decoderへ変換します。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
private nonisolated struct WealthyBonsaiConfiguration: Decodable {
    // 読み込んだ設定を共有のnative decoder用に保持します。
    let dense: WealthyDenseConfiguration
    // BonsaiのローカルJSONを読み込みます。
    init(from decoder: Decoder) throws {
        // 設定値を文字列キーで取得する容器を用意します。
        let values = try decoder.container(keyedBy: WealthyJSONKey.self)
        // 本モデルにないattention biasの指定を読みます。
        let bias = try values.read(Bool.self, "attention_bias", default: false)
        // 本モデルにないsliding attentionの指定を読みます。
        let sliding = try values.read(Bool.self, "use_sliding_window", default: false)
        // 別構成を誤った計算方式で処理することを防ぎます。
        guard !bias, !sliding else { throw WealthyModelConfigurationError(detail: "Bonsai adapterはbiasなし・full attention構成専用です。") }
        // YaRN設定が格納されるrope_scalingを読みます。
        let rope = try values.decodeIfPresent(WealthyRopeConfiguration.self, forKey: WealthyJSONKey("rope_scaling"))
        // 未実装のlinearやdynamic RoPEを黙って通常回転へ置換しません。
        guard rope?.ropeType == nil || rope?.ropeType == "default" || rope?.ropeType == "yarn" else {
            // 未対応の回転方式が指定された場合は停止します。
            throw WealthyModelConfigurationError(detail: "Bonsai adapterはdefaultまたはYaRN RoPEに対応しています。")
        // RoPE方式の検査を終了します。
        }
        // YaRNの構成かどうかを明示的に判定します。
        let useYarn = rope?.ropeType == "yarn"
        // 通常RoPEならnil、YaRNなら検証した倍率を保持します。
        let factor: Float?
        // YaRNの基準位置範囲を保持します。
        let originalPositions: Int
        // YaRNへ渡す検証済みの注意振幅係数を保持します。
        let mscale: Float
        // YaRN構成の場合に必要な拡張値を読みます。
        if useYarn, let rope {
            // 倍率と元の位置範囲を必須として確認します。
            guard let explicitFactor = rope.factor, let original = rope.originalMaxPositions, original > 0 else {
                // 基準範囲を推測して誤った回転を作ることを防ぎます。
                throw WealthyModelConfigurationError(detail: "BonsaiのYaRNにはfactorとoriginal_max_position_embeddingsが必要です。")
            // YaRN必須項目の検査を終了します。
            }
            // YaRN拡張率を保存します。
            factor = explicitFactor
            // 元の位置範囲を保存します。
            originalPositions = original
            // 振幅指定を検証し、既存YaRN用係数へ変換します。
            mscale = try rope.validatedYarnMscale(factor: explicitFactor)
        // 通常RoPEで必要ないYaRN値には無効な既定値を置きます。
        } else {
            // 通常RoPEの利用を共通decoderへ伝えます。
            factor = nil
            // YaRN基準位置は使用しません。
            originalPositions = 0
            // 通常RoPEで使用しない振幅係数を既定にします。
            mscale = 1
        // YaRN値の設定を終了します。
        }
        // Qwen3の寸法・Q/K正規化と、検証済みYaRN設定をすべて共通decoderへ渡します。
        self.dense = try WealthyDenseConfiguration(hiddenSize: values.required(Int.self, "hidden_size"), hiddenLayers: values.required(Int.self, "num_hidden_layers"), intermediateSize: values.required(Int.self, "intermediate_size"), attentionHeads: values.required(Int.self, "num_attention_heads"), kvHeads: values.required(Int.self, "num_key_value_heads"), headDim: values.required(Int.self, "head_dim"), vocabularySize: values.required(Int.self, "vocab_size"), rmsNormEps: values.read(Float.self, "rms_norm_eps", default: 0.000001), normGroups: 1, queryKeyNorm: true, ropeTheta: values.read(Float.self, "rope_theta", default: 1000000), tieWordEmbeddings: values.read(Bool.self, "tie_word_embeddings", default: false), yarnFactor: factor, originalMaxPositions: originalPositions, maxPositions: values.read(Int.self, "max_position_embeddings", default: 65536), yarnBetaFast: rope?.betaFast ?? 32, yarnBetaSlow: rope?.betaSlow ?? 1, yarnMscale: mscale, yarnMscaleAllDim: rope?.mscaleAllDim ?? 0)
    // Bonsai設定の読み込みを終了します。
    }
// Bonsai adapter設定の定義を終了します。
}

// 標準Qwen3登録を上書きせずBonsai専用creatorを追加します。
func registerWealthyBonsaiModelType() {
    // ダウンロード後に書き換えるBonsai独自model_typeへ対応します。
    LLMTypeRegistry.shared.registerModelType("wealthy_bonsai_qwen3") { url in
        // ローカルJSONのみ読み、HFのPythonコードは実行しません。
        let args = try JSONDecoder().decode(WealthyBonsaiConfiguration.self, from: Data(contentsOf: url))
        // YaRNを含む設定からnative MLX言語モデルを作ります。
        return try WealthyDenseLanguageModel(args.dense)
    // Bonsai専用creatorの登録を終了します。
    }
// Bonsai登録関数の定義を終了します。
}
