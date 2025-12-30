//
//  DashboardView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DashboardView: View {
    // ■ 言語マネージャーを受け取る
    @EnvironmentObject var lm: LanguageManager
    
    @Query(sort: \Expense.date, order: .reverse) var expenses: [Expense]
    @Query var assets: [Asset]
    @Query var categories: [Category]
    @Environment(\.modelContext) var modelContext
    
    @State private var showScanner = false
    @State private var showDeposit = false
    @State private var scannedImage: UIImage?
    @State private var expenseToEdit: Expense?
    @State private var isNewEditingEntry = false
    @State private var sortOption = SortOption.dateDesc
    
    enum SortOption { case dateDesc, dateAsc, amountDesc, amountAsc }
    
    var sortedExpenses: [Expense] { /* 変更なし */
        switch sortOption {
        case .dateDesc: return expenses.sorted { $0.date > $1.date }
        case .dateAsc: return expenses.sorted { $0.date < $1.date }
        case .amountDesc: return expenses.sorted { $0.amount > $1.amount }
        case .amountAsc: return expenses.sorted { $0.amount < $1.amount }
        }
    }
    var totalBalance: Int { assets.reduce(0) { $0 + $1.balance } }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // AI Ticker
                    // AI Ticker
                    if !aiAdviceText.isEmpty {
                        AITickerView(text: aiAdviceText, onTapSparkle: {
                            generateDailyAdvice(forceRefresh: true)
                        }, onFinish: {
                             // Hide after one run
                             withAnimation {
                                 aiAdviceText = ""
                             }
                        })
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    } else {
                        // Show just sparkle button if hidden? or just empty space?
                        // User said "Initially nothing". "When sparkles button tapped..."
                        // Wait, if hidden, how to tap sparkles?
                        // I should show the Sparkles Button regardless?
                        // "Trigger AI content generation only when the 'sparkles' icon is tapped."
                        // If Ticker is hidden, we need a trigger button.
                        HStack {
                            Button(action: {
                                generateDailyAdvice(forceRefresh: true)
                            }) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.yellow)
                                    .padding(12)
                                    .background(Color(white: 0.12))
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                        
                    headerView
                    actionButtonsView
                    walletListView
                    historyListView
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showScanner) { ScannerView(scannedImage: $scannedImage).ignoresSafeArea() }
            .sheet(isPresented: $showDeposit) { DepositView() }
            .sheet(item: $expenseToEdit) { expense in 
                EditExpenseView(expense: expense, isNewEntry: isNewEditingEntry) 
            }
            .sheet(isPresented: $showSettings) { AdvancedSettingsView() }
            .sheet(isPresented: $showChat) { ChatView() }
            .onAppear {
                // Initial load removed as per request
            }
            // ... (rest of modifiers)

    

            .onChange(of: scannedImage) {
                if let img = scannedImage {
                     let filename = saveImageToDocuments(image: img)
                     
                     Task {
                         // 1. まずOCRで生テキストなどを取得
                         let result = await ReceiptScanner.scan(image: img)
                         self.currentScanResult = result
                         self.tempImageFilename = filename
                         
                         // 2. モデルがインストール済みか確認
                         if LocalLLMService.shared.isModelInstalled {
                             await processWithAI(result: result, filename: filename)
                         } else {
                             // 未インストールなら旧方式
                             processLegacy(result: result, filename: filename)
                         }
                     }
                 }
            }
            // Removed AI Download Alert Modifier
            }
            .overlay {
                Group {
                    if !LocalLLMService.shared.loadStatus.contains("準備完了") && LocalLLMService.shared.loadStatus != "未インストール" && LocalLLMService.shared.loadStatus != "準備中..." {
                        ZStack {
                            Color.black.opacity(0.6).ignoresSafeArea()
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                Text(LocalLLMService.shared.loadStatus)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                if LocalLLMService.shared.downloadProgress > 0 && LocalLLMService.shared.downloadProgress < 1.0 {
                                    ProgressView(value: LocalLLMService.shared.downloadProgress)
                                        .progressViewStyle(.linear)
                                        .frame(width: 200)
                                }
                            }
                            .padding(40)
                            .background(Color(white: 0.2))
                            .cornerRadius(20)
                        }
                    } else if isScanningReceipt {
                        ZStack {
                            Color.black.opacity(0.6).ignoresSafeArea()
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                Text("AIがレシートを解析中...")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .padding(40)
                            .background(Color(white: 0.2))
                            .cornerRadius(20)
                        }
                    }
                }
            }
        }


    
    // 一時保持用
    @State private var currentScanResult: ReceiptScanner.ReceiptScanResult?
    @State private var tempImageFilename: String?

    @State private var showSettings = false
    @State private var showChat = false
    
    // Ticker State
    @State private var aiAdviceText: String = "" // Initially hidden
    @State private var isAdviceLoading = false
    @State private var isScanningReceipt = false
    
    // AI処理
    private func processWithAI(result: ReceiptScanner.ReceiptScanResult, filename: String?) async {
        isScanningReceipt = true
        defer { isScanningReceipt = false }
        
        do {
            let catNames = categories.map { $0.name }
            let jsonString = try await LocalLLMService.shared.extractReceiptData(prompt: result.rawText, categories: catNames)
            
            if let data = jsonString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                
                let amount = json["amount"] as? Int ?? result.legacyAmount
                let shopName = json["shopName"] as? String ?? result.legacyTitle
                let categoryName = json["category"] as? String ?? "未分類"
                
                // 日付解析
                var date = Date()
                if let dateString = json["date"] as? String {
                     let formatter = DateFormatter()
                     formatter.dateFormat = "yyyy-MM-dd"
                     if let d = formatter.date(from: dateString) {
                         date = d
                     }
                }
                
                let finalAmount = amount > 0 ? amount : result.legacyAmount
                let finalTitle = (shopName.isEmpty || shopName == "Store Name") ? result.legacyTitle : shopName
                
                await MainActor.run {
                    addExpense(title: finalTitle, amount: finalAmount, date: date, category: categoryName, filename: filename)
                }
                return
            }
        } catch {
            print("AI Error: \(error)")
        }
        processLegacy(result: result, filename: filename)
    }
    
    // 旧方式
    private func processLegacy(result: ReceiptScanner.ReceiptScanResult, filename: String?) {
        let title = result.legacyTitle
        let amount = result.legacyAmount
        let predictedCategory = predictCategory(title: title)
        addExpense(title: title, amount: amount, date: Date(), category: predictedCategory, filename: filename)
    }
    
    private func addExpense(title: String, amount: Int, date: Date, category: String, filename: String?) {
        let newExpense = Expense(title: title, amount: amount, date: date, imageFilename: filename, isIncome: false, categoryName: category)
        if let mainAsset = assets.first {
            mainAsset.balance -= amount
            newExpense.assetName = mainAsset.name
        }
        modelContext.insert(newExpense)
        isNewEditingEntry = true
        expenseToEdit = newExpense
        scannedImage = nil
        currentScanResult = nil
        tempImageFilename = nil
    }
    
    struct WalletFlipCard: View {
        let asset: Asset
        let allExpenses: [Expense]
        // ■ 環境変数追加
        @EnvironmentObject var lm: LanguageManager
        @State private var rotation: Double = 0
        
        var stats: (income: Int, expense: Int) { /* 変更なし */
            let related = allExpenses.filter { $0.assetName == asset.name }
            let inc = related.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
            let exp = related.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
            return (inc, exp)
        }
        
        var body: some View {
            ZStack {
                let angle = rotation.truncatingRemainder(dividingBy: 360)
                let isFront = angle < 90 || angle > 270
                
                if isFront {
                    VStack(alignment: .leading) {
                        HStack { Image(systemName: "creditcard.fill"); Spacer(); Text(asset.name).bold() }
                        Spacer()
                        // ■ 通貨記号
                        Text("\(lm.currencySymbol)\(asset.balance)").font(.title2).bold().contentTransition(.numericText())
                    }
                    .padding().background(Color(hex: asset.colorHex).opacity(0.8)).foregroundStyle(.white).cornerRadius(15)
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(.white.opacity(0.2), lineWidth: 1))
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        // ■ 言語対応: History
                        Text(lm.t(.history)).font(.caption2).bold().foregroundStyle(.white.opacity(0.7))
                        HStack {
                            Image(systemName: "arrow.up.right").foregroundStyle(.green)
                            // ■ 通貨記号
                            Text("\(lm.currencySymbol)\(stats.income)")
                        }
                        HStack {
                            Image(systemName: "arrow.down.right").foregroundStyle(.red)
                            // ■ 通貨記号
                            Text("\(lm.currencySymbol)\(stats.expense)")
                        }
                    }
                    .font(.subheadline.bold())
                    .padding().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .background(Color(hex: asset.colorHex).opacity(0.3)).background(.black).foregroundStyle(.white).cornerRadius(15)
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color(hex: asset.colorHex), lineWidth: 2))
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
            }
            .frame(width: 160, height: 140)
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            .onTapGesture { withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { rotation += 180 } }
        }
    }
    
    // (Helper関数は省略、変更なし)
    private func predictCategory(title: String) -> String { return "未分類" }
    private func deleteExpense(offsets: IndexSet) { withAnimation { offsets.map { sortedExpenses[$0] }.forEach(modelContext.delete) } }
    private func saveImageToDocuments(image: UIImage) -> String? { return nil }
    
    // AI Advice Generation
    private func generateDailyAdvice(forceRefresh: Bool = false) {
        // Prevent multiple calls
        guard LocalLLMService.shared.isModelInstalled, !isAdviceLoading else {
            return
        }
        
        isAdviceLoading = true
        
        // Silent update: Don't change text to "Loading..."
        // unless it's the very first load and empty? 
        // User wants: Loop existing text if not tapped. Update on tap.
        // If empty, maybe show default "Wealthy Butler" until loaded.
        
        Task {
            // Build Context (Brief)
            let context = FinancialDataSummary.generate(
                assets: assets,
                expenses: expenses,
                categories: categories,
                languageManager: lm
            )
            
            do {
                let advice = try await LocalLLMService.shared.generateAdvice(context: context)
                
                await MainActor.run {
                    self.aiAdviceText = advice.replacingOccurrences(of: "\"", with: "")
                    self.isAdviceLoading = false
                }
            } catch {
                await MainActor.run {
                    // unexpected error, keep old text or set default
                    if self.aiAdviceText == "Wealthy Butler" || self.aiAdviceText.isEmpty {
                         self.aiAdviceText = "Wealthy Butler"
                    }
                    self.isAdviceLoading = false
                }
            }
        }
    }

    // MARK: - Subviews
    
    // 1. Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(lm.t(.totalAssets)).font(.caption).foregroundStyle(.gray)
                Text("\(lm.currencySymbol)\(totalBalance)")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            Spacer()
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill").font(.title).foregroundStyle(.gray)
            }
        }
        .padding(.horizontal).padding(.top)
    }
    
    // 2. Action Buttons
    private var actionButtonsView: some View {
        HStack(spacing: 20) {
            ActionButton(icon: "camera.viewfinder", label: lm.t(.scan), color: .orange) { showScanner = true }
            ActionButton(icon: "plus.circle.fill", label: lm.t(.deposit), color: .green) { showDeposit = true }
            ActionButton(icon: "square.and.pencil", label: lm.t(.manualInput), color: .blue) {
                let newExpense = Expense(title: "", amount: 0, date: Date(), isIncome: false, categoryName: "未分類")
                modelContext.insert(newExpense)
                isNewEditingEntry = true
                expenseToEdit = newExpense
            }
            // Butler Button
            ActionButton(icon: "bubble.left.and.bubble.right.fill", label: lm.t(.aiButler), color: .purple) {
                showChat = true
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    
    // 3. Wallet List
    private var walletListView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(assets) { asset in
                    WalletFlipCard(asset: asset, allExpenses: expenses)
                }
            }
            .padding(.horizontal).padding(.vertical, 10)
        }
    }
    
    // 4. History List
    private var historyListView: some View {
        VStack(alignment: .leading) {
            Text(lm.t(.history)).font(.headline).foregroundStyle(.gray).padding(.horizontal)
            if sortedExpenses.isEmpty {
                ContentUnavailableView {
                    Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 40))
                    .foregroundStyle(.gray.opacity(0.5))
                } description: {
                    Text(lm.t(.noExpenses)).foregroundStyle(.gray)
                }
            } else {
                List {
                    ForEach(sortedExpenses) { expense in
                        Button {
                            isNewEditingEntry = false
                            expenseToEdit = expense
                        } label: {
                            HStack {
                                HStack {
                                    let category = categories.first(where: { $0.name == expense.categoryName })
                                    Image(systemName: category?.icon ?? "questionmark.circle")
                                        .foregroundStyle(Color(hex: category?.colorHex ?? "808080"))
                                        .frame(width: 30)
                                    Text(lm.translateCategory(name: expense.categoryName ?? lm.t(.unclassified)))
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                VStack(alignment: .leading) {
                                    Text(expense.title).font(.body.bold()).foregroundStyle(.white)
                                    Text(expense.date.formatted(date: .numeric, time: .omitted)).font(.caption).foregroundStyle(.gray)
                                }
                                Spacer()
                                Text((expense.isIncome ? "+ " : "- ") + "\(lm.currencySymbol)\(expense.amount)")
                                    .foregroundStyle(expense.isIncome ? .green : .red).bold()
                            }
                        }
                        .listRowBackground(Color(white: 0.1))
                    }
                    .onDelete(perform: deleteExpense)
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
            }
        }
    }
}

    struct ActionButton: View {
        let icon: String
        let label: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                    Text(label)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(Color(white: 0.12))
                .cornerRadius(16)
                // .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.3), lineWidth: 1)) // Optional: more subtle border
            }
        }
    }


