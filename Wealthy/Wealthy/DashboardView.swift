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
                    // ヘッダー
                    HStack {
                        VStack(alignment: .leading) {
                            // ■ 言語対応: Total Assets
                            Text(lm.t(.totalAssets)).font(.caption).foregroundStyle(.gray)
                            // ■ 言語対応: 通貨記号
                            Text("\(lm.currencySymbol)\(totalBalance)")
                                .font(.system(size: 34, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText())
                        }
                        Spacer()
                        Menu {
                            Button("Newest", action: { sortOption = .dateDesc })
                            Button("Oldest", action: { sortOption = .dateAsc })
                        } label: {
                            Image(systemName: "arrow.up.arrow.down.circle.fill").font(.title).foregroundStyle(.orange)
                        }
                    }
                    .padding(.horizontal).padding(.top)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            Button { showScanner = true } label: {
                                VStack {
                                    Image(systemName: "camera.viewfinder").font(.largeTitle)
                                    // ■ 言語対応: SCAN
                                    Text(lm.t(.scan)).font(.caption).bold()
                                }
                                .frame(width: 90, height: 140)
                                .background(Color.orange).foregroundStyle(.black).cornerRadius(15)
                            }
                            
                            Button { showDeposit = true } label: {
                                VStack {
                                    Image(systemName: "plus.circle.fill").font(.largeTitle)
                                    // ■ 言語対応: DEPOSIT
                                    Text(lm.t(.deposit)).font(.caption).bold()
                                }
                                .frame(width: 90, height: 140)
                                .background(Color(white: 0.15)).foregroundStyle(.green).cornerRadius(15)
                                .overlay(RoundedRectangle(cornerRadius: 15).stroke(.green.opacity(0.5), lineWidth: 1))
                            }
                            
                            ForEach(assets) { asset in
                                WalletFlipCard(asset: asset, allExpenses: expenses)
                            }
                        }
                        .padding(.horizontal).padding(.vertical, 10)
                    }
                    
                    VStack(alignment: .leading) {
                        // ■ 言語対応: History
                        Text(lm.t(.history)).font(.headline).foregroundStyle(.gray).padding(.horizontal)
                        List {
                            ForEach(sortedExpenses) { expense in
                                Button { expenseToEdit = expense } label: {
                                    HStack {
                                        // カテゴリとアイコン
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
                                        // ■ 言語対応: 通貨記号
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
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $showScanner) { ScannerView(scannedImage: $scannedImage).ignoresSafeArea() }
            .sheet(isPresented: $showDeposit) { DepositView() }
            .sheet(item: $expenseToEdit) { expense in EditExpenseView(expense: expense) }
            .onChange(of: scannedImage) { /* 省略（変更なし） */
                if let img = scannedImage {
                     let filename = saveImageToDocuments(image: img)
                     ReceiptScanner.scan(image: img) { title, amount in
                         let predictedCategory = predictCategory(title: title)
                         let newExpense = Expense(title: title, amount: amount, date: Date(), imageFilename: filename, isIncome: false, categoryName: predictedCategory)
                         if let mainAsset = assets.first {
                             mainAsset.balance -= amount
                             newExpense.assetName = mainAsset.name
                         }
                         modelContext.insert(newExpense)
                         expenseToEdit = newExpense
                         scannedImage = nil
                     }
                 }
            }
        }
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
}
