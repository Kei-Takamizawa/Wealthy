//
//  CategoriesView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

// 画面部品やレイアウトを使うためのフレームワークを読み込みます。
import SwiftUI
// 保存データの検索や追加に使う仕組みを読み込みます。
import SwiftData
// 画像やUIKit部品を扱うための仕組みを読み込みます。
import UIKit

// カテゴリの一覧表示と追加・編集を行う画面を定義します。
struct CategoriesView: View {
    // SwiftDataへの追加・削除に使う保存コンテキストを受け取ります。
    @Environment(\.modelContext) var modelContext
    // この画面を閉じるための操作をSwiftUI環境から受け取ります。
    @Environment(\.dismiss) var dismiss
    // 画面間で共有される言語設定を受け取り、表示文や通貨記号に使います。
    @EnvironmentObject var lm: LanguageManager
    // 保存済みカテゴリを取得し、選択肢や色・アイコン表示に使います。
    @Query var categories: [Category]
    
    // 追加フォームを開くかどうかを保持し、値が変わると画面を更新します。
    @State private var showAddSheet = false
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 画面遷移やナビゲーションタイトルを持つ画面の土台を作ります。
        NavigationStack {
            // 背景と前景の部品を重ねて配置する領域を作ります。
            ZStack {
                // 黒い背景を画面の端まで広げます。
                Color.black.ignoresSafeArea()
                
                // 「categories.isEmpty」の条件が真の場合にだけ、次の処理を実行します。
                if categories.isEmpty {
                    // 表示できるデータがない状態を利用者へ案内します。
                    ContentUnavailableView("No Categories", systemImage: "tray")
                // ここで「条件分岐」の処理範囲を閉じます。
                } else {
                    // 各データを行に分けて表示するスクロール可能な一覧を作ります。
                    List {
                        // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                        ForEach(categories) { category in
                            // 子部品を左から右へ並べる領域を作ります。
                            HStack {
                                // 円形の色見本やマークを作ります。
                                Circle()
                                    // 図形の内側を塗りつぶします。
                                    .fill(Color(hex: category.colorHex))
                                    // 部品の幅、高さ、配置できる範囲を指定します。
                                    .frame(width: 40, height: 40)
                                    // この部品の上に枠や補助表示を重ねます。
                                    .overlay(
                                        // 「Group」の中身を記述する範囲を始めます。
                                        Group {
                                            // 「UIImage(systemName: category.icon) != nil」の条件が真の場合にだけ、次の処理を実行します。
                                            if UIImage(systemName: category.icon) != nil {
                                                // 画像またはシステムアイコンを表示します。
                                                Image(systemName: category.icon)
                                                    // この文字やアイコンを.whiteで描画します。
                                                    .foregroundStyle(.white)
                                                    // 文字またはアイコンの書体と大きさを指定します。
                                                    .font(.caption)
                                            // ここで「条件分岐」の処理範囲を閉じます。
                                            } else {
                                                // 画面に文字を表示します。
                                                Text(category.icon)
                                                    // 文字またはアイコンの書体と大きさを指定します。
                                                    .font(.caption)
                                            // この画面部品または処理の範囲をここで閉じます。
                                            }
                                        // この画面部品または処理の範囲をここで閉じます。
                                        }
                                    // 直前に開いた引数または配列のまとまりを閉じます。
                                    )
                                // 画面に文字を表示します。
                                Text(lm.translateCategory(name: category.name))
                                    // 文字またはアイコンの書体と大きさを指定します。
                                    .font(.headline)
                                    // この文字やアイコンを.whiteで描画します。
                                    .foregroundStyle(.white)
                            // ここで「横並びレイアウト」の範囲を閉じます。
                            }
                            // 一覧行の背景色を設定します。
                            .listRowBackground(Color(white: 0.1))
                        // ここで「ForEachクロージャ」の範囲を閉じます。
                        }
                        // 一覧行を削除する操作が行われたときの処理を登録します。
                        .onDelete { indexSet in
                            // indexへindexSet { modelContext.delete(categories[index]) }の各要素を順番に取り出して処理します。
                            for index in indexSet { modelContext.delete(categories[index]) }
                        // この画面部品または処理の範囲をここで閉じます。
                        }
                    // ここで「一覧表示」の範囲を閉じます。
                    }
                    // 一覧の行や区切りの表示形式を指定します。
                    .listStyle(.plain)
                    // 標準のフォーム背景を隠し、設定した背景色を見せます。
                    .scrollContentBackground(.hidden)
                // この画面部品または処理の範囲をここで閉じます。
                }
            // ここで「重ね合わせレイアウト」の範囲を閉じます。
            }
            // ナビゲーションバーに現在の画面名を表示します。
            .navigationTitle(lm.t(.categorySettings))
            // 画面タイトルをナビゲーションバー内に表示します。
            .navigationBarTitleDisplayMode(.inline)
            // ナビゲーションバーなどの操作項目をまとめます。
            .toolbarColorScheme(.dark, for: .navigationBar)
            // ナビゲーションバーなどの操作項目をまとめます。
            .toolbar {
                // キャンセルまたは確定などの操作をナビゲーションバーへ配置します。
                ToolbarItem(placement: .topBarTrailing) {
                    // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                    Button { showAddSheet = true } label: { Image(systemName: "plus") }
                // ここで「ツールバー項目」の範囲を閉じます。
                }

            // この画面部品または処理の範囲をここで閉じます。
            }
            // 状態に応じてモーダルのシート画面を表示します。
            .sheet(isPresented: $showAddSheet) {
                // 新しいカテゴリを入力する画面を表示します。
                AddCategoryForm()
            // ここで「シート表示」の範囲を閉じます。
            }
        // ここで「ナビゲーション画面」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
// ここで「CategoriesView型」の範囲を閉じます。
}

