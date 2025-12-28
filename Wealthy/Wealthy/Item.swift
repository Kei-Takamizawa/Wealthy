//
//  Item.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

import Foundation
import SwiftData

// 1. 資産（財布）データ
@Model
class Asset {
    var name: String
    var balance: Int
    var colorHex: String
    
    init(name: String, balance: Int, colorHex: String = "FFA500") {
        self.name = name
        self.balance = balance
        self.colorHex = colorHex
    }
}

// 2. 履歴データ
@Model
class Expense {
    var title: String
    var amount: Int
    var date: Date
    var imageFilename: String?
    var assetName: String?
    var isIncome: Bool
    var categoryName: String?
    
    init(title: String, amount: Int, date: Date, imageFilename: String? = nil, assetName: String? = "現金", isIncome: Bool = false, categoryName: String? = "未分類") {
        self.title = title
        self.amount = amount
        self.date = date
        self.imageFilename = imageFilename
        self.assetName = assetName
        self.isIncome = isIncome
        self.categoryName = categoryName
    }
}

// 3. 定期ルール（給料やサブスク）
@Model
class RecurringItem {
    var title: String
    var amount: Int
    var dayOfMonth: Int
    var isIncome: Bool
    var assetName: String
    var lastProcessedDate: Date?
    
    init(title: String, amount: Int, dayOfMonth: Int, isIncome: Bool, assetName: String) {
        self.title = title
        self.amount = amount
        self.dayOfMonth = dayOfMonth
        self.isIncome = isIncome
        self.assetName = assetName
    }
}

// 4. カテゴリデータ
@Model
class Category {
    var name: String
    var icon: String
    var colorHex: String
    
    init(name: String, icon: String, colorHex: String) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}
