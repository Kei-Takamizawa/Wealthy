import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AdvancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var lm: LanguageManager
    @State private var isProcessing = false
    @State private var showFileExporter = false
    @State private var showFileImporter = false
    @State private var backupDocument: BackupDocument?
    @State private var imageSummary: ReceiptImageSummary?
    @State private var showImageChoice = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    private func text(_ japanese: String, _ english: String) -> String {
        lm.currentLanguage == .japanese ? japanese : english
    }

    private var backupChoiceMessage: String {
        guard let summary = imageSummary else { return "" }
        let size = ByteCountFormatter.string(fromByteCount: summary.totalBytes, countStyle: .file)
        let main = text(
            "レシート画像 \(summary.uniqueImageCount)枚、合計 \(size)。画像もバックアップに含めますか？\nJSONに含めると画像データの容量は約33%増えます。チャット履歴は含まれません。",
            "\(summary.uniqueImageCount) receipt images, \(size) in total. Include them in the backup?\nEmbedding images in JSON adds about 33% to their size. Chat history is excluded."
        )
        guard summary.missingImageCount > 0 else { return main }
        return main + text(
            "\n読み取れない画像が\(summary.missingImageCount)枚あります。画像を含めるには元画像が必要です。「記録のみ」を選んでください。",
            "\n\(summary.missingImageCount) images are unavailable. Choose “Records only”, or recover the originals before including images."
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(lm.t(.languageSettings))) {
                    Picker(selection: $lm.currentLanguage) {
                        ForEach(AppLanguage.allCases) { language in Text(language.rawValue).tag(language) }
                    } label: { Text(lm.t(.languageSettings)) }
                    .pickerStyle(.menu)
                }
                Section(header: Text(lm.t(.settings))) {
                    NavigationLink(destination: RecurringSettingsView()) {
                        Label(lm.t(.recurring), systemImage: "repeat.circle.fill")
                    }
                    NavigationLink(destination: CategoriesView()) {
                        Label(lm.t(.category), systemImage: "tag.fill")
                    }
                }
                Section(header: Text(lm.t(.dataManagement)), footer: Text(text(
                    "資産、収支、定期収支、カテゴリーをJSONで保存します。レシート画像を含めるか選べます。チャット履歴は24時間で削除され、バックアップにも含まれません。復元すると現在の記録は置き換わります。",
                    "Save wallets, income, expenses, recurring items and categories as JSON. Choose whether to include receipt images. Chat history expires after 24 hours and is excluded. Restoring replaces your current records."
                ))) {
                    Button(action: prepareBackupChoice) {
                        Label(lm.t(.backup), systemImage: "square.and.arrow.up")
                    }
                    Button { showFileImporter = true } label: {
                        Label(lm.t(.restore), systemImage: "square.and.arrow.down")
                    }
                }
            }
            .disabled(isProcessing || showFileExporter || showFileImporter)
            .navigationTitle(lm.t(.settings))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button(lm.t(.close)) { dismiss() } }
            }
            .alert(showImageChoice ? text("レシート画像のバックアップ", "Back up receipt images") : alertMessage, isPresented: $showAlert) {
                if showImageChoice {
                    Button(text("画像も含める", "Include images")) { createBackup(includeImages: true) }
                    Button(text("記録のみ", "Records only")) { createBackup(includeImages: false) }
                    Button(lm.t(.cancel), role: .cancel) {}
                } else {
                    Button("OK", role: .cancel) {}
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
            .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    try BackupManager.shared.restoreBackup(from: url, context: modelContext)
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
