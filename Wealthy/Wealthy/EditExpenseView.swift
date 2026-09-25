//
//  EditExpenseView.swift
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

// 収支の内容と関連する財布残高を編集する画面を定義します。
struct EditExpenseView: View {
    // この画面を閉じるための操作をSwiftUI環境から受け取ります。
    @Environment(\.dismiss) var dismiss
    // SwiftDataへの追加・削除に使う保存コンテキストを受け取ります。
    @Environment(\.modelContext) var modelContext
    // 画面間で共有される言語設定を受け取り、表示文や通貨記号に使います。
    @EnvironmentObject var lm: LanguageManager
    // expenseの保存モデルを入力欄から直接編集できるように受け取ります。
    @Bindable var expense: Expense
    // isNewEntryという値または計算結果を定義します。
    var isNewEntry: Bool = false // Default false (for existing items)
    
    // ■ 修正1: カテゴリ一覧と財布一覧を取得するコードを追加
    // 保存済みの財布を取得し、選択肢や残高更新に使います。
    @Query var assets: [Asset]
    // 保存済みカテゴリを取得し、選択肢や色・アイコン表示に使います。
    @Query var categories: [Category]
    
    // 画像表示用
    // 画像を全画面表示するかどうかを保持し、値が変わると画面を更新します。
    @State private var showingFullScreenImage = false
    // 一覧内に表示する画像を保持し、値が変わると画面を更新します。
    @State private var previewImage: UIImage? = nil
    
