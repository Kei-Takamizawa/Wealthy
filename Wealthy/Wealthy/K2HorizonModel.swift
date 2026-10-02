// IFMのdense 3.7B用。MoE/MoVAを含む別サイズは読み込み時に拒否します。
// 参照: https://huggingface.co/mlx-community/K2-Horizon-3.7B-4bit/blob/3b453d026bd4f433c0bc9a532706f87488269e4d/k2_horizon.py
// 公式構成: IFM/K2-Horizon-3.7B @ c7d0261442c13212486091422de52f4ce381a7ca。
// 大きな重みを用いた公式実装との数値一致・実機速度は未検証です。
// JSON設定の読み込みと、説明付きエラーに必要な標準機能を読み込みます。
import Foundation
// GPUで扱う配列と、平均・逆平方根などの演算を読み込みます。
import MLX
// 言語モデルの共通規約、モデル登録簿、YaRN位置埋め込みを読み込みます。
import MLXLLM
// 推論キャッシュと、因果関係を守る注意マスクの機能を読み込みます。
import MLXLMCommon
// 学習済み重みを保持する層、埋め込み、線形変換を読み込みます。
import MLXNN

// 未対応構成を、誤った計算に進む前に説明付きで停止するエラーです。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated struct WealthyModelConfigurationError: LocalizedError {
    // 呼び出し元が画面へ表示できる具体的な停止理由を保持します。
    let detail: String
    // LocalizedErrorの説明として停止理由を返します。
    var errorDescription: String? { detail }
// 設定エラー型の定義を終了します。
}

// K2とBonsaiが共有するdense decoderの寸法と計算設定です。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated struct WealthyDenseConfiguration {
    // 各トークンの内部ベクトルが持つ要素数です。
    let hiddenSize: Int
    // 順番に通過するTransformer層の数です。
    let hiddenLayers: Int
    // MLP内部で一時的に広げるベクトルの要素数です。
    let intermediateSize: Int
    // 問い合わせ側の注意ヘッド数です。
    let attentionHeads: Int
    // キャッシュするキーと値のヘッド数です。
    let kvHeads: Int
    // 1つの注意ヘッド内の要素数です。
    let headDim: Int
    // 埋め込みと最終出力が扱うトークンの種類数です。
    let vocabularySize: Int
    // 正規化時のゼロ除算を防ぐ小さい正数です。
    let rmsNormEps: Float
    // 入力を独立に正規化するグループ数です。
    let normGroups: Int
    // QとKをヘッドごとに追加正規化するかを示します。
    let queryKeyNorm: Bool
    // RoPEの位置回転に使う周波数の基数です。
    let ropeTheta: Float
    // 入力埋め込みと出力重みを共有するかを示します。
    let tieWordEmbeddings: Bool
    // YaRNを使う場合の拡張率で、nilなら通常RoPEです。
    let yarnFactor: Float?
    // YaRNが学習時の位置範囲として参照するトークン数です。
    let originalMaxPositions: Int
    // モデル設定が宣言する最大の位置範囲です。
    let maxPositions: Int
    // YaRNが高周波数側へ切り替える回転数です。
    let yarnBetaFast: Float
    // YaRNが低周波数側へ切り替える回転数です。
    let yarnBetaSlow: Float
    // YaRNの注意振幅を調整する係数です。
    let yarnMscale: Float
    // YaRN振幅の分母側へ適用する調整係数です。
    let yarnMscaleAllDim: Float

    // 不正な寸法をGPUへ渡す前に検出します。
    func validate() throws {
        // 配列の寸法になる値がすべて正か確認します。
        guard hiddenSize > 0, hiddenLayers > 0, intermediateSize > 0, vocabularySize > 0, attentionHeads > 0, kvHeads > 0, headDim > 0, normGroups > 0 else {
            // 無効な寸法では配列を作らず停止します。
            throw WealthyModelConfigurationError(detail: "モデルの層数・ベクトル寸法は正数が必要です。")
        // 正数の検査を終了します。
        }
        // グループ分割・GQA共有・RoPE回転に必要な条件を確認します。
        guard hiddenSize % normGroups == 0, attentionHeads % kvHeads == 0, headDim % 2 == 0, rmsNormEps > 0, rmsNormEps.isFinite, ropeTheta > 1, ropeTheta.isFinite else {
            // 間違った分割や回転を計算する前に停止します。
            throw WealthyModelConfigurationError(detail: "モデルの正規化・注意ヘッド・RoPE設定が不正です。")
        // 寸法間の関係の検査を終了します。
        }
    // 共通設定の検証を終了します。
    }
