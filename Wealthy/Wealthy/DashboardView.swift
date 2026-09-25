//
//  DashboardView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

// `SwiftUI` の機能をこのファイルで使えるように読み込みます。
import SwiftUI
// `SwiftData` の機能をこのファイルで使えるように読み込みます。
import SwiftData
// `UniformTypeIdentifiers` の機能をこのファイルで使えるように読み込みます。
import UniformTypeIdentifiers

// `DashboardView` という構造体を定義し、関連する値や処理をまとめます。
struct DashboardView: View {
    // ■ 言語マネージャーを受け取る
    // 表示言語の管理役を親画面から受け取ります。
    @EnvironmentObject var lm: LanguageManager
    
    // SwiftDataから収支履歴を読み、変更を画面に反映します。
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    // SwiftDataから財布・資産を読み、変更を画面に反映します。
    @Query var assets: [Asset]
    // SwiftDataからカテゴリを読み、変更を画面に反映します。
    @Query var categories: [Category]
    // SwiftUIの環境からデータ保存用のコンテキストを取得します。
    @Environment(\.modelContext) var modelContext
    
    // スキャナーの表示状態を画面の状態として保持し、変更時に表示を更新します。
    @State private var showScanner = false
    // 入金画面の表示状態を画面の状態として保持し、変更時に表示を更新します。
    @State private var showDeposit = false
    // 撮影したレシート画像を画面の状態として保持し、変更時に表示を更新します。
    @State private var scannedImage: UIImage?
    // 編集中の収支を画面の状態として保持し、変更時に表示を更新します。
    @State private var expenseToEdit: Expense?
    // 新規入力かどうかを画面の状態として保持し、変更時に表示を更新します。
    @State private var isNewEditingEntry = false
    // `sortOption`を画面の状態として保持し、変更時に表示を更新します。
    @State private var sortOption = SortOption.dateDesc
    
    // `SortOption` という選択肢の型を定義し、関連する値や処理をまとめます。
    enum SortOption { case dateDesc, dateAsc, amountDesc, amountAsc }
    
    // `sortedExpenses`を表す変更可能な値または計算結果を定義します。
    var sortedExpenses: [Expense] { /* 変更なし */
        // 値に応じて実行する処理を分けます。
        switch sortOption {
        // 新しい日付から順に収支履歴を並べて返します。
        case .dateDesc: return expenses.sorted { $0.date > $1.date }
        // 古い日付から順に収支履歴を並べて返します。
        case .dateAsc: return expenses.sorted { $0.date < $1.date }
        // 金額の大きい順に収支履歴を並べて返します。
        case .amountDesc: return expenses.sorted { $0.amount > $1.amount }
        // 金額の小さい順に収支履歴を並べて返します。
        case .amountAsc: return expenses.sorted { $0.amount < $1.amount }
        // 条件の振り分けの範囲をここで閉じます。
        }
    // 直前の処理の範囲をここで閉じます。
    }
    // `totalBalance`を表す変更可能な値または計算結果を定義します。
    var totalBalance: Int { assets.reduce(0) { $0 + $1.balance } }
    
