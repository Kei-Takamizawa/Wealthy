// Foundationの機能を、このファイルから使えるように読み込みます。
import Foundation
// MLXの機能を、このファイルから使えるように読み込みます。
import MLX
// MLXRandomの機能を、このファイルから使えるように読み込みます。
import MLXRandom
// MLXNNの機能を、このファイルから使えるように読み込みます。
import MLXNN
// MLXLLMの機能を、このファイルから使えるように読み込みます。
import MLXLLM
// MLXLMCommonの機能を、このファイルから使えるように読み込みます。
import MLXLMCommon
// Tokenizersの機能を、このファイルから使えるように読み込みます。
import Tokenizers
// SwiftUIの機能を、このファイルから使えるように読み込みます。
import SwiftUI

// このクラスの値の変化を画面が監視できるようにします。
@Observable
// 端末上のAIモデルを管理して文章を生成する型を定義します。
class LocalLLMService {
    // アプリ内で共有する、この管理クラスのインスタンスを一つ作ります。
    static let shared = LocalLLMService()
    
    // AIモデルの識別子と表示名をまとめる型を定義します。
    struct AIModel: Identifiable, Equatable, Hashable {
        // 各データを識別するIDを保持するプロパティを定義します。
        let id: String
        // 表示名を保持するプロパティを定義します。
        let name: String
        // モデルをダウンロードする配布元のIDを保持します。
        let repoId: String
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // Available Models
    // Available Models
    // 利用可能なAIモデルの一覧を作成または更新します。
    let availableModels: [AIModel] = [
        // 表示名と取得元を指定して、利用可能なAIモデルを一覧に追加します。
        AIModel(id: "phi", name: "Phi 3.5 Mini", repoId: "mlx-community/Phi-3.5-mini-instruct-4bit"),
        // 表示名と取得元を指定して、利用可能なAIモデルを一覧に追加します。
        AIModel(id: "llama", name: "Llama 3.2 3B", repoId: "mlx-community/Llama-3.2-3B-Instruct-4bit"),
        // 表示名と取得元を指定して、利用可能なAIモデルを一覧に追加します。
        AIModel(id: "lfm", name: "LFM2 2.6B Exp", repoId: "mlx-community/LFM2-2.6B-Exp-4bit"),
        // 表示名と取得元を指定して、利用可能なAIモデルを一覧に追加します。
        AIModel(id: "gemma", name: "Gemma 3n E2B", repoId: "mlx-community/gemma-3n-E2B-it-lm-4bit")
    // ここで一覧または辞書を閉じます。
    ]
    
    // AIが出力した文章を作成または更新します。
    var outputText: String = ""
    // AIが生成中かを示す値を作成または更新します。
    var isThinking: Bool = false
    // モデル読み込み状況の表示文言を作成または更新します。
    var loadStatus: String = "未インストール"
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor var downloadProgress: Double = 0.0
    
