//
//  ChatView.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

// `SwiftUI` の機能をこのファイルで使えるように読み込みます。
import SwiftUI
// `SwiftData` の機能をこのファイルで使えるように読み込みます。
import SwiftData

// `ChatView` という構造体を定義し、関連する値や処理をまとめます。
struct ChatView: View {
    // SwiftUIの環境から`dismiss`を取得します。
    @Environment(\.dismiss) var dismiss
    // 表示言語の管理役を親画面から受け取ります。
    @EnvironmentObject var lm: LanguageManager
    
    // Core Data
    // Core Data
    // SwiftDataから財布・資産を読み、変更を画面に反映します。
    @Query var assets: [Asset]
    // SwiftDataから収支履歴を読み、変更を画面に反映します。
    @Query var expenses: [Expense]
    // SwiftDataからカテゴリを読み、変更を画面に反映します。
    @Query var categories: [Category]
    // SwiftDataから`messages`を読み、変更を画面に反映します。
    @Query(sort: \ChatMessageModel.timestamp) var messages: [ChatMessageModel]
    // SwiftUIの環境からデータ保存用のコンテキストを取得します。
    @Environment(\.modelContext) var modelContext
    
    // `inputText`を画面の状態として保持し、変更時に表示を更新します。
    @State private var inputText: String = ""
    // `isThinking`を画面の状態として保持し、変更時に表示を更新します。
    @State private var isThinking = false
    // `@FocusState private var isInputFocused: Bool` の属性を付け、次の宣言の動作を指定します。
    @FocusState private var isInputFocused: Bool
    