    // 画面に表示する部品の並びを返す `body` を定義します。
    var body: some View {
        // 画面遷移と見出しを管理する領域を作ります。
        NavigationStack {
            // 要素を手前と奥に重ねます。
            ZStack {
                // 画面に色を表示します。
                Color.black.ignoresSafeArea()
                
                // 要素を上から下へ並べます。
                VStack(spacing: 20) {
                    // AI Ticker
                    // AI Ticker
                    // 表示できるAIの助言がある場合、画面上部の帯に表示します。
                    if !aiAdviceText.isEmpty {
                        // AIの助言を流れる表示として配置します。
                        AITickerView(text: aiAdviceText, onTapSparkle: {
                            // `generateDailyAdvice` を呼び出し、括弧内の値を使って処理します。
                            generateDailyAdvice(forceRefresh: true)
                        // 開いていた画面部品や処理の範囲を閉じます。
                        }, onFinish: {
                             // Hide after one run
                             // この中で変える画面状態にアニメーション設定を適用します。
                             withAnimation {
                                 // 画面に表示するAIの助言へ `""` の結果を代入します。
                                 aiAdviceText = ""
                             // withAnimationの範囲をここで閉じます。
                             }
                        // }, onFinish:の範囲をここで閉じます。
                        })
                        // 表示の周囲に余白を設けます。
                        .padding(.horizontal)
                        // 表示の周囲に余白を設けます。
                        .padding(.top, 10)
                        // 表示と非表示を切り替えるときの動きを設定します。
                        .transition(.move(edge: .top).combined(with: .opacity))
                    // 前の条件に当てはまらない場合の処理に進みます。
                    } else {
                        // Show just sparkle button if hidden? or just empty space?
                        // User said "Initially nothing". "When sparkles button tapped..."
                        // Wait, if hidden, how to tap sparkles?
                        // I should show the Sparkles Button regardless?
                        // "Trigger AI content generation only when the 'sparkles' icon is tapped."
                        // If Ticker is hidden, we need a trigger button.
                        // 要素を左から右へ並べます。
                        HStack {
                            // タップで処理を実行するボタンを配置します。
                            Button(action: {
                                // `generateDailyAdvice` を呼び出し、括弧内の値を使って処理します。
                                generateDailyAdvice(forceRefresh: true)
                            // ボタンの処理の範囲をここで閉じます。
                            }) {
                                // 画像またはシステムアイコンを表示します。
                                Image(systemName: "sparkles")
                                    // 文字やアイコンの色を設定します。
                                    .foregroundStyle(.yellow)
                                    // 表示の周囲に余白を設けます。
                                    .padding(12)
                                    // 背景の色や形を設定します。
                                    .background(Color(white: 0.12))
                                    // 指定した形に表示を切り抜きます。
                                    .clipShape(Circle())
                            // })の範囲をここで閉じます。
                            }
                            // 空き領域を使って要素間の距離を広げます。
                            Spacer()
                        // 横並びの表示の範囲をここで閉じます。
                        }
                        // 表示の周囲に余白を設けます。
                        .padding(.horizontal)
                        // 表示の周囲に余白を設けます。
                        .padding(.top, 10)
                    // } elseの範囲をここで閉じます。
                    }
                        
                    // 残高などを示す画面上部の表示を配置します。
                    headerView
                    // 収支入力などを始める操作ボタンを配置します。
                    actionButtonsView
                    // 財布の一覧を表示します。
                    walletListView
                    // 収支履歴の一覧を表示します。
                    historyListView
                // 縦並びの表示の範囲をここで閉じます。
                }
            // 重ねた表示の範囲をここで閉じます。
            }
            // 画面上部の見出しを設定します。
            .navigationTitle("")
            // 画面上部の操作項目を設定します。
            .toolbar(.hidden, for: .navigationBar)
            // 条件に応じて全画面の画面を表示します。
            .fullScreenCover(isPresented: $showScanner) { ScannerView(scannedImage: $scannedImage).ignoresSafeArea() }
            // 条件に応じて下から現れる画面を表示します。
            .sheet(isPresented: $showDeposit) { DepositView() }
            // 条件に応じて下から現れる画面を表示します。
            .sheet(item: $expenseToEdit) { expense in 
                // 収支の編集画面を表示します。
                EditExpenseView(expense: expense, isNewEntry: isNewEditingEntry) 
            // シート画面の範囲をここで閉じます。
            }
            // 条件に応じて下から現れる画面を表示します。
            .sheet(isPresented: $showSettings) { AdvancedSettingsView() }
            // 条件に応じて下から現れる画面を表示します。
            .sheet(isPresented: $showChat) { ChatView() }
            // この画面が現れたときの処理を登録します。
            .onAppear {
                // Initial load removed as per request
            // 画面表示時の処理の範囲をここで閉じます。
            }
            // ... (rest of modifiers)

    

            // 指定した値が変わったときの処理を登録します。
            .onChange(of: scannedImage) {
                // 撮影済みのレシート画像がある場合、その画像の読み取りを開始します。
                if let img = scannedImage {
                     // `filename`を変更できない値として作り、右辺の結果を保存します。
                     let filename = saveImageToDocuments(image: img)
                     
                     // 時間のかかる非同期処理を開始します。
                     Task {
                         // 1. まずOCRで生テキストなどを取得
                         // `result`を変更できない値として作り、右辺の結果を保存します。
                         let result = await ReceiptScanner.scan(image: img)
                         // `self.currentScanResult`へ `result` の結果を代入します。
                         self.currentScanResult = result
                         // `self.tempImageFilename`へ `filename` の結果を代入します。
                         self.tempImageFilename = filename
                         
                         // 2. モデルがインストール済みか確認
                         // AIモデルがインストール済みなら、そのモデルを使う処理へ進みます。
                         if LocalLLMService.shared.isModelInstalled {
                             // `processWithAI(result: result, filename: filename)` が終わるまで待ってから次へ進みます。
                             await processWithAI(result: result, filename: filename)
                         // 前の条件に当てはまらない場合の処理に進みます。
                         } else {
                             // 未インストールなら旧方式
                             // `processLegacy` を呼び出し、括弧内の値を使って処理します。
                             processLegacy(result: result, filename: filename)
                         // } elseの範囲をここで閉じます。
                         }
                     // 非同期処理の範囲をここで閉じます。
                     }
                 // 条件分岐の範囲をここで閉じます。
                 }
            // 値が変わったときの処理の範囲をここで閉じます。
            }
            // Removed AI Download Alert Modifier
            // 画面遷移の範囲をここで閉じます。
            }
            // 元の表示の上に別の表示を重ねます。
            .overlay {
                // 複数の表示要素を一つのまとまりとして扱います。
                Group {
                    // AIモデルが準備完了・未インストール・準備中のいずれでもない場合に、進行状況を表示します。
                    if !LocalLLMService.shared.loadStatus.contains("準備完了") && LocalLLMService.shared.loadStatus != "未インストール" && LocalLLMService.shared.loadStatus != "準備中..." {
                        // 要素を手前と奥に重ねます。
                        ZStack {
                            // 画面に色を表示します。
                            Color.black.opacity(0.6).ignoresSafeArea()
                            // 要素を上から下へ並べます。
                            VStack(spacing: 20) {
                                // 処理の進行状況を示す表示を作ります。
                                ProgressView()
                                    // 表示の拡大率を設定します。
                                    .scaleEffect(1.5)
                                    // 操作部品に使う強調色を設定します。
                                    .tint(.white)
                                // 文字列を画面に表示します。
                                Text(LocalLLMService.shared.loadStatus)
                                    // 文字の大きさや書体を設定します。
                                    .font(.headline)
                                    // 文字やアイコンの色を設定します。
                                    .foregroundStyle(.white)
                                // AIモデルのダウンロードが始まり、まだ完了していない場合の表示を作ります。
                                if LocalLLMService.shared.downloadProgress > 0 && LocalLLMService.shared.downloadProgress < 1.0 {
                                    // 処理の進行状況を示す表示を作ります。
                                    ProgressView(value: LocalLLMService.shared.downloadProgress)
                                        // 進行状況を横長のバーで表示します。
                                        .progressViewStyle(.linear)
                                        // 表示領域の幅や高さを設定します。
                                        .frame(width: 200)
                                // 条件分岐の範囲をここで閉じます。
                                }
                            // 縦並びの表示の範囲をここで閉じます。
                            }
                            // 表示の周囲に余白を設けます。
                            .padding(40)
                            // 背景の色や形を設定します。
                            .background(Color(white: 0.2))
                            // 表示の角を丸くします。
                            .cornerRadius(20)
                        // 重ねた表示の範囲をここで閉じます。
                        }
                    // 前の条件が成り立たず、続く条件が成り立つ場合の処理に進みます。
                    } else if isScanningReceipt {
                        // 要素を手前と奥に重ねます。
                        ZStack {
                            // 画面に色を表示します。
                            Color.black.opacity(0.6).ignoresSafeArea()
                            // 要素を上から下へ並べます。
                            VStack(spacing: 20) {
                                // 処理の進行状況を示す表示を作ります。
                                ProgressView()
                                    // 表示の拡大率を設定します。
                                    .scaleEffect(1.5)
                                    // 操作部品に使う強調色を設定します。
                                    .tint(.white)
                                // 文字列を画面に表示します。
                                Text("AIがレシートを解析中...")
                                    // 文字の大きさや書体を設定します。
                                    .font(.headline)
                                    // 文字やアイコンの色を設定します。
                                    .foregroundStyle(.white)
                            // 縦並びの表示の範囲をここで閉じます。
                            }
                            // 表示の周囲に余白を設けます。
                            .padding(40)
                            // 背景の色や形を設定します。
                            .background(Color(white: 0.2))
                            // 表示の角を丸くします。
                            .cornerRadius(20)
                        // 重ねた表示の範囲をここで閉じます。
                        }
                    // } else if isScanningReceiptの範囲をここで閉じます。
                    }
                // Groupの範囲をここで閉じます。
                }
            // .overlayの範囲をここで閉じます。
            }
        // 画面構成の範囲をここで閉じます。
        }


    
    // 一時保持用
    // `currentScanResult`を画面の状態として保持し、変更時に表示を更新します。
    @State private var currentScanResult: ReceiptScanner.ReceiptScanResult?
    // `tempImageFilename`を画面の状態として保持し、変更時に表示を更新します。
    @State private var tempImageFilename: String?

