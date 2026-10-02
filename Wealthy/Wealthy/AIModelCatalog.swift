// モデル名・固定版・容量を扱うための標準機能を読み込みます。
import Foundation

// OSが管理するAppleモデルと、アプリが取得するMLXモデルを区別します。
enum AIModelBackend: String, Codable, Sendable {
    // Apple Intelligenceの端末内モデルを使う方式です。
    case apple
    // ダウンロードした重みを端末のGPUで実行する方式です。
    case mlx
// 推論方式の定義を閉じます。
}

// 一つのモデルの表示情報と、安全に取得するための固定配布情報を保持します。
struct OnDeviceAIModel: Identifiable, Equatable, Hashable, Sendable {
    // 設定を保存する際に使う、アプリ内で一意の識別子です。
    let id: String
    // 画面に表示するモデル名です。
    let name: String
    // AppleのOSモデルか、MLXの取得モデルかを示します。
    let backend: AIModelBackend
    // Hugging Faceの配布元で、Appleモデルには配布元を設定しません。
    let repoId: String?
    // 取得内容が後から入れ替わらないように固定する40文字のコミットIDです。
    let revision: String?
    // 2026年10月2日に公開APIで確認した、取得対象ファイルの合計バイト数です。
    let downloadBytes: Int64
    // 重みの量子化方式を表示し、モデル名のパラメーター数と容量を混同させません。
    let quantization: String
    // 推論を許可するために必要な、端末全体のRAMの保守的な目安です。
    let minimumMemoryBytes: UInt64
    // 重み・最大4096トークンのKVキャッシュ・作業領域を含むアプリ用メモリの目安です。
    let runtimeMemoryBytes: UInt64
    // チャットテンプレートで推論モードを明示的に有効にするかを指定します。
    let isReasoning: Bool
// モデル情報の定義を閉じます。
}

// このアプリで選択できる5種類のモデルだけを定義します。
enum AIModelCatalog {
    // 未選択時と、廃止モデルからの移行時に使うAppleモデルのIDです。
    static let defaultID = "apple-foundation-models"
    // Appleモデルを先頭にして、設定画面の選択肢を定義します。
    static let models: [OnDeviceAIModel] = [
        // Appleモデルの本体容量はOS管理なので、ここではアプリによる追加取得を0と表します。
        OnDeviceAIModel(id: defaultID, name: "Apple Foundation Models", backend: .apple, repoId: nil, revision: nil, downloadBytes: 0, quantization: "OS managed", minimumMemoryBytes: 0, runtimeMemoryBytes: 0, isReasoning: false),
        // Bonsaiの標準MLX互換2-bit版を採用し、公式1-bit版の容量と区別します。
        OnDeviceAIModel(id: "bonsai-8b", name: "Bonsai 8B", backend: .mlx, repoId: "inferencerlabs/Bonsai-8B-MLX-Q2", revision: "2fa829d190a9d2a0c3d8850ea2d62ebfd06019f4", downloadBytes: 2_315_156_449, quantization: "2-bit", minimumMemoryBytes: 6_000_000_000, runtimeMemoryBytes: 3_500_000_000, isReasoning: false),
        // 1Bモデルではチャットテンプレートの推論モードを有効にします。
        OnDeviceAIModel(id: "minicpm5-1b-reasoning", name: "MiniCPM5-1B (Reasoning)", backend: .mlx, repoId: "mlx-community/MiniCPM5-1B-4bit", revision: "36447e84d28c57588a6e91907675e44afe54ab00", downloadBytes: 617_970_893, quantization: "4-bit", minimumMemoryBytes: 4_000_000_000, runtimeMemoryBytes: 1_600_000_000, isReasoning: true),
        // 2Bモデルは短い家計操作向けに、通常の応答モードを使います。
        OnDeviceAIModel(id: "minicpm5-2b", name: "MiniCPM5-2B", backend: .mlx, repoId: "mlx-community/MiniCPM5-2B-mlx-4Bit", revision: "86ad5182c5a8532a4681ab972011d34c3b89477a", downloadBytes: 1_426_009_037, quantization: "4-bit", minimumMemoryBytes: 6_000_000_000, runtimeMemoryBytes: 2_500_000_000, isReasoning: false),
        // K2は埋め込みなどが8-bitの混合量子化なので、単純な3.7B×4bitでは容量を計算しません。
        OnDeviceAIModel(id: "k2-horizon-3-7b", name: "K2 Horizon 3.7B", backend: .mlx, repoId: "mlx-community/K2-Horizon-3.7B-4bit", revision: "3b453d026bd4f433c0bc9a532706f87488269e4d", downloadBytes: 4_156_855_917, quantization: "4 / 8-bit", minimumMemoryBytes: 8_000_000_000, runtimeMemoryBytes: 5_600_000_000, isReasoning: false)
    // 5種類の選択肢一覧を閉じます。
    ]

    // 未知のIDや以前のモデルIDはAppleに移行し、有効な新モデルの選択は保持します。
    static func restoredSelection(_ savedID: String?) -> String {
        // 保存値が今回の一覧にある場合だけ、その選択を復元します。
        guard let savedID, models.contains(where: { $0.id == savedID }) else { return defaultID }
        // 有効な選択IDを呼び出し元へ返します。
        return savedID
    // 選択の復元処理を閉じます。
    }
// モデルカタログの定義を閉じます。
}

// 画面で「使える理由・使えない理由」と、実際の起動確認の有無を一緒に表示します。
struct AIModelCompatibility {
    // 短く表示する利用状況です。
    let title: String
    // メモリ不足やApple Intelligenceの設定など、判断の理由です。
    let detail: String
    // この時点でモデルを選んで読み込めるかを示します。
    let canSelect: Bool
    // AppleはOSの確定判定、MLXは今回の実機推論またはGPU不可の確定判定が得られたことを示します。
    let isVerified: Bool
// 利用状況の定義を閉じます。
}