    // 残高調整用
    // 編集開始時点の金額を保持し、値が変わると画面を更新します。
    @State private var initialAmount: Int = 0
    // 編集開始時点の財布名を保持し、値が変わると画面を更新します。
    @State private var initialAssetName: String? = nil
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 画面遷移やナビゲーションタイトルを持つ画面の土台を作ります。
        NavigationStack {
            // 背景と前景の部品を重ねて配置する領域を作ります。
            ZStack {
                // 黒い背景を画面の端まで広げます。
                Color.black.ignoresSafeArea()
                
                // 内容が画面より大きい場合にスクロールできる表示領域を作ります。
                ScrollView {
                    // 子部品を上から下へ並べる領域を作ります。
                    VStack(spacing: 25) {
                        
                        // 1. 画像エリア
                        // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
                        if let filename = expense.imageFilename {
                            // 保存されたレシート画像を開くボタンを配置します。
                            imageButton(filename: filename)
                        // ここで「条件分岐」の範囲を閉じます。
                        }
                        
                        // 2. 入力フォーム群
                        // 子部品を上から下へ並べる領域を作ります。
                        VStack(spacing: 20) {
                            
                            // 店名
                            // 「shopName」の見出しとアイコンを付けて、内側の入力部品をまとめます。
                            InputGroup(label: lm.t(.shopName), icon: "building.2.fill") {
                                // 「shopName」に対応する値を入力し、バインド先の状態またはモデルへ反映します。
                                TextField(lm.t(.shopName), text: $expense.title)
                                    // この文字やアイコンを.whiteで描画します。
                                    .foregroundStyle(.white)
                            // この画面部品または処理の範囲をここで閉じます。
                            }
                            
                            // 金額
                            // 「amount」の見出しとアイコンを付けて、内側の入力部品をまとめます。
                            InputGroup(label: lm.t(.amount), icon: "yen.circle.fill") {
                                // 「0」に対応する値を入力し、バインド先の状態またはモデルへ反映します。
                                TextField("0", value: $expense.amount, format: .number)
                                    // 金額を入力しやすい数字キーボードを表示します。
                                    .keyboardType(.numberPad)
                                    // この文字やアイコンを.whiteで描画します。
                                    .foregroundStyle(.white)
                                    // 文字またはアイコンの書体と大きさを指定します。
                                    .font(.title2.bold())
                            // この画面部品または処理の範囲をここで閉じます。
                            }
                            
                            // ■ カテゴリ選択（エラー対策のため構造を整理）
                            // 「category」の見出しとアイコンを付けて、内側の入力部品をまとめます。
                            InputGroup(label: lm.t(.category), icon: "tag.fill") {
                                // メニューの選択肢と表示内容の範囲を始めます。
                                Menu {
                                    // 選択肢一覧
                                    // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                                    ForEach(categories) { cat in
                                        // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                                        Button {
                                            // expense.categoryNameへ右辺の値を代入し、状態または集計結果を更新します。
                                            expense.categoryName = cat.name
                                        // ここで「ボタン定義」の処理範囲を閉じます。
                                        } label: {
                                            // 子部品を左から右へ並べる領域を作ります。
                                            HStack {
                                                // 「expense.categoryName == cat.name」の条件が真の場合にだけ、次の処理を実行します。
                                                if expense.categoryName == cat.name {
                                                    // 画像またはシステムアイコンを表示します。
                                                    Image(systemName: "checkmark")
                                                // ここで「条件分岐」の範囲を閉じます。
                                                }
                                                // カテゴリ名を翻訳
                                                // 画面に文字を表示します。
                                                Text(lm.translateCategory(name: cat.name))
                                                // 画像またはシステムアイコンを表示します。
                                                Image(systemName: cat.icon)
                                            // ここで「横並びレイアウト」の範囲を閉じます。
                                            }
                                        // この画面部品または処理の範囲をここで閉じます。
                                        }
                                    // ここで「ForEachクロージャ」の範囲を閉じます。
                                    }
                                // ここで「メニュー」の処理範囲を閉じます。
                                } label: {
                                    // 選択中の表示
                                    // 子部品を左から右へ並べる領域を作ります。
                                    HStack {
                                        // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
                                        if let cat = categories.first(where: { $0.name == expense.categoryName }) {
                                            // カテゴリ名を翻訳
                                            // 画面に文字を表示します。
                                            Text(lm.translateCategory(name: cat.name)).foregroundStyle(.white).bold()
                                            // 伸縮する空白を入れ、周囲の部品を離して配置します。
                                            Spacer()
                                            // 修正: AssetViewのエラー回避のため、ここでは色は白かグレーにする
                                            // 画像またはシステムアイコンを表示します。
                                            Image(systemName: cat.icon).foregroundStyle(.gray)
                                        // ここで「条件分岐」の処理範囲を閉じます。
                                        } else {
                                            // 言語設定の「unclassified」に対応する翻訳文を表示します。
                                            Text(expense.categoryName ?? lm.t(.unclassified)).foregroundStyle(.white).bold()
                                            // 伸縮する空白を入れ、周囲の部品を離して配置します。
                                            Spacer()
                                        // この画面部品または処理の範囲をここで閉じます。
                                        }
                                        // 画像またはシステムアイコンを表示します。
                                        Image(systemName: "chevron.up.chevron.down").foregroundStyle(.gray)
                                    // ここで「横並びレイアウト」の範囲を閉じます。
                                    }
                                // この画面部品または処理の範囲をここで閉じます。
                                }
                            // この画面部品または処理の範囲をここで閉じます。
                            }
                            
                            // 財布選択
                            // 「wallet」の見出しとアイコンを付けて、内側の入力部品をまとめます。
                            InputGroup(label: lm.t(.wallet), icon: "creditcard.fill") {
                                // メニューの選択肢と表示内容の範囲を始めます。
                                Menu {
                                    // 配列や範囲の各要素に対応する画面部品を繰り返し生成します。
                                    ForEach(assets) { asset in
                                        // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                                        Button {
                                            // expense.assetNameへ右辺の値を代入し、状態または集計結果を更新します。
                                            expense.assetName = asset.name
                                        // ここで「ボタン定義」の処理範囲を閉じます。
                                        } label: {
                                            // 子部品を左から右へ並べる領域を作ります。
                                            HStack {
                                                // 「expense.assetName == asset.name」の条件が真の場合にだけ、次の処理を実行します。
                                                if expense.assetName == asset.name {
                                                    // 画像またはシステムアイコンを表示します。
                                                    Image(systemName: "checkmark")
                                                // ここで「条件分岐」の範囲を閉じます。
                                                }
                                                // 画面に文字を表示します。
                                                Text(asset.name)
                                            // ここで「横並びレイアウト」の範囲を閉じます。
                                            }
                                        // この画面部品または処理の範囲をここで閉じます。
                                        }
                                    // ここで「ForEachクロージャ」の範囲を閉じます。
                                    }
                                // ここで「メニュー」の処理範囲を閉じます。
                                } label: {
                                    // 子部品を左から右へ並べる領域を作ります。
                                    HStack {
                                        // 言語設定の「unselected」に対応する翻訳文を表示します。
                                        Text(expense.assetName ?? lm.t(.unselected))
                                            // この文字やアイコンを.whiteで描画します。
                                            .foregroundStyle(.white)
                                            // 文字を太字にします。
                                            .bold()
                                        // 伸縮する空白を入れ、周囲の部品を離して配置します。
                                        Spacer()
                                        // 画像またはシステムアイコンを表示します。
                                        Image(systemName: "chevron.up.chevron.down")
                                            // この文字やアイコンを.grayで描画します。
                                            .foregroundStyle(.gray)
                                    // ここで「横並びレイアウト」の範囲を閉じます。
                                    }
                                // この画面部品または処理の範囲をここで閉じます。
                                }
                            // この画面部品または処理の範囲をここで閉じます。
                            }
                            
                            // 日付
                            // 「date」の見出しとアイコンを付けて、内側の入力部品をまとめます。
                            InputGroup(label: lm.t(.date), icon: "calendar") {
                                // 日付選択欄を表示し、選んだ年月日を日付の状態へ反映します。
                                DatePicker("", selection: $expense.date, displayedComponents: .date)
                                    // 入力部品の標準ラベルを隠します。
                                    .labelsHidden()
                                    // 表示色を反転して暗い背景でも見やすくします。
                                    .colorInvert()
                            // この画面部品または処理の範囲をここで閉じます。
                            }
                        // ここで「縦並びレイアウト」の範囲を閉じます。
                        }
                        // 部品の内側または外側に余白を追加します。
                        .padding(.horizontal)
                    // ここで「縦並びレイアウト」の範囲を閉じます。
                    }
                    // 部品の内側または外側に余白を追加します。
                    .padding(.vertical)
                // ここで「スクロール領域」の範囲を閉じます。
                }
            // ここで「重ね合わせレイアウト」の範囲を閉じます。
            }
            // ナビゲーションバーに現在の画面名を表示します。
            .navigationTitle(lm.t(.editTitle))
            // 画面タイトルをナビゲーションバー内に表示します。
            .navigationBarTitleDisplayMode(.inline)
            // ナビゲーションバーなどの操作項目をまとめます。
            .toolbarColorScheme(.dark, for: .navigationBar)
            // ナビゲーションバーなどの操作項目をまとめます。
            .toolbar {
                // キャンセルまたは確定などの操作をナビゲーションバーへ配置します。
                ToolbarItem(placement: .topBarLeading) {
                    // 「isNewEntry」の条件が真の場合にだけ、次の処理を実行します。
                    if isNewEntry {
                        // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                        Button(lm.t(.cancel)) {
                            // キャンセル時は削除
                            // 選択された保存データを削除対象として登録します。
                            modelContext.delete(expense)
                            // 現在のシートまたは画面を閉じます。
                            dismiss()
                        // ここで「ボタン定義」の範囲を閉じます。
                        }
                        // この文字やアイコンを.redで描画します。
                        .foregroundStyle(.red)
                    // ここで「条件分岐」の範囲を閉じます。
                    }
                // ここで「ツールバー項目」の範囲を閉じます。
                }
                // キャンセルまたは確定などの操作をナビゲーションバーへ配置します。
                ToolbarItem(placement: .topBarTrailing) {
                    // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                    Button(lm.t(.done)) {
                        // 金額0の場合は保存せず削除
                        // 「expense.amount == 0」の条件が真の場合にだけ、次の処理を実行します。
                        if expense.amount == 0 {
                            // 選択された保存データを削除対象として登録します。
                            modelContext.delete(expense)
                        // ここで「条件分岐」の処理範囲を閉じます。
                        } else {
                            // 編集前後の金額差を計算して財布の残高に反映します。
                            updateAssetBalance()
                        // この画面部品または処理の範囲をここで閉じます。
                        }
                        // 現在のシートまたは画面を閉じます。
                        dismiss()
                    // ここで「ボタン定義」の範囲を閉じます。
                    }
                    // この文字やアイコンを.orangeで描画します。
                    .foregroundStyle(.orange)
                    // 文字を太字にします。
                    .bold()
                // ここで「ツールバー項目」の範囲を閉じます。
                }
            // この画面部品または処理の範囲をここで閉じます。
            }
            // 状態に応じて画像を画面全体のモーダルで表示します。
            .fullScreenCover(isPresented: $showingFullScreenImage) {
                // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
                if let filename = expense.imageFilename {
                    // 保存した画像を読み込み、全画面で表示します。
                    AsyncFullScreenImageView(filename: filename, isPresented: $showingFullScreenImage)
                // ここで「条件分岐」の範囲を閉じます。
                }
            // この画面部品または処理の範囲をここで閉じます。
            }
            // 画面が表示された直後に必要な初期化処理を実行します。
            .onAppear {
                // initialAmountへ右辺の値を代入し、状態または集計結果を更新します。
                initialAmount = expense.amount
                // initialAssetNameへ右辺の値を代入し、状態または集計結果を更新します。
                initialAssetName = expense.assetName
            // ここで「画面表示時の処理」の範囲を閉じます。
            }
        // ここで「ナビゲーション画面」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
    
    // 画像ボタン部分を切り出してコードを軽くする
    // 複数のSwiftUI部品を返せる画面構築用の属性を付けます。
    @ViewBuilder
    // 画像のプレビューと拡大操作を表示する部品を定義します。
    private func imageButton(filename: String) -> some View {
        // 押したときに実行する処理と、ボタンに見せる内容を定義します。
        Button {
            // このインスタンスが持つプロパティへ値を設定します。
            self.showingFullScreenImage = true
        // ここで「ボタン定義」の処理範囲を閉じます。
        } label: {
            // 背景と前景の部品を重ねて配置する領域を作ります。
            ZStack {
                // 角を丸めた四角形を背景や枠として作ります。
                RoundedRectangle(cornerRadius: 15)
                    // 図形の内側を塗りつぶします。
                    .fill(Color(white: 0.1))
                    // 図形の輪郭線を描きます。
                    .stroke(Color.orange, lineWidth: 1)
                
                // 子部品を上から下へ並べる領域を作ります。
                VStack {
                    // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
                    if let img = previewImage {
                        // 画像またはシステムアイコンを表示します。
                        Image(uiImage: img)
                            // .resizableをこの画面部品に適用します。
                            .resizable()
                            // .scaledToFitをこの画面部品に適用します。
                            .scaledToFit()
                            // 部品の幅、高さ、配置できる範囲を指定します。
                            .frame(maxHeight: 200)
                            // 部品の角を指定した半径で丸くします。
                            .cornerRadius(10)
                    // ここで「条件分岐」の処理範囲を閉じます。
                    } else {
                        // 子部品を上から下へ並べる領域を作ります。
                        VStack(spacing: 10) {
                            // 画像またはシステムアイコンを表示します。
                            Image(systemName: "photo")
                                // 文字またはアイコンの書体と大きさを指定します。
                                .font(.largeTitle)
                            // 言語設定の「loading」に対応する翻訳文を表示します。
                            Text(lm.t(.loading))
                                // 文字またはアイコンの書体と大きさを指定します。
                                .font(.caption)
                        // ここで「縦並びレイアウト」の範囲を閉じます。
                        }
                        // 部品の幅、高さ、配置できる範囲を指定します。
                        .frame(height: 150)
                        // この文字やアイコンを.grayで描画します。
                        .foregroundStyle(.gray)
                    // この画面部品または処理の範囲をここで閉じます。
                    }
                    
                    // 子部品を左から右へ並べる領域を作ります。
                    HStack {
                        // 画像またはシステムアイコンを表示します。
                        Image(systemName: "magnifyingglass")
                        // 言語設定の「tapToExpand」に対応する翻訳文を表示します。
                        Text(lm.t(.tapToExpand))
                    // ここで「横並びレイアウト」の範囲を閉じます。
                    }
                    // 文字またはアイコンの書体と大きさを指定します。
                    .font(.caption)
                    // この文字やアイコンを.orangeで描画します。
                    .foregroundStyle(.orange)
                    // 部品の内側または外側に余白を追加します。
                    .padding(.bottom, 8)
                // ここで「縦並びレイアウト」の範囲を閉じます。
                }
                // 部品の内側または外側に余白を追加します。
                .padding(8)
            // ここで「重ね合わせレイアウト」の範囲を閉じます。
            }
        // この画面部品または処理の範囲をここで閉じます。
        }
        // 部品の内側または外側に余白を追加します。
        .padding(.horizontal)
        // 画面が表示された直後に必要な初期化処理を実行します。
        .onAppear {
            // 「previewImage == nil { loadPreviewImage(filename: filename) }」の条件が真の場合にだけ、次の処理を実行します。
            if previewImage == nil { loadPreviewImage(filename: filename) }
        // ここで「画面表示時の処理」の範囲を閉じます。
        }
    // ここで「imageButton関数」の範囲を閉じます。
    }
    
    // 編集前後の金額に合わせて財布残高を調整する処理を定義します。
    private func updateAssetBalance() {
        // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
        if let oldName = initialAssetName,
           // oldAssetという定数へ「assets.first(where: { $0.name == oldName }) {」の計算結果を保存します。
           let oldAsset = assets.first(where: { $0.name == oldName }) {
            // oldAsset.balance +へ右辺の値を代入し、状態または集計結果を更新します。
            oldAsset.balance += initialAmount
        // この画面部品または処理の範囲をここで閉じます。
        }
        // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
        if let newName = expense.assetName,
           // newAssetという定数へ「assets.first(where: { $0.name == newName }) {」の計算結果を保存します。
           let newAsset = assets.first(where: { $0.name == newName }) {
            // newAsset.balance -へ右辺の値を代入し、状態または集計結果を更新します。
            newAsset.balance -= expense.amount
        // この画面部品または処理の範囲をここで閉じます。
        }
    // ここで「updateAssetBalance関数」の範囲を閉じます。
    }
    
    // 保存先から画像を読み込む処理を定義します。
    private func loadPreviewImage(filename: String) {
        // 画面操作を止めずに独立した非同期処理を開始します。
        Task.detached(priority: .background) {
            // urlという定数へ「FileManager.default.urls(for: .documentDirectory, in: .」の計算結果を保存します。
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
            // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
            if let image = UIImage(contentsOfFile: url.path) {
                // 非同期処理の完了を待ってから次へ進みます。
                await MainActor.run { self.previewImage = image }
            // ここで「条件分岐」の範囲を閉じます。
            }
        // ここで「非同期タスク」の範囲を閉じます。
        }
    // ここで「loadPreviewImage関数」の範囲を閉じます。
    }