    // 設定画面の表示状態を画面の状態として保持し、変更時に表示を更新します。
    @State private var showSettings = false
    // チャット画面の表示状態を画面の状態として保持し、変更時に表示を更新します。
    @State private var showChat = false
    
    // Ticker State
    // 画面に表示するAIの助言を画面の状態として保持し、変更時に表示を更新します。
    @State private var aiAdviceText: String = "" // Initially hidden
    // `isAdviceLoading`を画面の状態として保持し、変更時に表示を更新します。
    @State private var isAdviceLoading = false
    // `isScanningReceipt`を画面の状態として保持し、変更時に表示を更新します。
    @State private var isScanningReceipt = false
    
    // AI処理
    // `processWithAI` という関数を定義し、括弧内の入力を使って処理します。
    private func processWithAI(result: ReceiptScanner.ReceiptScanResult, filename: String?) async {
        // `isScanningReceipt`をオンにし、対応する状態を更新します。
        isScanningReceipt = true
        // この処理が終わるときは必ずレシート読取中の状態を解除します。
        defer { isScanningReceipt = false }
        
        // 失敗する可能性がある処理を実行する範囲を始めます。
        do {
            // `catNames`を変更できない値として作り、右辺の結果を保存します。
            let catNames = categories.map { $0.name }
            // `jsonString`を変更できない値として作り、右辺の結果を保存します。
            let jsonString = try await LocalLLMService.shared.extractReceiptData(prompt: result.rawText, categories: catNames)
            
            // JSON文字列をUTF-8のデータに変換できた場合、続けて内容を解析します。
            if let data = jsonString.data(using: .utf8),
               // `json`を変更できない値として作り、右辺の結果を保存します。
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                // `amount`を変更できない値として作り、右辺の結果を保存します。
                let amount = json["amount"] as? Int ?? result.legacyAmount
                // `shopName`を変更できない値として作り、右辺の結果を保存します。
                let shopName = json["shopName"] as? String ?? result.legacyTitle
                // `categoryName`を変更できない値として作り、右辺の結果を保存します。
                let categoryName = json["category"] as? String ?? "未分類"
                
                // 日付解析
                // `date`を表す変更可能な値または計算結果を定義します。
                var date = Date()
                // 解析したJSONに日付の文字列があれば、日付型へ変換します。
                if let dateString = json["date"] as? String {
                     // `formatter`を変更できない値として作り、右辺の結果を保存します。
                     let formatter = DateFormatter()
                     // `formatter.dateFormat`へ `"yyyy-MM-dd"` の結果を代入します。
                     formatter.dateFormat = "yyyy-MM-dd"
                     // 日付の文字列を日付型に変換できた場合、その値を使います。
                     if let d = formatter.date(from: dateString) {
                         // `date`へ `d` の結果を代入します。
                         date = d
                     // 条件分岐の範囲をここで閉じます。
                     }
                // 条件分岐の範囲をここで閉じます。
                }
                
                // `finalAmount`を変更できない値として作り、右辺の結果を保存します。
                let finalAmount = amount > 0 ? amount : result.legacyAmount
                // `finalTitle`を変更できない値として作り、右辺の結果を保存します。
                let finalTitle = (shopName.isEmpty || shopName == "Store Name") ? result.legacyTitle : shopName
                
                // `MainActor.run {` が終わるまで待ってから次へ進みます。
                await MainActor.run {
                    // `addExpense` を呼び出し、括弧内の値を使って処理します。
                    addExpense(title: finalTitle, amount: finalAmount, date: date, category: categoryName, filename: filename)
                // await MainActor.runの範囲をここで閉じます。
                }
                // ここで現在の関数や処理から抜けます。
                return
            // 開いていた画面部品や処理の範囲を閉じます。
            }
        // 直前の処理でエラーが起きたときの処理を始めます。
        } catch {
            // `print` を呼び出し、括弧内の値を使って処理します。
            print("AI Error: \(error)")
        // } catchの範囲をここで閉じます。
        }
        // `processLegacy` を呼び出し、括弧内の値を使って処理します。
        processLegacy(result: result, filename: filename)
    // 関数の範囲をここで閉じます。
    }
    
    // 旧方式
    // `processLegacy` という関数を定義し、括弧内の入力を使って処理します。
    private func processLegacy(result: ReceiptScanner.ReceiptScanResult, filename: String?) {
        // `title`を変更できない値として作り、右辺の結果を保存します。
        let title = result.legacyTitle
        // `amount`を変更できない値として作り、右辺の結果を保存します。
        let amount = result.legacyAmount
        // `predictedCategory`を変更できない値として作り、右辺の結果を保存します。
        let predictedCategory = predictCategory(title: title)
        // `addExpense` を呼び出し、括弧内の値を使って処理します。
        addExpense(title: title, amount: amount, date: Date(), category: predictedCategory, filename: filename)
    // 関数の範囲をここで閉じます。
    }
    
    // `addExpense` という関数を定義し、括弧内の入力を使って処理します。
    private func addExpense(title: String, amount: Int, date: Date, category: String, filename: String?) {
        // `newExpense`を変更できない値として作り、右辺の結果を保存します。
        let newExpense = Expense(title: title, amount: amount, date: date, imageFilename: filename, isIncome: false, categoryName: category)
        // 保存済みの財布が一件以上あれば、最初の財布を使います。
        if let mainAsset = assets.first {
            // `mainAsset.balance`を右辺の値で増減し、結果を保存します。
            mainAsset.balance -= amount
            // `newExpense.assetName`へ `mainAsset.name` の結果を代入します。
            newExpense.assetName = mainAsset.name
        // 条件分岐の範囲をここで閉じます。
        }
        // 新しい収支記録をSwiftDataの保存対象に追加します。
        modelContext.insert(newExpense)
        // 新規入力かどうかをオンにし、対応する状態を更新します。
        isNewEditingEntry = true
        // 編集中の収支へ `newExpense` の結果を代入します。
        expenseToEdit = newExpense
        // 撮影したレシート画像の参照を空にして、前の値を解除します。
        scannedImage = nil
        // `currentScanResult`の参照を空にして、前の値を解除します。
        currentScanResult = nil
        // `tempImageFilename`の参照を空にして、前の値を解除します。
        tempImageFilename = nil
    // 関数の範囲をここで閉じます。
    }
    
    // `WalletFlipCard` という構造体を定義し、関連する値や処理をまとめます。
    struct WalletFlipCard: View {
        // `asset`を変更できない値として作り、右辺の結果を保存します。
        let asset: Asset
        // `allExpenses`を変更できない値として作り、右辺の結果を保存します。
        let allExpenses: [Expense]
        // ■ 環境変数追加
        // 表示言語の管理役を親画面から受け取ります。
        @EnvironmentObject var lm: LanguageManager
        // `rotation`を画面の状態として保持し、変更時に表示を更新します。
        @State private var rotation: Double = 0
        
        // `stats`を表す変更可能な値または計算結果を定義します。
        var stats: (income: Int, expense: Int) { /* 変更なし */
            // `related`を変更できない値として作り、右辺の結果を保存します。
            let related = allExpenses.filter { $0.assetName == asset.name }
            // `inc`を変更できない値として作り、右辺の結果を保存します。
            let inc = related.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
            // `exp`を変更できない値として作り、右辺の結果を保存します。
            let exp = related.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
            // `(inc, exp)` の結果を呼び出し元へ返します。
            return (inc, exp)
        // 直前の処理の範囲をここで閉じます。
        }
        
        // 画面に表示する部品の並びを返す `body` を定義します。
        var body: some View {
            // 要素を手前と奥に重ねます。
            ZStack {
                // `angle`を変更できない値として作り、右辺の結果を保存します。
                let angle = rotation.truncatingRemainder(dividingBy: 360)
                // `isFront`を変更できない値として作り、右辺の結果を保存します。
                let isFront = angle < 90 || angle > 270
                
                // カードの表側を表示する状態なら、表側の内容を描きます。
                if isFront {
                    // 要素を上から下へ並べます。
                    VStack(alignment: .leading) {
                        // 要素を左から右へ並べます。
                        HStack { Image(systemName: "creditcard.fill"); Spacer(); Text(asset.name).bold() }
                        // 空き領域を使って要素間の距離を広げます。
                        Spacer()
                        // ■ 通貨記号
                        // 文字列を画面に表示します。
                        Text("\(lm.currencySymbol)\(asset.balance)").font(.title2).bold().contentTransition(.numericText())
                    // 縦並びの表示の範囲をここで閉じます。
                    }
                    // 表示の周囲に余白を設けます。
                    .padding().background(Color(hex: asset.colorHex).opacity(0.8)).foregroundStyle(.white).cornerRadius(15)
                    // 元の表示の上に別の表示を重ねます。
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.2), lineWidth: 1))
                // 前の条件に当てはまらない場合の処理に進みます。
                } else {
                    // 要素を上から下へ並べます。
                    VStack(alignment: .leading, spacing: 10) {
                        // ■ 言語対応: History
                        // 文字列を画面に表示します。
                        Text(lm.t(.history)).font(.caption2).bold().foregroundStyle(.white.opacity(0.7))
                        // 要素を左から右へ並べます。
                        HStack {
                            // 画像またはシステムアイコンを表示します。
                            Image(systemName: "arrow.up.right").foregroundStyle(.green)
                            // ■ 通貨記号
                            // 文字列を画面に表示します。
                            Text("\(lm.currencySymbol)\(stats.income)")
                        // 横並びの表示の範囲をここで閉じます。
                        }
                        // 要素を左から右へ並べます。
                        HStack {
                            // 画像またはシステムアイコンを表示します。
                            Image(systemName: "arrow.down.right").foregroundStyle(.red)
                            // ■ 通貨記号
                            // 文字列を画面に表示します。
                            Text("\(lm.currencySymbol)\(stats.expense)")
                        // 横並びの表示の範囲をここで閉じます。
                        }
                    // 縦並びの表示の範囲をここで閉じます。
                    }
                    // 文字の大きさや書体を設定します。
                    .font(.subheadline.bold())
                    // 表示の周囲に余白を設けます。
                    .padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    // 背景の色や形を設定します。
                    .background(Color(hex: asset.colorHex).opacity(0.3)).background(.black).foregroundStyle(.white).cornerRadius(15)
                    // 元の表示の上に別の表示を重ねます。
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color(hex: asset.colorHex), lineWidth: 2))
                    // カードを縦軸の周りに180度回して裏面を表示します。
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                // } elseの範囲をここで閉じます。
                }
            // 重ねた表示の範囲をここで閉じます。
            }
            // 表示領域の幅や高さを設定します。
            .frame(width: 160, height: 140)
            // 現在の回転角に合わせてカードを縦軸の周りに回します。
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            // タップされたときの処理を登録します。
            .onTapGesture { withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { rotation += 180 } }
        // 画面構成の範囲をここで閉じます。
        }
    // 構造体の範囲をここで閉じます。
    }
    
    // (Helper関数は省略、変更なし)
    // `predictCategory` という関数を定義し、括弧内の入力を使って処理します。
    private func predictCategory(title: String) -> String { return "未分類" }
    // `deleteExpense` という関数を定義し、括弧内の入力を使って処理します。
    private func deleteExpense(offsets: IndexSet) { withAnimation { offsets.map { sortedExpenses[$0] }.forEach(modelContext.delete) } }
    // `saveImageToDocuments` という関数を定義し、括弧内の入力を使って処理します。
    private func saveImageToDocuments(image: UIImage) -> String? { return nil }
    
    // AI Advice Generation
    // `generateDailyAdvice` という関数を定義し、括弧内の入力を使って処理します。
    private func generateDailyAdvice(forceRefresh: Bool = false) {
        // Prevent multiple calls
        // AIモデルがあり、助言生成がまだ始まっていない場合だけ処理を続けます。
        guard LocalLLMService.shared.isModelInstalled, !isAdviceLoading else {
            // ここで現在の関数や処理から抜けます。
            return
        // 開いていた画面部品や処理の範囲を閉じます。
        }
        
        // `isAdviceLoading`をオンにし、対応する状態を更新します。
        isAdviceLoading = true
        
        // Silent update: Don't change text to "Loading..."
        // unless it's the very first load and empty? 
        // User wants: Loop existing text if not tapped. Update on tap.
        // If empty, maybe show default "Wealthy Butler" until loaded.
        
        // 時間のかかる非同期処理を開始します。
        Task {
            // Build Context (Brief)
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
                // `advice`を変更できない値として作り、右辺の結果を保存します。
                let advice = try await LocalLLMService.shared.generateAdvice(context: context)
                
                // `MainActor.run {` が終わるまで待ってから次へ進みます。
                await MainActor.run {
                    // `self.aiAdviceText`へ `advice.replacingOccurrences(of: "\"", with: "")` の結果を代入します。
                    self.aiAdviceText = advice.replacingOccurrences(of: "\"", with: "")
                    // `self.isAdviceLoading`をオフにし、対応する状態を更新します。
                    self.isAdviceLoading = false
                // await MainActor.runの範囲をここで閉じます。
                }
            // 直前の処理でエラーが起きたときの処理を始めます。
            } catch {
                // `MainActor.run {` が終わるまで待ってから次へ進みます。
                await MainActor.run {
                    // unexpected error, keep old text or set default
                    // AIの助言が既定文または空なら、代わりの案内文を設定します。
                    if self.aiAdviceText == "Wealthy Butler" || self.aiAdviceText.isEmpty {
                         // `self.aiAdviceText`へ `"Wealthy Butler"` の結果を代入します。
                         self.aiAdviceText = "Wealthy Butler"
                    // 条件分岐の範囲をここで閉じます。
                    }
                    // `self.isAdviceLoading`をオフにし、対応する状態を更新します。
                    self.isAdviceLoading = false
                // await MainActor.runの範囲をここで閉じます。
                }
            // } catchの範囲をここで閉じます。
            }
        // 非同期処理の範囲をここで閉じます。
        }
    // 関数の範囲をここで閉じます。
    }

    // MARK: - Subviews
    
    // 1. Header
    // `headerView`を表す変更可能な値または計算結果を定義します。
    private var headerView: some View {
        // 要素を左から右へ並べます。
        HStack {
            // 要素を上から下へ並べます。
            VStack(alignment: .leading) {
                // 文字列を画面に表示します。
                Text(lm.t(.totalAssets)).font(.caption).foregroundStyle(.gray)
                // 文字列を画面に表示します。
                Text("\(lm.currencySymbol)\(totalBalance)")
                    // 文字の大きさや書体を設定します。
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    // 文字やアイコンの色を設定します。
                    .foregroundStyle(.white)
                    // 数字の変化を専用のアニメーションで見せます。
                    .contentTransition(.numericText())
            // 縦並びの表示の範囲をここで閉じます。
            }
            // 空き領域を使って要素間の距離を広げます。
            Spacer()
            // タップで処理を実行するボタンを配置します。
            Button(action: { showSettings = true }) {
                // 画像またはシステムアイコンを表示します。
                Image(systemName: "gearshape.fill").font(.title).foregroundStyle(.gray)
            // ボタンの処理の範囲をここで閉じます。
            }
        // 横並びの表示の範囲をここで閉じます。
        }
        // 表示の周囲に余白を設けます。
        .padding(.horizontal).padding(.top)
    // 開いていた画面部品や処理の範囲を閉じます。
    }
    
    // 2. Action Buttons
    // `actionButtonsView`を表す変更可能な値または計算結果を定義します。
    private var actionButtonsView: some View {
        // 要素を左から右へ並べます。
        HStack(spacing: 20) {
            // アプリ共通の操作ボタンを表示します。
            ActionButton(icon: "camera.viewfinder", label: lm.t(.scan), color: .orange) { showScanner = true }
            // アプリ共通の操作ボタンを表示します。
            ActionButton(icon: "plus.circle.fill", label: lm.t(.deposit), color: .green) { showDeposit = true }
            // アプリ共通の操作ボタンを表示します。
            ActionButton(icon: "square.and.pencil", label: lm.t(.manualInput), color: .blue) {
                // `newExpense`を変更できない値として作り、右辺の結果を保存します。
                let newExpense = Expense(title: "", amount: 0, date: Date(), isIncome: false, categoryName: "未分類")
                // 新しい収支記録をSwiftDataの保存対象に追加します。
                modelContext.insert(newExpense)
                // 新規入力かどうかをオンにし、対応する状態を更新します。
                isNewEditingEntry = true
                // 編集中の収支へ `newExpense` の結果を代入します。
                expenseToEdit = newExpense
            // 開いていた画面部品や処理の範囲を閉じます。
            }
            // Butler Button
            // アプリ共通の操作ボタンを表示します。
            ActionButton(icon: "bubble.left.and.bubble.right.fill", label: lm.t(.aiButler), color: .purple) {
                // チャット画面の表示状態をオンにし、対応する状態を更新します。
                showChat = true
            // 開いていた画面部品や処理の範囲を閉じます。
            }
        // 横並びの表示の範囲をここで閉じます。
        }
        // 表示の周囲に余白を設けます。
        .padding(.horizontal)
        // 表示の周囲に余白を設けます。
        .padding(.bottom, 10)
    // 開いていた画面部品や処理の範囲を閉じます。
    }
    
    // 3. Wallet List
    // `walletListView`を表す変更可能な値または計算結果を定義します。
    private var walletListView: some View {
        // 内容をスクロールできる領域を作ります。
        ScrollView(.horizontal, showsIndicators: false) {
            // 要素を左から右へ並べます。
            HStack(spacing: 15) {
                // 配列などの各要素について同じ表示を作ります。
                ForEach(assets) { asset in
                    // `WalletFlipCard` を呼び出し、括弧内の値を使って処理します。
                    WalletFlipCard(asset: asset, allExpenses: expenses)
                // 繰り返し表示の範囲をここで閉じます。
                }
            // 横並びの表示の範囲をここで閉じます。
            }
            // 表示の周囲に余白を設けます。
            .padding(.horizontal).padding(.vertical, 10)
        // 開いていた画面部品や処理の範囲を閉じます。
        }
    // 開いていた画面部品や処理の範囲を閉じます。
    }
    
    // 4. History List
    // `historyListView`を表す変更可能な値または計算結果を定義します。
    private var historyListView: some View {
        // 要素を上から下へ並べます。
        VStack(alignment: .leading) {
            // 文字列を画面に表示します。
            Text(lm.t(.history)).font(.headline).foregroundStyle(.gray).padding(.horizontal)
            // 並べ替え後の収支履歴が空なら、履歴がないことを案内します。
            if sortedExpenses.isEmpty {
                // 表示する項目がない場合の案内画面を作ります。
                ContentUnavailableView {
                    // 画像またはシステムアイコンを表示します。
                    Image(systemName: "list.bullet.clipboard")
                    // 文字の大きさや書体を設定します。
                    .font(.system(size: 40))
                    // 文字やアイコンの色を設定します。
                    .foregroundStyle(.gray.opacity(0.5))
                // ContentUnavailableViewの範囲をここで閉じます。
                } description: {
                    // 文字列を画面に表示します。
                    Text(lm.t(.noExpenses)).foregroundStyle(.gray)
                // } description:の範囲をここで閉じます。
                }
            // 前の条件に当てはまらない場合の処理に進みます。
            } else {
                // 項目を一覧表示します。
                List {
                    // 配列などの各要素について同じ表示を作ります。
                    ForEach(sortedExpenses) { expense in
                        // タップで処理を実行するボタンを配置します。
                        Button {
                            // 新規入力かどうかをオフにし、対応する状態を更新します。
                            isNewEditingEntry = false
                            // 編集中の収支へ `expense` の結果を代入します。
                            expenseToEdit = expense
                        // ボタンの処理の範囲をここで閉じます。
                        } label: {
                            // 要素を左から右へ並べます。
                            HStack {
                                // 要素を左から右へ並べます。
                                HStack {
                                    // `category`を変更できない値として作り、右辺の結果を保存します。
                                    let category = categories.first(where: { $0.name == expense.categoryName })
                                    // 画像またはシステムアイコンを表示します。
                                    Image(systemName: category?.icon ?? "questionmark.circle")
                                        // 文字やアイコンの色を設定します。
                                        .foregroundStyle(Color(hex: category?.colorHex ?? "808080"))
                                        // 表示領域の幅や高さを設定します。
                                        .frame(width: 30)
                                    // 文字列を画面に表示します。
                                    Text(lm.translateCategory(name: expense.categoryName ?? lm.t(.unclassified)))
                                        // 文字の大きさや書体を設定します。
                                        .font(.caption)
                                        // 文字やアイコンの色を設定します。
                                        .foregroundStyle(.gray)
                                // 横並びの表示の範囲をここで閉じます。
                                }
                                // 要素を上から下へ並べます。
                                VStack(alignment: .leading) {
                                    // 文字列を画面に表示します。
                                    Text(expense.title).font(.body.bold()).foregroundStyle(.white)
                                    // 文字列を画面に表示します。
                                    Text(expense.date.formatted(date: .numeric, time: .omitted)).font(.caption).foregroundStyle(.gray)
                                // 縦並びの表示の範囲をここで閉じます。
                                }
                                // 空き領域を使って要素間の距離を広げます。
                                Spacer()
                                // 文字列を画面に表示します。
                                Text((expense.isIncome ? "+ " : "- ") + "\(lm.currencySymbol)\(expense.amount)")
                                    // 文字やアイコンの色を設定します。
                                    .foregroundStyle(expense.isIncome ? .green : .red).bold()
                            // 横並びの表示の範囲をここで閉じます。
                            }
                        // } label:の範囲をここで閉じます。
                        }
                        // 一覧の行の背景を設定します。
                        .listRowBackground(Color(white: 0.1))
                    // 繰り返し表示の範囲をここで閉じます。
                    }
                    // 一覧から削除したときに収支削除処理を呼びます。
                    .onDelete(perform: deleteExpense)
                // Listの範囲をここで閉じます。
                }
                // 一覧の見た目を設定します。
                .listStyle(.plain).scrollContentBackground(.hidden)
            // } elseの範囲をここで閉じます。
            }
        // 縦並びの表示の範囲をここで閉じます。
        }
    // 開いていた画面部品や処理の範囲を閉じます。
    }