// 共通decoder設定の定義を終了します。
}

// 各グループをFP32で独立正規化してから学習済み重みを掛けます。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated final class WealthyGroupedRMSNorm: Module, UnaryLayer {
    // 名前をweightにして、配布ファイルの正規化重みと対応させます。
    let weight: MLXArray
    // 最後の軸を分割する数を保持します。
    private let groups: Int
    // 逆平方根の安定化に加える小さい値を保持します。
    private let eps: Float
    // 正規化層を作るための寸法とグループ数を受け取ります。
    init(dimensions: Int, groups: Int, eps: Float) {
        // loaderが上書きするまで、要素を変えない1の重みを置きます。
        self.weight = MLXArray.ones([dimensions])
        // 指定されたグループ数を保存します。
        self.groups = groups
        // 指定された安定化係数を保存します。
        self.eps = eps
        // Moduleの重み管理を初期化します。
        super.init()
    // グループ正規化層の初期化を終了します。
    }
    // 入力ベクトルを正規化した結果を返します。
    func callAsFunction(_ x: MLXArray) -> MLXArray {
        // 出力を入力と同じ形へ戻すため、元の形を保存します。
        var shape = x.shape
        // 分割前の最後のベクトル軸を取り除きます。
        shape.removeLast()
        // 新しいグループ軸を追加します。
        shape.append(groups)
        // 各グループが持つ要素数の軸を追加します。
        shape.append(x.dim(-1) / groups)
        // 丸め誤差を抑えるFP32へ変換して、グループごとに分割します。
        let y = x.asType(.float32).reshaped(shape)
        // 各グループ内で二乗の平均を計算します。
        let variance = mean(y * y, axis: -1, keepDims: true)
        // 平均二乗の逆平方根で割り、入力と同じ形へ戻します。
        let normalized = (y * rsqrt(variance + eps)).reshaped(x.shape)
        // 学習済みの全幅重みを掛け、入力と同じ数値型へ戻します。
        return (weight * normalized).asType(x.dtype)
    // グループ正規化の計算を終了します。
    }
// グループ正規化層の定義を終了します。
}