// ここで「EditExpenseView型」の範囲を閉じます。
}

// MARK: - Subviews

// AsyncFullScreenImageViewという画面または補助部品の定義を始めます。
struct AsyncFullScreenImageView: View {
    // 読み込む画像ファイルの名前を受け取ります。
    let filename: String
    // 画像画面を閉じる状態を親画面と共有します。
    @Binding var isPresented: Bool
    // 読み込んだ全画面画像を保持し、値が変わると画面を更新します。
    @State private var image: UIImage? = nil
    // 画像読み込み中かどうかを保持し、値が変わると画面を更新します。
    @State private var isLoading = true
    
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 背景と前景の部品を重ねて配置する領域を作ります。
        ZStack {
            // 黒い背景を画面の端まで広げます。
            Color.black.ignoresSafeArea()
            // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
            if let img = image {
                // 読み込んだ画像を拡大できる表示にして画面全体へ広げます。
                ZoomableImageView(image: img).ignoresSafeArea()
            // ここで「条件分岐」の処理範囲を閉じます。
            } else if isLoading {
                // 画像の読み込み中であることを示す表示を出します。
                ProgressView().scaleEffect(2.0).tint(.orange)
            // この画面部品または処理の範囲をここで閉じます。
            } else {
                // 画面に「Error」という文字を表示します。
                Text("Error").foregroundStyle(.red)
            // この画面部品または処理の範囲をここで閉じます。
            }
            // 子部品を上から下へ並べる領域を作ります。
            VStack {
                // 子部品を左から右へ並べる領域を作ります。
                HStack {
                    // 伸縮する空白を入れ、周囲の部品を離して配置します。
                    Spacer()
                    // 押したときに実行する処理と、ボタンに見せる内容を定義します。
                    Button { isPresented = false } label: {
                        // 画像またはシステムアイコンを表示します。
                        Image(systemName: "xmark.circle.fill")
                            // SF Symbolsの色の描画方式を指定します。
                            .symbolRenderingMode(.palette).foregroundStyle(.black, .orange)
                            // 文字またはアイコンの書体と大きさを指定します。
                            .font(.system(size: 40)).padding()
                    // ここで「ボタン定義」の範囲を閉じます。
                    }
                // ここで「横並びレイアウト」の範囲を閉じます。
                }
                // 伸縮する空白を入れ、周囲の部品を離して配置します。
                Spacer()
            // ここで「縦並びレイアウト」の範囲を閉じます。
            }
        // ここで「重ね合わせレイアウト」の範囲を閉じます。
        }
        // 画面が表示された直後に必要な初期化処理を実行します。
        .onAppear {
            // 画面操作を止めずに独立した非同期処理を開始します。
            Task.detached {
                // urlという定数へ「FileManager.default.urls(for: .documentDirectory, in: .」の計算結果を保存します。
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
                // オプショナル値の取得に成功した場合だけ、中の値を使って表示します。
                if let loaded = UIImage(contentsOfFile: url.path) {
                    // 非同期処理の完了を待ってから次へ進みます。
                    await MainActor.run { self.image = loaded; self.isLoading = false }
                // ここで「条件分岐」の範囲を閉じます。
                }
            // ここで「非同期タスク」の範囲を閉じます。
            }
        // ここで「画面表示時の処理」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
// ここで「AsyncFullScreenImageView型」の範囲を閉じます。
}

// ZoomableImageViewという画面または補助部品の定義を始めます。
struct ZoomableImageView: UIViewRepresentable {
    // 拡大表示するUIImageを受け取ります。
    var image: UIImage
    // SwiftUIの画面に表示するUIKit部品を作る処理を定義します。
    func makeUIView(context: Context) -> UIScrollView {
        // scrollViewという定数へ「UIScrollView()」の計算結果を保存します。
        let scrollView = UIScrollView()
        // scrollView.delegateへ右辺の値を代入し、状態または集計結果を更新します。
        scrollView.delegate = context.coordinator
        // scrollView.maximumZoomScaleへ右辺の値を代入し、状態または集計結果を更新します。
        scrollView.maximumZoomScale = 5.0
        // scrollView.minimumZoomScaleへ右辺の値を代入し、状態または集計結果を更新します。
        scrollView.minimumZoomScale = 1.0
        // scrollView.backgroundColorへ右辺の値を代入し、状態または集計結果を更新します。
        scrollView.backgroundColor = .black
        // imageViewという定数へ「UIImageView(image: image)」の計算結果を保存します。
        let imageView = UIImageView(image: image)
        // imageView.contentModeへ右辺の値を代入し、状態または集計結果を更新します。
        imageView.contentMode = .scaleAspectFit
        // imageView.tagへ右辺の値を代入し、状態または集計結果を更新します。
        imageView.tag = 999
        // imageView.translatesAutoresizingMaskIntoConstraintsへ右辺の値を代入し、状態または集計結果を更新します。
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // スクロール領域の中に画像の表示部品を追加します。
        scrollView.addSubview(imageView)
        // この行で「NSLayoutConstraint.activate([」を指定し、画面構成または処理の一部を定義します。
        NSLayoutConstraint.activate([
            // この行で「imageView.widthAnchor.constraint(equalTo: 」を指定し、画面構成または処理の一部を定義します。
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            // この行で「imageView.heightAnchor.constraint(equalTo:」を指定し、画面構成または処理の一部を定義します。
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            // この行で「imageView.centerXAnchor.constraint(equalTo」を指定し、画面構成または処理の一部を定義します。
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            // 画像の縦方向の中心をスクロール領域の中心に合わせます。
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        // 直前に開いた引数または配列のまとまりを閉じます。
        ])
        // doubleTapという定数へ「UITapGestureRecognizer(target: context.coordinator, act」の計算結果を保存します。
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap))
        // doubleTap.numberOfTapsRequiredへ右辺の値を代入し、状態または集計結果を更新します。
        doubleTap.numberOfTapsRequired = 2
        // 画像を二回タップした操作をスクロール領域で受け取れるようにします。
        scrollView.addGestureRecognizer(doubleTap)
        // 計算結果を呼び出し元へ返し、この関数の処理を終えます。
        return scrollView
    // ここで「makeUIView関数」の範囲を閉じます。
    }
    // 既存UIKit部品を更新する処理を定義します。
    func updateUIView(_ uiView: UIScrollView, context: Context) {}
    // UIKitとのイベント仲介役を作る処理を定義します。
    func makeCoordinator() -> Coordinator { Coordinator() }
    // Coordinatorというクラスの定義を始めます。
    class Coordinator: NSObject, UIScrollViewDelegate {
        // viewForZoomingを実行する処理を定義します。
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { scrollView.viewWithTag(999) }
        // scrollViewDidZoomを実行する処理を定義します。
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // 必要な値を安全に取り出し、値がなければこの関数をその場で終了します。
            guard let imageView = scrollView.viewWithTag(999) else { return }
            // offsetXという定数へ「max((scrollView.bounds.width - scrollView.contentSize.w」の計算結果を保存します。
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
            // offsetYという定数へ「max((scrollView.bounds.height - scrollView.contentSize.」の計算結果を保存します。
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            // imageView.centerへ右辺の値を代入し、状態または集計結果を更新します。
            imageView.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
        // ここで「scrollViewDidZoom関数」の範囲を閉じます。
        }
        // Objective-C経由のジェスチャー呼び出しにこのメソッドを公開します。
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            // 必要な値を安全に取り出し、値がなければこの関数をその場で終了します。
            guard let scrollView = gesture.view as? UIScrollView else { return }
            // 「scrollView.zoomScale > 1 { scrollView.setZoomScale(1, animated: true) }」の条件が真の場合にだけ、次の処理を実行します。
            if scrollView.zoomScale > 1 { scrollView.setZoomScale(1, animated: true) }
            // 先行する条件に当てはまらない場合の処理を始めます。
            else {
                // tapPointという定数へ「gesture.location(in: scrollView.viewWithTag(999))」の計算結果を保存します。
                let tapPoint = gesture.location(in: scrollView.viewWithTag(999))
                // newZoomScaleに後から変更しない値を保持します。
                let newZoomScale: CGFloat = 3.0
                // sizeという定数へ「scrollView.bounds.size」の計算結果を保存します。
                let size = scrollView.bounds.size
                // wという定数へ「size.width / newZoomScale」の計算結果を保存します。
                let w = size.width / newZoomScale
                // hという定数へ「size.height / newZoomScale」の計算結果を保存します。
                let h = size.height / newZoomScale
                // rectという定数へ「CGRect(x: tapPoint.x - w/2, y: tapPoint.y - h/2, width:」の計算結果を保存します。
                let rect = CGRect(x: tapPoint.x - w/2, y: tapPoint.y - h/2, width: w, height: h)
                // 指定された画像範囲までアニメーション付きで拡大します。
                scrollView.zoom(to: rect, animated: true)
            // ここで「else分岐」の範囲を閉じます。
            }
        // この画面部品または処理の範囲をここで閉じます。
        }
    // ここで「Coordinatorクラス」の範囲を閉じます。
    }
