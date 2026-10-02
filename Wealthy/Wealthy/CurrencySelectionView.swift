import SwiftUI

struct CurrencySelectionView: View {
    let firstLaunch: Bool
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var lm: LanguageManager
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var searchText = ""
    @State private var selectedCodes: Set<String> = []

    private var visibleCodes: [String] {
        // 入力された検索語の前後にある空白を取り除きます。
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        // 検索語がなければ全ての通貨を表示します。
        guard !query.isEmpty else { return currencyManager.supportedCodes }
        // 通貨コードまたは表示言語の通貨名に一致する候補を返します。
        return currencyManager.supportedCodes.filter { code in
            code.localizedCaseInsensitiveContains(query)
                || CurrencyPolicy.localizedName(for: code, locale: lm.currentLanguage.locale)
                    .localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        // 通貨選択画面をナビゲーション画面として表示します。
        NavigationStack {
            // 通貨一覧と選択件数をスクロール可能なリストへ表示します。
            List {
                // 選択済み件数と説明を一覧の見出しと脚注に表示します。
                Section(header: Text(lm.format("currency.selected", selectedCodes.count)), footer: Text(lm.text("currency.hint"))) {
                    // 検索結果の通貨を選択行として表示します。
                    ForEach(visibleCodes, id: \.self) { code in
                        // 行を押したときに選択状態を切り替えます。
                        Button {
                            // 選択状態を更新する処理を呼び出します。
                            toggle(code)
                        } label: {
                            // チェック欄と通貨名を横一列に表示します。
                            HStack {
                                // 選択状態に応じたチェック欄を表示します。
                                Image(systemName: selectedCodes.contains(code) ? "checkmark.square.fill" : "square")
                                // 表示言語の通貨名とISOコードを併記します。
                                Text("\(CurrencyPolicy.localizedName(for: code, locale: lm.currentLanguage.locale)) (\(code))")
                                // 行の残り幅を埋め、タップ領域を整えます。
                                Spacer()
                            }.contentShape(Rectangle())
                        }
                        // 行を押しても標準ボタン背景を付けません。
                        .buttonStyle(.plain)
                        // UI自動化で個別の通貨を識別します。
                        .accessibilityIdentifier("currency.toggle.\(code)")
                        // アクセシビリティへ現在の選択状態を伝えます。
                        .accessibilityAddTraits(selectedCodes.contains(code) ? .isSelected : [])
                    }
                }
            }
            // 通貨名とコードを入力して一覧を絞り込みます。
            .searchable(text: $searchText)
            // UI自動化で検索一覧を識別します。
            .accessibilityIdentifier("currency.selection.search")
            // 画面タイトルを現在の表示言語で表示します。
            .navigationTitle(lm.text("currency.choose"))
            // 検索中も確定操作を表示し、キーボードを閉じる手間を減らします。
            .safeAreaInset(edge: .bottom) {
                HStack {
                    if !firstLaunch {
                        Button { dismiss() } label: {
                            Text(lm.t(.cancel)).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("currency.cancel")
                    }
                    Button { save() } label: {
                        Text(lm.t(.done)).frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCodes.isEmpty)
                    .accessibilityIdentifier("currency.selection.save")
                }
                .controlSize(.large)
                .padding()
                .background(.regularMaterial)
            }

            // 初回設定時はスワイプで選択画面を閉じられないようにします。
            .interactiveDismissDisabled(firstLaunch)
            // 保存済みの選択を編集用の下書きへ複製します。
            .onAppear { selectedCodes = Set(currencyManager.selectedCodes) }
        }
    }

    private func toggle(_ code: String) {
        // すでに選ばれていれば下書きから外します。
        if selectedCodes.contains(code) {
            selectedCodes.remove(code)
        // まだ選ばれていなければ下書きへ追加します。
        } else {
            selectedCodes.insert(code)
        }
    }

    private func save() {
        // サポート一覧の順で、選択した通貨だけを並べます。
        let ordered = currencyManager.supportedCodes.filter { selectedCodes.contains($0) }
        // 空の選択内容は保存しません。
        guard !ordered.isEmpty else { return }
        // 選択した通貨一覧を共有設定へ保存します。
        currencyManager.selectedCodes = ordered
        // 既定通貨が外された場合は、残った先頭の通貨を既定にします。
        if !ordered.contains(currencyManager.selectedCode) {
            currencyManager.selectedCode = ordered[0]
        }
        // 親画面へ保存完了を通知します。
        onSave()
        // 通貨選択画面を閉じます。
        dismiss()
    }
}