    // 画面に表示する部品の並びを返す `body` を定義します。
    var body: some View {
        // 画面遷移と見出しを管理する領域を作ります。
        NavigationStack {
            // 要素を手前と奥に重ねます。
            ZStack {
                // 画面に色を表示します。
                Color.black.ignoresSafeArea()
                
                // 要素を上から下へ並べます。
                VStack(spacing: 0) {
                    // Chat History
                    // スクロール位置を操作するための `proxy` を受け取ります。
                    ScrollViewReader { proxy in
                        // 内容をスクロールできる領域を作ります。
                        ScrollView {
                            // 要素を上から下へ並べます。
                            VStack(spacing: 16) {
                                // Welcome Message
                                // 文字列を画面に表示します。
                                Text(lm.t(.aiButlerWelcome))
                                    // 文字の大きさや書体を設定します。
                                    .font(.caption)
                                    // 文字やアイコンの色を設定します。
                                    .foregroundStyle(.gray)
                                    // 表示の周囲に余白を設けます。
                                    .padding(.top)
                                
                                // 配列などの各要素について同じ表示を作ります。
                                ForEach(messages, id: \.id) { msg in
                                    // `MessageBubble` を呼び出し、括弧内の値を使って処理します。
                                    MessageBubble(message: msg)
                                // 繰り返し表示の範囲をここで閉じます。
                                }
                                
                                // 指定した値が変わったときの処理を登録します。
                                .onChange(of: messages) {
                                    // `print` を呼び出し、括弧内の値を使って処理します。
                                    print("ChatView: Messages updated. Count: \(messages.count)")
                                // 値が変わったときの処理の範囲をここで閉じます。
                                } 
                                // AIが返答を生成している間だけ、待機中の表示を出します。
                                if isThinking {
                                    // 要素を左から右へ並べます。
                                    HStack {
                                        // 処理の進行状況を示す表示を作ります。
                                        ProgressView()
                                            // 操作部品に使う強調色を設定します。
                                            .tint(.gray)
                                        // 文字列を画面に表示します。
                                        Text("Thinking...")
                                            // 文字の大きさや書体を設定します。
                                            .font(.caption)
                                            // 文字やアイコンの色を設定します。
                                            .foregroundStyle(.gray)
                                        // 空き領域を使って要素間の距離を広げます。
                                        Spacer()
                                    // 横並びの表示の範囲をここで閉じます。
                                    }
                                    // 表示の周囲に余白を設けます。
                                    .padding(.horizontal)
                                // 条件分岐の範囲をここで閉じます。
                                }
                                
                                // 画面に色を表示します。
                                Color.clear.frame(height: 1).id("bottom")
                            // 縦並びの表示の範囲をここで閉じます。
                            }
                            // 表示の周囲に余白を設けます。
                            .padding()
                        // ScrollViewの範囲をここで閉じます。
                        }
                        // 指定した値が変わったときの処理を登録します。
                        .onChange(of: messages) { proxy.scrollTo("bottom", anchor: .bottom) }
                        // 指定した値が変わったときの処理を登録します。
                        .onChange(of: isThinking) { if isThinking { proxy.scrollTo("bottom", anchor: .bottom) } }
                    // 直前の処理の範囲をここで閉じます。
                    }
                    
                    // Input Area
                    // 要素を左から右へ並べます。
                    HStack(alignment: .bottom) {
                        // 文字を入力する欄を配置します。
                        TextField(lm.t(.askAnything), text: $inputText, axis: .vertical)
                            // 表示の周囲に余白を設けます。
                            .padding(12)
                            // 背景の色や形を設定します。
                            .background(Color(white: 0.15))
                            // 表示の角を丸くします。
                            .cornerRadius(20)
                            // 文字やアイコンの色を設定します。
                            .foregroundStyle(.white)
                            // 入力欄のフォーカス状態を結び付けます。
                            .focused($isInputFocused)
                            // 表示する文章の行数を制限します。
                            .lineLimit(1...5)
                        
                        // タップで処理を実行するボタンを配置します。
                        Button {
                            // `sendMessage` を呼び出し、括弧内の値を使って処理します。
                            sendMessage()
                        // ボタンの処理の範囲をここで閉じます。
                        } label: {
                            // 画像またはシステムアイコンを表示します。
                            Image(systemName: "arrow.up.circle.fill")
                                // 文字の大きさや書体を設定します。
                                .font(.system(size: 32))
                                // 文字やアイコンの色を設定します。
                                .foregroundStyle(inputText.isEmpty || isThinking ? .gray : .blue)
                        // } label:の範囲をここで閉じます。
                        }
                        // 条件に応じて操作を無効にします。
                        .disabled(inputText.isEmpty || isThinking)
                    // 横並びの表示の範囲をここで閉じます。
                    }
                    // 表示の周囲に余白を設けます。
                    .padding()
                    // 背景の色や形を設定します。
                    .background(Color(white: 0.1))
                // 縦並びの表示の範囲をここで閉じます。
                }
            // 重ねた表示の範囲をここで閉じます。
            }
            // 画面上部の見出しを設定します。
            .navigationTitle(lm.t(.aiButler))
            // 見出しの表示形式を設定します。
            .navigationBarTitleDisplayMode(.inline)
            // 操作欄の配色を設定します。
            .toolbarColorScheme(.dark, for: .navigationBar)
            // 画面上部の操作項目を設定します。
            .toolbar {
                // 画面上部の操作項目を追加します。
                ToolbarItem(placement: .topBarLeading) {
                    // タップで処理を実行するボタンを配置します。
                    Button(lm.t(.close)) { dismiss() }
                // 開いていた画面部品や処理の範囲を閉じます。
                }
                // 画面上部の操作項目を追加します。
                ToolbarItem(placement: .topBarTrailing) {
                    // タップで処理を実行するボタンを配置します。
                    Button(action: resetChat) {
                        // 画像またはシステムアイコンを表示します。
                        Image(systemName: "trash")
                    // ボタンの処理の範囲をここで閉じます。
                    }
                // 開いていた画面部品や処理の範囲を閉じます。
                }
            // .toolbarの範囲をここで閉じます。
            }
        // 画面遷移の範囲をここで閉じます。
        }
    // 画面構成の範囲をここで閉じます。
    }
    
