//
//  AssetsView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

// `SwiftUI` の機能をこのファイルで使えるように読み込みます。
import SwiftUI
// `SwiftData` の機能をこのファイルで使えるように読み込みます。
import SwiftData

// `AssetsView` という構造体を定義し、関連する値や処理をまとめます。
struct AssetsView: View {
    // SwiftUIの環境からデータ保存用のコンテキストを取得します。
    @Environment(\.modelContext) var modelContext
    // 表示言語の管理役を親画面から受け取ります。
    @EnvironmentObject var lm: LanguageManager
    // SwiftDataから財布・資産を読み、変更を画面に反映します。
    @Query var assets: [Asset]
    
    // `showingAddAsset`を画面の状態として保持し、変更時に表示を更新します。
    @State private var showingAddAsset = false
    // `assetToEdit`を画面の状態として保持し、変更時に表示を更新します。
    @State private var assetToEdit: Asset?
    
    // 画面に表示する部品の並びを返す `body` を定義します。
    var body: some View {
        // 画面遷移と見出しを管理する領域を作ります。
        NavigationStack {
            // 要素を手前と奥に重ねます。
            ZStack {
                // 画面に色を表示します。
                Color.black.ignoresSafeArea()
                
                // 項目を一覧表示します。
                List {
                    // 資産リスト
                    // 関連する項目を一つのまとまりに分けます。
                    Section(lm.t(.wallets)) {
                        // 配列などの各要素について同じ表示を作ります。
                        ForEach(assets) { asset in
                            // タップで処理を実行するボタンを配置します。
                            Button { assetToEdit = asset } label: {
                                // 要素を左から右へ並べます。
                                HStack {
                                    // 円形の図形を描きます。
                                    Circle().fill(Color(hex: asset.colorHex)).frame(width: 40, height: 40)
                                        // 元の表示の上に別の表示を重ねます。
                                        .overlay(Image(systemName: "creditcard.fill").foregroundStyle(.white).font(.caption))
                                    // 要素を上から下へ並べます。
                                    VStack(alignment: .leading) { Text(asset.name).font(.headline).foregroundStyle(.white) }
                                    // 空き領域を使って要素間の距離を広げます。
                                    Spacer()
                                    // 文字列を画面に表示します。
                                    Text("\(lm.currencySymbol)\(asset.balance)").font(.title3.bold()).foregroundStyle(.white)
                                // 横並びの表示の範囲をここで閉じます。
                                }
                            // ボタンの処理の範囲をここで閉じます。
                            }
                            // 一覧の行の背景を設定します。
                            .listRowBackground(Color(white: 0.1))
                            // 横にスワイプしたときの操作を追加します。
                            .swipeActions {
                                // タップで処理を実行するボタンを配置します。
                                Button(role: .destructive) { modelContext.delete(asset) } label: { Label(lm.t(.delete), systemImage: "trash") }
                            // .swipeActionsの範囲をここで閉じます。
                            }
                        // 繰り返し表示の範囲をここで閉じます。
                        }
                    // Section(lm.t(.wallets))の範囲をここで閉じます。
                    }
                // Listの範囲をここで閉じます。
                }
                // 一覧の見た目を設定します。
                .listStyle(.insetGrouped)
                // 一覧が持つ標準の背景を隠します。
                .scrollContentBackground(.hidden)
                
                // 追加ボタン
                // 要素を上から下へ並べます。
                VStack {
                    // 空き領域を使って要素間の距離を広げます。
                    Spacer()
                    // タップで処理を実行するボタンを配置します。
                    Button { showingAddAsset = true } label: {
                        // 要素を左から右へ並べます。
                        HStack { Image(systemName: "plus"); Text(lm.t(.add)) }
                            // 文字の大きさや書体を設定します。
                            .font(.headline).foregroundStyle(.black).padding()
                            // 表示領域の幅や高さを設定します。
                            .frame(maxWidth: .infinity).background(Color.white).cornerRadius(15).padding()
                    // ボタンの処理の範囲をここで閉じます。
                    }
                // 縦並びの表示の範囲をここで閉じます。
                }
            // 重ねた表示の範囲をここで閉じます。
            }
            // 画面上部の見出しを設定します。
            .navigationTitle(lm.t(.wallets))
            // 見出しの表示形式を設定します。
            .navigationBarTitleDisplayMode(.inline)
            // 操作欄の配色を設定します。
            .toolbarColorScheme(.dark, for: .navigationBar)
            // 条件に応じて下から現れる画面を表示します。
            .sheet(isPresented: $showingAddAsset) { AddAssetView() }
            // 条件に応じて下から現れる画面を表示します。
            .sheet(item: $assetToEdit) { asset in EditAssetView(asset: asset) }
        // 画面遷移の範囲をここで閉じます。
        }
    // 画面構成の範囲をここで閉じます。
    }
// 構造体の範囲をここで閉じます。
}