// 追加フォーム
// AddCategoryFormという画面または補助部品の定義を始めます。
struct AddCategoryForm: View {
    // SwiftDataへの追加・削除に使う保存コンテキストを受け取ります。
    @Environment(\.modelContext) var modelContext
    // この画面を閉じるための操作をSwiftUI環境から受け取ります。
    @Environment(\.dismiss) var dismiss
    // 画面間で共有される言語設定を受け取り、表示文や通貨記号に使います。
    @EnvironmentObject var lm: LanguageManager
    
    // 入力するカテゴリ名を保持し、値が変わると画面を更新します。
    @State private var name = ""
    // 選択中のカテゴリ用アイコンを保持し、値が変わると画面を更新します。
    @State private var selectedIcon = "cart.fill"
    // 選択中のカテゴリ色を保持し、値が変わると画面を更新します。
    @State private var selectedColor = "FFA500"
    
    // Advanced Customization
    // 入力された絵文字を保持し、値が変わると画面を更新します。
    @State private var emojiText = ""
    // 選択された自由色を保持し、値が変わると画面を更新します。
    @State private var customColor = Color.orange
    
    // プリセットアイコン (Expanded)
    // Expanded Icons List (Approx 50+)
    // iconsという定数へ「[」の計算結果を保存します。
    let icons = [
        // この行で「"cart.fill", "fork.knife", "cup.and.saucer」を指定し、画面構成または処理の一部を定義します。
        "cart.fill", "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "birthday.cake.fill", "takeoutbag.and.cup.and.straw.fill",
        // この行で「"car.fill", "bus.fill", "tram.fill", "airp」を指定し、画面構成または処理の一部を定義します。
        "car.fill", "bus.fill", "tram.fill", "airplane", "bicycle", "fuelpump.fill", "steeringwheel", "figure.walk",
        // この行で「"house.fill", "bed.double.fill", "chair.lo」を指定し、画面構成または処理の一部を定義します。
        "house.fill", "bed.double.fill", "chair.lounge.fill", "lightbulb.fill", "washer.fill", "shower.fill", "trash.fill",
        // この行で「"tshirt.fill", "shoe.fill", "scissors", "m」を指定し、画面構成または処理の一部を定義します。
        "tshirt.fill", "shoe.fill", "scissors", "medical.thermometer.fill", "pills.fill", "heart.fill", "cross.case.fill", "comb.fill",
        // この行で「"gamecontroller.fill", "tv.fill", "headpho」を指定し、画面構成または処理の一部を定義します。
        "gamecontroller.fill", "tv.fill", "headphones", "book.fill", "ticket.fill", "music.note", "theatermasks.fill",
        // この行で「"iphone", "desktopcomputer", "laptopcomput」を指定し、画面構成または処理の一部を定義します。
        "iphone", "desktopcomputer", "laptopcomputer", "printer.fill", "cable.connector", "camera.fill",
        // この行で「"banknote.fill", "creditcard.fill", "case.」を指定し、画面構成または処理の一部を定義します。
        "banknote.fill", "creditcard.fill", "case.fill", "briefcase.fill", "chart.bar.fill", "scroll.fill", "doc.text.fill",
        // この行で「"gift.fill", "pawprint.fill", "leaf.fill",」を指定し、画面構成または処理の一部を定義します。
        "gift.fill", "pawprint.fill", "leaf.fill", "wifi", "graduationcap.fill", "airplane.departure", "hammer.fill",
        // この行で「"envelope.fill", "phone.fill", "video.fill」を指定し、画面構成または処理の一部を定義します。
        "envelope.fill", "phone.fill", "video.fill", "photo.fill", "globe", "sun.max.fill", "moon.fill", "cloud.rain.fill",
        // この行で「"umbrella.fill", "flame.fill", "drop.fill"」を指定し、画面構成または処理の一部を定義します。
        "umbrella.fill", "flame.fill", "drop.fill", "bolt.fill", "star.fill", "flag.fill", "bell.fill", "tag.fill"
    // 直前に開いた引数または配列のまとまりを閉じます。
    ]
    