// K2とBonsaiが共有するGQA注意層です。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated final class WealthyDenseAttention: Module {
    // ヘッド数などの寸法を保持します。
    private let configuration: WealthyDenseConfiguration
    // 注意スコアをヘッド次元の平方根で調整する倍率です。
    private let scale: Float
    // 配布重みq_projへ対応する問い合わせ変換です。
    @ModuleInfo(key: "q_proj") var query: Linear
    // 配布重みk_projへ対応するキー変換です。
    @ModuleInfo(key: "k_proj") var key: Linear
    // 配布重みv_projへ対応する値変換です。
    @ModuleInfo(key: "v_proj") var value: Linear
    // 配布重みo_projへ対応する出力変換です。
    @ModuleInfo(key: "o_proj") var output: Linear
    // Bonsaiだけが持つ問い合わせのヘッド正規化です。
    @ModuleInfo(key: "q_norm") var queryNorm: RMSNorm?
    // Bonsaiだけが持つキーのヘッド正規化です。
    @ModuleInfo(key: "k_norm") var keyNorm: RMSNorm?
    // K2が使用する通常の位置回転を保持します。
    private let rope: RoPE?
    // Bonsaiが使用するYaRN拡張位置回転を保持します。
    private let yarn: YarnRoPE?
    // 設定に応じて各線形層と位置回転を作ります。
    init(_ args: WealthyDenseConfiguration) {
        // 後のreshapeに必要な寸法を保存します。
        self.configuration = args
        // ヘッド次元の逆平方根を注意スコアの倍率にします。
        self.scale = pow(Float(args.headDim), -0.5)
        // 問い合わせをqueryヘッド数に合わせて広げます。
        _query.wrappedValue = Linear(args.hiddenSize, args.attentionHeads * args.headDim, bias: false)
        // キーを共有KVヘッド数に合わせて変換します。
        _key.wrappedValue = Linear(args.hiddenSize, args.kvHeads * args.headDim, bias: false)
        // 値を共有KVヘッド数に合わせて変換します。
        _value.wrappedValue = Linear(args.hiddenSize, args.kvHeads * args.headDim, bias: false)
        // 結合した全queryヘッドを内部ベクトル幅へ戻します。
        _output.wrappedValue = Linear(args.attentionHeads * args.headDim, args.hiddenSize, bias: false)
        // Q/K追加正規化が必要なBonsaiの構成か確認します。
        if args.queryKeyNorm {
            // 各queryヘッドの要素に同じ学習済み正規化を適用します。
            _queryNorm.wrappedValue = RMSNorm(dimensions: args.headDim, eps: args.rmsNormEps)
            // 各keyヘッドの要素に同じ学習済み正規化を適用します。
            _keyNorm.wrappedValue = RMSNorm(dimensions: args.headDim, eps: args.rmsNormEps)
        // Q/K正規化の準備を終了します。
        }
        // YaRNの拡張率が指定されているか確認します。
        if let factor = args.yarnFactor {
            // この構成では通常RoPEを使用しません。
            self.rope = nil
            // YaRNの設定値を省略せず既存実装へ渡します。
            self.yarn = YarnRoPE(dimensions: args.headDim, traditional: false, maxPositionEmbeddings: args.maxPositions, base: args.ropeTheta, scalingFactor: factor, originalMaxPositionEmbeddings: args.originalMaxPositions, betaFast: args.yarnBetaFast, betaSlow: args.yarnBetaSlow, mscale: args.yarnMscale, mscaleAllDim: args.yarnMscaleAllDim)
        // YaRNがない通常位置回転の構成を処理します。
        } else {
            // rotate-half方式で、指定基数による位置回転を作ります。
            self.rope = RoPE(dimensions: args.headDim, traditional: false, base: args.ropeTheta)
            // この構成ではYaRNを使用しません。
            self.yarn = nil
        // 位置回転の選択を終了します。
        }
    // 注意層の初期化を終了します。
    }
    // 同じ関数で通常RoPEとYaRNを呼び分けます。
    private func rotate(_ x: MLXArray, offset: Int) -> MLXArray {
        // YaRNがある場合はキャッシュ後の位置から回転します。
        if let yarn { return yarn(x, offset: offset) }
        // 通常RoPEがある場合はキャッシュ後の位置から回転します。
        if let rope { return rope(x, offset: offset) }
        // 初期化では必ず回転層があるため、到達しない保険の返却です。
        return x
    // 位置回転の呼び分けを終了します。
    }
    // 現在のトークンと過去のKVキャッシュから注意出力を計算します。
    func callAsFunction(_ x: MLXArray, mask: MLXFast.ScaledDotProductAttentionMaskMode, cache: KVCache?) -> MLXArray {
        // 同時処理する入力列の数を読み取ります。
        let batch = x.dim(0)
        // 今回処理するトークンの数を読み取ります。
        let length = x.dim(1)
        // 問い合わせ変換の結果をヘッド単位に分割します。
        var queries = query(x).reshaped(batch, length, configuration.attentionHeads, configuration.headDim)
        // キー変換の結果をKVヘッド単位に分割します。
        var keys = key(x).reshaped(batch, length, configuration.kvHeads, configuration.headDim)
        // 値のヘッド軸をトークン軸より前へ移します。
        let values = value(x).reshaped(batch, length, configuration.kvHeads, configuration.headDim).transposed(0, 2, 1, 3)
        // Bonsai構成では各queryヘッドを正規化します。
        if let queryNorm { queries = queryNorm(queries) }
        // Bonsai構成では各keyヘッドを正規化します。
        if let keyNorm { keys = keyNorm(keys) }
        // query軸順を変更し、絶対位置に応じた回転を適用します。
        queries = rotate(queries.transposed(0, 2, 1, 3), offset: cache?.offset ?? 0)
        // key軸順を変更し、queryと同じ絶対位置で回転します。
        keys = rotate(keys.transposed(0, 2, 1, 3), offset: cache?.offset ?? 0)
        // KVを追加保存し、未来のトークンを参照しないGQAを計算します。
        let attended = attentionWithCacheUpdate(queries: queries, keys: keys, values: values, cache: cache, scale: scale, mask: mask)
        // 全queryヘッドを結合して、内部ベクトル幅へ変換します。
        return output(attended.transposed(0, 2, 1, 3).reshaped(batch, length, -1))
    // 注意計算を終了します。
    }
