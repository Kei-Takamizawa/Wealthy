import Foundation
import MLX
import MLXRandom
import MLXNN
import MLXLLM
import MLXLMCommon
import Tokenizers

@Observable
class LocalLLMService {
    static let shared = LocalLLMService()
    
    var outputText: String = ""
    var isThinking: Bool = false
    var loadStatus: String = "未インストール"
    @MainActor var downloadProgress: Double = 0.0
    @MainActor var isModelInstalled: Bool {
        get { UserDefaults.standard.bool(forKey: "isModelInstalled") }
        set { UserDefaults.standard.set(newValue, forKey: "isModelInstalled") }
    }
    
    private var modelContainer: ModelContainer?
    private let modelId = "mlx-community/Llama-3.2-3B-Instruct-4bit"
    
    @MainActor
    func loadModel() async {
        self.loadStatus = "モデルを確認中..."
        self.downloadProgress = 0.0
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
        
        do {
            let modelConfiguration = ModelConfiguration(id: modelId)
            let factory = LLMModelFactory.shared
            
            self.loadStatus = "準備を開始..."
            
            self.modelContainer = try await factory.loadContainer(
                configuration: modelConfiguration
            ) { progress in
                Task { @MainActor in
                    self.downloadProgress = progress.fractionCompleted
                    self.loadStatus = "ダウンロード中: \(Int(progress.fractionCompleted * 100))%"
                    // ダウンロード中はインストールフラグをfalseにしておく
                    self.isModelInstalled = false
                }
            }
            
            self.isModelInstalled = true // 成功したらフラグを立てる
            self.loadStatus = "準備完了"
            print("Llama 3 Loaded Successfully!")
            
        } catch {
            self.loadStatus = "エラー発生: \(error.localizedDescription)"
            print("Model Load Error: \(error)")
            self.isModelInstalled = false // 失敗ならフラグを下げる
        }
    }
    
    // モデル削除機能
    @MainActor
    func deleteModel() {
        // MLXのキャッシュディレクトリ等は隠蔽されていることが多いが、
        // 簡易的にフラグを落とし、次回ロード時に上書き/再取得させる運用にする。
        // 本当はファイル削除が望ましいが、MLXLMFactoryの仕様依存。
        // ここでは「使用停止」として扱う。
        self.isModelInstalled = false
        self.loadStatus = "未インストール"
        self.modelContainer = nil
    }
    
    // チャット用メッセージ構造体
    struct ChatMessage: Identifiable, Equatable {
        let id = UUID()
        let role: MessageRole
        let content: String
        
        enum MessageRole {
            case user, assistant, system
        }
    }

    @MainActor
    func extractReceiptData(prompt: String, categories: [String]) async throws -> String {
        guard let container = modelContainer else {
            throw NSError(domain: "LocalLLMService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        let categoryListString = categories.map { "\"\($0)\"" }.joined(separator: ", ")
        
        // 1. System Prompt: Role & Constraints for Receipt
        let systemPrompt = """
        You are a Receipt Information Extractor. Your job is to extract specific data from receipt OCR text and output strict JSON.
        
        TARGET DATA:
        - "shopName": The name of the store (often at the top).
        - "amount": The total paid amount (look for "TOTAL", "合計", "支払", or the largest logical number).
        - "category": Choose the best fit from this list: [\(categoryListString)]. If unsure, use "未分類".
        - "date": The transaction date in "YYYY-MM-DD" format.
        
        RULES:
        - Output ONLY valid JSON.
        - DO NOT return Markdown (no ```json).
        - DO NOT explain your reasoning.
        - If multiple candidates exist for Shop Name, pick the most prominent text at the header.
        - If amount is ambiguous, prefer the number following "Total" or "合計".
        """
        
        // 2. One-Shot Example
        let exampleInput = """
        RECEIPT
        Store ABC
        2023-10-25 14:30
        Item A   1000
        Item B    500
        Total    1500
        """
        let exampleOutput = "{\"shopName\": \"Store ABC\", \"amount\": 1500, \"category\": \"食費\", \"date\": \"2023-10-25\"}"
        
        // 3. Final Prompt Construction
        let formattedPrompt = """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        
        \(systemPrompt)<|eot_id|><|start_header_id|>user<|end_header_id|>
        
        Example Input:
        \(exampleInput)
        
        Example Output:
        \(exampleOutput)
        
        Actual Input:
        \(prompt)<|eot_id|><|start_header_id|>assistant<|end_header_id|>
        
        """
        
        return try await generate(container: container, formattedPrompt: formattedPrompt, temperature: 0.1)
    }
    
    @MainActor
    func chat(history: [ChatMessage], context: String) async throws -> String {
        guard let container = modelContainer else {
            throw NSError(domain: "LocalLLMService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        // システムプロンプト + コンテキスト (Butler Role)
        let systemPrompt = """
        You are a helpful and intelligent financial butler for the user.
        Your name is "Wealthy Butler".
        You have access to the user's financial summary provided below.
        
        FINANCIAL CONTEXT:
        \(context)
        
        RULES:
        - Be polite, professional, yet friendly.
        - Analyze the data provided in the context to answer questions.
        - If asked about future advice, give constructive and prudent financial advice based on the data.
        - If the user speaks Japanese, reply in Japanese.
        - Keep answers concise unless asked for details.
        """
        
        var fullPrompt = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n\(systemPrompt)<|eot_id|>"
        
        for msg in history {
            let roleStr = msg.role == .user ? "user" : "assistant"
            fullPrompt += "<|start_header_id|>\(roleStr)<|end_header_id|>\n\n\(msg.content)<|eot_id|>"
        }
        
        fullPrompt += "<|start_header_id|>assistant<|end_header_id|>\n\n"
        
        return try await generate(container: container, formattedPrompt: fullPrompt, temperature: 0.7)
    }

    @MainActor
    private func generate(container: ModelContainer, formattedPrompt: String, temperature: Float) async throws -> String {
        self.isThinking = true
        defer { self.isThinking = false }
        
        let result: GenerateResult = try await container.perform { (context: ModelContext) -> GenerateResult in
            let userInput = UserInput(prompt: formattedPrompt)
            let input = try await context.processor.prepare(input: userInput)
            
            var params = GenerateParameters()
            params.temperature = temperature
            params.maxTokens = 1024 // Increased for chat
            
            let eosTokenId = context.tokenizer.eosTokenId
            
            return try MLXLMCommon.generate(
                input: input,
                parameters: params,
                context: context
            ) { (tokens: [Int]) -> GenerateDisposition in
                if let eosId = eosTokenId, tokens.contains(eosId) { return .stop }
                if tokens.contains(128009) { return .stop } // <|eot_id|>
                if tokens.contains(128001) { return .stop } // <|end_of_text|>
                return .more
            }
        }
        return result.output
    }
}
