import Foundation
import Testing
@testable import WealthyCore

@Suite("Ledger invariants")
@MainActor
struct LedgerTests {
    let now = Date(timeIntervalSince1970: 1_791_158_400)
    var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(secondsFromGMT: 0)!
        return result
    }
    var day: LedgerDay { try! LedgerDay(year: 2026, month: 10, day: 5) }
    func wallet(_ name: String = "Cash", currency: String = "JPY", provisional: Bool = false) -> WalletValue {
        WalletValue(name: name, currencyCode: currency, createdAt: now, isProvisional: provisional)
    }
    func entry(_ wallet: WalletValue, kind: EntryKind = .expense, amount: Int = 100,
               category: UUID? = nil, target: UUID? = nil, direction: AdjustmentDirection? = nil) -> EntryValue {
        EntryValue(kind: kind, amount: amount, currencyCode: wallet.currencyCode, day: day,
                   walletID: wallet.id, direction: direction, timestamp: now, counterpartWalletID: target,
                   categoryID: category, title: "Test", createdAt: now, updatedAt: now)
    }
    func expectFailure(_ core: LedgerCore, _ command: LedgerCommand, _ expected: CoreError) throws {
        let before = try core.snapshot()
        #expect(throws: expected) { try core.run(command, now: now) }
        #expect(try core.snapshot() == before)
    }
    func makeCore() throws -> LedgerCore {
        try LedgerCore(store: try LedgerStore(inMemory: true, seed: false), calendar: calendar)
    }

    @Test("L1 every entry kind and signed opening balances")
    func derivedBalancesAndOpening() throws {
        let core = try makeCore()
        let a = wallet(), b = wallet("Bank"), negative = wallet("Debt"), zero = wallet("Zero")
        try core.run(.createWallet(a, openingBalance: 1_000), now: now)
        try core.run(.createWallet(b), now: now)
        try core.run(.createWallet(negative, openingBalance: -200), now: now)
        try core.run(.createWallet(zero), now: now)
        try core.run(.addEntry(entry(a, kind: .income, amount: 500)), now: now)
        try core.run(.addEntry(entry(a, amount: 100)), now: now)
        try core.run(.addEntry(entry(a, kind: .transfer, amount: 300, target: b.id)), now: now)
        try core.run(.reconcileWallet(a.id, actualBalance: 1_150, day: day), now: now)
        try core.run(.reconcileWallet(a.id, actualBalance: 1_125, day: day), now: now)
        let state = try core.snapshot()
        #expect(LedgerMath.balance(a.id, in: state) == 1_125)
        #expect(LedgerMath.balance(b.id, in: state) == 300)
        #expect(LedgerMath.balance(negative.id, in: state) == -200)
        #expect(!state.entries.contains { $0.walletID == zero.id })
        #expect(state.entries.filter { $0.source == .openingBalance }.allSatisfy { $0.day == day })
    }

    @Test("L2 same-wallet and cross-currency transfer failures are atomic")
    func transferValidation() throws {
        let core = try makeCore(), a = wallet(), usd = wallet("USD", currency: "USD")
        try core.run(.createWallet(a), now: now)
        try core.run(.createWallet(usd), now: now)
        try expectFailure(core, .addEntry(entry(a, kind: .transfer, target: a.id)), .sameWalletTransfer(a.id))
        try expectFailure(core, .addEntry(entry(a, kind: .transfer, target: usd.id)), .crossCurrencyTransfer(a.id, usd.id))
    }

    @Test("L3 reconciliation uses end-of-day history and clears provisional")
    func reconcile() throws {
        let core = try makeCore(), a = wallet(provisional: true)
        try core.run(.createWallet(a, openingBalance: 1_000), now: now)
        var future = entry(a, kind: .income, amount: 700)
        future.day = try day.adding(days: 1, calendar: calendar)
        try core.run(.addEntry(future), now: now)
        try core.run(.reconcileWallet(a.id, actualBalance: 800, day: day), now: now)
        var state = try core.snapshot()
        #expect(state.entries.filter { $0.source == .reconciliation }.count == 1)
        let adjustment = try #require(state.entries.first { $0.source == .reconciliation })
        #expect(adjustment.amount == 200 && adjustment.direction == .decrease && adjustment.day == day)
        #expect(state.wallets.first { $0.id == a.id }?.isProvisional == false)
        #expect(LedgerMath.balance(a.id, in: state, through: day) == 800)
        try core.run(.reconcileWallet(a.id, actualBalance: 800, day: day), now: now)
        state = try core.snapshot()
        #expect(state.entries.filter { $0.source == .reconciliation }.count == 1)
    }

    @Test("L4 currency mismatch, unsupported codes, immutable currency")
    func currencies() throws {
        let core = try makeCore(), a = wallet()
        try core.run(.createWallet(a), now: now)
        var mismatch = entry(a); mismatch.currencyCode = "USD"
        try expectFailure(core, .addEntry(mismatch), .currencyMismatch(a.id))
        let unsupported = wallet("Unknown", currency: "ZZZ")
        try expectFailure(core, .createWallet(unsupported), .unsupportedCurrency("ZZZ"))
        var changed = a; changed.currencyCode = "USD"
        try expectFailure(core, .updateWallet(changed), .invalidField("currencyCode", a.id))
        #expect(throws: CoreError.unsupportedCurrency("ZZZ")) { try CoreCurrency.normalizedCode("ZZZ") }
    }

    @Test("L5 nonpositive amounts and overflow rejected; aggregate exceeds Int.max")
    func amounts() throws {
        let core = try makeCore(), a = wallet()
        try core.run(.createWallet(a), now: now)
        for amount in [0, -1, Int.min] {
            let invalid = entry(a, amount: amount)
            try expectFailure(core, .addEntry(invalid), .invalidField("amount", invalid.id))
        }
        #expect(try CoreCurrency.parseMinorUnits("9223372036854775808", currencyCode: "JPY", locale: Locale(identifier: "en_US_POSIX")) == nil)
        let invalidOpening = wallet("Minimum")
        try expectFailure(core, .createWallet(invalidOpening, openingBalance: Int.min), .invalidField("openingBalance", invalidOpening.id))
        try core.run(.addEntry(entry(a, kind: .income, amount: Int.max)), now: now)
        try core.run(.addEntry(entry(a, kind: .income, amount: Int.max)), now: now)
        #expect(LedgerMath.balance(a.id, in: try core.snapshot()) == Decimal(Int.max) * 2)
        try expectFailure(core, .reconcileWallet(a.id, actualBalance: 0, day: day), .invalidField("reconciliationAmount", a.id))
    }

    @Test("L6 archived wallets retain history and reject assignments")
    func archiveWallet() throws {
        let core = try makeCore(), a = wallet(), b = wallet("Bank")
        try core.run(.createWallet(a, openingBalance: 500), now: now)
        try core.run(.createWallet(b), now: now)
        try core.run(.archiveWallet(a.id, archived: true), now: now)
        #expect(LedgerMath.balance(a.id, in: try core.snapshot()) == 500)
        try expectFailure(core, .addEntry(entry(a)), .archivedWallet(a.id))
        try expectFailure(core, .addEntry(entry(b, kind: .transfer, target: a.id)), .archivedWallet(a.id))
        try core.run(.archiveWallet(a.id, archived: false), now: now)
        try core.run(.addEntry(entry(a)), now: now)
        #expect(LedgerMath.balance(a.id, in: try core.snapshot()) == 400)
    }

    @Test("L7 entry amount wallet and kind updates derive both balances")
    func updateEntry() throws {
        let core = try makeCore(), a = wallet(), b = wallet("Bank")
        try core.run(.createWallet(a), now: now)
        try core.run(.createWallet(b), now: now)
        var value = entry(a)
        try core.run(.addEntry(value), now: now)
        value.amount = 200
        try core.run(.updateEntry(value), now: now)
        #expect(LedgerMath.balance(a.id, in: try core.snapshot()) == -200)
        value.walletID = b.id; value.kind = .income
        try core.run(.updateEntry(value), now: now)
        let state = try core.snapshot()
        #expect(LedgerMath.balance(a.id, in: state) == 0)
        #expect(LedgerMath.balance(b.id, in: state) == 200)
        #expect(state.entries.first?.id == value.id)
    }

    @Test("L8 wallet deletion guards history including transfer destination")
    func deleteWallet() throws {
        let core = try makeCore(), a = wallet(), b = wallet("Bank"), opening = wallet("Opening")
        try core.run(.createWallet(a), now: now)
        try core.run(.createWallet(b), now: now)
        try core.run(.createWallet(opening, openingBalance: 100), now: now)
        try core.run(.addEntry(entry(a, kind: .transfer, target: b.id)), now: now)
        try expectFailure(core, .deleteWallet(a.id), .walletHasHistory(a.id))
        try expectFailure(core, .deleteWallet(b.id), .walletHasHistory(b.id))
        try core.run(.deleteWallet(opening.id), now: now)
        let state = try core.snapshot()
        #expect(!state.wallets.contains { $0.id == opening.id })
        #expect(!state.entries.contains { $0.walletID == opening.id })
    }

    @Test("L9 category kinds and archived categories enforce assignment rules")
    func categoryValidation() throws {
        let core = try makeCore(), a = wallet(), b = wallet("Bank")
        let category = CategoryValue(kind: .expense, customName: "Food")
        try core.run(.createWallet(a), now: now)
        try core.run(.createWallet(b), now: now)
        try core.run(.createCategory(category), now: now)
        try expectFailure(core, .addEntry(entry(a, kind: .income, category: category.id)), .categoryKindMismatch(category.id))
        let transfer = entry(a, kind: .transfer, category: category.id, target: b.id)
        try expectFailure(core, .addEntry(transfer), .invalidField("categoryID", transfer.id))
        let adjustment = entry(a, kind: .adjustment, category: category.id, direction: .increase)
        try expectFailure(core, .addEntry(adjustment), .invalidField("kind", adjustment.id))
        var invalidHistory = core.state
        invalidHistory.entries.append(adjustment)
        #expect(throws: CoreError.invalidField("categoryID", adjustment.id)) { try CoreValidation.validate(invalidHistory) }
        try core.run(.addEntry(entry(a, category: category.id)), now: now)
        try core.run(.archiveCategory(category.id, archived: true), now: now)
        try expectFailure(core, .addEntry(entry(a, category: category.id)), .archivedCategory(category.id))
        #expect(try core.snapshot().entries.first?.categoryID == category.id)
    }

    @Test("L10 category deletion clears entries rules and category budgets")
    func deleteCategory() throws {
        let core = try makeCore(), a = wallet()
        let category = CategoryValue(kind: .expense, customName: "Food")
        var state = LedgerState(wallets: [a], categories: [category], entries: [entry(a, category: category.id)])
        state.rules = [RuleValue(amount: 100, currencyCode: "JPY", walletID: a.id, categoryID: category.id,
                                schedule: .monthly(day: 5), startDay: day, createdAt: now)]
        state.budgets = [BudgetValue(currencyCode: "JPY", monthlyAmount: 1_000),
                         BudgetValue(currencyCode: "JPY", categoryID: category.id, monthlyAmount: 500)]
        try core.store.replace(state)
        try core.reload()
        try core.run(.deleteCategory(category.id), now: now)
        let after = try core.snapshot()
        #expect(after.categories.isEmpty && after.entries.first?.categoryID == nil)
        #expect(after.rules.first?.categoryID == nil)
        #expect(after.budgets.count == 1 && after.budgets.first?.categoryID == nil)
        #expect(after.entries.first?.id == state.entries.first?.id)
        #expect(LedgerMath.balance(a.id, in: after) == -100)
    }

    @Test("L11 normalized names uniqueness, separate kinds and archived reuse")
    func normalizedNames() throws {
        let core = try makeCore(), a = wallet(" ＣＡＳＨ ")
        try core.run(.createWallet(a), now: now)
        let duplicate = wallet("cash", currency: "USD")
        try expectFailure(core, .createWallet(duplicate), .duplicateName("cash"))
        try core.run(.archiveWallet(a.id, archived: true), now: now)
        try core.run(.createWallet(duplicate), now: now)
        let food = CategoryValue(kind: .expense, customName: " ＦＯＯＤ ")
        let duplicateFood = CategoryValue(kind: .expense, customName: "food")
        try core.run(.createCategory(food), now: now)
        try expectFailure(core, .createCategory(duplicateFood), .duplicateName("food"))
        try core.run(.createCategory(CategoryValue(kind: .income, customName: "food")), now: now)
        try core.run(.archiveCategory(food.id, archived: true), now: now)
        try core.run(.createCategory(duplicateFood), now: now)
        #expect(CoreValidation.normalizedName(" ＦＯＯＤ \n") == "food")
    }

    @Test("L12 injected save failure rolls back complete state")
    func saveFailure() throws {
        let core = try makeCore(), a = wallet()
        core.store.failNextSave = true
        try expectFailure(core, .createWallet(a, openingBalance: 500), .saveFailed)
        try core.run(.createWallet(a), now: now)
        core.store.failNextSave = true
        try expectFailure(core, .addEntry(entry(a)), .saveFailed)
        #expect(try core.snapshot().wallets.count == 1)
        #expect(try core.snapshot().entries.isEmpty)
    }

    @Test("Duplicate IDs reject all partial mutations")
    func duplicateIDs() throws {
        let core = try makeCore(), a = wallet()
        try core.run(.createWallet(a), now: now)
        try expectFailure(core, .createWallet(a), .duplicateID(a.id))
        try expectFailure(core, .createCategory(CategoryValue(id: a.id, kind: .expense, customName: "Food")), .duplicateID(a.id))
    }
}
