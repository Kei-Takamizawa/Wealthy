//
//  BackupManager.swift
//  Wealthy
//
//  Created by Harrison on 12/28/25.
//

import Foundation
import SwiftData
import SwiftUI

struct BackupManager {
    static let shared = BackupManager()
    
    // MARK: - DTOs for JSON Serialization
    struct BackupData: Codable {
        let assets: [AssetDTO]
        let expenses: [ExpenseDTO]
        let recurringItems: [RecurringItemDTO]
        let categories: [CategoryDTO]
        let chatMessages: [ChatMessageDTO]
        let timestamp: Date
        let appVersion: String
    }
    
    struct AssetDTO: Codable {
        let name: String
        let balance: Int
        let colorHex: String
    }
    
    struct ExpenseDTO: Codable {
        let title: String
        let amount: Int
        let date: Date
        let imageFilename: String?
        let assetName: String?
        let isIncome: Bool
        let categoryName: String?
    }
    
    struct RecurringItemDTO: Codable {
        let title: String
        let amount: Int
        let dayOfMonth: Int
        let isIncome: Bool
        let assetName: String
        let lastProcessedDate: Date?
    }
    
    struct CategoryDTO: Codable {
        let name: String
        let icon: String
        let colorHex: String
    }
    
    struct ChatMessageDTO: Codable {
        let role: String
        let content: String
        let timestamp: Date
    }
    
    // MARK: - Export
    @MainActor
    func createBackupURL(context: ModelContext) throws -> URL {
        // Fetch all data
        let assetsDescriptor = FetchDescriptor<Asset>()
        let expensesDescriptor = FetchDescriptor<Expense>()
        let recurringDescriptor = FetchDescriptor<RecurringItem>()
        let categoriesDescriptor = FetchDescriptor<Category>()
        let chatDescriptor = FetchDescriptor<ChatMessageModel>()
        
        let assets = try context.fetch(assetsDescriptor)
        let expenses = try context.fetch(expensesDescriptor)
        let recurringItems = try context.fetch(recurringDescriptor)
        let categories = try context.fetch(categoriesDescriptor)
        let chatMessages = try context.fetch(chatDescriptor)
        
        // Convert to DTOs
        let assetDTOs = assets.map { AssetDTO(name: $0.name, balance: $0.balance, colorHex: $0.colorHex) }
        let expenseDTOs = expenses.map { ExpenseDTO(title: $0.title, amount: $0.amount, date: $0.date, imageFilename: $0.imageFilename, assetName: $0.assetName, isIncome: $0.isIncome, categoryName: $0.categoryName) }
        let recurringDTOs = recurringItems.map { RecurringItemDTO(title: $0.title, amount: $0.amount, dayOfMonth: $0.dayOfMonth, isIncome: $0.isIncome, assetName: $0.assetName, lastProcessedDate: $0.lastProcessedDate) }
        let categoryDTOs = categories.map { CategoryDTO(name: $0.name, icon: $0.icon, colorHex: $0.colorHex) }
        let chatDTOs = chatMessages.map { ChatMessageDTO(role: $0.roleRaw, content: $0.content, timestamp: $0.timestamp) }
        
        let backupData = BackupData(
            assets: assetDTOs,
            expenses: expenseDTOs,
            recurringItems: recurringDTOs,
            categories: categoryDTOs,
            chatMessages: chatDTOs,
            timestamp: Date(),
            appVersion: "1.0"
        )
        
        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(backupData)
        
        // Save to Temporary File
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "wealthy_backup_\(Int(Date().timeIntervalSince1970)).json"
        let fileURL = tempDir.appendingPathComponent(filename)
        
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Import
    @MainActor
    func restoreBackup(from url: URL, context: ModelContext) throws {
        // Start secure access if needed (for user selected files)
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backupData = try decoder.decode(BackupData.self, from: data)
        
        // Clear existing data
        try context.delete(model: Asset.self)
        try context.delete(model: Expense.self)
        try context.delete(model: RecurringItem.self)
        try context.delete(model: Category.self)
        try context.delete(model: ChatMessageModel.self)
        
        // Insert new data
        for dto in backupData.assets {
            let item = Asset(name: dto.name, balance: dto.balance, colorHex: dto.colorHex)
            context.insert(item)
        }
        for dto in backupData.expenses {
            let item = Expense(title: dto.title, amount: dto.amount, date: dto.date, imageFilename: dto.imageFilename, assetName: dto.assetName, isIncome: dto.isIncome, categoryName: dto.categoryName)
            context.insert(item)
        }
        for dto in backupData.recurringItems {
            let item = RecurringItem(title: dto.title, amount: dto.amount, dayOfMonth: dto.dayOfMonth, isIncome: dto.isIncome, assetName: dto.assetName)
            item.lastProcessedDate = dto.lastProcessedDate
            context.insert(item)
        }
        for dto in backupData.categories {
            let item = Category(name: dto.name, icon: dto.icon, colorHex: dto.colorHex)
            context.insert(item)
        }
        for dto in backupData.chatMessages {
            let item = ChatMessageModel(role: dto.role, content: dto.content)
            item.timestamp = dto.timestamp
            context.insert(item)
        }
        
        // Save context
        try context.save()
    }
}

import UniformTypeIdentifiers

struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var text: String = ""
    
    init(text: String = "") {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            text = string
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
