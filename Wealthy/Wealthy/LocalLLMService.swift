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
    
    @MainActor
    func generateResponse(prompt: String, categories: [String]) async throws -> String {
        guard let container = modelContainer else {
            throw NSError(domain: "LocalLLMService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        return try await generateInternal(container: container, prompt: prompt, categories: categories)
    }

    @MainActor
    private func generateInternal(container: ModelContainer, prompt: String, categories: [String]) async throws -> String {
        self.isThinking = true
        defer { self.isThinking = false }
        
        let categoryListString = categories.map { "\"\($0)\"" }.joined(separator: ", ")
        
        // レシート解析用の厳格なシステムプロンプト (日付追加)
        let systemPrompt = """
        You are a receipt scanner assistant. Extract "Shop Name", "Total Amount", and "Date" from the OCR text.
        Also classify the receipt into one of these categories: [\(categoryListString)].
        Output JSON ONLY. Format: {"shopName": "Store Name", "amount": 1000, "category": "CategoryName", "date": "YYYY-MM-DD"}
        If amount is unknown, set to 0. If category is unclear, choose "Others". If date is unknown, use null.
        NO markdown, NO explanations.
        """
        
        let formattedPrompt = """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        
        \(systemPrompt)<|eot_id|><|start_header_id|>user<|end_header_id|>
        
        \(prompt)<|eot_id|><|start_header_id|>assistant<|end_header_id|>
        
        """
        
        // fullOutput removed
        
        let result: GenerateResult = try await container.perform { (context: ModelContext) -> GenerateResult in
            let userInput = UserInput(prompt: formattedPrompt)
            let input = try await context.processor.prepare(input: userInput)
            
            var params = GenerateParameters()
            params.temperature = 0.1
            params.maxTokens = 512
            
            let eosTokenId = context.tokenizer.eosTokenId
            
            return try MLXLMCommon.generate(
                input: input,
                parameters: params,
                context: context
            ) { (tokens: [Int]) -> GenerateDisposition in
                
                let text = context.tokenizer.decode(tokens: tokens)
                // fullOutput accumulation removed
                
                if let eosId = eosTokenId, tokens.contains(eosId) { return .stop }
                if tokens.contains(128009) { return .stop }
                if tokens.contains(128001) { return .stop }
                
                return .more
            }
        }
        return result.output
    }
}
