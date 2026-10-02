// 一時設定ファイルと独立した平方根の計算に標準ライブラリを使います。
import Foundation
// 小さい配列をCPUで計算するMLXを読み込みます。
import MLX
// ネイティブモデルの重み階層を検証して上書きする機能を読み込みます。
import MLXNN
// ローカル設定からモデルを生成する登録簿を読み込みます。
import MLXLLM
// 比較対象のKVキャッシュと量子化設定を読み込みます。
import MLXLMCommon

// このファイルを小さいコマンドライン検証プログラムの入口にします。
@main
// 大きい学習済み重みを取得せず行える数値検証をまとめます。
struct NativeModelChecks {
    // 差が許容値を超えた場合の失敗理由を保持します。
    enum CheckError: Error { case mismatch(String) }
    // 条件が満たされない場合だけ検証を失敗させます。
    static func expect(_ condition: Bool, _ message: String) throws {
        // 失敗理由を実行結果へ伝えます。
        guard condition else { throw CheckError.mismatch(message) }
    // 共通の検証条件関数を閉じます。
    }
    // 2つの同サイズ配列を最大絶対誤差で比較します。
    static func close(_ actual: [Float], _ expected: [Float], tolerance: Float, label: String) throws {
        // 要素数の違いを数値誤差と混同せず検出します。
        try expect(actual.count == expected.count, label + ": shape mismatch")
        // 独立した要素ごとの差の最大値を求めます。
        let error = zip(actual, expected).map { abs($0 - $1) }.max() ?? 0
        // NaN・無限大・過大な誤差を失敗にします。
        try expect(error.isFinite && error <= tolerance, "\(label): max error \(error) > \(tolerance)")
        // 実際に測った誤差と許容値を記録します。
        print("PASS \(label): max_abs_error=\(error), tolerance=\(tolerance)")
    // 配列の数値比較関数を閉じます。
    }
    // グループ正規化を独立したDouble精度のスカラー式と比較します。
    static func groupedNorm() throws {
        // 2行・2グループへ分割する再現可能な入力値です。
        let input: [Float] = [1, -2, 3, -4, 5, -6, 7, -8]
        // グループの外で掛ける学習済み重みの小さい代用品です。
        let weights: [Float] = [1, 0.5, -0.25, 2]
        // 実アプリの2グループ正規化層を使います。
        let norm = WealthyGroupedRMSNorm(dimensions: 4, groups: 2, eps: 0.000001)
        // 実アプリの重み名で代用重みを厳密に読み込みます。
        try norm.update(parameters: .unflattened(["weight": MLXArray(weights)]), verify: .all)
        // MLXを使用しない独立した正解値を蓄積します。
        var reference: [Float] = []
        // 入力の各行を順番に処理します。
        for row in 0..<2 {
            // 各行の2グループを独立に処理します。
            for group in 0..<2 {
                // このグループの先頭の要素位置を計算します。
                let base = row * 4 + group * 2
                // 2要素の二乗平均をDouble精度で計算します。
                let variance = (Double(input[base]) * Double(input[base]) + Double(input[base + 1]) * Double(input[base + 1])) / 2
                // このグループ内の各要素を処理します。
                for offset in 0..<2 {
                    // スカラー式による正規化後に全幅重みを掛けます。
                    reference.append(Float(Double(input[base + offset]) / sqrt(variance + 0.000001) * Double(weights[group * 2 + offset])))
                // このグループの要素処理を閉じます。
                }
            // 各行のグループ処理を閉じます。
            }
        // 各行の処理を閉じます。
        }
        // アプリのFP32結果を2e-6以内で比較します。
        try close(norm(MLXArray(input).reshaped(2, 4)).asArray(Float.self), reference, tolerance: 0.000002, label: "grouped RMS FP32")
        // FP16へ戻す丸め誤差も含めて2e-3以内で比較します。
        try close(norm(MLXArray(input).reshaped(2, 4).asType(.float16)).asType(.float32).asArray(Float.self), reference, tolerance: 0.002, label: "grouped RMS FP16 cast")
    // 独立スカラー参照との正規化比較を閉じます。
    }
    // 配布形式に対応した小さい設定を公式登録経路から読み込みます。
    @MainActor static func tinyModel(type: String) throws -> WealthyDenseLanguageModel {
        // 数百パラメータ規模のdenseモデル設定を作ります。
        var configuration: [String: Any] = ["model_type": type, "hidden_size": 8, "num_hidden_layers": 2, "intermediate_size": 16, "num_attention_heads": 2, "num_key_value_heads": 1, "head_dim": 4, "vocab_size": 16, "rms_norm_eps": 0.000001, "tie_word_embeddings": false, "attention_bias": false, "use_sliding_window": false, "max_position_embeddings": 64]
        // K2では2グループ正規化と通常RoPEを使います。
        if type == "k2_horizon" {
            // 実配布と同じ2グループの正規化を指定します。
            configuration["layernorm_num_groups"] = 2
            // 実配布と同じくQ/K追加正規化を使いません。
            configuration["query_key_norm"] = false
            // 実配布と同じRoPE基数と方式を指定します。
            configuration["rope_parameters"] = ["rope_type": "default", "rope_theta": 10000000]
        // BonsaiではYaRNとQ/K正規化を使います。
        } else {
            // 実配布と同じRoPE基数を指定します。
            configuration["rope_theta"] = 1000000
            // 実配布のYaRN拡張率と元の位置範囲を指定します。
            configuration["rope_scaling"] = ["rope_type": "yarn", "factor": 4, "original_max_position_embeddings": 16384]
        // K2とBonsaiの設定選択を閉じます。
        }
        // アプリの保存モデルと無関係な一時JSONの場所を作ります。
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("wealthy-native-\(UUID().uuidString).json")
        // 検証の成否にかかわらず一時設定だけを削除します。
        defer { try? FileManager.default.removeItem(at: url) }
        // 公式creatorへ渡す小さい設定を保存します。
        try JSONSerialization.data(withJSONObject: configuration).write(to: url)
        // 実際の登録簿で目的のネイティブモデルが生成されるか確認します。
        guard let model = try LLMTypeRegistry.shared.createModel(configuration: url, modelType: type) as? WealthyDenseLanguageModel else { throw CheckError.mismatch("wrong creator") }
        // モデルから全重み名と寸法を取得します。
        let original = Dictionary(uniqueKeysWithValues: model.parameters().flattened())
        // 初期乱数に依存しない代用重みを作ります。
        var deterministic: [String: MLXArray] = [:]
        // 重み名の順を固定して再現性を守ります。
        for (index, name) in original.keys.sorted().enumerated() {
            // 表にない重みを黙って飛ばしません。
            guard let parameter = original[name] else { throw CheckError.mismatch("missing parameter") }
            // 13値の周期から小さい決定的な重みを生成します。
            let values = (0..<parameter.size).map { Float(($0 + index) % 13 - 6) * 0.03 }
            // 配布時と同じ各重みの形へ変換します。
            deterministic[name] = MLXArray(values).reshaped(parameter.shape)
        // 全代用重みの生成を閉じます。
        }
        // 全重みの名前・形・不足を厳密に照合して読み込みます。
        try model.update(parameters: .unflattened(deterministic), verify: .all)
        // K2は21、Q/K正規化が加わるBonsaiは25の重みを期待します。
        let expectedCount = type == "k2_horizon" ? 21 : 25
        // privateプロパティやOptionalによる重み階層欠落を検出します。
        try expect(original.count == expectedCount, "wrong parameter count: \(original.count)")
        // 配布ファイルと一致する重要な重み名を確認します。
        try expect(original["model.embed_tokens.weight"] != nil && original["model.layers.0.self_attn.q_proj.weight"] != nil && original["model.layers.0.mlp.gate_proj.weight"] != nil && original["model.norm.weight"] != nil && original["lm_head.weight"] != nil, "wrong weight hierarchy")
        // 設定の読み込みと重み階層の検証成功を記録します。
        print("PASS \(type): configuration / \(original.count) named weights")
        // 数値検証に使う決定的な小さいモデルを返します。
        return model
    // 小さいネイティブモデルの生成を閉じます。
    }
    // 一括入力と1トークンずつのキャッシュ入力を比較します。
    static func cachedForward(_ model: WealthyDenseLanguageModel, label: String) throws {
        // 4トークンだけの決定的な入力列です。
        let sequence = [1, 2, 3, 4]
        // キャッシュなしで全トークンを一括処理します。
        let full = model(MLXArray(sequence).reshaped(1, 4), cache: nil).asArray(Float.self)
        // 2層のそれぞれに空のKVキャッシュを作ります。
        let cache: [KVCache] = [KVCacheSimple(), KVCacheSimple()]
        // 1トークンずつ処理した出力スコアを蓄積します。
        var incremental: [Float] = []
        // 同じ入力トークンを順番に与えます。
        for token in sequence {
            // 過去のKVを再利用した各位置の出力を保存します。
            incremental.append(contentsOf: model(MLXArray([token]).reshaped(1, 1), cache: cache).asArray(Float.self))
        // 全入力トークンのキャッシュ処理を閉じます。
        }
        // 因果マスク・RoPE offset・KV更新の一致を1e-5以内で確認します。
        try close(incremental, full, tolerance: 0.00001, label: label + " full/cache")
    // キャッシュの前向き計算比較を閉じます。
    }
    // 大きいモデルファイルなしで小さいネイティブ検証を実行します。
    @MainActor static func main() throws {
        // 実機Metalへ依存しない小さいCPU演算として実行します。
        try Device.withDefaultDevice(.cpu) {
        // 実アプリと同じモデルcreatorを登録します。
        registerWealthyModelTypes()
        // 独立スカラー参照とのFP32・FP16正規化比較を実行します。
        try groupedNorm()
        // K2の設定読込・重み階層・キャッシュ計算を検証します。
        try cachedForward(tinyModel(type: "k2_horizon"), label: "K2")
        // BonsaiのYaRN設定読込とキャッシュ計算を検証します。
        try cachedForward(tinyModel(type: "wealthy_bonsai_qwen3"), label: "Bonsai YaRN")
        // 小さい検証と実重み検証の範囲を区別して完了を記録します。
        print("PASS all tiny native checks; real weights / real-device inference remain unverified")
        // 小さいCPU演算だけに既定デバイスを固定する範囲を閉じます。
        }
    // 検証プログラムの入口を閉じます。
    }
// 数値検証プログラムの定義を閉じます。
}