// 共通GQA注意層の定義を終了します。
}

// SwiGLU方式のdense MLPです。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated final class WealthyDenseMLP: Module, UnaryLayer {
    // 配布重みgate_projへ対応するゲート変換です。
    @ModuleInfo(key: "gate_proj") var gate: Linear
    // 配布重みup_projへ対応する幅を広げる変換です。
    @ModuleInfo(key: "up_proj") var up: Linear
    // 配布重みdown_projへ対応する幅を戻す変換です。
    @ModuleInfo(key: "down_proj") var down: Linear
    // 内部幅とMLP幅を設定から受け取ります。
    init(_ args: WealthyDenseConfiguration) {
        // ゲート側の広いベクトルを作ります。
        _gate.wrappedValue = Linear(args.hiddenSize, args.intermediateSize, bias: false)
        // 内容側の広いベクトルを作ります。
        _up.wrappedValue = Linear(args.hiddenSize, args.intermediateSize, bias: false)
        // 最終結果を元の内部幅へ戻します。
        _down.wrappedValue = Linear(args.intermediateSize, args.hiddenSize, bias: false)
    // MLPの初期化を終了します。
    }
    // SiLUゲートと内容を要素ごとに掛け、その結果を元の幅へ戻します。
    func callAsFunction(_ x: MLXArray) -> MLXArray { down(silu(gate(x)) * up(x)) }
// dense MLPの定義を終了します。
}

// 注意層とMLPを順番に通す1つのTransformerブロックです。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated final class WealthyDenseBlock: Module {
    // 配布のself_attn階層へ対応させます。
    @ModuleInfo(key: "self_attn") var attention: WealthyDenseAttention
    // 配布のmlp階層へ対応するフィードフォワード層です。
    let mlp: WealthyDenseMLP
    // 注意層の前に入力を正規化します。
    @ModuleInfo(key: "input_layernorm") var inputNorm: WealthyGroupedRMSNorm
    // 注意層の後、MLPの前に正規化します。
    @ModuleInfo(key: "post_attention_layernorm") var postNorm: WealthyGroupedRMSNorm
    // このブロックを共通設定から作ります。
    init(_ args: WealthyDenseConfiguration) {
        // GQA注意層を作ります。
        _attention.wrappedValue = WealthyDenseAttention(args)
        // dense MLPを作ります。
        self.mlp = WealthyDenseMLP(args)
        // 入力正規化を指定グループ数で作ります。
        _inputNorm.wrappedValue = WealthyGroupedRMSNorm(dimensions: args.hiddenSize, groups: args.normGroups, eps: args.rmsNormEps)
        // MLP前の正規化を同じグループ数で作ります。
        _postNorm.wrappedValue = WealthyGroupedRMSNorm(dimensions: args.hiddenSize, groups: args.normGroups, eps: args.rmsNormEps)
    // ブロックの初期化を終了します。
    }
    // 正規化・注意・残差・MLPを順番に計算します。
    func callAsFunction(_ x: MLXArray, mask: MLXFast.ScaledDotProductAttentionMaskMode, cache: KVCache?) -> MLXArray {
        // 注意出力に元の入力を加え、残差経路を保持します。
        let attended = x + attention(inputNorm(x), mask: mask, cache: cache)
        // MLP出力にも注意後の入力を加えます。
        return attended + mlp(postNorm(attended))
    // ブロックの計算を終了します。
    }
