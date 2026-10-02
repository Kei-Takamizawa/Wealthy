import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AdvancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var lm: LanguageManager
    // 通貨設定を共有し、新規記録に使う通貨を画面へ反映します。
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var isProcessing = false
    @State private var showFileExporter = false
    @State private var showFileImporter = false
    // 通貨の複数選択画面を表示する状態を保持します。
    @State private var showCurrencySelection = false
    @State private var backupDocument: BackupDocument?
    @State private var imageSummary: ReceiptImageSummary?
    @State private var showImageChoice = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    private var backupChoiceMessage: String {
        guard let summary = imageSummary else { return "" }
        let size = summary.totalBytes.formatted(.byteCount(style: .file).locale(lm.currentLanguage.locale))
        let main = lm.format("backup.imageSummary", summary.uniqueImageCount, size)
            + "\n" + lm.text("backup.imageSizeNote")
        guard summary.missingImageCount > 0 else { return main }
        return main + "\n" + lm.format("backup.missingImages", summary.missingImageCount)
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(lm.t(.languageSettings))) {
                    Picker(selection: $lm.currentLanguage) {
                        ForEach(AppLanguage.allCases) { language in Text(language.nativeName).tag(language) }
                    } label: { Text(lm.t(.languageSettings)) }
                    .pickerStyle(.menu).accessibilityIdentifier("settings.language")
                }
                // 新しい記録に使う通貨と、利用する通貨一覧を設定します。
                Section(header: Text(lm.text("currency.setting")), footer: Text(lm.text("currency.help"))) {
                    // 利用可能な通貨から新規記録の既定通貨を選択します。
                    Picker(selection: $currencyManager.selectedCode) {
                        // 有効化された各通貨を選択肢として表示します。
                        ForEach(currencyManager.selectedCodes, id: \.self) { code in
                            // 表示言語での通貨名とISOコードを併記します。
                            Text("\(CurrencyPolicy.localizedName(for: code, locale: lm.currentLanguage.locale)) (\(code))").tag(code)
                        }
                    } label: {
                        // 既定通貨の選択欄を現在の表示言語で表示します。
                        Text(lm.text("currency.default"))
                    }
                    // 選択肢をメニュー形式で表示します。
                    .pickerStyle(.menu).accessibilityIdentifier("settings.currency.default")
                    // 有効化する通貨一覧を編集する画面を開きます。
                    Button { showCurrencySelection = true } label: {
                        // 現在選択中の通貨数を追加アイコンとともに表示します。
                        Label(lm.format("currency.choose") + " · " + lm.format("currency.selected", currencyManager.selectedCodes.count), systemImage: "plus.circle")
                    }
                    // 通貨一覧を編集するボタンへアクセシビリティ識別子を付けます。
                    .accessibilityIdentifier("settings.currency.choose")
                }
                Section(header: Text(lm.t(.settings))) {
                    NavigationLink(destination: RecurringSettingsView()) {
                        Label(lm.t(.recurring), systemImage: "repeat.circle.fill")
                    }
                    NavigationLink(destination: CategoriesView()) {
                        Label(lm.t(.category), systemImage: "tag.fill")
                    }
                }
                Section(header: Text(lm.t(.dataManagement)), footer: Text(lm.text("backup.description") + " " + lm.text("backup.pointsIncluded"))) {
                    Button(action: prepareBackupChoice) {
                        Label(lm.t(.backup), systemImage: "square.and.arrow.up")
                    }.accessibilityIdentifier("backup.open")
                    Button { showFileImporter = true } label: {
                        Label(lm.t(.restore), systemImage: "square.and.arrow.down")
                    }
                }
            }
            .disabled(isProcessing || showFileExporter || showFileImporter)
            .navigationTitle(lm.t(.settings))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button(lm.t(.close)) { dismiss() }.accessibilityIdentifier("settings.close") }
            }
            .alert(showImageChoice ? lm.text("backup.imageTitle") : alertMessage, isPresented: $showAlert) {
                if showImageChoice {
                    Button(lm.text("backup.includeImages")) { createBackup(includeImages: true) }
                    Button(lm.text("backup.recordsOnly")) { createBackup(includeImages: false) }
                    Button(lm.t(.cancel), role: .cancel) {}
                } else {
                    Button(lm.text("ok"), role: .cancel) {}
                }
            } message: {
                if showImageChoice { Text(backupChoiceMessage) }
            }
            .fileExporter(isPresented: $showFileExporter, document: backupDocument, contentType: .json, defaultFilename: "Wealthy_Backup") { result in
                isProcessing = false
                switch result {
                case .success: notify(lm.t(.backupSuccess))
                case .failure(let error): notify("\(lm.t(.error)): \(error.localizedDescription)")
                }
            }
            // 通貨コード検索と複数選択を行うシートを表示します。
            .sheet(isPresented: $showCurrencySelection) {
                // 設定画面から開くためキャンセル操作を表示する選択画面を作ります。
                CurrencySelectionView(firstLaunch: false, onSave: {})
            }
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    try BackupManager.shared.restoreBackup(from: url, context: modelContext)
                    // Make every restored record visible even if its currency was not previously enabled.
                    let restoredCodes = try modelContext.fetch(FetchDescriptor<Asset>()).map(\.effectiveCurrencyCode)
                        + modelContext.fetch(FetchDescriptor<Expense>()).map(\.effectiveCurrencyCode)
                        + modelContext.fetch(FetchDescriptor<RecurringItem>()).map(\.effectiveCurrencyCode)
                    currencyManager.selectedCodes = Array(Set(currencyManager.selectedCodes + restoredCodes)).sorted()
                    notify(lm.t(.restoreSuccess))
                } catch { notify("\(lm.t(.error)): \(error.localizedDescription)") }
            }
        }
    }

    private func prepareBackupChoice() {
        do {
            imageSummary = try BackupManager.shared.receiptImageSummary(context: modelContext)
            showImageChoice = true
            showAlert = true
        } catch { notify("\(lm.t(.error)): \(error.localizedDescription)") }
    }

    private func createBackup(includeImages: Bool) {
        guard !isProcessing else { return }
        isProcessing = true
        do {
            backupDocument = BackupDocument(data: try BackupManager.shared.createBackupData(context: modelContext, includeReceiptImages: includeImages))
            // Present after dismissing the choice alert, avoiding overlapping modal presentations.
            DispatchQueue.main.async { showFileExporter = true }
        } catch {
            isProcessing = false
            notify("\(lm.t(.error)): \(error.localizedDescription)")
        }
    }

    private func notify(_ message: String) {
        DispatchQueue.main.async {
            showImageChoice = false
            alertMessage = message
            showAlert = true
        }
    }
}