    // `sendMessage` という関数を定義し、括弧内の入力を使って処理します。
    private func sendMessage() {
        // 入力欄が空なら送る内容がないため、メッセージ送信を終了します。
        guard !inputText.isEmpty else { return }
        // `text`を変更できない値として作り、右辺の結果を保存します。
        let text = inputText
        // `inputText`へ `""` の結果を代入します。
        inputText = ""
        // `isInputFocused`をオフにし、対応する状態を更新します。
        isInputFocused = false
        
        // Add User Message (Persist)
        // `userMsg`を変更できない値として作り、右辺の結果を保存します。
        let userMsg = ChatMessageModel(role: "user", content: text)
        // 利用者が送ったメッセージを保存対象に追加します。
        modelContext.insert(userMsg)
        // 失敗する可能性がある処理を試し、失敗時は結果を空にします。
        try? modelContext.save()
        
        // `isThinking`をオンにし、対応する状態を更新します。
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
        
        // `existingHistory`を変更できない値として作り、右辺の結果を保存します。
        let existingHistory = messages.map {
             // 保存済みメッセージの役割と本文をAIへ渡す形式に変換します。
             LocalLLMService.ChatMessage(role: $0.role, content: $0.content)
        // 開いていた画面部品や処理の範囲を閉じます。
        }
        // `currentHistoryItem`を変更できない値として作り、右辺の結果を保存します。
        let currentHistoryItem = LocalLLMService.ChatMessage(role: .user, content: text)
        // `history`を変更できない値として作り、右辺の結果を保存します。
        let history = existingHistory + [currentHistoryItem]
        
        // 時間のかかる非同期処理を開始します。
        Task {
            // Build Context
            // `context`を変更できない値として作り、右辺の結果を保存します。
            let context = FinancialDataSummary.generate(
                // `assets` という引数・項目に続く値を指定します。
                assets: assets,
                // `expenses` という引数・項目に続く値を指定します。
                expenses: expenses,
                // `categories` という引数・項目に続く値を指定します。
                categories: categories,
                // `languageManager` という引数・項目に続く値を指定します。
                languageManager: lm
            // 非同期処理の範囲をここで閉じます。
            )
            
            // 失敗する可能性がある処理を実行する範囲を始めます。
            do {
                // `responseText`を変更できない値として作り、右辺の結果を保存します。
                let responseText = try await LocalLLMService.shared.chat(history: history, context: context)
                
                // Debug log
                // `print` を呼び出し、括弧内の値を使って処理します。
                print("AI Response: \(responseText)") // For console debugging
                
                // `MainActor.run {` が終わるまで待ってから次へ進みます。
                await MainActor.run {
                    // `aiMsg`を変更できない値として作り、右辺の結果を保存します。
                    let aiMsg = ChatMessageModel(role: "assistant", content: responseText)
                    // AIからの返答を保存対象に追加します。
                    modelContext.insert(aiMsg)
                    // 失敗する可能性がある処理を試し、失敗時は結果を空にします。
                    try? modelContext.save()
                    // `isThinking`をオフにし、対応する状態を更新します。
                    isThinking = false
                // await MainActor.runの範囲をここで閉じます。
                }
            // 直前の処理でエラーが起きたときの処理を始めます。
            } catch {
                // `MainActor.run {` が終わるまで待ってから次へ進みます。
                await MainActor.run {
                    // `errorMsg`を変更できない値として作り、右辺の結果を保存します。
                    let errorMsg = ChatMessageModel(role: "system", content: "Error: \(error.localizedDescription)")
                    // エラーを知らせるメッセージを保存対象に追加します。
                    modelContext.insert(errorMsg)
                    // 失敗する可能性がある処理を試し、失敗時は結果を空にします。
                    try? modelContext.save()
                    // `isThinking`をオフにし、対応する状態を更新します。
                    isThinking = false
                // await MainActor.runの範囲をここで閉じます。
                }
            // } catchの範囲をここで閉じます。
            }
        // 非同期処理の範囲をここで閉じます。
        }
    // 関数の範囲をここで閉じます。
    }
    
