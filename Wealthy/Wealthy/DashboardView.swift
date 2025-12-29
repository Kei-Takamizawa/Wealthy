//
//  DashboardView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData

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
                    } else if LocalLLMService.shared.isThinking {
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
    
    // AI処理
    private func processWithAI(result: ReceiptScanner.ReceiptScanResult, filename: String?) async {
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
    @EnvironmentObject var lm: LanguageManager
    @State private var isProcessing = false // Feedback state
    
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
                
                Section(header: Text(lm.t(.aiModelManagement)), footer: Text(lm.t(.modelDescription))) {
                    if isProcessing {
                        HStack {
                            ProgressView()
                            Text("Processing...") // Simple feedback
                        }
                    } else if LocalLLMService.shared.isModelInstalled {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text(lm.t(.installed))
                        }
                        Button(role: .destructive) {
                            isProcessing = true
                            // Simulate async delay for feedback
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                LocalLLMService.shared.deleteModel()
                                isProcessing = false
                            }
                        } label: {
                            Text(lm.t(.deleteModel))
                        }
                    } else {
                        VStack(alignment: .leading) {
                            Text(lm.t(.uninstalled)).foregroundStyle(.gray)
                            if LocalLLMService.shared.downloadProgress > 0 && LocalLLMService.shared.downloadProgress < 1.0 {
                                ProgressView(value: LocalLLMService.shared.downloadProgress) {
                                    Text("\(lm.t(.downloading)): \(Int(LocalLLMService.shared.downloadProgress * 100))%")
                                }
                            } else {
                                Button("\(lm.t(.download)) (~2GB)") {
                                    isProcessing = true
                                    Task {
                                        await LocalLLMService.shared.loadModel()
                                        isProcessing = false
                                    }
                                }
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
        }
    }
}