// ここで「ZoomableImageView型」の範囲を閉じます。
}

// InputGroupという画面または補助部品の定義を始めます。
struct InputGroup<Content: View>: View {
    // labelに後から変更しない値を保持します。
    let label: String
    // iconに後から変更しない値を保持します。
    let icon: String
    // contentに後から変更しない値を保持します。
    let content: Content
    // この型を作るときに実行する初期化処理を定義します。
    init(label: String, icon: String, @ViewBuilder content: () -> Content) {
        // このインスタンスが持つプロパティへ値を設定します。
        self.label = label; self.icon = icon; self.content = content()
    // ここで「初期化処理」の範囲を閉じます。
    }
    // この画面または部品の表示内容をSwiftUIの部品として返します。
    var body: some View {
        // 子部品を上から下へ並べる領域を作ります。
        VStack(alignment: .leading, spacing: 6) {
            // 入力項目の見出しをアイコン付きの小さな太字で表示します。
            Label(label, systemImage: icon).font(.caption2).bold().foregroundStyle(.gray).tracking(1)
            // 子部品を左から右へ並べる領域を作ります。
            HStack { content }
                // 部品の内側または外側に余白を追加します。
                .padding()
                // この部品の背後に指定した背景を描きます。
                .background(Color(white: 0.12))
                // 部品の角を指定した半径で丸くします。
                .cornerRadius(12)
                // この部品の上に枠や補助表示を重ねます。
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        // ここで「縦並びレイアウト」の範囲を閉じます。
        }
    // この画面部品または処理の範囲をここで閉じます。
    }
// ここで「InputGroup<Content型」の範囲を閉じます。
}