    // `resetChat` という関数を定義し、括弧内の入力を使って処理します。
    private func resetChat() {
        // この中で変える画面状態にアニメーション設定を適用します。
        withAnimation {
            // `msg in messages` の要素を順番に処理します。
            for msg in messages {
                // 指定された会話メッセージを保存データから削除します。
                modelContext.delete(msg)
            // 繰り返しの範囲をここで閉じます。
            }
        // withAnimationの範囲をここで閉じます。
        }
    // 関数の範囲をここで閉じます。
    }
// 構造体の範囲をここで閉じます。
}

// `MessageBubble` という構造体を定義し、関連する値や処理をまとめます。
struct MessageBubble: View {
    // `message`を変更できない値として作り、右辺の結果を保存します。
    let message: ChatMessageModel
    
    // 画面に表示する部品の並びを返す `body` を定義します。
    var body: some View {
        // 要素を左から右へ並べます。
        HStack(alignment: .top, spacing: 12) {
            // MARK: - Assistant Leading
            // 利用者以外のメッセージなら、AI側の表示を使います。
            if message.role != .user {
                // 画像またはシステムアイコンを表示します。
                Image(systemName: "person.crop.circle.badge.checkmark") // Butler Icon
                    // 文字の大きさや書体を設定します。
                    .font(.title2)
                    // 文字やアイコンの色を設定します。
                    .foregroundStyle(.blue)
            // 条件分岐の範囲をここで閉じます。
            }
            
            // Spacer if User (pushes content to right)
            // 利用者のメッセージなら、利用者側の表示を使います。
            if message.role == .user {
                // 空き領域を使って要素間の距離を広げます。
                Spacer()
            // 条件分岐の範囲をここで閉じます。
            }
            
            // 要素を上から下へ並べます。
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                // 文字列を画面に表示します。
                Text(message.content)
                    // 文字やアイコンの色を設定します。
                    .foregroundStyle(.white)
                    // 表示の周囲に余白を設けます。
                    .padding(12)
                    // 背景の色や形を設定します。
                    .background(bubbleColor)
                    // 表示の角を丸くします。
                    .cornerRadius(16)
            // 縦並びの表示の範囲をここで閉じます。
            }
            
            // Spacer if Assistant (pushes content to left)
            // 利用者以外のメッセージなら、AI側の表示を使います。
            if message.role != .user {
                // 空き領域を使って要素間の距離を広げます。
                Spacer()
            // 条件分岐の範囲をここで閉じます。
            }
        // 横並びの表示の範囲をここで閉じます。
        }
    // 画面構成の範囲をここで閉じます。
    }
    
    // `bubbleColor`を表す変更可能な値または計算結果を定義します。
    var bubbleColor: Color {
        // 利用者のメッセージなら、利用者側の表示を使います。
        if message.role == .user {
            // `Color.blue.opacity(0.8)` の結果を呼び出し元へ返します。
            return Color.blue.opacity(0.8)
        // 前の条件が成り立たず、続く条件が成り立つ場合の処理に進みます。
        } else if message.role == .system {
            // `Color.red.opacity(0.6)` の結果を呼び出し元へ返します。
            return Color.red.opacity(0.6)
        // 前の条件に当てはまらない場合の処理に進みます。
        } else {
            // `Color(white: 0.2) // Assistant` の結果を呼び出し元へ返します。
            return Color(white: 0.2) // Assistant
        // } elseの範囲をここで閉じます。
        }
    // var bubbleColor: Colorの範囲をここで閉じます。
    }
// 構造体の範囲をここで閉じます。
}
