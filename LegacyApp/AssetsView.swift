// xcode: set sdk=iOS

import SwiftUI
import SwiftData

struct AssetsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var lm: LanguageManager
    // 利用者が選択中の通貨に属する財布だけを一覧に表示します。
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @Query private var assets: [Asset]
    @Query private var pointCards: [PointCard]
    @State private var showAdd = false
    @State private var editingAsset: Asset?
    @State private var showPoints = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            List {
                Section(lm.t(.wallets)) {
                    ForEach(assets.filter { currencyManager.selectedCodes.contains($0.effectiveCurrencyCode) }) { asset in
                        Button { editingAsset = asset } label: {
                            HStack {
                                Circle().fill(Color(hex: asset.colorHex)).frame(width: 18, height: 18)
                                VStack(alignment: .leading) {
                                    Text(asset.name).foregroundStyle(.primary)
                                    if asset.isAutoCreated {
                                        Text(lm.text("wallet.provisional")).font(.caption).foregroundStyle(.orange)
                                    }
                                }
                                Spacer()
                                // 財布ごとの通貨と表示言語で残高を整形します。
                                Text(CurrencyPolicy.format(asset.balance, currencyCode: asset.effectiveCurrencyCode, locale: lm.currentLanguage.locale))
                                    .accessibilityIdentifier("wallet.balance.\(asset.name)")
                                    .foregroundStyle(asset.balance < 0 ? .red : .primary)
                            }
                        }
                        .accessibilityIdentifier("wallet.row.\(asset.name)")
                        .swipeActions {
                            Button(role: .destructive) {
                                context.delete(asset)
                                do { try context.save() } catch { context.rollback(); self.error = error.localizedDescription }
                            } label: { Label(lm.t(.delete), systemImage: "trash") }
                        }
                    }
                    Button { showAdd = true } label: { Label(lm.t(.add), systemImage: "plus") }.accessibilityIdentifier("wallet.add")
                }
                Section {
                    Button { showPoints = true } label: {
                        HStack {
                            Label(lm.text("points.title"), systemImage: "creditcard.and.123")
                            Spacer()
                            Text(pointCards.count.formatted(.number.locale(lm.currentLanguage.locale)))
                        }
                    }
                    .accessibilityIdentifier("points.open")
                    NavigationLink { FinancialServicesView() } label: {
                        Label(lm.text("connections.title"), systemImage: "building.columns")
                    }
                }
            }
            .navigationTitle(lm.t(.wallets))
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showAdd) { AddAssetView() }
            .sheet(item: $editingAsset) { EditAssetView(asset: $0) }
            .sheet(isPresented: $showPoints) { PointCardsView() }
            .alert(lm.t(.error), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button(lm.text("ok"), role: .cancel) {}
            } message: { Text(error ?? "") }
        }
        .preferredColorScheme(.dark)
    }
}

struct AddAssetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var lm: LanguageManager
    // 新規財布に使う通貨を共有設定から取得します。
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var name = ""
    // 入力途中の小数表記を保持します。
    @State private var balanceText = ""
    // フォームを開いた時点の新規通貨を保持します。
    @State private var currencyCode = CurrencyPolicy.defaultCode
    @State private var method = ""
    @State private var selectedColor = "FFA500"
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                TextField(lm.text("wallet.name"), text: $name).accessibilityIdentifier("wallet.name")
                // 新規財布に使う通貨を利用可能な一覧から選択します。
                Picker(lm.text("currency.default"), selection: $currencyCode) {
                    // 利用可能な通貨の表示名とISOコードを並べます。
                    ForEach(currencyManager.selectedCodes, id: \.self) { code in
                        // 選択欄の値にISOコードを設定します。
                        Text("\(CurrencyPolicy.localizedName(for: code, locale: lm.currentLanguage.locale)) (\(code))").tag(code)
                    }
                }
                // 選択通貨に合わせて初期残高を入力します。
                TextField(lm.format("currency.amount", currencyCode), text: $balanceText)
                    // 通貨の最小単位に応じた入力キーボードを表示します。
                    .keyboardType(.numbersAndPunctuation)
                    // 既存のUI自動化用識別子を維持します。
                    .accessibilityIdentifier("wallet.amount")
                Section {
                    WalletPaymentPicker(method: $method)
                } footer: { Text(lm.text("wallet.paymentHint")) }
                WalletColorPicker(color: $selectedColor)
                Section { Text(lm.text("wallet.openingNote")).font(.footnote) }
            }
            .navigationTitle(lm.t(.add))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(lm.t(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.t(.save)) { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            // フォーム表示時に共有通貨とゼロの入力表記を初期化します。
            .onAppear {
                currencyCode = currencyManager.selectedCode
                balanceText = CurrencyPolicy.inputText(0, currencyCode: currencyCode, locale: lm.currentLanguage.locale)
            }
            // 通貨を変えたとき、前の通貨で入力した額を引き継がないようにします。
            .onChange(of: currencyCode) { _, newCode in
                balanceText = CurrencyPolicy.inputText(0, currencyCode: newCode, locale: lm.currentLanguage.locale)
            }
            .alert(lm.t(.error), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button(lm.text("ok"), role: .cancel) {}
            } message: { Text(error ?? "") }
        }
        .preferredColorScheme(.dark)
    }
    private func save() {
        do {
            let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
            // 選択通貨と表示言語の小数規則に従って入力値を最小単位へ変換します。
            guard let amount = CurrencyPolicy.parseMinorUnits(balanceText, currencyCode: currencyCode, locale: lm.currentLanguage.locale) else {
                error = lm.text("currency.invalidAmount")
                return
            }
            let key = method.isEmpty ? (ReceiptPaymentPolicy.method(forAssetName: title) ?? "custom:" + AppLocalization.normalized(title)) : method
            let assets = try context.fetch(FetchDescriptor<Asset>())
            // 支出記録は財布名で関連付くため、通貨が違う同名財布を拒否します。
            if let sameName = assets.first(where: { AppLocalization.normalized($0.name) == AppLocalization.normalized(title) }), sameName.effectiveCurrencyCode != currencyCode {
                throw ExpenseLedger.failure("wallet.duplicate")
            }
            // 自動作成財布を統合する候補も同じ通貨に限定します。
            let matches = assets.filter { $0.effectiveCurrencyCode == currencyCode && (AppLocalization.normalized($0.name) == AppLocalization.normalized(title) || ($0.paymentMethod ?? ReceiptPaymentPolicy.method(forAssetName: $0.name)) == key) }
            if let existing = matches.first {
                guard matches.count == 1 && existing.isAutoCreated else { throw ExpenseLedger.failure("wallet.duplicate") }
                let sum = existing.balance.addingReportingOverflow(amount)
                guard !sum.overflow else { throw ExpenseLedger.failure("ledger.invalidAmount") }
                let old = existing.balance
                existing.balance = sum.partialValue
                existing.isAutoCreated = false
                do { try context.save() } catch { existing.balance = old; existing.isAutoCreated = true; throw error }
            } else {
                context.insert(Asset(name: title, balance: amount, colorHex: selectedColor, paymentMethod: key, currencyCode: currencyCode))
                try context.save()
            }
            dismiss()
        } catch { context.rollback(); self.error = error.localizedDescription }
    }
}

