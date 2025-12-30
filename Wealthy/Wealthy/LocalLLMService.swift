import Foundation
import MLX
import MLXRandom
import MLXNN
import MLXLLM
import MLXLMCommon
import Tokenizers
import SwiftUI

@Observable
class LocalLLMService {
    static let shared = LocalLLMService()
    
    struct AIModel: Identifiable, Equatable, Hashable {
        let id: String
        let name: String
        let repoId: String
    }
    
    // Available Models
    // Available Models
    let availableModels: [AIModel] = [
        AIModel(id: "phi", name: "Phi 3.5 Mini", repoId: "mlx-community/Phi-3.5-mini-instruct-4bit"),
        AIModel(id: "llama", name: "Llama 3.2 3B", repoId: "mlx-community/Llama-3.2-3B-Instruct-4bit"),
        AIModel(id: "lfm", name: "LFM2 2.6B Exp", repoId: "mlx-community/LFM2-2.6B-Exp-4bit"),
        AIModel(id: "gemma", name: "Gemma 3n E2B", repoId: "mlx-community/gemma-3n-E2B-it-lm-4bit")
    ]
    
    var outputText: String = ""
    var isThinking: Bool = false
    var loadStatus: String = "未インストール"
    @MainActor var downloadProgress: Double = 0.0
    
    // Ticker Language Setting
    @MainActor var tickerLanguage: String {
        get { UserDefaults.standard.string(forKey: "aiTickerLanguage") ?? "日本語" }
        set { UserDefaults.standard.set(newValue, forKey: "aiTickerLanguage") }
    }
    
    @MainActor
    func setTickerLanguage(_ language: String) {
        tickerLanguage = language
    }
    
    @MainActor var isModelInstalled: Bool {
        get { UserDefaults.standard.bool(forKey: "isModelInstalled_\(currentModelId)") }
        set { UserDefaults.standard.set(newValue, forKey: "isModelInstalled_\(currentModelId)") }
    }
    
    // Check status for any model
    func isInstalled(modelId: String) -> Bool {
        // Simple check: user default flag + directory existence check could be better but heavy?
        // For now, rely on flag, but physical delete clears it.
        return UserDefaults.standard.bool(forKey: "isModelInstalled_\(modelId)")
    }
    
    // Store Selected Model ID
    @MainActor var currentModelId: String {
        get { UserDefaults.standard.string(forKey: "selectedAIModelId") ?? "phi" }
        set { UserDefaults.standard.set(newValue, forKey: "selectedAIModelId") }
    }
    
    var currentModel: AIModel {
        availableModels.first(where: { $0.id == currentModelId }) ?? availableModels[0]
    }
    
    // ... [Rest of setModel, loadModel, deleteModel remains mostly same until Chat Logic] ...
    
    private var modelContainer: ModelContainer?
    private var backgroundTask: Task<Void, Never>?
    
    @MainActor
    func setModel(_ model: AIModel) async {
        if currentModelId != model.id {
            currentModelId = model.id
            // Force reload
            print("Switched model to: \(model.name)")
            self.loadStatus = "モデル切り替え: \(model.name)"
            await loadModel()
        }
    }
    
    @MainActor
    func startBackgroundDownload(model: AIModel) {
        // Just set the ID, don't wait. Task will run in background.
        currentModelId = model.id
        self.loadStatus = "ダウンロード準備中... (\(model.name))"
        
        // Cancel existing task if any
        backgroundTask?.cancel()
        
        backgroundTask = Task.detached { 
            await self.loadModel()
        }
    }
    
    @MainActor
    func loadModel() async {
        self.loadStatus = "モデルを確認中... (\(currentModel.name))"
        self.downloadProgress = 0.0
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
        
        do {
            let modelConfiguration = ModelConfiguration(id: currentModel.repoId)
            let factory = LLMModelFactory.shared
            
            self.loadStatus = "準備を開始..."
            print("Loading Model: \(currentModel.repoId)")
            
            // This loadContainer call downloads if needed
            self.modelContainer = try await factory.loadContainer(
                configuration: modelConfiguration
            ) { progress in
                Task { @MainActor in
                    self.downloadProgress = progress.fractionCompleted
                    self.loadStatus = "ダウンロード中: \(Int(progress.fractionCompleted * 100))%"
                }
            }
            
            self.isModelInstalled = true // Sets specific flag for currentModelId
            self.loadStatus = "準備完了 (\(currentModel.name))"
            print("\(currentModel.name) Loaded Successfully!")
            
        } catch {
            self.loadStatus = "エラー発生: \(error.localizedDescription)"
            print("Model Load Error: \(error)")
        }
    }
    
    @MainActor
    func deleteModel() {
        deleteModel(id: currentModelId)
    }
    
