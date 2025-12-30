//
//  CategoriesView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

import SwiftUI
import SwiftData
import UIKit

struct CategoriesView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var lm: LanguageManager
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
                                        Group {
                                            if UIImage(systemName: category.icon) != nil {
                                                Image(systemName: category.icon)
                                                    .foregroundStyle(.white)
                                                    .font(.caption)
                                            } else {
                                                Text(category.icon)
                                                    .font(.caption)
                                            }
                                        }
                                    )
                                Text(lm.translateCategory(name: category.name))
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
            .navigationTitle(lm.t(.categorySettings))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: { Image(systemName: "plus") }
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
    @EnvironmentObject var lm: LanguageManager
    
    @State private var name = ""
    @State private var selectedIcon = "cart.fill"
    @State private var selectedColor = "FFA500"
    
    // Advanced Customization
    @State private var emojiText = ""
    @State private var customColor = Color.orange
    
    // プリセットアイコン (Expanded)
    // Expanded Icons List (Approx 50+)
    let icons = [
        "cart.fill", "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "birthday.cake.fill", "takeoutbag.and.cup.and.straw.fill",
        "car.fill", "bus.fill", "tram.fill", "airplane", "bicycle", "fuelpump.fill", "steeringwheel", "figure.walk",
        "house.fill", "bed.double.fill", "chair.lounge.fill", "lightbulb.fill", "washer.fill", "shower.fill", "trash.fill",
        "tshirt.fill", "shoe.fill", "scissors", "medical.thermometer.fill", "pills.fill", "heart.fill", "cross.case.fill", "comb.fill",
        "gamecontroller.fill", "tv.fill", "headphones", "book.fill", "ticket.fill", "music.note", "theatermasks.fill",
        "iphone", "desktopcomputer", "laptopcomputer", "printer.fill", "cable.connector", "camera.fill",
        "banknote.fill", "creditcard.fill", "case.fill", "briefcase.fill", "chart.bar.fill", "scroll.fill", "doc.text.fill",
        "gift.fill", "pawprint.fill", "leaf.fill", "wifi", "graduationcap.fill", "airplane.departure", "hammer.fill",
        "envelope.fill", "phone.fill", "video.fill", "photo.fill", "globe", "sun.max.fill", "moon.fill", "cloud.rain.fill",
        "umbrella.fill", "flame.fill", "drop.fill", "bolt.fill", "star.fill", "flag.fill", "bell.fill", "tag.fill"
    ]
    
    // Expanded Colors List (Approx 30+)
    let colors = [
        "FF4500", "FF6347", "FF7F50", "DC143C", "B22222", "8B0000", // Reds/Oranges
        "FFA500", "FF8C00", "DAA520", "FFD700", "FFFF00", "F0E68C", // Yellows/Golds
        "32CD32", "228B22", "008000", "006400", "66CDAA", "8FBC8F", // Greens
        "1E90FF", "00BFFF", "87CEEB", "4169E1", "0000FF", "000080", // Blues
        "8A2BE2", "9370DB", "800080", "4B0082", "FF00FF", "FF69B4", // Purples/Pinks
        "A52A2A", "8B4513", "D2691E", "F4A460", "D2B48C", "808080", "2F4F4F", "000000" // Browns/Grays
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(lm.t(.basicInfo)) {
                    TextField(lm.t(.categoryName), text: $name)
                }
                
                Section(lm.t(.icon)) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 45))], spacing: 15) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 45, height: 45)
                                .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.3) : Color.clear)
                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : .gray)
                                .cornerRadius(8)
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical)
                }
                
                Section(lm.t(.color)) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(colors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.white)
                                            .opacity(selectedColor == hex ? 1 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = hex
                                    }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle(lm.t(.newCategory))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(lm.t(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.t(.save)) {
                        let newCat = Category(name: name, icon: selectedIcon, colorHex: selectedColor)
                        modelContext.insert(newCat)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    // Removed colorToHex since we only use presets now
}