    // Expanded Colors List (Approx 30+)
    // colorsという定数へ「[」の計算結果を保存します。
    let colors = [
        // この行で「"FF4500", "FF6347", "FF7F50", "DC143C", "B」を指定し、画面構成または処理の一部を定義します。
        "FF4500", "FF6347", "FF7F50", "DC143C", "B22222", "8B0000", // Reds/Oranges
        // この行で「"FFA500", "FF8C00", "DAA520", "FFD700", "F」を指定し、画面構成または処理の一部を定義します。
        "FFA500", "FF8C00", "DAA520", "FFD700", "FFFF00", "F0E68C", // Yellows/Golds
        // この行で「"32CD32", "228B22", "008000", "006400", "6」を指定し、画面構成または処理の一部を定義します。
        "32CD32", "228B22", "008000", "006400", "66CDAA", "8FBC8F", // Greens
        // この行で「"1E90FF", "00BFFF", "87CEEB", "4169E1", "0」を指定し、画面構成または処理の一部を定義します。
        "1E90FF", "00BFFF", "87CEEB", "4169E1", "0000FF", "000080", // Blues
        // この行で「"8A2BE2", "9370DB", "800080", "4B0082", "F」を指定し、画面構成または処理の一部を定義します。
        "8A2BE2", "9370DB", "800080", "4B0082", "FF00FF", "FF69B4", // Purples/Pinks
        // この行で「"A52A2A", "8B4513", "D2691E", "F4A460", "D」を指定し、画面構成または処理の一部を定義します。
        "A52A2A", "8B4513", "D2691E", "F4A460", "D2B48C", "808080", "2F4F4F", "000000" // Browns/Grays
    // 直前に開いた引数または配列のまとまりを閉じます。
    ]
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 画面遷移やナビゲーションタイトルを持つ画面の土台を作ります。
        NavigationStack {
            // 入力欄を標準のフォームレイアウトでまとめます。
            Form {
                // フォーム項目を見出し付きのグループにまとめます。
                Section(lm.t(.basicInfo)) {
                    // 「categoryName」に対応する値を入力し、バインド先の状態またはモデルへ反映します。
                    TextField(lm.t(.categoryName), text: $name)
                // ここで「セクション」の範囲を閉じます。
                }
                
                // フォーム項目を見出し付きのグループにまとめます。
                Section(lm.t(.icon)) {
                    // 項目を列に並べ、必要になった分だけ生成するグリッドを作ります。
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 45))], spacing: 15) {
                        // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                        ForEach(icons, id: \.self) { icon in
                            // 画像またはシステムアイコンを表示します。
                            Image(systemName: icon)
                                // 文字またはアイコンの書体と大きさを指定します。
                                .font(.title2)
                                // 部品の幅、高さ、配置できる範囲を指定します。
                                .frame(width: 45, height: 45)
                                // この部品の背後に指定した背景を描きます。
                                .background(selectedIcon == icon ? Color(hex: selectedColor).opacity(0.3) : Color.clear)
                                // この文字やアイコンをselectedIcon == icon ? Color(hex: selectedColorで描画します。
                                .foregroundStyle(selectedIcon == icon ? Color(hex: selectedColor) : .gray)
                                // 部品の角を指定した半径で丸くします。
                                .cornerRadius(8)
                                // タップされたときに選択状態などを更新します。
                                .onTapGesture {
                                    // selectedIconへ右辺の値を代入し、状態または集計結果を更新します。
                                    selectedIcon = icon
                                // この画面部品または処理の範囲をここで閉じます。
                                }
                        // ここで「ForEachクロージャ」の範囲を閉じます。
                        }
                    // この画面部品または処理の範囲をここで閉じます。
                    }
                    // 部品の内側または外側に余白を追加します。
                    .padding(.vertical)
                // ここで「セクション」の範囲を閉じます。
                }
                
                // フォーム項目を見出し付きのグループにまとめます。
                Section(lm.t(.color)) {
                    // 内容が画面より大きい場合にスクロールできる表示領域を作ります。
                    ScrollView(.horizontal, showsIndicators: false) {
                        // 子部品を左から右へ並べる領域を作ります。
                        HStack(spacing: 15) {
                            // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                            ForEach(colors, id: \.self) { hex in
                                // 円形の色見本やマークを作ります。
                                Circle()
                                    // 図形の内側を塗りつぶします。
                                    .fill(Color(hex: hex))
                                    // 部品の幅、高さ、配置できる範囲を指定します。
                                    .frame(width: 40, height: 40)
                                    // この部品の上に枠や補助表示を重ねます。
                                    .overlay(
                                        // 画像またはシステムアイコンを表示します。
                                        Image(systemName: "checkmark")
                                            // この文字やアイコンを.whiteで描画します。
                                            .foregroundStyle(.white)
                                            // 透明度を指定します。
                                            .opacity(selectedColor == hex ? 1 : 0)
                                    // 直前に開いた引数または配列のまとまりを閉じます。
                                    )
                                    // タップされたときに選択状態などを更新します。
                                    .onTapGesture {
                                        // selectedColorへ右辺の値を代入し、状態または集計結果を更新します。
                                        selectedColor = hex
                                    // この画面部品または処理の範囲をここで閉じます。
                                    }
                            // ここで「ForEachクロージャ」の範囲を閉じます。
                            }
                        // ここで「横並びレイアウト」の範囲を閉じます。
                        }
                        // 部品の内側または外側に余白を追加します。
                        .padding(.vertical, 5)
                    // ここで「スクロール領域」の範囲を閉じます。
                    }
                // ここで「セクション」の範囲を閉じます。
                }
            // ここで「フォーム」の範囲を閉じます。
            }
            // ナビゲーションバーに現在の画面名を表示します。
            .navigationTitle(lm.t(.newCategory))
            // ナビゲーションバーなどの操作項目をまとめます。
            .toolbar {
                // キャンセルまたは確定などの操作をナビゲーションバーへ配置します。
                ToolbarItem(placement: .cancellationAction) { Button(lm.t(.cancel)) { dismiss() } }
                // キャンセルまたは確定などの操作をナビゲーションバーへ配置します。
                ToolbarItem(placement: .confirmationAction) {
                    // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                    Button(lm.t(.save)) {
                        // newCatという定数へ「Category(name: name, icon: selectedIcon, colorHex: sele」の計算結果を保存します。
                        let newCat = Category(name: name, icon: selectedIcon, colorHex: selectedColor)
                        // 新しい収支または設定をSwiftDataへ追加します。
                        modelContext.insert(newCat)
                        // 現在のシートまたは画面を閉じます。
                        dismiss()
                    // ここで「ボタン定義」の範囲を閉じます。
                    }
                    // 条件に応じてこの操作を無効にします。
                    .disabled(name.isEmpty)
                // ここで「ツールバー項目」の範囲を閉じます。
                }
            // この画面部品または処理の範囲をここで閉じます。
            }
        // ここで「ナビゲーション画面」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // Removed colorToHex since we only use presets now
// ここで「AddCategoryForm型」の範囲を閉じます。
}
