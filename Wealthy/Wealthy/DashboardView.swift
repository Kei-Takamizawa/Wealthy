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
                    if !aiAdviceText.isEmpty {
                        AITickerView(text: aiAdviceText, onTapSparkle: {
                            generateDailyAdvice()
                        }, onFinish: {
                            withAnimation { aiAdviceText = "" }
                        })
                        .id(aiAdviceText)
                        .environment(\.colorScheme, .dark)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .transition(.opacity)
                    } else {
                        HStack {
                            Button(action: generateDailyAdvice) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.yellow)
                                    .padding(12)
                            }
                            .accessibilityLabel(lm.currentLanguage == .japanese ? "お金のひとこと" : "Money tip")
                            .disabled(isAdviceLoading)
                            if isAdviceLoading { ProgressView().tint(.white) }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
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
                EditExpenseView(expense: expense, isNewEntry: isNewEditingEntry,
                                receiptDateUsesCapture: receiptDateUsesCapture)
            // シート画面の範囲をここで閉じます。
            }
            // 条件に応じて下から現れる画面を表示します。
            .sheet(isPresented: $showSettings) { AdvancedSettingsView() }
            // 条件に応じて下から現れる画面を表示します。
            .sheet(isPresented: $showChat) { ChatView() }
            .alert(lm.t(.error), isPresented: Binding(
                get: { receiptError != nil },
                set: { if !$0 { receiptError = nil } }
            )) {
                Button("OK", role: .cancel) { receiptError = nil }
            } message: {
                Text(receiptError ?? "")
            }
            .onChange(of: scannedImage) {
                guard let image = scannedImage else { return }
                // Fix the capture date before asynchronous OCR or AI processing begins.
                let capturedAt = Date()
                do {
                    let filename = try saveImageToDocuments(image: image)
                    isScanningReceipt = true
                    Task {
                        let result = await ReceiptScanner.scan(image: image, capturedAt: capturedAt)
                        await processWithAI(result: result, filename: filename)
                    }
                } catch {
                    scannedImage = nil
                    receiptError = error.localizedDescription
                }
            }
            // Removed AI Download Alert Modifier
            // 画面遷移の範囲をここで閉じます。
            }
            // 元の表示の上に別の表示を重ねます。
            .overlay {
                // 複数の表示要素を一つのまとまりとして扱います。
                Group {
                    if isScanningReceipt {
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
                                Text(lm.currentLanguage == .japanese ? "レシートを解析中…" : "Reading receipt…")
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


    
    @State private var receiptError: String?
    @State private var receiptDateUsesCapture = false

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
    
    @MainActor
    private func processWithAI(result: ReceiptScanner.ReceiptScanResult, filename: String) async {
        defer { isScanningReceipt = false }
        receiptDateUsesCapture = !result.dateWasPrinted
        do {
            let jsonString = try await LocalLLMService.shared.extractReceiptData(
                prompt: result.rawText, categories: categories.map { $0.name }
            )
            if let data = jsonString.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let shopName = (json["shopName"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let title = shopName.isEmpty || shopName == "Store Name" ? result.legacyTitle : shopName
                let category = (json["category"] as? String) ?? suggestedCategory(for: result.rawText)
                // Amounts and dates come from the deterministic OCR parser, never a model guess.
                addExpense(title: title, amount: result.legacyAmount, date: result.receiptDate,
                           category: category, filename: filename)
                return
            }
        } catch {
            // A busy or unavailable model still leaves a reviewable OCR result.
        }
        addExpense(title: result.legacyTitle, amount: result.legacyAmount, date: result.receiptDate,
                   category: suggestedCategory(for: result.rawText), filename: filename)
    }

    private func suggestedCategory(for receiptText: String) -> String {
        ReceiptCategoryPolicy.suggestedCategory(
            text: receiptText, existingCategories: categories.map { $0.name },
            language: lm.currentLanguage == .japanese ? "ja" : "en"
        )
    }

    // `addExpense` という関数を定義し、括弧内の入力を使って処理します。
    private func addExpense(title: String, amount: Int, date: Date, category: String, filename: String?) {
        // Persist useful new categories so they are also available to later receipts and backups.
        if !["未分類", "Unclassified"].contains(category),
           !categories.contains(where: { $0.name.compare(category, options: [.caseInsensitive, .widthInsensitive]) == .orderedSame }) {
            modelContext.insert(Category(name: category, icon: "tag.fill", colorHex: "#7E8CE0"))
        }
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
    
    private func deleteExpense(offsets: IndexSet) {
        withAnimation { offsets.map { sortedExpenses[$0] }.forEach(modelContext.delete) }
    }

    private func saveImageToDocuments(image: UIImage) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "ReceiptImage", code: 1, userInfo: [NSLocalizedDescriptionKey:
                lm.currentLanguage == .japanese ? "レシート画像を保存できませんでした。もう一度撮影してください。"
                                               : "The receipt image could not be saved. Please scan it again."])
        }
        let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                     appropriateFor: nil, create: true)
        let filename = UUID().uuidString + ".jpg"
        try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
        return filename
    }

    private func generateDailyAdvice() {
        guard LocalLLMService.shared.isReady, !isAdviceLoading else { return }
        isAdviceLoading = true
        Task { @MainActor in
            defer { isAdviceLoading = false }
            let context = FinancialDataSummary.moneyTipContext(assets: assets, expenses: expenses)
            do {
                aiAdviceText = try await LocalLLMService.shared.generateAdvice(context: context)
            } catch {
                receiptError = error.localizedDescription
            }
        }
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