// Transformerブロックの定義を終了します。
}

// 埋め込み・複数ブロック・最終正規化をまとめます。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated final class WealthyDenseDecoder: Module {
    // 配布のmodel.embed_tokensへ対応する入力埋め込みです。
    @ModuleInfo(key: "embed_tokens") var embedding: Embedding
    // 配布のmodel.layers.0などに順番どおり対応する層配列です。
    let layers: [WealthyDenseBlock]
    // 配布のmodel.normへ対応する最終正規化です。
    let norm: WealthyGroupedRMSNorm
    // 設定に従ってdecoder全体を組み立てます。
    init(_ args: WealthyDenseConfiguration) {
        // 各トークンを内部ベクトルへ変換する表を用意します。
        _embedding.wrappedValue = Embedding(embeddingCount: args.vocabularySize, dimensions: args.hiddenSize)
        // 指定された層数だけTransformerブロックを並べます。
        self.layers = (0..<args.hiddenLayers).map { _ in WealthyDenseBlock(args) }
        // decoder出力の最終正規化を用意します。
        self.norm = WealthyGroupedRMSNorm(dimensions: args.hiddenSize, groups: args.normGroups, eps: args.rmsNormEps)
    // decoderの初期化を終了します。
    }
    // トークン番号列をdecoder出力へ変換します。
    func callAsFunction(_ inputs: MLXArray, cache: [KVCache]?) -> MLXArray {
        // トークン番号を学習済み内部ベクトルへ変換します。
        var hidden = embedding(inputs)
        // 未来トークンを読まないマスクを、キャッシュ位置に合わせて作ります。
        let mask = createAttentionMask(h: hidden, cache: cache)
        // 各層を先頭から順番に実行します。
        for (index, layer) in layers.enumerated() {
            // 同じ層番号のKVキャッシュと、直前の層の出力を使います。
            hidden = layer(hidden, mask: mask, cache: cache?[index])
        // 全層の処理を終了します。
        }
        // 最後に正規化した内部ベクトルを返します。
        return norm(hidden)
    // decoderの計算を終了します。
    }
// 共通decoderの定義を終了します。
}

