// 配布テンプレートの文字列とパスを扱う標準機能を読み込みます。
import Foundation
// アプリと同じバージョンのSwift Jinja処理を読み込みます。
import Jinja

// GPUや大きな重みを使わず、実際のチャットテンプレート互換性を検証します。
@main
// コマンドライン検証の入口を定義します。
struct ChatTemplateChecks {
    // 一つの会話メッセージを、Jinjaの型付き値へ変換します。
    static func message(_ role: String, _ content: String) -> Value {
        // roleとcontentを含む辞書を、会話テンプレートへ渡せる形式で返します。
        .object(["role": .string(role), "content": .string(content)])
    // メッセージ作成処理を閉じます。
    }

    // 期待と異なる結果を、検証全体の失敗として記録します。
    static func require(_ condition: Bool, _ name: String) throws {
        // 実際に期待と違った場合だけ、具体的な検査名で停止します。
        guard condition else { throw NSError(domain: "ChatTemplateChecks", code: 1, userInfo: [NSLocalizedDescriptionKey: name]) }
        // 一件の検査を通過したことを表示します。
        print("PASS: \(name)")
    // 期待値の確認処理を閉じます。
    }

    // 固定revisionから取得したテンプレートを、アプリと同じ実装で評価します。
    static func main() throws {
        // 第一引数を、事前に取得した小さな設定ファイルのディレクトリとして使います。
        let directory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        // 本番Tokenizerが使うAny変換でも、trueがBoolとして保たれることを確認します。
        try require(try Value(any: true) == .boolean(true), "Tokenizer additionalContext true conversion")
        // 非推論モードのfalseも整数0へ誤変換されないことを確認します。
        try require(try Value(any: false) == .boolean(false), "Tokenizer additionalContext false conversion")
        // 本番で採用した四つの配布テンプレートを、取得元名に合わせて列挙します。
        let models = [("inferencerlabs--Bonsai-8B-MLX-Q2", false), ("mlx-community--MiniCPM5-1B-4bit", true), ("mlx-community--MiniCPM5-2B-mlx-4Bit", false), ("mlx-community--K2-Horizon-3.7B-4bit", false)]
        // 四モデルを独立に検査します。
        for (name, reasoning) in models {
            // 実際に公開されているテンプレートをUTF-8で読み取ります。
            let source = try String(contentsOf: directory.appendingPathComponent(name + ".jinja"), encoding: .utf8)
            // アプリが使用するSwift Jinjaの文法解析を実行します。
            let template = try Template(source)
            // 初回質問と過去のアシスタント応答を含む二種類の会話を検査します。
            for includeHistory in [false, true] {
                // 日本語のsystem指示を最初のメッセージへ入れます。
                var messages = [message("system", "家計の質問に日本語で答えてください。")]
                // 継続会話の場合だけ、思考欄のない既存の会話履歴を追加します。
                if includeHistory { messages += [message("user", "食費は1000円です。"), message("assistant", "食費1000円を確認しました。")] }
                // 最後のユーザー質問を加えます。
                messages.append(message("user", "今月の食費を教えてください。"))
                // 実サービスと同じ推論モードとK2の短い推論強度を設定します。
                let context: [String: Value] = ["messages": .array(messages), "bos_token": .string(""), "eos_token": .string(""), "add_generation_prompt": .boolean(true), "enable_thinking": .boolean(reasoning), "reasoning_effort": .string("low")]
                // モデルごとのテンプレートを実行し、プロンプト文字列を得ます。
                let rendered = try template.render(context)
                // 会話履歴を含むかを検査結果の名前へ添えます。
                let label = "\(name), history=\(includeHistory)"
                // 日本語の指示・質問がテンプレートで失われていないことを調べます。
                try require(rendered.contains("家計の質問に日本語で答えてください。") && rendered.contains("今月の食費を教えてください。"), "Japanese content: " + label)
                // 継続会話なら、既存応答が正しく埋め込まれていることも調べます。
                try require(!includeHistory || rendered.contains("食費1000円を確認しました。"), "Assistant history: " + label)
                // K2では専用のトークンと、low設定の開始タグが必要です。
                if name.contains("K2-Horizon") {
                    // K2のモデルカードにある短い思考モードで生成が始まるか確認します。
                    try require(rendered.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("<|ifm|im_start|>assistant\n<ifm|think_faster>"), "K2 low reasoning prefix: " + label)
                // MiniCPMのReasoningモデルだけは思考欄を開いたまま生成を開始します。
                } else if reasoning {
                    // 推論モードの開始タグが生成プロンプトの末尾にあるか確認します。
                    try require(rendered.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("<think>"), "Reasoning prefix: " + label)
                // 通常応答モデルは思考欄を閉じてから生成を開始します。
                } else {
                    // 非推論モードの空の思考欄が確実に閉じられているか確認します。
                    try require(rendered.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("<think>\n\n</think>"), "Normal response prefix: " + label)
                // モデル別の末尾確認を閉じます。
                }
            // 二種類の会話の検査を閉じます。
            }
        // 四モデルの検査を閉じます。
        }
        // 重みの推論とは区別し、テンプレートの実行件数を表示します。
        print("PASS: 26 chat-template assertions; no model weights were downloaded")
    // コマンドライン検証の入口を閉じます。
    }
// 検証用の型定義を閉じます。
}