struct EditAssetView: View {
    let asset: Asset
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var lm: LanguageManager
    @State private var name = ""
    // 入力途中の小数表記を保持します。
    @State private var balanceText = ""
    @State private var method = ""
    @State private var selectedColor = "FFA500"
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                TextField(lm.text("wallet.name"), text: $name).accessibilityIdentifier("wallet.name")
                // 保存済み財布の通貨に合わせて残高を入力します。
                TextField(lm.format("currency.amount", asset.effectiveCurrencyCode), text: $balanceText)
                    // 通貨の最小単位に応じた入力キーボードを表示します。
                    .keyboardType(.numbersAndPunctuation)
                    // 既存のUI自動化用識別子を維持します。
                    .accessibilityIdentifier("wallet.amount")
                WalletPaymentPicker(method: $method)
                WalletColorPicker(color: $selectedColor)
                if asset.isAutoCreated { Text(lm.text("wallet.provisional")).foregroundStyle(.orange) }
            }
            .navigationTitle(lm.t(.edit))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(lm.t(.cancel)) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(lm.t(.save)) { save() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            // 既存の財布情報と通貨に合わせた入力表記を読み込みます。
            .onAppear {
                name = asset.name
                balanceText = CurrencyPolicy.inputText(asset.balance, currencyCode: asset.effectiveCurrencyCode, locale: lm.currentLanguage.locale)
                method = asset.paymentMethod ?? ""
                selectedColor = asset.colorHex
            }
            .alert(lm.t(.error), isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button(lm.text("ok"), role: .cancel) {}
            } message: { Text(error ?? "") }
        }
        .preferredColorScheme(.dark)
    }
    private func save() {
        do {
            let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
            // 財布の通貨に従って入力値を最小単位へ変換します。
            guard let amount = CurrencyPolicy.parseMinorUnits(balanceText, currencyCode: asset.effectiveCurrencyCode, locale: lm.currentLanguage.locale) else {
                error = lm.text("currency.invalidAmount")
                return
            }
            let all = try context.fetch(FetchDescriptor<Asset>())
            guard !all.contains(where: { $0 != asset && AppLocalization.normalized($0.name) == AppLocalization.normalized(title) }) else { throw ExpenseLedger.failure("wallet.duplicate") }
            let oldName = asset.name
            for expense in try context.fetch(FetchDescriptor<Expense>()) where expense.assetName == oldName { expense.assetName = title }
            for rule in try context.fetch(FetchDescriptor<RecurringItem>()) where rule.assetName == oldName { rule.assetName = title }
            asset.name = title; asset.balance = amount; asset.colorHex = selectedColor
            asset.paymentMethod = method.isEmpty ? ReceiptPaymentPolicy.method(forAssetName: title) : method
            asset.isAutoCreated = false
            try context.save()
            dismiss()
        } catch { context.rollback(); self.error = error.localizedDescription }
    }
}

struct WalletPaymentPicker: View {
    @Binding var method: String
    @EnvironmentObject private var lm: LanguageManager
    var body: some View {
        Picker(lm.text("payment.title"), selection: $method) {
            Text(lm.text("payment.other")).tag("")
            ForEach(ReceiptPaymentPolicy.methods, id: \.self) { key in
                Text(ReceiptPaymentPolicy.displayName(key, language: lm.currentLanguage)).tag(key)
            }
        }
    }
}

struct WalletColorPicker: View {
    @Binding var color: String
    @EnvironmentObject private var lm: LanguageManager
    var body: some View {
        Section(lm.t(.color)) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(["FFA500", "FF4500", "32CD32", "1E90FF", "8A2BE2", "FF69B4", "808080", "000000"], id: \.self) { value in
                        Button { color = value } label: {
                            Circle().fill(Color(hex: value)).frame(width: 30, height: 30)
                                .overlay { if color == value { Image(systemName: "checkmark").foregroundStyle(.white) } }
                        }.buttonStyle(.plain).accessibilityLabel(lm.t(.color) + " " + value)
                    }
                }
            }
        }
    }
}

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