// 同じ重み階層でK2とBonsaiのトークン予測を実装します。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated final class WealthyDenseLanguageModel: Module, LLMModel, KVCacheDimensionProvider {
    // 推論処理へ語彙数を公開します。
    let vocabularySize: Int
    // 各層のキャッシュ生成に必要な層数とKVヘッド数を公開します。
    let kvHeads: [Int]
    // LoRA共通規約へ、学習対象になり得るTransformerブロック一覧を公開します。
    var loraLayers: [Module] { model.layers }
    // 配布のmodel階層と一致するdecoderを保持します。
    private let model: WealthyDenseDecoder
    // 配布のlm_headへ対応する最終トークン予測層です。
    @ModuleInfo(key: "lm_head") var head: Linear?
    // 出力に入力埋め込みを再利用するかを保存します。
    private let tied: Bool
    // 共通設定を検証した後で言語モデルを作ります。
    init(_ args: WealthyDenseConfiguration) throws {
        // 不正な配列寸法でGPU処理が始まるのを防ぎます。
        try args.validate()
        // トークン出力の種類数を公開します。
        self.vocabularySize = args.vocabularySize
        // 各層に同じKVヘッド数を設定します。
        self.kvHeads = Array(repeating: args.kvHeads, count: args.hiddenLayers)
        // 配布重みのmodel階層を作ります。
        self.model = WealthyDenseDecoder(args)
        // 出力重みの共有設定を保存します。
        self.tied = args.tieWordEmbeddings
        // 入力と出力に別の重みが必要か確認します。
        if !args.tieWordEmbeddings {
            // 内部ベクトルから各トークンのスコアを予測する層を作ります。
            _head.wrappedValue = Linear(args.hiddenSize, args.vocabularySize, bias: false)
        // 最終予測層の準備を終了します。
        }
    // 共通言語モデルの初期化を終了します。
    }
    // decoderの出力から次のトークンのスコアを計算します。
    func callAsFunction(_ inputs: MLXArray, cache: [KVCache]?) -> MLXArray {
        // 入力列をdecoderで処理します。
        let hidden = model(inputs, cache: cache)
        // 独立した予測層がある場合は、その重みでスコアを作ります。
        if let head { return head(hidden) }
        // 重み共有の場合は埋め込み表を出力予測に再利用します。
        return model.embedding.asLinear(hidden)
    // トークン予測の計算を終了します。
    }
    // loaderへ渡す重みの名前を調整します。
    func sanitize(weights: [String: MLXArray]) -> [String: MLXArray] {
        // 入力の辞書を壊さず、編集できるコピーを作ります。
        var result = weights
        // 重み共有の場合に不要な独立出力重みを除きます。
        if tied { result["lm_head.weight"] = nil }
        // 正しい階層名の重みをloaderへ返します。
        return result
    // 重み調整を終了します。
    }
// 共通言語モデルの定義を終了します。
}

// 公式K2設定の推論に必要な項目だけを読みます。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
private nonisolated struct K2HorizonConfiguration: Decodable {
    // 検証した設定を共通decoderの形式で保持します。
    let dense: WealthyDenseConfiguration
    // JSONからK2の設定を読み込みます。
    init(from decoder: Decoder) throws {
        // 文字列キーで設定値を取得する容器を用意します。
        let values = try decoder.container(keyedBy: WealthyJSONKey.self)
        // MoEが要求されているか判定するためexpert数を読みます。
        let experts = try values.read(Int.self, "num_experts", default: 0)
        // MoVAが要求されているか判定するためvalue expert数を読みます。
        let mova = try values.read(Int.self, "mova_num_experts", default: 0)
        // 部分RoPEかどうかを判定する次元を読みます。
        let partial = try values.decodeIfPresent(Int.self, forKey: WealthyJSONKey("rope_head_dim"))
        // 各ヘッド内の次元を読みます。
        let headDim = try values.required(Int.self, "head_dim")
        // sliding attentionが要求されているか読みます。
        let sliding = try values.read(Bool.self, "use_sliding_window", default: false)
        // この実装にないattention biasが必要か読みます。
        let bias = try values.read(Bool.self, "attention_bias", default: false)
        // この実装にないattention gateが必要か読みます。
        let gated = try values.decodeIfPresent(String.self, forKey: WealthyJSONKey("attention_gate_func"))
        // K2の別構成によるQ/K正規化の有無を読みます。
        let queryKeyNorm = try values.read(Bool.self, "query_key_norm", default: false)
        // 現行dense 3.7Bとは異なる推論方式を拒否します。
        guard experts == 0, mova == 0, !sliding, !bias, gated == nil, !queryKeyNorm, partial == nil || partial == headDim else {
            // 未対応構成で誤った回答を生成する前に停止します。
            throw WealthyModelConfigurationError(detail: "このK2実装はdense 3.7B専用です。MoE・MoVA・partial RoPE・attention gate等には未対応です。")
        // K2専用構成の検査を終了します。
        }
        // K2の新形式のRoPE設定を読みます。
        let rope = try values.decodeIfPresent(WealthyRopeConfiguration.self, forKey: WealthyJSONKey("rope_parameters"))
        // dense 3.7Bが使う通常RoPEだけを受け付けます。
        guard rope?.ropeType == nil || rope?.ropeType == "default" else {
            // 未対応の拡張RoPEを拒否します。
            throw WealthyModelConfigurationError(detail: "K2 3.7Bにはdefault RoPEが必要です。")
        // K2のRoPE方式の検査を終了します。
        }
        // JSONの寸法を共通設定へ対応させ、RoPE基数は入れ子設定を優先します。
        self.dense = try WealthyDenseConfiguration(hiddenSize: values.required(Int.self, "hidden_size"), hiddenLayers: values.required(Int.self, "num_hidden_layers"), intermediateSize: values.required(Int.self, "intermediate_size"), attentionHeads: values.required(Int.self, "num_attention_heads"), kvHeads: values.required(Int.self, "num_key_value_heads"), headDim: headDim, vocabularySize: values.required(Int.self, "vocab_size"), rmsNormEps: values.read(Float.self, "rms_norm_eps", default: 0.000001), normGroups: values.read(Int.self, "layernorm_num_groups", default: 2), queryKeyNorm: false, ropeTheta: rope?.theta ?? values.read(Float.self, "rope_theta", default: 10000000), tieWordEmbeddings: values.read(Bool.self, "tie_word_embeddings", default: false), yarnFactor: nil, originalMaxPositions: 0, maxPositions: values.read(Int.self, "max_position_embeddings", default: 524288), yarnBetaFast: 32, yarnBetaSlow: 1, yarnMscale: 1, yarnMscaleAllDim: 0)
    // K2設定の読み込みを終了します。
    }
// K2設定型の定義を終了します。
}