// ■ 以下、足りなかった部品（サブルーチン）を全て定義しました

// 1. 資産追加画面
// `AddAssetView` という構造体を定義し、関連する値や処理をまとめます。
struct AddAssetView: View {
    // SwiftUIの環境から`dismiss`を取得します。
    @Environment(\.dismiss) var dismiss
    // SwiftUIの環境からデータ保存用のコンテキストを取得します。
    @Environment(\.modelContext) var modelContext
    // 表示言語の管理役を親画面から受け取ります。
    @EnvironmentObject var lm: LanguageManager
    
    // `name`を画面の状態として保持し、変更時に表示を更新します。
    @State private var name = ""
    // `balance`を画面の状態として保持し、変更時に表示を更新します。
    @State private var balance = 0
    // `selectedColor`を画面の状態として保持し、変更時に表示を更新します。
    @State private var selectedColor = "FFA500"
    // `colors`を変更できない値として作り、右辺の結果を保存します。
    let colors = ["FFA500", "FF4500", "32CD32", "1E90FF", "8A2BE2", "FF69B4", "808080", "000000"]
    
    // 画面に表示する部品の並びを返す `body` を定義します。
    var body: some View {
        // 画面遷移と見出しを管理する領域を作ります。
        NavigationStack {
            // 設定項目を入力しやすい形式で並べます。
            Form {
                // 文字を入力する欄を配置します。
                TextField("Wallet Name", text: $name)
                // 文字を入力する欄を配置します。
                TextField("Initial Balance", value: $balance, format: .number).keyboardType(.numberPad)
                
                // 関連する項目を一つのまとまりに分けます。
                Section("Color") {
                    // 要素を左から右へ並べます。
                    HStack {
                        // 配列などの各要素について同じ表示を作ります。
                        ForEach(colors, id: \.self) { color in
                            // 円形の図形を描きます。
                            Circle().fill(Color(hex: color))
                                // 表示領域の幅や高さを設定します。
                                .frame(width: 30, height: 30)
                                // 元の表示の上に別の表示を重ねます。
                                .overlay(selectedColor == color ? Image(systemName: "checkmark").foregroundStyle(.white) : nil)
                                // タップされたときの処理を登録します。
                                .onTapGesture { selectedColor = color }
                        // 繰り返し表示の範囲をここで閉じます。
                        }
                    // 横並びの表示の範囲をここで閉じます。
                    }
                // Section("Color")の範囲をここで閉じます。
                }
            // Formの範囲をここで閉じます。
            }
            // 画面上部の見出しを設定します。
            .navigationTitle(lm.t(.add))
            // 画面上部の操作項目を設定します。
            .toolbar {
                // 画面上部の操作項目を追加します。
                ToolbarItem(placement: .cancellationAction) { Button(lm.t(.cancel)) { dismiss() } }
                // 画面上部の操作項目を追加します。
                ToolbarItem(placement: .confirmationAction) {
                    // タップで処理を実行するボタンを配置します。
                    Button(lm.t(.save)) {
                        // `newAsset`を変更できない値として作り、右辺の結果を保存します。
                        let newAsset = Asset(name: name, balance: balance, colorHex: selectedColor)
                        // 新しく作った財布をSwiftDataの保存対象に追加します。
                        modelContext.insert(newAsset)
                        // `dismiss` を呼び出し、括弧内の値を使って処理します。
                        dismiss()
                    // ボタンの処理の範囲をここで閉じます。
                    }
                    // 条件に応じて操作を無効にします。
                    .disabled(name.isEmpty)
                // 開いていた画面部品や処理の範囲を閉じます。
                }
            // .toolbarの範囲をここで閉じます。
            }
        // 画面遷移の範囲をここで閉じます。
        }
    // 画面構成の範囲をここで閉じます。
    }
// 構造体の範囲をここで閉じます。
}

// 2. 資産編集画面 (これが見つからないエラーが出ていました)
// `EditAssetView` という構造体を定義し、関連する値や処理をまとめます。
struct EditAssetView: View {
    // SwiftUIの環境から`dismiss`を取得します。
    @Environment(\.dismiss) var dismiss
    // 表示言語の管理役を親画面から受け取ります。
    @EnvironmentObject var lm: LanguageManager
    // `@Bindable var asset: Asset` の属性を付け、次の宣言の動作を指定します。
    @Bindable var asset: Asset
    
