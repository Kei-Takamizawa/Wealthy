//
//  Item.swift
//  Wealthy
//
//  Created by Harrison on 12/26/25.
//

// Foundationの機能を、このファイルから使えるように読み込みます。
import Foundation
// SwiftDataの機能を、このファイルから使えるように読み込みます。
import SwiftData

// 1. 資産（財布）データ
// このクラスをSwiftDataで保存できるデータとして登録します。
@Model
// 財布や資産を保存する型を定義します。
class Asset {
    // 表示名を保持するプロパティを定義します。
    var name: String
    // 資産残高を保持するプロパティを定義します。
    var balance: Int
    // 表示色の16進数文字列を保持するプロパティを定義します。
    var colorHex: String
    
    // 渡された引数で新しい値を初期化する入口を定義します。
    init(name: String, balance: Int, colorHex: String = "FFA500") {
        // nameに、右辺で指定した値を設定します。
        self.name = name
        // balanceに、右辺で指定した値を設定します。
        self.balance = balance
        // colorHexに、右辺で指定した値を設定します。
        self.colorHex = colorHex
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}

// 2. 履歴データ
// このクラスをSwiftDataで保存できるデータとして登録します。
@Model
// 収入と支出の履歴を保存する型を定義します。
class Expense {
    // 表示する項目名を保持するプロパティを定義します。
    var title: String
    // 金額を保持するプロパティを定義します。
    var amount: Int
    // 取引または処理の日付を保持するプロパティを定義します。
    var date: Date
    // レシート画像のファイル名を保持するプロパティを定義します。
    var imageFilename: String?
    // 関連する財布の名前を保持するプロパティを定義します。
    var assetName: String?
    // 収入かどうかを示す真偽値を保持するプロパティを定義します。
    var isIncome: Bool
    // カテゴリ名を保持するプロパティを定義します。
    var categoryName: String?
    
    // 渡された引数で新しい値を初期化する入口を定義します。
    init(title: String, amount: Int, date: Date, imageFilename: String? = nil, assetName: String? = "現金", isIncome: Bool = false, categoryName: String? = "未分類") {
        // titleに、右辺で指定した値を設定します。
        self.title = title
        // amountに、右辺で指定した値を設定します。
        self.amount = amount
        // dateに、右辺で指定した値を設定します。
        self.date = date
        // imageFilenameに、右辺で指定した値を設定します。
        self.imageFilename = imageFilename
        // assetNameに、右辺で指定した値を設定します。
        self.assetName = assetName
        // isIncomeに、右辺で指定した値を設定します。
        self.isIncome = isIncome
        // categoryNameに、右辺で指定した値を設定します。
        self.categoryName = categoryName
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}

// 3. 定期ルール（給料やサブスク）
// このクラスをSwiftDataで保存できるデータとして登録します。
@Model
// 毎月の収支ルールを保存する型を定義します。
class RecurringItem {
    // 表示する項目名を保持するプロパティを定義します。
    var title: String
    // 金額を保持するプロパティを定義します。
    var amount: Int
    // 定期収支を毎月処理する日を保持します。
    var dayOfMonth: Int
    // 収入かどうかを示す真偽値を保持するプロパティを定義します。
    var isIncome: Bool
    // 関連する財布の名前を保持するプロパティを定義します。
    var assetName: String
    // 最後に定期処理した日を保持するプロパティを定義します。
    var lastProcessedDate: Date?
    
    // 渡された引数で新しい値を初期化する入口を定義します。
    init(title: String, amount: Int, dayOfMonth: Int, isIncome: Bool, assetName: String) {
        // titleに、右辺で指定した値を設定します。
        self.title = title
        // amountに、右辺で指定した値を設定します。
        self.amount = amount
        // dayOfMonthに、右辺で指定した値を設定します。
        self.dayOfMonth = dayOfMonth
        // isIncomeに、右辺で指定した値を設定します。
        self.isIncome = isIncome
        // assetNameに、右辺で指定した値を設定します。
        self.assetName = assetName
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}

// 4. カテゴリデータ
// このクラスをSwiftDataで保存できるデータとして登録します。
@Model
// 支出カテゴリを保存する型を定義します。
class Category {
    // 表示名を保持するプロパティを定義します。
    var name: String
    // カテゴリのアイコンを保持するプロパティを定義します。
    var icon: String
    // 表示色の16進数文字列を保持するプロパティを定義します。
    var colorHex: String
    
    // 渡された引数で新しい値を初期化する入口を定義します。
    init(name: String, icon: String, colorHex: String) {
        // nameに、右辺で指定した値を設定します。
        self.name = name
        // iconに、右辺で指定した値を設定します。
        self.icon = icon
        // colorHexに、右辺で指定した値を設定します。
        self.colorHex = colorHex
    // ここまでの処理またはデータ定義を閉じます。
    }
// ここまでの処理またはデータ定義を閉じます。
}