    @MainActor
    func deleteModel(id: String) {
        // 1. Identify Model
        guard let model = availableModels.first(where: { $0.id == id }) else { return }
        
        // 2. Unset Flag
        UserDefaults.standard.set(false, forKey: "isModelInstalled_\(id)")
        
        // 3. Clear Memory if current
        if id == currentModelId {
            self.loadStatus = "未インストール"
            self.modelContainer = nil
        }
        
        // 4. Physical Deletion
        let repoId = model.repoId
        let sanitizedRepo = "models--" + repoId.replacingOccurrences(of: "/", with: "--")
        let fileManager = FileManager.default
        
        let searchPaths: [FileManager.SearchPathDirectory] = [.documentDirectory, .applicationSupportDirectory, .cachesDirectory]
        
        for searchPath in searchPaths {
            if let baseURL = fileManager.urls(for: searchPath, in: .userDomainMask).first {
                let potentialPaths = [
                    "huggingface/hub/\(sanitizedRepo)",
                    ".cache/huggingface/hub/\(sanitizedRepo)"
                ]
                
                for subPath in potentialPaths {
                    let cacheDir = baseURL.appendingPathComponent(subPath)
                    if fileManager.fileExists(atPath: cacheDir.path) {
                        do {
                            try fileManager.removeItem(at: cacheDir)
                            print("Deleted model cache at: \(cacheDir.path)")
                        } catch {
                            print("Failed to delete model cache at \(cacheDir.path): \(error)")
                        }
                    }
                }
            }
        }
    }
    
    // Chat Logic
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
        
        // Receipt Extraction logic is generic, but we must enforce valid JSON.
        // We use a strict prompt.
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
        
        return try await generate(container: container, formattedPrompt: formattedPrompt, temperature: 0.1)
    }
    
    @MainActor
    func chat(history: [ChatMessage], context: String) async throws -> String {
        guard let container = modelContainer else {
            throw NSError(domain: "LocalLLMService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        // Adaptive Language Logic
        let languageInstruction = "- **Reply in the same language as the user's input.**"
        
        // Dynamic System Prompt
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
        var fullPrompt = ""
        
        if currentModel.id.contains("gemma") {
             fullPrompt = "<start_of_turn>user\nSystem Instructions:\n\(systemPrompt)\n\n"
            
            for (index, msg) in history.enumerated() {
                if msg.role == .user {
                    if index > 0 { fullPrompt += "<start_of_turn>user\n" }
                    fullPrompt += "\(msg.content)<end_of_turn>\n"
                } else {
                    fullPrompt += "<start_of_turn>model\n\(msg.content)<end_of_turn>\n"
                }
            }
            fullPrompt += "<start_of_turn>model\n"
            
        } else {
            // Llama 3 / Phi-3
            fullPrompt = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n\(systemPrompt)<|eot_id|>"
            
            for msg in history {
                let roleStr = msg.role == .user ? "user" : "assistant"
                fullPrompt += "<|start_header_id|>\(roleStr)<|end_header_id|>\n\n\(msg.content)<|eot_id|>"
            }
            
            fullPrompt += "<|start_header_id|>assistant<|end_header_id|>\n\n"
        }
        
        print("DEBUG: Sending Prompt (Model: \(currentModel.name))\nFormat: \(currentModel.id.contains("gemma") ? "Gemma" : "Llama")")
        return try await generate(container: container, formattedPrompt: fullPrompt, temperature: 0.6)
    }
    
    @MainActor
    func generateAdvice(context: String) async throws -> String {
        guard let container = modelContainer else {
            throw NSError(domain: "LocalLLMService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
        }
        
        // Ticker Language Logic
        var languageInstruction = ""
        if tickerLanguage == "日本語" {
            languageInstruction = "- **ALWAYS OUTPUT IN JAPANESE**. Do not use English."
        } else {
            languageInstruction = "- **ALWAYS OUTPUT IN ENGLISH**."
        }
        
        let systemPrompt = """
        You are a witty and humorous financial butler.
        Generate a VERY SHORT (under 25 words) daily advice based on the context.
        
        REQUIRED STYLE:
        - Be funny, slightly sarcastic, or playful.
        - Include a "Lucky Item" or "Fortune" at the end.
        \(languageInstruction)
        
        Context: \(context)
        """
        
        let formattedPrompt = """
        <|begin_of_text|><|start_header_id|>system<|end_header_id|>
        \(systemPrompt)<|eot_id|><|start_header_id|>user<|end_header_id|>
        Give me today's advice.<|eot_id|><|start_header_id|>assistant<|end_header_id|>
        """
        
        return try await generate(container: container, formattedPrompt: formattedPrompt, temperature: 0.7)
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
            params.maxTokens = 1024
            
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
