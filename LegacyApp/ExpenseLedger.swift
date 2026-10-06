import Foundation
import SwiftData

/// A receipt draft does not touch balances. Saving applies one change to the chosen wallet.
@MainActor
enum ExpenseLedger {
    /// Keep an editable copy outside SwiftData so autosave cannot persist an unfinished edit.
    static func draft(for expense: Expense) -> Expense {
        Expense(title: expense.title, amount: expense.amount, date: expense.date,
                imageFilename: expense.imageFilename, assetName: expense.assetName,
                isIncome: expense.isIncome, categoryName: expense.categoryName,
                paymentMethod: expense.paymentMethod, balanceApplied: expense.balanceApplied,
                paymentNeedsReview: expense.paymentNeedsReview, currencyCode: expense.currencyCode)
    }
    static func saveDraft(_ draft: Expense, replacing original: Expense?, context: ModelContext) throws {
        guard let original else {
            try save(draft, previous: nil, context: context)
            return
        }
        let previous = Snapshot(original)
        let previousImage = original.imageFilename
        Snapshot(draft).restore(original)
        original.imageFilename = draft.imageFilename
        do { try save(original, previous: previous, context: context) }
        catch {
            previous.restore(original)
            original.imageFilename = previousImage
            throw error
        }
    }
    struct Snapshot {
        let currencyCode: String?
        var effectiveCurrencyCode: String { CurrencyPolicy.normalizedCode(currencyCode) }
        let title: String
        let date: Date
        let categoryName: String?
        let paymentMethod: String?
        let paymentNeedsReview: Bool
        let amount: Int
        let assetName: String?
        let isIncome: Bool
        let balanceApplied: Bool
        init(_ expense: Expense) {
            currencyCode = expense.currencyCode
            title = expense.title; date = expense.date; categoryName = expense.categoryName
            paymentMethod = expense.paymentMethod; paymentNeedsReview = expense.paymentNeedsReview
            amount = expense.amount; assetName = expense.assetName
            isIncome = expense.isIncome; balanceApplied = expense.balanceApplied
        }
        func restore(_ expense: Expense) {
            expense.currencyCode = currencyCode
            expense.title = title; expense.date = date; expense.categoryName = categoryName
            expense.amount = amount; expense.assetName = assetName; expense.isIncome = isIncome
            expense.balanceApplied = balanceApplied; expense.paymentMethod = paymentMethod; expense.paymentNeedsReview = paymentNeedsReview
        }
    }
    static func failure(_ key: String) -> NSError {
        NSError(domain: "ExpenseLedger", code: 1, userInfo: [NSLocalizedDescriptionKey: AppLocalization.text(key, language: .saved)])
    }
    static func save(_ expense: Expense, previous: Snapshot?, context: ModelContext) throws {
        guard expense.amount > 0 else { throw failure("ledger.invalidAmount") }
        if previous == nil && expense.balanceApplied { return }
        let assets = try context.fetch(FetchDescriptor<Asset>())
        let currency = expense.effectiveCurrencyCode
        let sameCurrencyAssets = assets.filter { $0.effectiveCurrencyCode == currency }
        let method = expense.paymentMethod ?? "cash"
        let matches = sameCurrencyAssets.filter { ($0.paymentMethod ?? ReceiptPaymentPolicy.method(forAssetName: $0.name) ?? "custom:" + AppLocalization.normalized($0.name)) == method }
        let namedWallets = expense.assetName.map { name in assets.filter { $0.name == name } } ?? []
        guard namedWallets.count <= 1 else { throw failure("ledger.chooseWallet") }
        var wallet = namedWallets.first
        if let wallet, wallet.effectiveCurrencyCode != currency { throw failure("currency.currencyMismatch") }
        if wallet == nil {
            guard matches.count <= 1 else { throw failure("ledger.chooseWallet") }
            wallet = matches.first
        }
        let created = wallet == nil
        var newName = expense.assetName ?? ReceiptPaymentPolicy.displayName(method, language: .saved)
        if created {
            if currency != CurrencyPolicy.defaultCode { newName += " · " + currency }
            let baseName = newName
            var suffix = 2
            while assets.contains(where: { AppLocalization.normalized($0.name) == AppLocalization.normalized(newName) }) {
                newName = "\(baseName) (\(suffix))"
                suffix += 1
            }
        }
        let target = wallet ?? Asset(name: newName, balance: 0, paymentMethod: method, isAutoCreated: true, currencyCode: currency)
        let oldMatches = previous?.assetName.map { name in assets.filter { $0.name == name } } ?? []
        guard oldMatches.count <= 1 else { throw failure("ledger.chooseWallet") }
        let oldWallet = oldMatches.first
        if let previous, previous.balanceApplied, let oldWallet,
           oldWallet.effectiveCurrencyCode != previous.effectiveCurrencyCode { throw failure("currency.currencyMismatch") }
        var balances: [Asset: Int] = [target: target.balance]
        if let oldWallet { balances[oldWallet] = oldWallet.balance }
        func changed(_ value: Int, by delta: Int) throws -> Int {
            let result = value.addingReportingOverflow(delta)
            guard !result.overflow else { throw failure("ledger.invalidAmount") }
            return result.partialValue
        }
        if let previous, previous.balanceApplied, let oldWallet {
            guard previous.amount >= 0 else { throw failure("ledger.invalidAmount") }
            balances[oldWallet] = try changed(balances[oldWallet]!, by: previous.isIncome ? -previous.amount : previous.amount)
        }
        balances[target] = try changed(balances[target]!, by: expense.isIncome ? expense.amount : -expense.amount)
        let originalBalances = Dictionary(uniqueKeysWithValues: balances.keys.map { ($0, $0.balance) })
        let originalName = expense.assetName
        let originallyApplied = expense.balanceApplied
        let wasUninserted = expense.modelContext == nil
        if created { context.insert(target) }
        if wasUninserted { context.insert(expense) }
        balances.forEach { $0.key.balance = $0.value }
        expense.assetName = target.name
        expense.balanceApplied = true
        do { try context.save() }
        catch {
            originalBalances.forEach { $0.key.balance = $0.value }
            expense.assetName = originalName; expense.balanceApplied = originallyApplied
            if created { context.delete(target) }
            if wasUninserted { context.delete(expense) }
            throw error
        }
    }
    static func delete(_ expense: Expense, previous: Snapshot? = nil, context: ModelContext) throws {
        let state = previous ?? Snapshot(expense)
        let matches = try context.fetch(FetchDescriptor<Asset>()).filter { $0.name == state.assetName }
        guard matches.count <= 1 else { throw failure("ledger.chooseWallet") }
        let asset = matches.first
        if state.balanceApplied, let asset, asset.effectiveCurrencyCode != state.effectiveCurrencyCode { throw failure("currency.currencyMismatch") }
        let oldBalance = asset?.balance
        if state.balanceApplied, let asset {
            guard state.amount >= 0 else { throw failure("ledger.invalidAmount") }
            let result = asset.balance.addingReportingOverflow(state.isIncome ? -state.amount : state.amount)
            guard !result.overflow else { throw failure("ledger.invalidAmount") }
            asset.balance = result.partialValue
        }
        context.delete(expense)
        do { try context.save() }
        catch {
            context.rollback()
            if let asset, let oldBalance { asset.balance = oldBalance }
            throw error
        }
    }
}
