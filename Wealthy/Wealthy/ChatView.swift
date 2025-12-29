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
    @Query var assets: [Asset]
    @Query var expenses: [Expense]
    @Query var categories: [Category]
    
    @State private var messages: [LocalLLMService.ChatMessage] = []
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
                                Text(lm.t(.aiButlerWelcome)) // Need to add translation key or string
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                    .padding(.top)
                                
                                ForEach(messages) { msg in
                                    MessageBubble(message: msg)
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
        
        // Add User Message
        let userMsg = LocalLLMService.ChatMessage(role: .user, content: text)
        messages.append(userMsg)
        
        isThinking = true
        
        Task {
            // Build Context
            let context = FinancialDataSummary.generate(
                assets: assets,
                expenses: expenses,
                categories: categories,
                languageManager: lm
            )
            
            do {
                let responseText = try await LocalLLMService.shared.chat(history: messages, context: context)
                
                await MainActor.run {
                    let aiMsg = LocalLLMService.ChatMessage(role: .assistant, content: responseText)
                    messages.append(aiMsg)
                    isThinking = false
                }
            } catch {
                await MainActor.run {
                    let errorMsg = LocalLLMService.ChatMessage(role: .system, content: "Error: \(error.localizedDescription)")
                    messages.append(errorMsg)
                    isThinking = false
                }
            }
        }
    }
    
    private func resetChat() {
        messages = []
    }
}

struct MessageBubble: View {
    let message: LocalLLMService.ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                Image(systemName: "person.crop.circle.badge.checkmark") // Butler Icon
                    .font(.title2)
                    .foregroundStyle(.blue)
            } else if message.role == .system {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.red)
            }
            
            if message.role != .user { Spacer() }
            
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                Text(message.content)
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(bubbleColor)
                    .cornerRadius(16)
            }
            
            if message.role == .user {
                // User Icon or Spacer
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
    
    var bubbleColor: Color {
        switch message.role {
        case .user: return Color.blue.opacity(0.8)
        case .assistant: return Color(white: 0.2)
        case .system: return Color.red.opacity(0.6)
        }
    }
}
