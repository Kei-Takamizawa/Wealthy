//
//  RecurringSettingsView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData

struct RecurringSettingsView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query var recurringItems: [RecurringItem]
    @Query var assets: [Asset]
    
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if recurringItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Recurring Items", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("毎月の固定給やサブスクを登録しよう")
                    }
                    .foregroundStyle(.gray)
                } else {
                    List {
                        ForEach(recurringItems) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    HStack {
                                        Text("毎月 \(item.dayOfMonth)日")
                                        Text("•")
                                        Text(item.assetName)
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                }
                                
                                Spacer()
                                
                                Text("¥\(item.amount)")
                                    .font(.title3.bold())
                                    // 収入は緑、支出は赤
                                    .foregroundStyle(item.isIncome ? .green : .red)
                            }
                            .listRowBackground(Color(white: 0.1))
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                modelContext.delete(recurringItems[index])
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("固定収支の設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: { Image(systemName: "plus") }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddRecurringForm(assets: assets)
            }
        }
    }
}

// 追加フォーム
struct AddRecurringForm: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    var assets: [Asset]
    
    @State private var title = ""
    @State private var amount = 0
    @State private var day = 25
    @State private var isIncome = false // false=支出, true=収入
    @State private var selectedAsset = "現金"
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("タイトル (例: 給料, 家賃)", text: $title)
                    TextField("金額", value: $amount, format: .number)
                        .keyboardType(.numberPad)
                    
                    Picker("タイプ", selection: $isIncome) {
                        Text("支出 (支払)").tag(false)
                        Text("収入 (入金)").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("スケジュール") {
                    Picker("毎月の日付", selection: $day) {
                        ForEach(1...31, id: \.self) { d in
                            Text("\(d)日").tag(d)
                        }
                    }
                    
                    Picker("対象の財布", selection: $selectedAsset) {
                        ForEach(assets) { asset in
                            Text(asset.name).tag(asset.name)
                        }
                    }
                }
            }
            .navigationTitle("新規ルール作成")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let newItem = RecurringItem(title: title, amount: amount, dayOfMonth: day, isIncome: isIncome, assetName: selectedAsset)
                        modelContext.insert(newItem)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