// 構造体の範囲をここで閉じます。
}

    // `ActionButton` という構造体を定義し、関連する値や処理をまとめます。
    struct ActionButton: View {
        // `icon`を変更できない値として作り、右辺の結果を保存します。
        let icon: String
        // `label`を変更できない値として作り、右辺の結果を保存します。
        let label: String
        // `color`を変更できない値として作り、右辺の結果を保存します。
        let color: Color
        // `action`を変更できない値として作り、右辺の結果を保存します。
        let action: () -> Void
        
        // 画面に表示する部品の並びを返す `body` を定義します。
        var body: some View {
            // タップで処理を実行するボタンを配置します。
            Button(action: action) {
                // 要素を上から下へ並べます。
                VStack(spacing: 8) {
                    // 画像またはシステムアイコンを表示します。
                    Image(systemName: icon)
                        // 文字の大きさや書体を設定します。
                        .font(.title2)
                        // 文字やアイコンの色を設定します。
                        .foregroundStyle(color)
                    // 文字列を画面に表示します。
                    Text(label)
                        // 文字の大きさや書体を設定します。
                        .font(.caption)
                        // 文字の太さを設定します。
                        .fontWeight(.semibold)
                        // 文字やアイコンの色を設定します。
                        .foregroundStyle(.white)
                // 縦並びの表示の範囲をここで閉じます。
                }
                // 表示領域の幅や高さを設定します。
                .frame(maxWidth: .infinity)
                // 表示領域の幅や高さを設定します。
                .frame(height: 80)
                // 背景の色や形を設定します。
                .background(Color(white: 0.12))
                // 表示の角を丸くします。
                .cornerRadius(16)
                // .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1)) // Optional: more subtle border
            // ボタンの処理の範囲をここで閉じます。
            }
        // 画面構成の範囲をここで閉じます。
        }
    // 構造体の範囲をここで閉じます。
    }


