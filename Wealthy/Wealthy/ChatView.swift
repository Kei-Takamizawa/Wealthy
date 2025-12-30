//
//  ChatView.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lm: LanguageManager
    
    // Core Data
    // Core Data
    @Query var assets: [Asset]
    @Query var expenses: [Expense]
    @Query var categories: [Category]
    @Query(sort: \ChatMessageModel.timestamp) var messages: [ChatMessageModel]
    @Environment(\.modelContext) var modelContext
    
    @State private var inputText: String = ""
    @State private var isThinking = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Chat History
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 16) {
                                // Welcome Message
                                Text(lm.t(.aiButlerWelcome))
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .padding(.top)
                                
                                ForEach(messages, id: \.id) { msg in
                                    MessageBubble(message: msg)
                                }
                                
                                .onChange(of: messages) {
                                    print("ChatView: Messages updated. Count: \(messages.count)")
                                } 
                                if isThinking {
                                    HStack {
                                        ProgressView()
                                            .tint(.gray)
                                        Text("Thinking...")
                                            .font(.caption)
                                            .foregroundStyle(.gray)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                                
                                Color.clear.frame(height: 1).id("bottom")
                            }
                            .padding()
                        }
                        .onChange(of: messages) { proxy.scrollTo("bottom", anchor: .bottom) }
                        .onChange(of: isThinking) { if isThinking { proxy.scrollTo("bottom", anchor: .bottom) } }
                    }
                    
                    // Input Area
                    HStack(alignment: .bottom) {
                        TextField(lm.t(.askAnything), text: $inputText, axis: .vertical)
                            .padding(12)
                            .background(Color(white: 0.15))
                            .cornerRadius(20)
                            .foregroundStyle(.white)
                            .focused($isInputFocused)
                            .lineLimit(1...5)
                        
                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(inputText.isEmpty || isThinking ? .gray : .blue)
                        }
                        .disabled(inputText.isEmpty || isThinking)
                    }
                    .padding()
                    .background(Color(white: 0.1))
                }
            }
            .navigationTitle(lm.t(.aiButler))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(lm.t(.close)) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: resetChat) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let text = inputText
        inputText = ""
        isInputFocused = false
        
        // Add User Message (Persist)
        let userMsg = ChatMessageModel(role: "user", content: text)
        modelContext.insert(userMsg)
        try? modelContext.save()
        
        isThinking = true
        
        // Prepare history for AI
        // Convert SwiftData models to LocalLLMService structs
        // We use the current state of messages (which includes the new userMsg because of @Query, 
        // but timing might be tricky. Safer to construct it manually or fetch sort.)
        // Actually, @Query updates might not be instant in this scope.
        // Better to construct history: existing messages + current one.
        
        // Create explicit history list
        // Important: SwiftData Query might not have updated yet to include `userMsg`.
        // Also we don't want to double count.
        // Let's create a stable list from current `messages` + our new input.
        // BUT `messages` (Query) is a live view. If we blocked main thread, it won't update.
        // The safest way: Map existing `messages` (from Query which represents OLD state before insert propagates to view? Or after?)
        // Actually, since we just inserted `userMsg`, it might appear in `messages` on next run loop.
        // To be safe: Filter `messages` to EXCLUDE the one we just made (by ID if possible, but we didn't save ID).
        // Simplest strategy: Convert `messages` to array, and append `userMsg` manually IF it's not seemingly there.
        // OR: Just trust `messages` will update eventually, but for the API call we need instant history.
        
        let existingHistory = messages.map {
             LocalLLMService.ChatMessage(role: $0.role, content: $0.content)
        }
        let currentHistoryItem = LocalLLMService.ChatMessage(role: .user, content: text)
        let history = existingHistory + [currentHistoryItem]
        
        Task {
            // Build Context
            let context = FinancialDataSummary.generate(
                assets: assets,
                expenses: expenses,
                categories: categories,
                languageManager: lm
            )
            
            do {
                let responseText = try await LocalLLMService.shared.chat(history: history, context: context)
                
                // Debug log
                print("AI Response: \(responseText)") // For console debugging
                
                await MainActor.run {
                    let aiMsg = ChatMessageModel(role: "assistant", content: responseText)
                    modelContext.insert(aiMsg)
                    try? modelContext.save()
                    isThinking = false
                }
            } catch {
                await MainActor.run {
                    let errorMsg = ChatMessageModel(role: "system", content: "Error: \(error.localizedDescription)")
                    modelContext.insert(errorMsg)
                    try? modelContext.save()
                    isThinking = false
                }
            }
        }
    }
    
    private func resetChat() {
        withAnimation {
            for msg in messages {
                modelContext.delete(msg)
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessageModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // MARK: - Assistant Leading
            if message.role != .user {
                Image(systemName: "person.crop.circle.badge.checkmark") // Butler Icon
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            
            // Spacer if User (pushes content to right)
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                Text(message.content)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(bubbleColor)
                    .cornerRadius(16)
            }
            
            // Spacer if Assistant (pushes content to left)
            if message.role != .user {
                Spacer()
            }
        }
    }
    
    var bubbleColor: Color {
        if message.role == .user {
            return Color.blue.opacity(0.8)
        } else if message.role == .system {
            return Color.red.opacity(0.6)
        } else {
            return Color(white: 0.2) // Assistant
        }
    }
}
