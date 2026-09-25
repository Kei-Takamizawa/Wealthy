//
//  BackupManager.swift
//  Wealthy
//
//  Created by Harrison on 12/28/25.
//

// Foundationの機能を、このファイルから使えるように読み込みます。
import Foundation
// SwiftDataの機能を、このファイルから使えるように読み込みます。
import SwiftData
// SwiftUIの機能を、このファイルから使えるように読み込みます。
import SwiftUI

// バックアップの作成と復元を担当する型を定義します。
struct BackupManager {
    // アプリ内で共有する、この管理クラスのインスタンスを一つ作ります。
    static let shared = BackupManager()
    
    // MARK: - DTOs for JSON Serialization
    // JSONに保存する全データの型を定義します。
    struct BackupData: Codable {
        // assetsとして後続の処理で使う値を保持するプロパティを定義します。
        let assets: [AssetDTO]
        // expensesとして後続の処理で使う値を保持するプロパティを定義します。
        let expenses: [ExpenseDTO]
        // recurringItemsとして後続の処理で使う値を保持するプロパティを定義します。
        let recurringItems: [RecurringItemDTO]
        // categoriesとして後続の処理で使う値を保持するプロパティを定義します。
        let categories: [CategoryDTO]
        // chatMessagesとして後続の処理で使う値を保持するプロパティを定義します。
        let chatMessages: [ChatMessageDTO]
        // 作成または保存した日時を保持するプロパティを定義します。
        let timestamp: Date
        // appVersionとして後続の処理で使う値を保持するプロパティを定義します。
        let appVersion: String
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 資産をJSON化するための型を定義します。
    struct AssetDTO: Codable {
        // 表示名を保持するプロパティを定義します。
        let name: String
        // 資産残高を保持するプロパティを定義します。
        let balance: Int
        // 表示色の16進数文字列を保持するプロパティを定義します。
        let colorHex: String
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 収支をJSON化するための型を定義します。
    struct ExpenseDTO: Codable {
        // 表示する項目名を保持するプロパティを定義します。
        let title: String
        // 金額を保持するプロパティを定義します。
        let amount: Int
        // 取引または処理の日付を保持するプロパティを定義します。
        let date: Date
        // レシート画像のファイル名を保持するプロパティを定義します。
        let imageFilename: String?
        // 関連する財布の名前を保持するプロパティを定義します。
        let assetName: String?
        // 収入かどうかを示す真偽値を保持するプロパティを定義します。
        let isIncome: Bool
        // カテゴリ名を保持するプロパティを定義します。
        let categoryName: String?
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 定期収支をJSON化するための型を定義します。
    struct RecurringItemDTO: Codable {
        // 表示する項目名を保持するプロパティを定義します。
        let title: String
        // 金額を保持するプロパティを定義します。
        let amount: Int
        // 定期収支を毎月処理する日をバックアップへ記録します。
        let dayOfMonth: Int
        // 収入かどうかを示す真偽値を保持するプロパティを定義します。
        let isIncome: Bool
        // 関連する財布の名前を保持するプロパティを定義します。
        let assetName: String
        // 最後に定期処理した日を保持するプロパティを定義します。
        let lastProcessedDate: Date?
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // カテゴリをJSON化するための型を定義します。
    struct CategoryDTO: Codable {
        // 表示名を保持するプロパティを定義します。
        let name: String
        // カテゴリのアイコンを保持するプロパティを定義します。
        let icon: String
        // 表示色の16進数文字列を保持するプロパティを定義します。
        let colorHex: String
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 会話履歴をJSON化するための型を定義します。
    struct ChatMessageDTO: Codable {
        // 発言者を保持するプロパティを定義します。
        let role: String
        // 通知に表示する題名と本文を入れる値を作ります。
        let content: String
        // 作成または保存した日時を保持するプロパティを定義します。
        let timestamp: Date
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // MARK: - Export
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // 保存済みの情報をJSONファイルに書き出す入口を定義します。
    func createBackupURL(context: ModelContext) throws -> URL {
        // Fetch all data
        // 資産を全件取得する検索条件を作ります。
        let assetsDescriptor = FetchDescriptor<Asset>()
        // 収支履歴を全件取得する検索条件を作ります。
        let expensesDescriptor = FetchDescriptor<Expense>()
        // 定期収支を全件取得する検索条件を作ります。
        let recurringDescriptor = FetchDescriptor<RecurringItem>()
        // カテゴリを全件取得する検索条件を作ります。
        let categoriesDescriptor = FetchDescriptor<Category>()
        // 会話履歴を全件取得する検索条件を作ります。
        let chatDescriptor = FetchDescriptor<ChatMessageModel>()
        
        // assetsとして後続の処理で使う値を作成または更新します。
        let assets = try context.fetch(assetsDescriptor)
        // expensesとして後続の処理で使う値を作成または更新します。
        let expenses = try context.fetch(expensesDescriptor)
        // recurringItemsとして後続の処理で使う値を作成または更新します。
        let recurringItems = try context.fetch(recurringDescriptor)
        // categoriesとして後続の処理で使う値を作成または更新します。
        let categories = try context.fetch(categoriesDescriptor)
        // chatMessagesとして後続の処理で使う値を作成または更新します。
        let chatMessages = try context.fetch(chatDescriptor)
        
        // Convert to DTOs
        // 資産をJSONに保存できる値へ変換します。
        let assetDTOs = assets.map { AssetDTO(name: $0.name, balance: $0.balance, colorHex: $0.colorHex) }
        // 収支履歴をJSONに保存できる値へ変換します。
        let expenseDTOs = expenses.map { ExpenseDTO(title: $0.title, amount: $0.amount, date: $0.date, imageFilename: $0.imageFilename, assetName: $0.assetName, isIncome: $0.isIncome, categoryName: $0.categoryName) }
        // 定期収支をJSONに保存できる値へ変換します。
        let recurringDTOs = recurringItems.map { RecurringItemDTO(title: $0.title, amount: $0.amount, dayOfMonth: $0.dayOfMonth, isIncome: $0.isIncome, assetName: $0.assetName, lastProcessedDate: $0.lastProcessedDate) }
        // カテゴリをJSONに保存できる値へ変換します。
        let categoryDTOs = categories.map { CategoryDTO(name: $0.name, icon: $0.icon, colorHex: $0.colorHex) }
        // 会話履歴をJSONに保存できる値へ変換します。
        let chatDTOs = chatMessages.map { ChatMessageDTO(role: $0.roleRaw, content: $0.content, timestamp: $0.timestamp) }
        
        // 各データと作成日時を一つのバックアップにまとめます。
        let backupData = BackupData(
            // 直前に定義した処理へ、この設定または引数を追加します。
            assets: assetDTOs,
            // 直前に定義した処理へ、この設定または引数を追加します。
            expenses: expenseDTOs,
            // 直前に定義した処理へ、この設定または引数を追加します。
            recurringItems: recurringDTOs,
            // 直前に定義した処理へ、この設定または引数を追加します。
            categories: categoryDTOs,
            // 直前に定義した処理へ、この設定または引数を追加します。
            chatMessages: chatDTOs,
            // 直前に定義した処理へ、この設定または引数を追加します。
            timestamp: Date(),
            // 直前に定義した処理へ、この設定または引数を追加します。
            appVersion: "1.0"
        // ここで引数を閉じ、直前の呼び出しを完成させます。
        )
        
        // Encode to JSON
        // Swiftの値をJSONへ変換する道具を作ります。
        let encoder = JSONEncoder()
        // encoder.dateEncodingStrategyに、右辺の計算結果または取得結果を設定します。
        encoder.dateEncodingStrategy = .iso8601
        // encoder.outputFormattingに、右辺の計算結果または取得結果を設定します。
        encoder.outputFormatting = .prettyPrinted
        // バックアップのJSONまたは書類のバイト列を用意します。
        let data = try encoder.encode(backupData)
        
        // Save to Temporary File
        // 一時ファイル用のフォルダを取得します。
        let tempDir = FileManager.default.temporaryDirectory
        // 作成時刻を使って重複しにくいバックアップ名を作ります。
        let filename = "wealthy_backup_\(Int(Date().timeIntervalSince1970)).json"
        // 一時保存するバックアップファイルの場所を作ります。
        let fileURL = tempDir.appendingPathComponent(filename)
        
        // 失敗した場合はエラーを呼び出し元へ伝えながら、この処理を実行します。
        try data.write(to: fileURL)
        // 計算または取得した値を呼び出し元へ返します。
        return fileURL
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // MARK: - Import
    // この処理と状態へのアクセスをメインアクター上に限定します。
    @MainActor
    // JSONファイルから保存済みの情報を復元する入口を定義します。
    func restoreBackup(from url: URL, context: ModelContext) throws {
        // Start secure access if needed (for user selected files)
        // 選択したファイルを読むためのアクセス権を開始します。
        let accessing = url.startAccessingSecurityScopedResource()
        // この関数を抜けるときに必ず実行する後片付けを登録します。
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        // バックアップのJSONまたは書類のバイト列を用意します。
        let data = try Data(contentsOf: url)
        // JSONからSwiftの値へ戻す道具を作ります。
        let decoder = JSONDecoder()
        // decoder.dateDecodingStrategyに、右辺の計算結果または取得結果を設定します。
        decoder.dateDecodingStrategy = .iso8601
        
        // 各データと作成日時を一つのバックアップにまとめます。
        let backupData = try decoder.decode(BackupData.self, from: data)
        
        // Clear existing data
        // 失敗した場合はエラーを呼び出し元へ伝えながら、この処理を実行します。
        try context.delete(model: Asset.self)
        // 失敗した場合はエラーを呼び出し元へ伝えながら、この処理を実行します。
        try context.delete(model: Expense.self)
        // 失敗した場合はエラーを呼び出し元へ伝えながら、この処理を実行します。
        try context.delete(model: RecurringItem.self)
        // 失敗した場合はエラーを呼び出し元へ伝えながら、この処理を実行します。
        try context.delete(model: Category.self)
        // 失敗した場合はエラーを呼び出し元へ伝えながら、この処理を実行します。
        try context.delete(model: ChatMessageModel.self)
        
        // Insert new data
        // 配列の各要素を順番に取り出して処理します。
        for dto in backupData.assets {
            // 復元データから保存対象の項目を作ります。
            let item = Asset(name: dto.name, balance: dto.balance, colorHex: dto.colorHex)
            // 復元したデータをSwiftDataの保存対象へ追加します。
            context.insert(item)
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 配列の各要素を順番に取り出して処理します。
        for dto in backupData.expenses {
            // 復元データから保存対象の項目を作ります。
            let item = Expense(title: dto.title, amount: dto.amount, date: dto.date, imageFilename: dto.imageFilename, assetName: dto.assetName, isIncome: dto.isIncome, categoryName: dto.categoryName)
            // 復元したデータをSwiftDataの保存対象へ追加します。
            context.insert(item)
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 配列の各要素を順番に取り出して処理します。
        for dto in backupData.recurringItems {
            // 復元データから保存対象の項目を作ります。
            let item = RecurringItem(title: dto.title, amount: dto.amount, dayOfMonth: dto.dayOfMonth, isIncome: dto.isIncome, assetName: dto.assetName)
            // item.lastProcessedDateに、右辺の計算結果または取得結果を設定します。
            item.lastProcessedDate = dto.lastProcessedDate
            // 復元したデータをSwiftDataの保存対象へ追加します。
            context.insert(item)
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 配列の各要素を順番に取り出して処理します。
        for dto in backupData.categories {
            // 復元データから保存対象の項目を作ります。
            let item = Category(name: dto.name, icon: dto.icon, colorHex: dto.colorHex)
            // 復元したデータをSwiftDataの保存対象へ追加します。
            context.insert(item)
        // ここまでの処理またはデータ定義を閉じます。
        }
        // 配列の各要素を順番に取り出して処理します。
        for dto in backupData.chatMessages {
            // 復元データから保存対象の項目を作ります。
            let item = ChatMessageModel(role: dto.role, content: dto.content)
            // item.timestampに、右辺の計算結果または取得結果を設定します。
            item.timestamp = dto.timestamp
            // 復元したデータをSwiftDataの保存対象へ追加します。
            context.insert(item)
        // ここまでの処理またはデータ定義を閉じます。
        }
        
        // Save context
        // 失敗した場合はエラーを呼び出し元へ伝えながら、この処理を実行します。
        try context.save()
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}

// UniformTypeIdentifiersの機能を、このファイルから使えるように読み込みます。
import UniformTypeIdentifiers

// ファイルの読み書きをSwiftUIへ渡す型を定義します。
struct BackupDocument: FileDocument {
    // この書類として読み込めるファイル形式をJSONに限定します。
    static var readableContentTypes: [UTType] { [.json] }
    
    // 認識した文字列または書類本文を作成または更新します。
    var text: String = ""
    
    // 渡された引数で新しい値を初期化する入口を定義します。
    init(text: String = "") {
        // textに、右辺で指定した値を設定します。
        self.text = text
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 渡された引数で新しい値を初期化する入口を定義します。
    init(configuration: ReadConfiguration) throws {
        // この条件が成り立つ場合だけ、続く処理を行います。
        if let data = configuration.file.regularFileContents,
           // stringとして後続の処理で使う値を作成または更新します。
           let string = String(data: data, encoding: .utf8) {
            // textに、右辺の計算結果または取得結果を設定します。
            text = string
        // ここまでの処理またはデータ定義を閉じます。
        }
    // ここまでの処理またはデータ定義を閉じます。
    }
    
    // 書類の文字列を保存用のファイル内容に変換する入口を定義します。
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // バックアップのJSONまたは書類のバイト列を用意します。
        let data = text.data(using: .utf8) ?? Data()
        // 文字データから作ったファイル内容を返します。
        return FileWrapper(regularFileWithContents: data)
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}
