//
//  RecurringSettingsView.swift
//  家計簿
//
//  Created by Harrison on 12/26/25.
//

// 画面部品やレイアウトを使うためのフレームワークを読み込みます。
import SwiftUI
// 保存データの検索や追加に使う仕組みを読み込みます。
import SwiftData

// 毎月繰り返す収支を管理する画面を定義します。
struct RecurringSettingsView: View {
    // SwiftDataへの追加・削除に使う保存コンテキストを受け取ります。
    @Environment(\.modelContext) var modelContext
    // この画面を閉じるための操作をSwiftUI環境から受け取ります。
    @Environment(\.dismiss) var dismiss
    // 画面間で共有される言語設定を受け取り、表示文や通貨記号に使います。
    @EnvironmentObject var lm: LanguageManager
    
    // 保存済みの定期登録ルールを一覧表示するために取得します。
    @Query var recurringItems: [RecurringItem]
    // 保存済みの財布を取得し、選択肢や残高更新に使います。
    @Query var assets: [Asset]
    
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
                
                // 「recurringItems.isEmpty」の条件が真の場合にだけ、次の処理を実行します。
                if recurringItems.isEmpty {
                    // 表示できるデータがない状態を利用者へ案内します。
                    ContentUnavailableView {
                        // 定期収支がないことをアイコンと文章で知らせます。
                        Label(lm.t(.noRecurringItems), systemImage: "clock.arrow.circlepath")
                    // この画面部品または処理の範囲をここで閉じます。
                    } description: {
                        // 言語設定の「recurringDesc」に対応する翻訳文を表示します。
                        Text(lm.t(.recurringDesc))
                    // この画面部品または処理の範囲をここで閉じます。
                    }
                    // この文字やアイコンを.grayで描画します。
                    .foregroundStyle(.gray)
                // ここで「条件分岐」の処理範囲を閉じます。
                } else {
                    // 各データを行に分けて表示するスクロール可能な一覧を作ります。
                    List {
                        // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                        ForEach(recurringItems) { item in
                            // 子部品を左から右へ並べる領域を作ります。
                            HStack {
                                // 子部品を上から下へ並べる領域を作ります。
                                VStack(alignment: .leading) {
                                    // 画面に文字を表示します。
                                    Text(item.title)
                                        // 文字またはアイコンの書体と大きさを指定します。
                                        .font(.headline)
                                        // この文字やアイコンを.whiteで描画します。
                                        .foregroundStyle(.white)
                                    // 子部品を左から右へ並べる領域を作ります。
                                    HStack {
                                        // 画面に「毎月 \(item.dayOfMonth)日」という文字を表示します。
                                        Text("毎月 \(item.dayOfMonth)日")
                                        // 画面に「•」という文字を表示します。
                                        Text("•")
                                        // 画面に文字を表示します。
                                        Text(item.assetName)
                                    // ここで「横並びレイアウト」の範囲を閉じます。
                                    }
                                    // 文字またはアイコンの書体と大きさを指定します。
                                    .font(.caption)
                                    // この文字やアイコンを.grayで描画します。
                                    .foregroundStyle(.gray)
                                // ここで「縦並びレイアウト」の範囲を閉じます。
                                }
                                
                                // 伸縮する空白を入れ、周囲の部品を離して配置します。
                                Spacer()
                                
                                // 画面に「¥\(item.amount)」という文字を表示します。
                                Text("¥\(item.amount)")
                                    // 文字またはアイコンの書体と大きさを指定します。
                                    .font(.title3.bold())
                                    // 収入は緑、支出は赤
                                    // この文字やアイコンをitem.isIncome ? .green : .redで描画します。
                                    .foregroundStyle(item.isIncome ? .green : .red)
                            // ここで「横並びレイアウト」の範囲を閉じます。
                            }
                            // 一覧行の背景色を設定します。
                            .listRowBackground(Color(white: 0.1))
                        // ここで「ForEachクロージャ」の範囲を閉じます。
                        }
                        // 一覧行を削除する操作が行われたときの処理を登録します。
                        .onDelete { indexSet in
                            // indexへindexSetの各要素を順番に取り出して処理します。
                            for index in indexSet {
                                // 選択された保存データを削除対象として登録します。
                                modelContext.delete(recurringItems[index])
                            // ここで「繰り返し」の範囲を閉じます。
                            }
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
            .navigationTitle(lm.t(.recurringSettings))
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
                // 財布一覧を渡して定期収支の入力画面を表示します。
                AddRecurringForm(assets: assets)
            // ここで「シート表示」の範囲を閉じます。
            }
        // ここで「ナビゲーション画面」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
// ここで「RecurringSettingsView型」の範囲を閉じます。
}

// 追加フォーム
// AddRecurringFormという画面または補助部品の定義を始めます。
struct AddRecurringForm: View {
    // SwiftDataへの追加・削除に使う保存コンテキストを受け取ります。
    @Environment(\.modelContext) var modelContext
    // この画面を閉じるための操作をSwiftUI環境から受け取ります。
    @Environment(\.dismiss) var dismiss
    // 画面間で共有される言語設定を受け取り、表示文や通貨記号に使います。
    @EnvironmentObject var lm: LanguageManager
    // assetsという値または計算結果を定義します。
    var assets: [Asset]
    
