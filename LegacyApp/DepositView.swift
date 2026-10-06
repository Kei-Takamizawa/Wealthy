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
    // 新規収入に使う既定通貨と有効通貨を参照します。
    @ObservedObject private var currencyManager = CurrencyManager.shared
    
    // 保存済みの財布を取得し、選択肢や残高更新に使います。
    @Query var assets: [Asset]
    // 保存済みカテゴリを取得し、選択肢や色・アイコン表示に使います。
    @Query var categories: [Category]
    
    // 通貨ごとの小数表記を含む入力文字列を保持します。
    @State private var amountText = ""
    // このフォームで登録する収入の通貨を保持します。
    @State private var currencyCode = CurrencyPolicy.defaultCode
    // 入力するタイトルを保持し、値が変わると画面を更新します。
    @State private var title = ""
    // 繰り返し対象の財布を保持し、値が変わると画面を更新します。
    @State private var selectedAsset: Asset?
    // 収入日を保持し、値が変わると画面を更新します。
    @State private var date = Date()
    // 選択中のカテゴリを保持し、値が変わると画面を更新します。
    @State private var selectedCategoryName: String = "未分類"
    // 収入の保存に失敗した場合の説明を保持します。
    @State private var saveError: String?
    
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
                        // 新規収入に使う通貨を有効な通貨一覧から選択します。
                        Picker(lm.text("currency.default"), selection: $currencyCode) {
                            // 有効な各通貨を表示名とISOコードで並べます。
                            ForEach(currencyManager.selectedCodes, id: \.self) { code in
                                // 選択値へISOコードを設定します。
                                Text("\(CurrencyPolicy.localizedName(for: code, locale: lm.currentLanguage.locale)) (\(code))").tag(code)
                            }
                        }
                        // 「depositTitle」に対応する値を入力し、バインド先の状態またはモデルへ反映します。
                        TextField(lm.t(.depositTitle) + " (e.g. Allowance)", text: $title)
                        
                        // 子部品を左から右へ並べる領域を作ります。
                        HStack {
                            // 金額欄へ通貨コードを表示します。
                            Text(currencyCode).foregroundStyle(.gray)
                            // 「0」に対応する値を入力し、バインド先の状態またはモデルへ反映します。
                            TextField(lm.format("currency.amount", currencyCode), text: $amountText)
                                .accessibilityIdentifier("deposit.amount")
                                // 金額を入力しやすい数字キーボードを表示します。
                                .keyboardType(CurrencyPolicy.minorUnits(for: currencyCode) == 0 ? .numberPad : .decimalPad)
                                // 文字またはアイコンの書体と大きさを指定します。
                                .font(.title2.bold())
                                // この文字やアイコンを.greenで描画します。
                                .foregroundStyle(.green) // 収入なので緑
                        // ここで「横並びレイアウト」の範囲を閉じます。
                        }
                        // 不正な小数桁数や形式が入力された場合に説明を表示します。
                        if !amountText.isEmpty && (parsedAmount.map { $0 > 0 } != true) {
                            Text(lm.text("currency.invalidAmount")).font(.footnote).foregroundStyle(.orange)
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
                            ForEach(assets.filter { $0.effectiveCurrencyCode == currencyCode }) { asset in
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
                    // 金額が不正または0、あるいは財布未選択の間は確定できません。
                    .accessibilityIdentifier("deposit.save")
                    .disabled(parsedAmount.map { $0 > 0 } != true || selectedAsset == nil)
                    // この文字やアイコンを.greenで描画します。
                    .foregroundStyle(.green) // 収入なので緑
                // ここで「ツールバー項目」の範囲を閉じます。
                }
            // この画面部品または処理の範囲をここで閉じます。
            }
            // 画面が表示された直後に必要な初期化処理を実行します。
            .onAppear {
                // 既定通貨を収入フォームへ読み込みます。
                currencyCode = currencyManager.selectedCode
                // 金額欄をこの通貨のゼロ表記で初期化します。
                amountText = CurrencyPolicy.inputText(0, currencyCode: currencyCode, locale: lm.currentLanguage.locale)
                // 同じ通貨の最初の財布を初期選択します。
                selectedAsset = assets.first { $0.effectiveCurrencyCode == currencyCode }
            // ここで「画面表示時の処理」の範囲を閉じます。
            }
            // 通貨変更時に金額をゼロへ戻し、同じ通貨の財布へ切り替えます。
            .onChange(of: currencyCode) { _, newCode in
                // 前の通貨の金額文字列を引き継がないようリセットします。
                amountText = CurrencyPolicy.inputText(0, currencyCode: newCode, locale: lm.currentLanguage.locale)
                // 選択財布を新しい通貨に合わせます。
                selectedAsset = assets.first { $0.effectiveCurrencyCode == newCode }
            }
            // 保存失敗時にエラーをフォーム上へ表示します。
            .alert(lm.t(.error), isPresented: Binding(get: { saveError != nil }, set: { if !$0 { saveError = nil } })) {
                // エラー表示を閉じます。
                Button(lm.text("ok"), role: .cancel) { saveError = nil }
            } message: {
                // ledgerまたは入力検証から返された説明を表示します。
                Text(saveError ?? "")
            }
        // ここで「ナビゲーション画面」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // 入力された収入を残高と履歴へ反映する処理を定義します。
    // 金額文字列をこのフォームの通貨最小単位へ変換します。
    private var parsedAmount: Int? {
        CurrencyPolicy.parseMinorUnits(amountText, currencyCode: currencyCode, locale: lm.currentLanguage.locale)
    }

    private func saveDeposit() {
        // 必要な値を安全に取り出し、値がなければこの関数をその場で終了します。
        // 入力金額、通貨、選択財布を検証し、失敗したら画面に説明を残します。
        guard let asset = selectedAsset, asset.effectiveCurrencyCode == currencyCode, let amount = parsedAmount, amount > 0 else {
            saveError = selectedAsset?.effectiveCurrencyCode == currencyCode ? lm.text("currency.invalidAmount") : lm.text("currency.currencyMismatch")
            return
        }
        
        // 1. タイトルが空ならデフォルトを入れる
        // finalTitleという定数へ「title.isEmpty ? "資金追加" : title」の計算結果を保存します。
        let finalTitle = title.isEmpty ? lm.t(.depositTitle) : title
        
        // 収入履歴を財布と同じ通貨で作成し、残高適用は台帳処理に任せます。
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
            categoryName: selectedCategoryName,
            // 選択財布の支払い方法を記録します。
            paymentMethod: asset.paymentMethod ?? ReceiptPaymentPolicy.method(forAssetName: asset.name),
            // 初回の台帳保存時に一度だけ残高へ適用させます。
            balanceApplied: false,
            // 収入記録へ財布と同じ通貨コードを保存します。
            currencyCode: asset.effectiveCurrencyCode
        // 直前に開いた引数または配列のまとまりを閉じます。
        )
        
        // 台帳処理へ保存とオーバーフロー確認を任せます。
        do {
            try ExpenseLedger.saveDraft(newIncome, replacing: nil, context: modelContext)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    // ここで「saveDeposit関数」の範囲を閉じます。
    }
// ここで「DepositView型」の範囲を閉じます。
}