    // Ticker Language Setting
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor var tickerLanguage: String {
        // 保存済みの設定値を読み取り、なければ既定値を返します。
        get { UserDefaults.standard.string(forKey: "aiTickerLanguage") ?? "日本語" }
        // 新しい設定値を端末の設定領域に保存します。
        set { UserDefaults.standard.set(newValue, forKey: "aiTickerLanguage") }
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // ホームのAIコメントに使う言語を変更する入口を定義します。
    func setTickerLanguage(_ language: String) {
        // tickerLanguageに、右辺の計算結果または取得結果を設定します。
        tickerLanguage = language
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor var isModelInstalled: Bool {
        // 保存済みの設定値を読み取り、なければ既定値を返します。
        get { UserDefaults.standard.bool(forKey: "isModelInstalled_\(currentModelId)") }
        // 新しい設定値を端末の設定領域に保存します。
        set { UserDefaults.standard.set(newValue, forKey: "isModelInstalled_\(currentModelId)") }
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // Check status for any model
    // 指定したAIモデルの保存済みフラグを調べる入口を定義します。
    func isInstalled(modelId: String) -> Bool {
        // Simple check: user default flag + directory existence check could be better but heavy?
        // For now, rely on flag, but physical delete clears it.
        // 計算または取得した値を呼び出し元へ返します。
        return UserDefaults.standard.bool(forKey: "isModelInstalled_\(modelId)")
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // Store Selected Model ID
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor var currentModelId: String {
        // 保存済みの設定値を読み取り、なければ既定値を返します。
        get { UserDefaults.standard.string(forKey: "selectedAIModelId") ?? "phi" }
        // 新しい設定値を端末の設定領域に保存します。
        set { UserDefaults.standard.set(newValue, forKey: "selectedAIModelId") }
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 現在のIDに対応するモデルを保持するプロパティを定義します。
    var currentModel: AIModel {
        // availableModels.first(where: { $0.idに、右辺の計算結果または取得結果を設定します。
        availableModels.first(where: { $0.id == currentModelId }) ?? availableModels[0]
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // ... [Rest of setModel, loadModel, deleteModel remains mostly same until Chat Logic] ...
    
    // 読み込んだAIモデルの実行用コンテナを保持するプロパティを定義します。
    private var modelContainer: ModelContainer?
    // 進行中のモデル読み込みタスクを保持するプロパティを定義します。
    private var backgroundTask: Task<Void, Never>?
    
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // 使用するAIモデルを切り替える入口を定義します。
    func setModel(_ model: AIModel) async {
        // この条件が成り立つ場合だけ、続く処理を行います。
        if currentModelId != model.id {
            // currentModelIdに、右辺の計算結果または取得結果を設定します。
            currentModelId = model.id
            // Force reload
            // 処理の状況を開発用ログへ出力します。
            print("Switched model to: \(model.name)")
            // loadStatusに、右辺で指定した値を設定します。
            self.loadStatus = "モデル切り替え: \(model.name)"
            // 直前に定義した処理へ、この設定または引数を追加します。
            await loadModel()
        // ここまでの処理またはデータ定義を閉じます。
        }
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // AIモデルの読み込みを非同期で始める入口を定義します。
    func startBackgroundDownload(model: AIModel) {
        // Just set the ID, don't wait. Task will run in background.
        // currentModelIdに、右辺の計算結果または取得結果を設定します。
        currentModelId = model.id
        // loadStatusに、右辺で指定した値を設定します。
        self.loadStatus = "ダウンロード準備中... (\(model.name))"
        
        // Cancel existing task if any
        // 直前に定義した処理へ、この設定または引数を追加します。
        backgroundTask?.cancel()
        
        // backgroundTaskに、右辺の計算結果または取得結果を設定します。
        backgroundTask = Task.detached { 
            // 直前に定義した処理へ、この設定または引数を追加します。
            await self.loadModel()
        // ここまでの処理またはデータ定義を閉じます。
        }
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // AIモデルを読み込み、必要ならダウンロードする入口を定義します。
    func loadModel() async {
        // loadStatusに、右辺で指定した値を設定します。
        self.loadStatus = "モデルを確認中... (\(currentModel.name))"
        // downloadProgressに、右辺で指定した値を設定します。
        self.downloadProgress = 0.0
        // 直前に定義した処理へ、この設定または引数を追加します。
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
        
        // エラーが発生する可能性のある処理を始めます。
        do {
            // 選択したAIモデルの取得元を読み込み設定に変えます。
            let modelConfiguration = ModelConfiguration(id: currentModel.repoId)
            // AIモデルを読み込む共有ファクトリを取得します。
            let factory = LLMModelFactory.shared
            
            // loadStatusに、右辺で指定した値を設定します。
            self.loadStatus = "準備を開始..."
            // 処理の状況を開発用ログへ出力します。
            print("Loading Model: \(currentModel.repoId)")
            
            // This loadContainer call downloads if needed
            // modelContainerに、右辺で指定した値を設定します。
            self.modelContainer = try await factory.loadContainer(
                // 直前に定義した処理へ、この設定または引数を追加します。
                configuration: modelConfiguration
            // ここで引数を閉じ、直前の呼び出しを完成させます。
            ) { progress in
                // 直前に定義した処理へ、この設定または引数を追加します。
                Task { @MainActor in
                    // downloadProgressに、右辺で指定した値を設定します。
                    self.downloadProgress = progress.fractionCompleted
                    // loadStatusに、右辺で指定した値を設定します。
                    self.loadStatus = "ダウンロード中: \(Int(progress.fractionCompleted * 100))%"
                // ここまでの処理またはデータ定義を閉じます。
                }
            // ここまでの処理またはデータ定義を閉じます。
            }
            
            // isModelInstalledに、右辺で指定した値を設定します。
            self.isModelInstalled = true // Sets specific flag for currentModelId
            // loadStatusに、右辺で指定した値を設定します。
            self.loadStatus = "準備完了 (\(currentModel.name))"
            // 処理の状況を開発用ログへ出力します。
            print("\(currentModel.name) Loaded Successfully!")
            
        // 直前の処理でエラーが起きた場合の処理へ進みます。
        } catch {
            // loadStatusに、右辺で指定した値を設定します。
            self.loadStatus = "エラー発生: \(error.localizedDescription)"
            // 処理の状況を開発用ログへ出力します。
            print("Model Load Error: \(error)")
        // ここまでの処理またはデータ定義を閉じます。
        }
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // 選んだAIモデルの保存データを削除する入口を定義します。
    func deleteModel() {
        // 直前に定義した処理へ、この設定または引数を追加します。
        deleteModel(id: currentModelId)
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // 選んだAIモデルの保存データを削除する入口を定義します。
    func deleteModel(id: String) {
        // 1. Identify Model
        // 必要な値があるか確かめ、なければ後続の処理を止めます。
        guard let model = availableModels.first(where: { $0.id == id }) else { return }
        
        // 2. Unset Flag
        // 直前に定義した処理へ、この設定または引数を追加します。
        UserDefaults.standard.set(false, forKey: "isModelInstalled_\(id)")
        
        // 3. Clear Memory if current
        // この条件が成り立つ場合だけ、続く処理を行います。
        if id == currentModelId {
            // loadStatusに、右辺で指定した値を設定します。
            self.loadStatus = "未インストール"
            // modelContainerに、右辺で指定した値を設定します。
            self.modelContainer = nil
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // 4. Physical Deletion
        // 削除対象モデルの取得元IDを取得します。
        let repoId = model.repoId
        // 取得元IDをHugging Faceのキャッシュ名に変換します。
        let sanitizedRepo = "models--" + repoId.replacingOccurrences(of: "/", with: "--")
        // ファイルの存在確認と削除に使う管理オブジェクトを取得します。
        let fileManager = FileManager.default
        
        // モデルのキャッシュを探す標準フォルダを列挙します。
        let searchPaths: [FileManager.SearchPathDirectory] = [.documentDirectory, .applicationSupportDirectory, .cachesDirectory]
        
        // 配列の各要素を順番に取り出して処理します。
        for searchPath in searchPaths {
            // この条件が成り立つ場合だけ、続く処理を行います。
            if let baseURL = fileManager.urls(for: searchPath, in: .userDomainMask).first {
                // Hugging Faceのキャッシュにあり得る相対パスを列挙します。
                let potentialPaths = [
                    // 直前に定義した処理へ、この設定または引数を追加します。
                    "huggingface/hub/\(sanitizedRepo)",
                    // 直前に定義した処理へ、この設定または引数を追加します。
                    ".cache/huggingface/hub/\(sanitizedRepo)"
                // ここで一覧または辞書を閉じます。
                ]
                
                // 配列の各要素を順番に取り出して処理します。
                for subPath in potentialPaths {
                    // 削除対象となるキャッシュフォルダの場所を作ります。
                    let cacheDir = baseURL.appendingPathComponent(subPath)
                    // この条件が成り立つ場合だけ、続く処理を行います。
                    if fileManager.fileExists(atPath: cacheDir.path) {
                        // エラーが発生する可能性のある処理を始めます。
                        do {
                            // 失敗した場合はエラーを呼び出し元へ伝えながら、この処理を実行します。
                            try fileManager.removeItem(at: cacheDir)
                            // 処理の状況を開発用ログへ出力します。
                            print("Deleted model cache at: \(cacheDir.path)")
                        // 直前の処理でエラーが起きた場合の処理へ進みます。
                        } catch {
                            // 処理の状況を開発用ログへ出力します。
                            print("Failed to delete model cache at \(cacheDir.path): \(error)")
                        // ここまでの処理またはデータ定義を閉じます。
                        }
                    // ここまでの処理またはデータ定義を閉じます。
                    }
                // ここまでの処理またはデータ定義を閉じます。
                }
            // ここまでの処理またはデータ定義を閉じます。
            }
        // ここまでの処理またはデータ定義を閉じます。
        }
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // Chat Logic
    // AIとの会話の一件を表す型を定義します。
    struct ChatMessage: Identifiable, Equatable {
        // 各データを識別するIDを作成または更新します。
        let id = UUID()
        // 発言者を保持するプロパティを定義します。
        let role: MessageRole
        // 通知に表示する題名と本文を入れる値を作ります。
        let content: String
        
        // 会話の発言者を区別する型を定義します。
        enum MessageRole {
            // 列挙型で使う選択肢として、user, assistant, systemを定義します。
            case user, assistant, system
        // ここまでの処理またはデータ定義を閉じます。
        }
    // ここまでの処理またはデータ定義を閉じます。
    }

    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // レシートOCRの文字をAIに解析させる入口を定義します。
    func extractReceiptData(prompt: String, categories: [String]) async throws -> String {
        // 必要な値があるか確かめ、なければ後続の処理を止めます。
        guard let container = modelContainer else {
            // 必要なAIモデルが読み込まれていないことをエラーとして伝えます。
            throw NSError(domain: "LocalLLMService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // AIに渡すカテゴリ候補の文字列を作成または更新します。
        let categoryListString = categories.map { "\"\($0)\"" }.joined(separator: ", ")
        
        // Receipt Extraction logic is generic, but we must enforce valid JSON.
        // We use a strict prompt.
        // AIに守らせる指示文を作成または更新します。
        let systemPrompt = """
        You are a Receipt Information Extractor. Your job is to extract specific data from receipt OCR text and output strict JSON.
        
        TARGET DATA:
        - "shopName": The name of the store.
        - "amount": The total paid amount.
        - "category": Choose from: [\(categoryListString)]. or "未分類".
        - "date": "YYYY-MM-DD".
        
        RULES:
        - Output ONLY valid JSON.
        - NO Markdown.
        """
        
        // One-shot example
        // モデル形式に合わせた指示文を作成または更新します。
        let formattedPrompt = """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        \(systemPrompt)<|eot_id|><|start_header_id|>user<|end_header_id|>
        RECEIPT
        Store A
        1000
        <|eot_id|><|start_header_id|>assistant<|end_header_id|>
        {"shopName": "Store A", "amount": 1000, "category": "未分類", "date": "2025-01-01"}<|eot_id|><|start_header_id|>user<|end_header_id|>
        \(prompt)<|eot_id|><|start_header_id|>assistant<|end_header_id|>
        """
        
        // 計算または取得した値を呼び出し元へ返します。
        return try await generate(container: container, formattedPrompt: formattedPrompt, temperature: 0.1)
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // 会話履歴と家計情報からAIの返答を作る入口を定義します。
    func chat(history: [ChatMessage], context: String) async throws -> String {
        // 必要な値があるか確かめ、なければ後続の処理を止めます。
        guard let container = modelContainer else {
            // 必要なAIモデルが読み込まれていないことをエラーとして伝えます。
            throw NSError(domain: "LocalLLMService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // Adaptive Language Logic
        // AIが使う言語の指示を作成または更新します。
        let languageInstruction = "- **Reply in the same language as the user's input.**"
        
        // Dynamic System Prompt
        // AIに守らせる指示文を作成または更新します。
        let systemPrompt = """
        You are a helpful and intelligent financial butler named "Wealthy Butler".
        You have access to the user's financial summary:
        \(context)
        
        RULES:
        - Be polite but VERY CONCISE.
        - **Limit your response to 2-3 sentences max.**
        - Avoid long explanations unless asked.
        - Give prudent financial advice based on the data.
        \(languageInstruction)
        """
        
        // Model-Specific Prompt Formatting
        // 会話履歴を連結したAI入力を作成または更新します。
        var fullPrompt = ""
        
        // この条件が成り立つ場合だけ、続く処理を行います。
        if currentModel.id.contains("gemma") {
             // fullPromptに、右辺の計算結果または取得結果を設定します。
             fullPrompt = "<start_of_turn>user\nSystem Instructions:\n\(systemPrompt)\n\n"
            
            // 配列の各要素を順番に取り出して処理します。
            for (index, msg) in history.enumerated() {
                // この条件が成り立つ場合だけ、続く処理を行います。
                if msg.role == .user {
                    // この条件が成り立つ場合だけ、続く処理を行います。
                    if index > 0 { fullPrompt += "<start_of_turn>user\n" }
                    // fullPrompt +に、右辺の計算結果または取得結果を設定します。
                    fullPrompt += "\(msg.content)<end_of_turn>\n"
                // 直前の条件が成り立たなかった場合の処理へ進みます。
                } else {
                    // fullPrompt +に、右辺の計算結果または取得結果を設定します。
                    fullPrompt += "<start_of_turn>model\n\(msg.content)<end_of_turn>\n"
                // ここまでの処理またはデータ定義を閉じます。
                }
            // ここまでの処理またはデータ定義を閉じます。
            }
            // fullPrompt +に、右辺の計算結果または取得結果を設定します。
            fullPrompt += "<start_of_turn>model\n"
            
        // 直前の条件が成り立たなかった場合の処理へ進みます。
        } else {
            // Llama 3 / Phi-3
            // fullPromptに、右辺の計算結果または取得結果を設定します。
            fullPrompt = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n\(systemPrompt)<|eot_id|>"
            
            // 配列の各要素を順番に取り出して処理します。
            for msg in history {
                // 会話の発言者をモデル用の名前に変換します。
                let roleStr = msg.role == .user ? "user" : "assistant"
                // fullPrompt +に、右辺の計算結果または取得結果を設定します。
                fullPrompt += "<|start_header_id|>\(roleStr)<|end_header_id|>\n\n\(msg.content)<|eot_id|>"
            // ここまでの処理またはデータ定義を閉じます。
            }
            
            // fullPrompt +に、右辺の計算結果または取得結果を設定します。
            fullPrompt += "<|start_header_id|>assistant<|end_header_id|>\n\n"
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // 処理の状況を開発用ログへ出力します。
        print("DEBUG: Sending Prompt (Model: \(currentModel.name))\nFormat: \(currentModel.id.contains("gemma") ? "Gemma" : "Llama")")
        // 計算または取得した値を呼び出し元へ返します。
        return try await generate(container: container, formattedPrompt: fullPrompt, temperature: 0.6)
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // 家計情報から短い助言をAIに作らせる入口を定義します。
    func generateAdvice(context: String) async throws -> String {
        // 必要な値があるか確かめ、なければ後続の処理を止めます。
        guard let container = modelContainer else {
            // 必要なAIモデルが読み込まれていないことをエラーとして伝えます。
            throw NSError(domain: "LocalLLMService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // Ticker Language Logic
        // AIが使う言語の指示を作成または更新します。
        var languageInstruction = ""
        // この条件が成り立つ場合だけ、続く処理を行います。
        if tickerLanguage == "日本語" {
            // languageInstructionに、右辺の計算結果または取得結果を設定します。
            languageInstruction = "- **ALWAYS OUTPUT IN JAPANESE**. Do not use English."
        // 直前の条件が成り立たなかった場合の処理へ進みます。
        } else {
            // languageInstructionに、右辺の計算結果または取得結果を設定します。
            languageInstruction = "- **ALWAYS OUTPUT IN ENGLISH**."
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // AIに守らせる指示文を作成または更新します。
        let systemPrompt = """
        You are a witty and humorous financial butler.
        Generate a VERY SHORT (under 25 words) daily advice based on the context.
        
        REQUIRED STYLE:
        - Be funny, slightly sarcastic, or playful.
        - Include a "Lucky Item" or "Fortune" at the end.
        \(languageInstruction)
        
        Context: \(context)
        """
        
        // モデル形式に合わせた指示文を作成または更新します。
        let formattedPrompt = """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        \(systemPrompt)<|eot_id|><|start_header_id|>user<|end_header_id|>
        Give me today's advice.<|eot_id|><|start_header_id|>assistant<|end_header_id|>
        """
        
        // 計算または取得した値を呼び出し元へ返します。
        return try await generate(container: container, formattedPrompt: formattedPrompt, temperature: 0.7)
    // ここまでの処理またはデータ定義を閉じます。
    }

    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // 渡された情報から文字列やAIの回答を生成する入口を定義します。
    private func generate(container: ModelContainer, formattedPrompt: String, temperature: Float) async throws -> String {
        // isThinkingに、右辺で指定した値を設定します。
        self.isThinking = true
        // この関数を抜けるときに必ず実行する後片付けを登録します。
        defer { self.isThinking = false }
        
        // 認識文字列、店名、金額を一つの結果にまとめます。
        let result: GenerateResult = try await container.perform { (context: ModelContext) -> GenerateResult in
            // 組み立てた文章をAIモデルの入力形式に包みます。
            let userInput = UserInput(prompt: formattedPrompt)
            // 文章をトークン化して、モデルに渡せる形式へ準備します。
            let input = try await context.processor.prepare(input: userInput)
            
            // AIが文章を生成するときの設定を作ります。
            var params = GenerateParameters()
            // params.temperatureに、右辺の計算結果または取得結果を設定します。
            params.temperature = temperature
            // params.maxTokensに、右辺の計算結果または取得結果を設定します。
            params.maxTokens = 1024
            
            // 生成終了を示すトークンのIDを取り出します。
            let eosTokenId = context.tokenizer.eosTokenId
            
            // MLXへ入力と生成条件を渡して文章を生成します。
            return try MLXLMCommon.generate(
                // 直前に定義した処理へ、この設定または引数を追加します。
                input: input,
                // 直前に定義した処理へ、この設定または引数を追加します。
                parameters: params,
                // 直前に定義した処理へ、この設定または引数を追加します。
                context: context
            // ここで引数を閉じ、直前の呼び出しを完成させます。
            ) { (tokens: [Int]) -> GenerateDisposition in
                // この条件が成り立つ場合だけ、続く処理を行います。
                if let eosId = eosTokenId, tokens.contains(eosId) { return .stop }
                // この条件が成り立つ場合だけ、続く処理を行います。
                if tokens.contains(128009) { return .stop } // <|eot_id|>
                // この条件が成り立つ場合だけ、続く処理を行います。
                if tokens.contains(128001) { return .stop } // <|end_of_text|>
                // 計算または取得した値を呼び出し元へ返します。
                return .more
            // ここまでの処理またはデータ定義を閉じます。
            }
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 計算または取得した値を呼び出し元へ返します。
        return result.output
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}
