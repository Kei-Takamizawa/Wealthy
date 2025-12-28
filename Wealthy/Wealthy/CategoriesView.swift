//
//  CategoriesView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @Query var categories: [Category]
    
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if categories.isEmpty {
                    ContentUnavailableView("No Categories", systemImage: "tray")
                } else {
                    List {
                        ForEach(categories) { category in
                            HStack {
                                Circle()
                                    .fill(Color(hex: category.colorHex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: category.icon)
                                            .foregroundStyle(.white)
                                            .font(.caption)
                                    )
                                Text(category.name)
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                            .listRowBackground(Color(white: 0.1))
                        }
                        .onDelete { indexSet in
                            for index in indexSet { modelContext.delete(categories[index]) }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("カテゴリ設定")
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
                AddCategoryForm()
            }
        }
    }
}

// 追加フォーム
struct AddCategoryForm: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var selectedIcon = "cart.fill"
    @State private var selectedColor = "FFA500"
    
    // プリセットアイコン
    let icons = ["cart.fill", "fork.knife", "bus", "house.fill", "tshirt.fill", "gamecontroller.fill", "book.fill", "cross.case.fill", "wifi", "gift.fill"]
    let colors = ["FFA500", "FF4500", "32CD32", "1E90FF", "8A2BE2", "FF69B4", "808080"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("基本情報") {
                    TextField("カテゴリ名 (例: 食費)", text: $name)
                }
                
                Section("アイコン") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 10) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? Color.orange.opacity(0.3) : Color.clear)
                                .cornerRadius(8)
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical)
                }
                
                Section("カラー") {
                    HStack {
                        ForEach(colors, id: \.self) { hex in
                            Circle().fill(Color(hex: hex)).frame(width: 30, height: 30)
                                .overlay(Image(systemName: "checkmark").foregroundStyle(.white).opacity(selectedColor == hex ? 1 : 0))
                                .onTapGesture { selectedColor = hex }
                        }
                    }
                }
            }
            .navigationTitle("新規カテゴリ")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let newCat = Category(name: name, icon: selectedIcon, colorHex: selectedColor)
                        modelContext.insert(newCat)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}
