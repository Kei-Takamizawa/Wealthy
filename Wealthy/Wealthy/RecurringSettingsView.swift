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
    @EnvironmentObject var lm: LanguageManager
    
    @Query var recurringItems: [RecurringItem]
    @Query var assets: [Asset]
    
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if recurringItems.isEmpty {
                    ContentUnavailableView {
                        Label(lm.t(.noRecurringItems), systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text(lm.t(.recurringDesc))
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
            .navigationTitle(lm.t(.recurringSettings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: { Image(systemName: "plus") }
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
    @EnvironmentObject var lm: LanguageManager
    var assets: [Asset]
    
    @State private var title = ""
    @State private var amount = 0
    @State private var day = 25
    @State private var isIncome = false // false=支出, true=収入
    @State private var selectedAsset = "現金"
    
    var body: some View {
        NavigationStack {
            Form {
                Section(lm.t(.basicInfo)) {
                    TextField(lm.t(.shopName), text: $title)
                    TextField(lm.t(.amount), value: $amount, format: .number)
                        .keyboardType(.numberPad)
                    
                    Picker(lm.t(.type), selection: $isIncome) {
                        Text(lm.t(.expense)).tag(false)
                        Text(lm.t(.income)).tag(true)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("スケジュール") {
                    Picker(lm.t(.monthlyDate), selection: $day) {
                        ForEach(1...31, id: \.self) { d in
                            Text("\(d)").tag(d)
                        }
                    }
                    
                    Picker("対象の財布", selection: $selectedAsset) {
                        ForEach(assets) { asset in
                            Text(asset.name).tag(asset.name)
                        }
                    }
                }
            }
            .navigationTitle(lm.t(.newRule))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(lm.t(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.t(.save)) {
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