// 設定名を文字列のまま使えるJSONキーです。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated struct WealthyJSONKey: CodingKey {
    // JSON内の文字列キーを保持します。
    let stringValue: String
    // この用途では数値キーを使用しません。
    let intValue: Int? = nil
    // 呼び出し元の文字列をJSONキーとして保存します。
    init(_ value: String) { self.stringValue = value }
    // Codableが文字列からキーを作る場合に対応します。
    init?(stringValue: String) { self.stringValue = stringValue }
    // 数値キーによる生成は受け付けません。
    init?(intValue: Int) { return nil }
// JSONキー型の定義を終了します。
}

// 必須値と省略可能値を読みやすい形で取得する補助機能です。 既定のMainActor隔離を外し、モデル実行領域から同期的に利用できるようにします。
nonisolated extension KeyedDecodingContainer where Key == WealthyJSONKey {
    // 必須項目は未指定ならJSON読込エラーにします。
    func required<T: Decodable>(_ type: T.Type, _ key: String) throws -> T { try decode(type, forKey: WealthyJSONKey(key)) }
    // 省略可能な項目は未指定の場合だけ既定値を使います。
    func read<T: Decodable>(_ type: T.Type, _ key: String, default fallback: T) throws -> T { try decodeIfPresent(type, forKey: WealthyJSONKey(key)) ?? fallback }
// JSON読込補助機能の定義を終了します。
}

// アプリ内のネイティブK2とBonsaiのcreatorを共通登録簿へ登録します。
public func registerWealthyModelTypes() {
    // model_typeがk2_horizonの設定に対応するcreatorを登録します。
    LLMTypeRegistry.shared.registerModelType("k2_horizon") { url in
        // ローカルJSONだけを読み、Python remote codeは実行しません。
        let args = try JSONDecoder().decode(K2HorizonConfiguration.self, from: Data(contentsOf: url))
        // K2の検証済み設定でネイティブMLXモデルを作ります。
        return try WealthyDenseLanguageModel(args.dense)
    // K2のcreator登録を終了します。
    }
    // Bonsai独自typeのcreatorも同じ呼び出しで登録します。
    registerWealthyBonsaiModelType()
// Wealthy用モデル登録関数の定義を終了します。
}