// `AdvancedSettingsView` という構造体を定義し、関連する値や処理をまとめます。
struct AdvancedSettingsView: View {
    // SwiftUIの環境から`dismiss`を取得します。
    @Environment(\.dismiss) var dismiss
    // SwiftUIの環境からデータ保存用のコンテキストを取得します。
    @Environment(\.modelContext) var modelContext
    // 表示言語の管理役を親画面から受け取ります。
    @EnvironmentObject var lm: LanguageManager
    // 処理中かどうかを画面の状態として保持し、変更時に表示を更新します。
    @State private var isProcessing = false // Feedback state
    
    // Backup State
    // `showFileExporter`を画面の状態として保持し、変更時に表示を更新します。
    @State private var showFileExporter = false
    // `showFileImporter`を画面の状態として保持し、変更時に表示を更新します。
    @State private var showFileImporter = false
    // `backupDocument`を画面の状態として保持し、変更時に表示を更新します。
    @State private var backupDocument: BackupDocument?
    // 確認メッセージを画面の状態として保持し、変更時に表示を更新します。
    @State private var alertMessage = ""
    // 確認画面の表示状態を画面の状態として保持し、変更時に表示を更新します。
    @State private var showAlert = false
    
    // 画面に表示する部品の並びを返す `body` を定義します。
    var body: some View {
        // 画面遷移と見出しを管理する領域を作ります。
        NavigationStack {
            // 項目を一覧表示します。
            List {
                // 言語設定
                // 関連する項目を一つのまとまりに分けます。
                Section(header: Text(lm.t(.languageSettings))) {
                    // 選択肢から値を選ぶ部品を作ります。
                    Picker(selection: $lm.currentLanguage) {
                        // 配列などの各要素について同じ表示を作ります。
                        ForEach(AppLanguage.allCases) { lang in
                            // 文字列を画面に表示します。
                            Text(lang.rawValue).tag(lang)
                        // 繰り返し表示の範囲をここで閉じます。
                        }
                    // 開いていた画面部品や処理の範囲を閉じます。
                    } label: {
                        // 文字列を画面に表示します。
                        Text(lm.t(.languageSettings))
                    // } label:の範囲をここで閉じます。
                    }
                    // 選択肢を開くメニュー形式にします。
                    .pickerStyle(.menu)
                // 開いていた画面部品や処理の範囲を閉じます。
                }
                
                // 一般設定
                // 関連する項目を一つのまとまりに分けます。
                Section(header: Text(lm.t(.settings))) {
                    // タップで別の画面へ移動する項目を作ります。
                    NavigationLink(destination: RecurringSettingsView()) {
                        // 文字とアイコンを組み合わせた表示を作ります。
                        Label(lm.t(.recurring), systemImage: "repeat.circle.fill")
                    // 開いていた画面部品や処理の範囲を閉じます。
                    }
                    // タップで別の画面へ移動する項目を作ります。
                    NavigationLink(destination: CategoriesView()) {
                        // 文字とアイコンを組み合わせた表示を作ります。
                        Label(lm.t(.category), systemImage: "tag.fill")
                    // 開いていた画面部品や処理の範囲を閉じます。
                    }
                // 開いていた画面部品や処理の範囲を閉じます。
                }
                
                // データ管理 (バックアップ)
                // 関連する項目を一つのまとまりに分けます。
                Section(header: Text(lm.t(.dataManagement)), footer: Text(lm.t(.backupDesc))) {
                    // タップで処理を実行するボタンを配置します。
                    Button {
                        // `createBackup` を呼び出し、括弧内の値を使って処理します。
                        createBackup()
                    // ボタンの処理の範囲をここで閉じます。
                    } label: {
                        // 文字とアイコンを組み合わせた表示を作ります。
                        Label(lm.t(.backup), systemImage: "square.and.arrow.up")
                    // } label:の範囲をここで閉じます。
                    }
                    
                    // タップで処理を実行するボタンを配置します。
                    Button {
                        // `showFileImporter`をオンにし、対応する状態を更新します。
                        showFileImporter = true
                    // ボタンの処理の範囲をここで閉じます。
                    } label: {
                        // 文字とアイコンを組み合わせた表示を作ります。
                        Label(lm.t(.restore), systemImage: "square.and.arrow.down")
                    // } label:の範囲をここで閉じます。
                    }
                // 開いていた画面部品や処理の範囲を閉じます。
                }
                
                // 関連する項目を一つのまとまりに分けます。
                Section(header: Text(lm.t(.aiModelManagement)), footer: Text(lm.t(.modelDescription))) {
                    // タップで別の画面へ移動する項目を作ります。
                    NavigationLink(destination: ModelSettingsView()) {
                        // 要素を左から右へ並べます。
                        HStack {
                            // 要素を上から下へ並べます。
                            VStack(alignment: .leading) {
                                // 文字列を画面に表示します。
                                Text(LocalLLMService.shared.currentModel.name)
                                    // 文字の大きさや書体を設定します。
                                    .font(.headline)
                                // 文字列を画面に表示します。
                                Text(LocalLLMService.shared.loadStatus)
                                    // 文字の大きさや書体を設定します。
                                    .font(.caption)
                                    // 文字やアイコンの色を設定します。
                                    .foregroundStyle(.gray)
                            // 縦並びの表示の範囲をここで閉じます。
                            }
                            // 空き領域を使って要素間の距離を広げます。
                            Spacer()
                            // AIモデルがインストール済みなら、そのモデルを使う処理へ進みます。
                            if LocalLLMService.shared.isModelInstalled {
                                // 画像またはシステムアイコンを表示します。
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            // 条件分岐の範囲をここで閉じます。
                            }
                        // 横並びの表示の範囲をここで閉じます。
                        }
                    // 開いていた画面部品や処理の範囲を閉じます。
                    }
                // 開いていた画面部品や処理の範囲を閉じます。
                }
            // Listの範囲をここで閉じます。
            }
            // 画面上部の見出しを設定します。
            .navigationTitle(lm.t(.settings))
            // 画面上部の操作項目を設定します。
            .toolbar {
                // 画面上部の操作項目を追加します。
                ToolbarItem(placement: .topBarTrailing) {
                    // タップで処理を実行するボタンを配置します。
                    Button(lm.t(.close)) { dismiss() }
                // 開いていた画面部品や処理の範囲を閉じます。
                }
            // .toolbarの範囲をここで閉じます。
            }
            // Modifiers for Backup
            // JSON形式のバックアップをファイルとして書き出し、結果を受け取ります。
            .fileExporter(isPresented: $showFileExporter, document: backupDocument, contentType: .json, defaultFilename: "Wealthy_Backup") { result in
                // 値に応じて実行する処理を分けます。
                switch result {
                // ファイルの書き出しが成功した場合に進みます。
                case .success(_):
                    // 確認メッセージへ `lm.t(.backupSuccess)` の結果を代入します。
                    alertMessage = lm.t(.backupSuccess)
                    // 確認画面の表示状態をオンにし、対応する状態を更新します。
                    showAlert = true
                // ファイル処理が失敗した場合、エラー内容を受け取ります。
                case .failure(let error):
                    // 確認メッセージへ `"\(lm.t(.error)): \(error.localizedDescription)"` の結果を代入します。
                    alertMessage = "\(lm.t(.error)): \(error.localizedDescription)"
                    // 確認画面の表示状態をオンにし、対応する状態を更新します。
                    showAlert = true
                // 条件の振り分けの範囲をここで閉じます。
                }
            // 直前の処理の範囲をここで閉じます。
            }
            // JSON形式のバックアップを選んで読み込み、結果を受け取ります。
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
                // 値に応じて実行する処理を分けます。
                switch result {
                // ファイルを正常に読み込めた場合、選ばれたURLを受け取ります。
                case .success(let url):
                    // 失敗する可能性がある処理を実行する範囲を始めます。
                    do {
                        // 失敗する可能性がある関数を呼び、エラーは呼び出し元へ伝えます。
                        try BackupManager.shared.restoreBackup(from: url, context: modelContext)
                        // 確認メッセージへ `lm.t(.restoreSuccess)` の結果を代入します。
                        alertMessage = lm.t(.restoreSuccess)
                        // 確認画面の表示状態をオンにし、対応する状態を更新します。
                        showAlert = true
                    // 直前の処理でエラーが起きたときの処理を始めます。
                    } catch {
                        // 確認メッセージへ `"\(lm.t(.error)): \(error.localizedDescription)"` の結果を代入します。
                        alertMessage = "\(lm.t(.error)): \(error.localizedDescription)"
                        // 確認画面の表示状態をオンにし、対応する状態を更新します。
                        showAlert = true
                    // } catchの範囲をここで閉じます。
                    }
                // ファイル処理が失敗した場合、エラー内容を受け取ります。
                case .failure(let error):
                    // 確認メッセージへ `"\(lm.t(.error)): \(error.localizedDescription)"` の結果を代入します。
                    alertMessage = "\(lm.t(.error)): \(error.localizedDescription)"
                    // 確認画面の表示状態をオンにし、対応する状態を更新します。
                    showAlert = true
                // 条件の振り分けの範囲をここで閉じます。
                }
            // 直前の処理の範囲をここで閉じます。
            }
            // 条件に応じて確認メッセージを表示します。
            .alert(isPresented: $showAlert) {
                // `Alert` を呼び出し、括弧内の値を使って処理します。
                Alert(title: Text(alertMessage))
            // 確認画面の範囲をここで閉じます。
            }
        // 画面遷移の範囲をここで閉じます。
        }
    // 画面構成の範囲をここで閉じます。
    }
    
    // `createBackup` という関数を定義し、括弧内の入力を使って処理します。
    private func createBackup() {
        // 失敗する可能性がある処理を実行する範囲を始めます。
        do {
            // `url`を変更できない値として作り、右辺の結果を保存します。
            let url = try BackupManager.shared.createBackupURL(context: modelContext)
            // `json`を変更できない値として作り、右辺の結果を保存します。
            let json = try String(contentsOf: url, encoding: .utf8)
            // `backupDocument`へ `BackupDocument(text: json)` の結果を代入します。
            backupDocument = BackupDocument(text: json)
            // `showFileExporter`をオンにし、対応する状態を更新します。
            showFileExporter = true
        // 直前の処理でエラーが起きたときの処理を始めます。
        } catch {
            // 確認メッセージへ `"\(lm.t(.error)): \(error.localizedDescription)"` の結果を代入します。
            alertMessage = "\(lm.t(.error)): \(error.localizedDescription)"
            // 確認画面の表示状態をオンにし、対応する状態を更新します。
            showAlert = true
        // } catchの範囲をここで閉じます。
        }
    // 関数の範囲をここで閉じます。
    }
// 構造体の範囲をここで閉じます。
}