    // 入力するタイトルを保持し、値が変わると画面を更新します。
    @State private var title = ""
    // 入力する金額を保持し、値が変わると画面を更新します。
    @State private var amount = 0
    // 毎月の実行日を保持し、値が変わると画面を更新します。
    @State private var day = 25
    // 収入として登録するかどうかを保持し、値が変わると画面を更新します。
    @State private var isIncome = false // false=支出, true=収入
    // 繰り返し対象の財布を保持し、値が変わると画面を更新します。
    @State private var selectedAsset = "現金"
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 画面遷移やナビゲーションタイトルを持つ画面の土台を作ります。
        NavigationStack {
            // 入力欄を標準のフォームレイアウトでまとめます。
            Form {
                // フォーム項目を見出し付きのグループにまとめます。
                Section(lm.t(.basicInfo)) {
                    // 「shopName」に対応する値を入力し、バインド先の状態またはモデルへ反映します。
                    TextField(lm.t(.shopName), text: $title)
                    // 「amount」に対応する値を入力し、バインド先の状態またはモデルへ反映します。
                    TextField(lm.t(.amount), value: $amount, format: .number)
                        // 金額を入力しやすい数字キーボードを表示します。
                        .keyboardType(.numberPad)
                    
                    // 「type」の候補を表示し、選択値をバインド先へ保存します。
                    Picker(lm.t(.type), selection: $isIncome) {
                        // 言語設定の「expense」に対応する翻訳文を表示します。
                        Text(lm.t(.expense)).tag(false)
                        // 言語設定の「income」に対応する翻訳文を表示します。
                        Text(lm.t(.income)).tag(true)
                    // この画面部品または処理の範囲をここで閉じます。
                    }
                    // .pickerStyleをこの画面部品に適用します。
                    .pickerStyle(.segmented)
                // ここで「セクション」の範囲を閉じます。
                }
                
                // フォーム項目を見出し付きのグループにまとめます。
                Section("スケジュール") {
                    // 「monthlyDate」の候補を表示し、選択値をバインド先へ保存します。
                    Picker(lm.t(.monthlyDate), selection: $day) {
                        // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                        ForEach(1...31, id: \.self) { d in
                            // 画面に「\(d)」という文字を表示します。
                            Text("\(d)").tag(d)
                        // ここで「ForEachクロージャ」の範囲を閉じます。
                        }
                    // この画面部品または処理の範囲をここで閉じます。
                    }
                    
                    // 「対象の財布」の候補を表示し、選択値をバインド先へ保存します。
                    Picker("対象の財布", selection: $selectedAsset) {
                        // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                        ForEach(assets) { asset in
                            // 画面に文字を表示します。
                            Text(asset.name).tag(asset.name)
                        // ここで「ForEachクロージャ」の範囲を閉じます。
                        }
                    // この画面部品または処理の範囲をここで閉じます。
                    }
                // ここで「セクション」の範囲を閉じます。
                }
            // ここで「フォーム」の範囲を閉じます。
            }
            // ナビゲーションバーに現在の画面名を表示します。
            .navigationTitle(lm.t(.newRule))
            // ナビゲーションバーなどの操作項目をまとめます。
            .toolbar {
                // キャンセルまたは確定などの操作をナビゲーションバーへ配置します。
                ToolbarItem(placement: .cancellationAction) { Button(lm.t(.cancel)) { dismiss() } }
                // キャンセルまたは確定などの操作をナビゲーションバーへ配置します。
                ToolbarItem(placement: .confirmationAction) {
                    // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                    Button(lm.t(.save)) {
                        // newItemという定数へ「RecurringItem(title: title, amount: amount, dayOfMonth:」の計算結果を保存します。
                        let newItem = RecurringItem(title: title, amount: amount, dayOfMonth: day, isIncome: isIncome, assetName: selectedAsset)
                        // 新しい収支または設定をSwiftDataへ追加します。
                        modelContext.insert(newItem)
                        // 現在のシートまたは画面を閉じます。
                        dismiss()
                    // ここで「ボタン定義」の範囲を閉じます。
                    }
                    // 条件に応じてこの操作を無効にします。
                    .disabled(title.isEmpty)
                // ここで「ツールバー項目」の範囲を閉じます。
                }
            // この画面部品または処理の範囲をここで閉じます。
            }
        // ここで「ナビゲーション画面」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
// ここで「AddRecurringForm型」の範囲を閉じます。
}
