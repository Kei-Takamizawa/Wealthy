import Foundation
import Testing
@testable import WealthyCore

@Suite("Domain v2 targets tax and drafts")
@MainActor
struct DomainV2Tests {
    var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(secondsFromGMT: 0)!; return c }
    func day(_ y: Int = 2027, _ m: Int = 1, _ d: Int = 1) throws -> LedgerDay { try LedgerDay(year: y, month: m, day: d) }
    func target(_ month: LedgerMonth, amount: Int, envelope: UUID = EnvelopeValue.householdID, category: UUID? = nil) -> TargetValue {
        TargetValue(envelopeID: envelope, categoryID: category, currencyCode: "JPY", amountMinor: amount, effectiveMonth: month)
    }
    @Test("Daily remainder sums exactly for 28 29 30 and 31 days")
    func monthlyRemainders() throws {
        for (year, month, count) in [(2027,2,28),(2028,2,29),(2027,4,30),(2027,1,31)] {
            let first = try day(year, month), version = LedgerMonth(day: first)
            let state = LedgerState(targets: [target(version, amount: 1003)])
            let allowances = try (1...count).map { try LedgerQueries.dailyAllowance(in: state, day: day(year,month,$0), currencyCode: "JPY", calendar: calendar)! }
            #expect(allowances.reduce(0,+) == 1003)
            #expect(allowances[0] >= allowances[count-1])
        }
    }
    @Test("Week crosses versions and negative remaining remains visible")
    func crossingWeek() throws {
        let jan = try day(), feb = try day(2027,2)
        let entries = [EntryValue(kind: .expense, amount: 2000, currencyCode: "JPY", day: try day(2027,1,31))]
        let state = LedgerState(entries: entries, targets: [target(LedgerMonth(day: jan), amount: 3100),target(LedgerMonth(day: feb),amount:5600)])
        let period = try LedgerPeriod(start: day(2027,1,29), end: day(2027,2,4))
        let result = try LedgerQueries.targetStatus(in: state, period: period, currencyCode: "JPY", calendar: calendar)
        #expect(result.allowance == 1100 && result.remaining == -900)
        let sunday = try LedgerPeriod.week(containing: day(2027,1,5),weekStart:1,calendar:calendar)
        let monday = try LedgerPeriod.week(containing: day(2027,1,5),weekStart:2,calendar:calendar)
        #expect(try sunday.start == day(2027,1,3) && monday.start == day(2027,1,4))
        var configured = state; configured.settings.weekStart = 1
        #expect(try LedgerQueries.weekTargetStatus(in:configured,containing:day(2027,1,5),currencyCode:"JPY",calendar:calendar).period == sunday)
    }
    @Test("Missing targets and partially configured weeks never reward")
    func missingTargets() throws {
        let jan = try day(), feb = try day(2027,2)
        var state = LedgerState(noSpendMarks: [NoSpendMarkValue(day: jan)])
        let unset = try LedgerQueries.weekTargetStatus(in: state, containing: jan, currencyCode: "JPY", calendar: calendar)
        #expect(unset.allowance == nil && unset.remaining == nil && unset.loggedDays == 1 && !unset.isRewardEligible)
        state.targets = [target(LedgerMonth(day: feb), amount:2800)]
        let partial = try LedgerQueries.targetStatus(in: state, period: LedgerPeriod(start: day(2027,1,29),end:day(2027,2,4)),currencyCode:"JPY",calendar:calendar)
        #expect(partial.allowance == nil && !partial.isRewardEligible)
    }
    @Test("Four logged days fail reward five succeed marks do not hide spending")
    func weeklyReward() throws {
        let monday = try day(2027,1,4)
        var state = LedgerState(targets:[target(LedgerMonth(day:monday),amount:3100)],noSpendMarks:try (0..<4).map { NoSpendMarkValue(day:try monday.adding(days:$0,calendar:calendar)) })
        var status = try LedgerQueries.weekTargetStatus(in:state,containing:monday,currencyCode:"JPY",calendar:calendar)
        #expect(status.loggedDays == 4 && !status.isRewardEligible)
        state.noSpendMarks.append(NoSpendMarkValue(day:try monday.adding(days:4,calendar:calendar)))
        status = try LedgerQueries.weekTargetStatus(in:state,containing:monday,currencyCode:"JPY",calendar:calendar)
        #expect(status.loggedDays == 5 && status.noSpendDays == 5 && status.isRewardEligible)
        state.entries.append(EntryValue(kind:.expense,amount:701,currencyCode:"JPY",day:monday))
        status = try LedgerQueries.weekTargetStatus(in:state,containing:monday,currencyCode:"JPY",calendar:calendar)
        #expect(status.loggedDays == 5 && status.noSpendDays == 4 && status.remaining == -1 && !status.isRewardEligible)
    }
    @Test("Monthly reward requires ceiling eighty percent logged days")
    func monthlyReward() throws {
        let first = try day(2027,2)
        var state = LedgerState(targets:[target(LedgerMonth(day:first),amount:2800)],noSpendMarks:try(1...22).map {NoSpendMarkValue(day:try day(2027,2,$0))})
        #expect(try !LedgerQueries.monthTargetStatus(in:state,month:LedgerMonth(day:first),currencyCode:"JPY").isRewardEligible)
        state.noSpendMarks.append(NoSpendMarkValue(day:try day(2027,2,23)))
        #expect(try LedgerQueries.monthTargetStatus(in:state,month:LedgerMonth(day:first),currencyCode:"JPY").isRewardEligible)
    }
    @Test("Household and child targets totals and marks remain isolated")
    func envelopeIsolation() throws {
        let first = try day(), child = EnvelopeValue(kind:.child,name:"Child")
        let state = LedgerState(envelopes:[EnvelopeValue(id:EnvelopeValue.householdID,name:"Household"),child],entries:[EntryValue(kind:.expense,amount:900,currencyCode:"JPY",day:first,envelopeID:child.id),EntryValue(kind:.expense,amount:100,currencyCode:"JPY",day:first)],targets:[target(LedgerMonth(day:first),amount:1000),target(LedgerMonth(day:first),amount:2000,envelope:child.id)],noSpendMarks:[NoSpendMarkValue(envelopeID:child.id,day:try day(2027,1,2))])
        let household = try LedgerQueries.monthTargetStatus(in:state,month:LedgerMonth(day:first),currencyCode:"JPY")
        let kid = try LedgerQueries.monthTargetStatus(in:state,month:LedgerMonth(day:first),envelopeID:child.id,currencyCode:"JPY")
        #expect(household.spent == 100 && household.loggedDays == 1 && household.remaining == 900)
        #expect(kid.spent == 900 && kid.loggedDays == 2 && kid.remaining == 1100)
        #expect(try LedgerQueries.periodSummary(in:state,period:LedgerPeriod.month(containing:first),currencyCode:"JPY").expense == 100)
    }
    @Test("Tax floor rule effective data classifier and overflow safe arithmetic")
    func taxRules() throws {
        #expect(try TaxMath.taxPart(inclusiveMinor:1100,rate:.standard) == 100)
        #expect(try TaxMath.taxPart(inclusiveMinor:1080,rate:.reduced) == 80)
        #expect(try TaxMath.taxPart(inclusiveMinor:999,rate:.reduced) == 74)
        #expect(try TaxMath.taxPart(inclusiveMinor:Int.max,rate:.standard) > 0)
        let before = try day(2019,9,30), after = try day(2019,10,1)
        #expect(TaxRuleBook().rule(on:before) == nil && TaxRuleBook().rule(on:after)?.standardRate == 10)
        #expect(TaxClassifier.suggestedRate(taxHint:.food,serviceMode:.takeout,day:after) == .reduced)
        #expect(TaxClassifier.suggestedRate(taxHint:.food,serviceMode:.delivery,day:after) == .reduced)
        #expect(TaxClassifier.suggestedRate(taxHint:.food,serviceMode:.dineIn,day:after) == .standard)
        #expect(TaxClassifier.suggestedRate(taxHint:.nonfood,serviceMode:.takeout,day:after) == .standard)
        #expect(TaxClassifier.suggestedRate(taxHint:.exempt,serviceMode:nil,day:after) == .exempt)
        #expect(TaxClassifier.suggestedRate(taxHint:.food,serviceMode:.takeout,day:before) == nil)
    }
    @Test("Tax summary excludes unknown rates and savings excludes unknown mode")
    func summariesAndEstimate() throws {
        let first = try day(), category = CategoryValue(kind:.expense,taxHint:.food,customName:"Food")
        let known = EntryValue(kind:.expense,amount:1100,currencyCode:"JPY",day:first,taxRate:.standard,serviceMode:.dineIn,categoryID:category.id)
        var unknown = known; unknown.id = UUID(); unknown.serviceMode = nil
        var missing = known; missing.id = UUID(); missing.taxRate = nil
        let state = LedgerState(categories:[category],entries:[known,unknown,missing])
        let summary = try LedgerQueries.taxSummary(in:state,period:LedgerPeriod.month(containing:first))
        #expect(summary.totalTaxPaid == 200 && summary.unknownTaxEntryCount == 1)
        #expect(summary.perRate.first { $0.rate == .standard }?.taxableBase == 2000)
        let estimate = try LedgerQueries.takeoutSavingEstimate(in:state,month:LedgerMonth(day:first))
        #expect(estimate.entryCount == 1 && estimate.estimatedTaxSaving == 19)
    }
    @Test("Draft defaults and tax disagreement are deterministic without writes")
    func draftResolution() throws {
        let core = try LedgerCore(store:LedgerStore(inMemory:true,seed:false)), first = try day()
        let category = CategoryValue(kind:.expense,taxHint:.food,customName:"Food")
        try core.run(.createCategory(category),now:Date())
        let before = core.state, revision = core.revision, fixedNow = Date(timeIntervalSince1970: 1800000000)
        let draft = EntryDraft(amountMinor:1080,currency:"JPY",categoryID:category.id,serviceMode:.takeout,proposedTaxRate:.standard)
        guard case let .ready(value) = try DraftResolver.resolve(draft,core:core,today:first,now:fixedNow) else { Issue.record("Expected ready draft"); return }
        #expect(value.entry.timestamp == fixedNow && value.entry.createdAt == fixedNow && value.entry.updatedAt == fixedNow)
        #expect(value.entry.taxRate == .reduced && value.taxRateDisagreement && value.preview.summary?.taxPart == 80)
        #expect(core.state == before && core.revision == revision)
        #expect(try DraftResolver.resolve(EntryDraft(),core:core,today:first) == .needsInput([.amountMinor,.currency]))
    }
    @Test("Pre-seed drafts retain unknown tax and summaries report unknown count")
    func historicalUnknownTax() throws {
        let before = try day(2019,9,30), core = try LedgerCore(store:LedgerStore(inMemory:true,seed:false))
        let draft = EntryDraft(amountMinor:1100,currency:"JPY",day:before,proposedTaxRate:.standard)
        guard case let .ready(value) = try DraftResolver.resolve(draft,core:core,today:before) else { Issue.record("Expected historical draft"); return }
        #expect(value.entry.taxRate == nil && value.taxRateDisagreement)
        try core.run(.addEntry(value.entry),now:Date())
        let summary = try LedgerQueries.taxSummary(in:core.state,period:LedgerPeriod.month(containing:before))
        #expect(summary.totalTaxPaid == 0 && summary.unknownTaxEntryCount == 1 && summary.perRate.allSatisfy { $0.taxableBase == 0 })
    }
    @Test("Unset monthly status retains actual spending and mark semantics")
    func unsetMonthlySpending() throws {
        let first = try day(), state = LedgerState(entries:[EntryValue(kind:.expense,amount:123,currencyCode:"JPY",day:first)],noSpendMarks:[NoSpendMarkValue(day:first)])
        let result = try LedgerQueries.monthTargetStatus(in:state,month:LedgerMonth(day:first),currencyCode:"JPY")
        #expect(result.allowance == nil && result.remaining == nil && result.spent == 123 && result.loggedDays == 1 && result.noSpendDays == 0 && !result.isRewardEligible)
    }
    @Test("Injected effective-rate tables use entry date instead of newest rule")
    func effectiveRateData() throws {
        let first = try day(2020), second = try day(2021)
        let book = TaxRuleBook(rules:[TaxRule(effectiveFrom:first,standardRate:10,reducedRate:8),TaxRule(effectiveFrom:second,standardRate:12,reducedRate:9)])
        #expect(book.rule(on:try day(2019)) == nil && book.rule(on:first)?.standardRate == 10 && book.rule(on:second)?.standardRate == 12)
        let state = LedgerState(entries:[EntryValue(kind:.expense,amount:1120,currencyCode:"JPY",day:second,taxRate:.standard)])
        #expect(try LedgerQueries.taxSummary(in:state,period:LedgerPeriod.month(containing:second),ruleBook:book).totalTaxPaid == 120)
    }

    @Test("Category deletion cannot discard historical target versions")
    func categoryTargetHistory() throws {
        let core = try LedgerCore(store:LedgerStore(inMemory:true,seed:false),calendar:calendar)
        let category = CategoryValue(kind:.expense,customName:"Historical")
        var state = core.state; state.categories.append(category)
        state.targets.append(target(try LedgerMonth(year:2026,month:12),amount:500,category:category.id))
        try core.store.replace(state); try core.reload()
        let before = core.state, revision = core.revision
        #expect(throws:CoreError.invalidField("historicalCategoryTarget",category.id)) {
            try core.run(.deleteCategory(category.id),now:day().date(calendar:calendar))
        }
        #expect(core.state == before && core.revision == revision)
        try core.run(.archiveCategory(category.id,archived:true),now:day().date(calendar:calendar))
        #expect(core.state.targets == before.targets)
    }

}