    // `colors`を変更できない値として作り、右辺の結果を保存します。
    let colors = ["FFA500", "FF4500", "32CD32", "1E90FF", "8A2BE2", "FF69B4", "808080", "000000"]
    
    // 画面に表示する部品の並びを返す `body` を定義します。
    var body: some View {
        // 画面遷移と見出しを管理する領域を作ります。
        NavigationStack {
            // 設定項目を入力しやすい形式で並べます。
            Form {
                // 文字を入力する欄を配置します。
                TextField("Wallet Name", text: $asset.name)
                // バランス修正時は手動修正とする
                // 文字を入力する欄を配置します。
                TextField("Balance", value: $asset.balance, format: .number).keyboardType(.numberPad)
                
                // 関連する項目を一つのまとまりに分けます。
                Section("Color") {
                    // 要素を左から右へ並べます。
                    HStack {
                        // 配列などの各要素について同じ表示を作ります。
                        ForEach(colors, id: \.self) { color in
                            // 円形の図形を描きます。
                            Circle().fill(Color(hex: color))
                                // 表示領域の幅や高さを設定します。
                                .frame(width: 30, height: 30)
                                // 元の表示の上に別の表示を重ねます。
                                .overlay(asset.colorHex == color ? Image(systemName: "checkmark").foregroundStyle(.white) : nil)
                                // タップされたときの処理を登録します。
                                .onTapGesture { asset.colorHex = color }
                        // 繰り返し表示の範囲をここで閉じます。
                        }
                    // 横並びの表示の範囲をここで閉じます。
                    }
                // Section("Color")の範囲をここで閉じます。
                }
            // Formの範囲をここで閉じます。
            }
            // 画面上部の見出しを設定します。
            .navigationTitle(lm.t(.edit))
            // 画面上部の操作項目を設定します。
            .toolbar {
                // タップで処理を実行するボタンを配置します。
                Button(lm.t(.save)) { dismiss() }
            // .toolbarの範囲をここで閉じます。
            }
        // 画面遷移の範囲をここで閉じます。
        }
    // 画面構成の範囲をここで閉じます。
    }
// 構造体の範囲をここで閉じます。
}

// 3. Hex色指定を使うための拡張 (これがなくてエラーが出ていました)
// `Color` という既存型の拡張を定義し、関連する値や処理をまとめます。
extension Color {
    // この型を作るときに受け取る初期値と初期化処理を定義します。
    init(hex: String) {
        // `hex`を変更できない値として作り、右辺の結果を保存します。
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        // `int`を表す変更可能な値または計算結果を定義します。
        var int: UInt64 = 0
        // `Scanner` を呼び出し、括弧内の値を使って処理します。
        Scanner(string: hex).scanHexInt64(&int)
        // `a`を変更できない値として作り、右辺の結果を保存します。
        let a, r, g, b: UInt64
        // 値に応じて実行する処理を分けます。
        switch hex.count {
        // 12ビットのRGB値を読み取る場合に進みます。
        case 3: // RGB (12-bit)
            // 括弧内に、この呼び出しへ渡す値を並べます。
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        // 24ビットのRGB値を読み取る場合に進みます。
        case 6: // RGB (24-bit)
            // 括弧内に、この呼び出しへ渡す値を並べます。
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        // 透明度を含む32ビットのARGB値を読み取る場合に進みます。
        case 8: // ARGB (32-bit)
            // 括弧内に、この呼び出しへ渡す値を並べます。
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        // どの候補にも当てはまらない場合の処理を始めます。
        default:
            // 括弧内に、この呼び出しへ渡す値を並べます。
            (a, r, g, b) = (1, 1, 1, 0)
        // 条件の振り分けの範囲をここで閉じます。
        }

        // 同じ型の別の初期化処理を呼び出して色を作ります。
        self.init(
            // 赤・緑・青で色を表すsRGB色空間を使います。
            .sRGB,
            // `red` という引数・項目に続く値を指定します。
            red: Double(r) / 255,
            // `green` という引数・項目に続く値を指定します。
            green: Double(g) / 255,
            // `blue` という引数・項目に続く値を指定します。
            blue: Double(b) / 255,
            // `opacity` という引数・項目に続く値を指定します。
            opacity: Double(a) / 255
        // init(hex: String)の範囲をここで閉じます。
        )
    // init(hex: String)の範囲をここで閉じます。
    }
// extension Colorの範囲をここで閉じます。
}
