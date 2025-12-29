//
//  AssetsView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData

struct AssetsView: View {
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var lm: LanguageManager
    @Query var assets: [Asset]
    
    @State private var showingAddAsset = false
    @State private var assetToEdit: Asset?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    // 資産リスト
                    Section(lm.t(.wallets)) {
                        ForEach(assets) { asset in
                            Button { assetToEdit = asset } label: {
                                HStack {
                                    Circle().fill(Color(hex: asset.colorHex)).frame(width: 40, height: 40)
                                        .overlay(Image(systemName: "creditcard.fill").foregroundStyle(.white).font(.caption))
                                    VStack(alignment: .leading) { Text(asset.name).font(.headline).foregroundStyle(.white) }
                                    Spacer()
                                    Text("\(lm.currencySymbol)\(asset.balance)").font(.title3.bold()).foregroundStyle(.white)
                                }
                            }
                            .listRowBackground(Color(white: 0.1))
                            .swipeActions {
                                Button(role: .destructive) { modelContext.delete(asset) } label: { Label(lm.t(.delete), systemImage: "trash") }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                
                // 追加ボタン
                VStack {
                    Spacer()
                    Button { showingAddAsset = true } label: {
                        HStack { Image(systemName: "plus"); Text(lm.t(.add)) }
                            .font(.headline).foregroundStyle(.black).padding()
                            .frame(maxWidth: .infinity).background(Color.white).cornerRadius(15).padding()
                    }
                }
            }
            .navigationTitle(lm.t(.wallets))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingAddAsset) { AddAssetView() }
            .sheet(item: $assetToEdit) { asset in EditAssetView(asset: asset) }
        }
    }
}

// ■ 以下、足りなかった部品（サブルーチン）を全て定義しました

// 1. 資産追加画面
struct AddAssetView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @EnvironmentObject var lm: LanguageManager
    
    @State private var name = ""
    @State private var balance = 0
    @State private var selectedColor = "FFA500"
    let colors = ["FFA500", "FF4500", "32CD32", "1E90FF", "8A2BE2", "FF69B4", "808080", "000000"]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Wallet Name", text: $name)
                TextField("Initial Balance", value: $balance, format: .number).keyboardType(.numberPad)
                
                Section("Color") {
                    HStack {
                        ForEach(colors, id: \.self) { color in
                            Circle().fill(Color(hex: color))
                                .frame(width: 30, height: 30)
                                .overlay(selectedColor == color ? Image(systemName: "checkmark").foregroundStyle(.white) : nil)
                                .onTapGesture { selectedColor = color }
                        }
                    }
                }
            }
            .navigationTitle(lm.t(.add))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(lm.t(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.t(.save)) {
                        let newAsset = Asset(name: name, balance: balance, colorHex: selectedColor)
                        modelContext.insert(newAsset)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// 2. 資産編集画面 (これが見つからないエラーが出ていました)
struct EditAssetView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lm: LanguageManager
    @Bindable var asset: Asset
    
    let colors = ["FFA500", "FF4500", "32CD32", "1E90FF", "8A2BE2", "FF69B4", "808080", "000000"]
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Wallet Name", text: $asset.name)
                // バランス修正時は手動修正とする
                TextField("Balance", value: $asset.balance, format: .number).keyboardType(.numberPad)
                
                Section("Color") {
                    HStack {
                        ForEach(colors, id: \.self) { color in
                            Circle().fill(Color(hex: color))
                                .frame(width: 30, height: 30)
                                .overlay(asset.colorHex == color ? Image(systemName: "checkmark").foregroundStyle(.white) : nil)
                                .onTapGesture { asset.colorHex = color }
                        }
                    }
                }
            }
            .navigationTitle(lm.t(.edit))
            .toolbar {
                Button(lm.t(.save)) { dismiss() }
            }
        }
    }
}

// 3. Hex色指定を使うための拡張 (これがなくてエラーが出ていました)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