struct AdvancedSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var lm: LanguageManager
    @State private var isProcessing = false // Feedback state
    
    // Backup State
    @State private var showFileExporter = false
    @State private var showFileImporter = false
    @State private var backupDocument: BackupDocument?
    @State private var alertMessage = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                // 言語設定
                Section(header: Text(lm.t(.languageSettings))) {
                    Picker(selection: $lm.currentLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.rawValue).tag(lang)
                        }
                    } label: {
                        Text(lm.t(.languageSettings))
                    }
                    .pickerStyle(.menu)
                }
                
                // 一般設定
                Section(header: Text(lm.t(.settings))) {
                    NavigationLink(destination: RecurringSettingsView()) {
                        Label(lm.t(.recurring), systemImage: "repeat.circle.fill")
                    }
                    NavigationLink(destination: CategoriesView()) {
                        Label(lm.t(.category), systemImage: "tag.fill")
                    }
                }
                
                // データ管理 (バックアップ)
                Section(header: Text(lm.t(.dataManagement)), footer: Text(lm.t(.backupDesc))) {
                    Button {
                        createBackup()
                    } label: {
                        Label(lm.t(.backup), systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showFileImporter = true
                    } label: {
                        Label(lm.t(.restore), systemImage: "square.and.arrow.down")
                    }
                }
                
                Section(header: Text(lm.t(.aiModelManagement)), footer: Text(lm.t(.modelDescription))) {
                    NavigationLink(destination: ModelSettingsView()) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(LocalLLMService.shared.currentModel.name)
                                    .font(.headline)
                                Text(LocalLLMService.shared.loadStatus)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            if LocalLLMService.shared.isModelInstalled {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle(lm.t(.settings))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(lm.t(.close)) { dismiss() }
                }
            }
            // Modifiers for Backup
            .fileExporter(isPresented: $showFileExporter, document: backupDocument, contentType: .json, defaultFilename: "Wealthy_Backup") { result in
                switch result {
                case .success(_):
                    alertMessage = lm.t(.backupSuccess)
                    showAlert = true
                case .failure(let error):
                    alertMessage = "\(lm.t(.error)): \(error.localizedDescription)"
                    showAlert = true
                }
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    do {
                        try BackupManager.shared.restoreBackup(from: url, context: modelContext)
                        alertMessage = lm.t(.restoreSuccess)
                        showAlert = true
                    } catch {
                        alertMessage = "\(lm.t(.error)): \(error.localizedDescription)"
                        showAlert = true
                    }
                case .failure(let error):
                    alertMessage = "\(lm.t(.error)): \(error.localizedDescription)"
                    showAlert = true
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertMessage))
            }
        }
    }
    
    private func createBackup() {
        do {
            let url = try BackupManager.shared.createBackupURL(context: modelContext)
            let json = try String(contentsOf: url, encoding: .utf8)
            backupDocument = BackupDocument(text: json)
            showFileExporter = true
        } catch {
            alertMessage = "\(lm.t(.error)): \(error.localizedDescription)"
            showAlert = true
        }
    }
}
