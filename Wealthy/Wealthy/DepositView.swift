//
//  DepositView.swift
//  Wealthy
//
//  Created by Harrison on 12/27/25.
//

import SwiftUI
import SwiftData

struct DepositView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query var assets: [Asset]
    @Query var categories: [Category]
    
    @State private var amount = 0
    @State private var title = ""
    @State private var selectedAsset: Asset?
    @State private var date = Date()
    @State private var selectedCategoryName: String = "未分類"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                Form {
                    Section("入金情報") {
                        TextField("タイトル (例: お小遣い, 臨時収入)", text: $title)
                        
                        HStack {
                            Text("¥").foregroundStyle(.gray)
                            TextField("0", value: $amount, format: .number)
                                .keyboardType(.numberPad)
                                .font(.title2.bold())
                                .foregroundStyle(.green) // 収入なので緑
                        }
                    }
                    
                    Section("詳細") {
                        // 日付
                        DatePicker("日付", selection: $date, displayedComponents: .date)
                        
                        // 入金先財布
                        Picker("入金先", selection: $selectedAsset) {
                            Text("選択してください").tag(nil as Asset?)
                            ForEach(assets) { asset in
                                Text(asset.name).tag(asset as Asset?)
                            }
                        }
                        
                        // カテゴリ（既存のものから選択）
                        Picker("カテゴリ", selection: $selectedCategoryName) {
                            Text("未分類").tag("未分類")
                            // 収入っぽいカテゴリがあればそれを選べるようにする
                            ForEach(categories) { cat in
                                Text(cat.name).tag(cat.name)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("資金の追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        saveDeposit()
                    }
                    .disabled(amount == 0 || selectedAsset == nil)
                    .foregroundStyle(.green) // 収入なので緑
                }
            }
            .onAppear {
                // デフォルトで最初の財布を選択
                if selectedAsset == nil {
                    selectedAsset = assets.first
                }
            }
        }
    }
    
    private func saveDeposit() {
        guard let asset = selectedAsset else { return }
        
        // 1. タイトルが空ならデフォルトを入れる
        let finalTitle = title.isEmpty ? "資金追加" : title
        
        // 2. 収入として履歴を作成 (isIncome: true)
        let newIncome = Expense(
            title: finalTitle,
            amount: amount,
            date: date,
            assetName: asset.name,
            isIncome: true, // ★重要: これで収入として扱われます
            categoryName: selectedCategoryName
        )
        
        // 3. 財布の残高を増やす
        asset.balance += amount
        
        // 4. 保存
        modelContext.insert(newIncome)
        dismiss()
    }
}
