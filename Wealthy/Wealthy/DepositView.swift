//
//  DepositView.swift
//  Wealthy
//
//  Created by Harrison on 12/27/25.
//

// 画面部品やレイアウトを使うためのフレームワークを読み込みます。
import SwiftUI
// 保存データの検索や追加に使う仕組みを読み込みます。
import SwiftData

// 収入を入力して財布へ加える画面を定義します。
struct DepositView: View {
    // SwiftDataへの追加・削除に使う保存コンテキストを受け取ります。
    @Environment(\.modelContext) var modelContext
    // この画面を閉じるための操作をSwiftUI環境から受け取ります。
    @Environment(\.dismiss) var dismiss
    // 画面間で共有される言語設定を受け取り、表示文や通貨記号に使います。
    @EnvironmentObject var lm: LanguageManager
    
    // 保存済みの財布を取得し、選択肢や残高更新に使います。
    @Query var assets: [Asset]
    // 保存済みカテゴリを取得し、選択肢や色・アイコン表示に使います。
    @Query var categories: [Category]
    
    // 入力する金額を保持し、値が変わると画面を更新します。
    @State private var amount = 0
    // 入力するタイトルを保持し、値が変わると画面を更新します。
    @State private var title = ""
    // 繰り返し対象の財布を保持し、値が変わると画面を更新します。
    @State private var selectedAsset: Asset?
    // 収入日を保持し、値が変わると画面を更新します。
    @State private var date = Date()
    // 選択中のカテゴリを保持し、値が変わると画面を更新します。
    @State private var selectedCategoryName: String = "未分類"
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 画面遷移やナビゲーションタイトルを持つ画面の土台を作ります。
        NavigationStack {
            // 背景と前景の部品を重ねて配置する領域を作ります。
            ZStack {
                // 黒い背景を画面の端まで広げます。
                Color.black.ignoresSafeArea()
                
                // 入力欄を標準のフォームレイアウトでまとめます。
                Form {
                    // フォーム項目を見出し付きのグループにまとめます。
                    Section(lm.t(.depositInfo)) {
                        // 「depositTitle」に対応する値を入力し、バインド先の状態またはモデルへ反映します。
                        TextField(lm.t(.depositTitle) + " (e.g. Allowance)", text: $title)
                        
                        // 子部品を左から右へ並べる領域を作ります。
                        HStack {
                            // 画面に「¥」という文字を表示します。
                            Text("¥").foregroundStyle(.gray)
                            // 「0」に対応する値を入力し、バインド先の状態またはモデルへ反映します。
                            TextField("0", value: $amount, format: .number)
                                // 金額を入力しやすい数字キーボードを表示します。
                                .keyboardType(.numberPad)
                                // 文字またはアイコンの書体と大きさを指定します。
                                .font(.title2.bold())
                                // この文字やアイコンを.greenで描画します。
                                .foregroundStyle(.green) // 収入なので緑
                        // ここで「横並びレイアウト」の範囲を閉じます。
                        }
                    // ここで「セクション」の範囲を閉じます。
                    }
                    
                    // フォーム項目を見出し付きのグループにまとめます。
                    Section(lm.t(.details)) {
                        // 日付
                        // 日付選択欄を表示し、選んだ年月日を日付の状態へ反映します。
                        DatePicker(lm.t(.dateLabel), selection: $date, displayedComponents: .date)
                        
                        // 入金先財布
                        // 「wallet」の候補を表示し、選択値をバインド先へ保存します。
                        Picker(lm.t(.wallet), selection: $selectedAsset) {
                            // 言語設定の「selectWallet」に対応する翻訳文を表示します。
                            Text(lm.t(.selectWallet)).tag(nil as Asset?)
                            // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                            ForEach(assets) { asset in
                                // 画面に文字を表示します。
                                Text(asset.name).tag(asset as Asset?)
                            // ここで「ForEachクロージャ」の範囲を閉じます。
                            }
                        // この画面部品または処理の範囲をここで閉じます。
                        }
                        
                        // カテゴリ（既存のものから選択）
                        // 「category」の候補を表示し、選択値をバインド先へ保存します。
                        Picker(lm.t(.category), selection: $selectedCategoryName) {
                            // 画面に文字を表示します。
                            Text(lm.translateCategory(name: "未分類")).tag("未分類")
                            // 収入っぽいカテゴリがあればそれを選べるようにする
                            // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                            ForEach(categories) { cat in
                                // 画面に文字を表示します。
                                Text(lm.translateCategory(name: cat.name)).tag(cat.name)
                            // ここで「ForEachクロージャ」の範囲を閉じます。
                            }
                        // この画面部品または処理の範囲をここで閉じます。
                        }
                    // ここで「セクション」の範囲を閉じます。
                    }
                // ここで「フォーム」の範囲を閉じます。
                }
                // 標準のフォーム背景を隠し、設定した背景色を見せます。
                .scrollContentBackground(.hidden)
            // ここで「重ね合わせレイアウト」の範囲を閉じます。
            }
            // ナビゲーションバーに現在の画面名を表示します。
            .navigationTitle(lm.t(.depositTitle))
            // 画面タイトルをナビゲーションバー内に表示します。
            .navigationBarTitleDisplayMode(.inline)
            // ナビゲーションバーなどの操作項目をまとめます。
            .toolbarColorScheme(.dark, for: .navigationBar)
            // ナビゲーションバーなどの操作項目をまとめます。
            .toolbar {
                // キャンセルまたは確定などの操作をナビゲーションバーへ配置します。
                ToolbarItem(placement: .cancellationAction) {
                    // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                    Button(lm.t(.cancel)) { dismiss() }
                // ここで「ツールバー項目」の範囲を閉じます。
                }
                // キャンセルまたは確定などの操作をナビゲーションバーへ配置します。
                ToolbarItem(placement: .confirmationAction) {
                    // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                    Button(lm.t(.add)) {
                        // 入力した収入を保存し、対応する財布の残高を更新します。
                        saveDeposit()
                    // ここで「ボタン定義」の範囲を閉じます。
                    }
                    // 金額が0、または財布未選択の間はこの操作を無効にします。
                    .disabled(amount == 0 || selectedAsset == nil)
                    // この文字やアイコンを.greenで描画します。
                    .foregroundStyle(.green) // 収入なので緑
                // ここで「ツールバー項目」の範囲を閉じます。
                }
            // この画面部品または処理の範囲をここで閉じます。
            }
            // 画面が表示された直後に必要な初期化処理を実行します。
            .onAppear {
                // デフォルトで最初の財布を選択
                // 「selectedAsset == nil」の条件が真の場合にだけ、次の処理を実行します。
                if selectedAsset == nil {
                    // selectedAssetへ右辺の値を代入し、状態または集計結果を更新します。
                    selectedAsset = assets.first
                // ここで「条件分岐」の範囲を閉じます。
                }
            // ここで「画面表示時の処理」の範囲を閉じます。
            }
        // ここで「ナビゲーション画面」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // 入力された収入を残高と履歴へ反映する処理を定義します。
    private func saveDeposit() {
        // 必要な値を安全に取り出し、値がなければこの関数をその場で終了します。
        guard let asset = selectedAsset else { return }
        
        // 1. タイトルが空ならデフォルトを入れる
        // finalTitleという定数へ「title.isEmpty ? "資金追加" : title」の計算結果を保存します。
        let finalTitle = title.isEmpty ? "資金追加" : title
        
        // 2. 収入として履歴を作成 (isIncome: true)
        // newIncomeという定数へ「Expense(」の計算結果を保存します。
        let newIncome = Expense(
            // title引数に、この部品または処理へ渡す値を指定します。
            title: finalTitle,
            // amount引数に、この部品または処理へ渡す値を指定します。
            amount: amount,
            // date引数に、この部品または処理へ渡す値を指定します。
            date: date,
            // assetName引数に、この部品または処理へ渡す値を指定します。
            assetName: asset.name,
            // isIncome引数に、この部品または処理へ渡す値を指定します。
            isIncome: true, // ★重要: これで収入として扱われます
            // categoryName引数に、この部品または処理へ渡す値を指定します。
            categoryName: selectedCategoryName
        // 直前に開いた引数または配列のまとまりを閉じます。
        )
        
        // 3. 財布の残高を増やす
        // asset.balance +へ右辺の値を代入し、状態または集計結果を更新します。
        asset.balance += amount
        
        // 4. 保存
        // 新しい収支または設定をSwiftDataへ追加します。
        modelContext.insert(newIncome)
        // 現在のシートまたは画面を閉じます。
        dismiss()
    // ここで「saveDeposit関数」の範囲を閉じます。
    }
// ここで「DepositView型」の範囲を閉じます。
}
