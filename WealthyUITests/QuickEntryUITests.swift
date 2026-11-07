@preconcurrency import XCTest

extension Cycle2aUITests {
    @MainActor
    func launchQuickEntry(_ flags: [String] = [], seeded: Bool = true, language: String = "en") {
        app.launchEnvironment["WEALTHY_TEST_AI_AVAILABLE"] = "0"
        app.launchArguments = ["--cycle2a-test", "--reset-test-preferences", "-v4.language", language, "-v4.currency", "JPY"]
            + (seeded ? ["--cycle2b2-seed"] : ["-v4.onboarded", "NO"]) + flags
        launchApp()
        let ready = seeded ? app.tabBars.firstMatch : app.buttons["onboardingNext"]
        XCTAssertTrue(ready.waitForExistence(timeout: 30), app.debugDescription)
    }

    @MainActor
    func testLocalizedQuickEntryAndSafeLine() throws {
        for (language, title, safe) in [("ja", "クイック記録", "今週あと安心して使える額"), ("es", "Registro rápido", "Puedes gastar con tranquilidad"), ("ko", "빠른 기록", "이번 주 안심하고 쓸 수 있는 금액")] {
            launchQuickEntry(["--quick-safe-rule"], language: language)
            XCTAssertTrue(app.staticTexts[safe].exists)
            tap("addEntry")
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
            app.textFields["quickAmount"].typeText("650")
            XCTAssertTrue(app.buttons["quickSave"].isHittable)
            capture("c2b2-quick-" + language)
            app.buttons["quickSave"].tap()
            XCTAssertTrue(app.textFields["quickAmount"].waitForNonExistence(timeout: 5))
            app.terminate()
        }
    }

    @MainActor
    func testQuickEntryWithoutAIFromOnboarding() throws {
        launchQuickEntry(seeded: false)
        app.buttons["onboardingNext"].tap(); app.buttons["onboardingNext"].tap()
        enter("onboardingAmount", "31000"); tap("onboardingNext"); tap("onboardingNext")
        XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 10))
        tap("addEntry")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        app.textFields["quickAmount"].typeText("650")
        app.buttons["quickSave"].tap()
        XCTAssertTrue(app.textFields["quickAmount"].waitForNonExistence(timeout: 5))
        app.tabBars.buttons["Info"].tap(); tap("Settings"); tap("aiInfoLink")
        XCTAssertTrue(app.staticTexts["Not available on this iPhone"].exists)
        XCTAssertTrue(app.staticTexts["All budgeting features work without on-device AI. Future voice features may use it."].exists)
    }

    @MainActor
    func testQuickEntryThreeInteractionsAndUncategorized() throws {
        launchQuickEntry()
        var interactions = 0
        app.buttons["addEntry"].tap(); interactions += 1
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        app.textFields["quickAmount"].typeText("650"); interactions += 1
        app.buttons["quickSave"].tap(); interactions += 1
        XCTAssertLessThanOrEqual(interactions, 3)
        print("QUICK_ENTRY_INTERACTIONS=\(interactions)")
        XCTAssertTrue(app.textFields["quickAmount"].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "¥69,350")).firstMatch.exists)
        app.tabBars.buttons["Info"].tap(); tap("calendarLink"); tap("calendar-2026-10-07")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Uncategorized")).firstMatch.exists, app.debugDescription)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "¥650")).firstMatch.exists)
        app.navigationBars.buttons.firstMatch.tap(); app.navigationBars.buttons.firstMatch.tap(); tap("analysisLink")
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "analysis-none").firstMatch.label.contains("Uncategorized"))
    }

    @MainActor
    func testQuickEntryCategoryDetailsAndInvalidAmount() throws {
        launchQuickEntry()
        tap("addEntry"); tap("quickSave")
        XCTAssertTrue(app.staticTexts["quickError"].exists)
        XCTAssertTrue(app.textFields["quickAmount"].exists)
        app.textFields["quickAmount"].typeText("650")
        tap("quickCategory-catFood")
        XCTAssertTrue(app.textFields["quickAmount"].waitForNonExistence(timeout: 5))
        app.tabBars.buttons["Info"].tap()
        let food = app.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Food", "¥650")).firstMatch
        for _ in 0..<10 { if food.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(food.exists)
        app.tabBars.buttons["Island"].tap()
        tap("addEntry"); app.textFields["quickAmount"].typeText("1234"); tap("quickDetails")
        XCTAssertTrue(app.textFields["entryAmount"].waitForExistence(timeout: 5))
        XCTAssertTrue((app.textFields["entryAmount"].value as? String ?? "").contains("1,234"))
    }

    @MainActor
    func testIntentWithoutTargetAndInvalidAmount() throws {
        launchQuickEntry(["--quick-no-target", "--run-intent-record-expense", "650"])
        let dialog = app.staticTexts["intentDialog"]
        XCTAssertTrue(dialog.waitForExistence(timeout: 10))
        XCTAssertTrue(dialog.label.contains("650")); XCTAssertFalse(dialog.label.contains("Left this week"))
        app.terminate()
        launchQuickEntry(["--run-intent-record-expense", "0"])
        XCTAssertTrue(dialog.waitForExistence(timeout: 10))
        XCTAssertFalse(dialog.label.contains("Recorded"))
        XCTAssertTrue(app.staticTexts["¥0"].firstMatch.exists)
    }

    @MainActor
    func testIntentIncludesTodaysRecurringExpense() throws {
        launchQuickEntry(["--quick-due-rule", "--run-intent-record-expense", "650"])
        if app.buttons["dismissCatchUp"].waitForExistence(timeout: 5) { tap("dismissCatchUp") }
        let dialog = app.staticTexts["intentDialog"]
        XCTAssertTrue(dialog.waitForExistence(timeout: 10))
        XCTAssertTrue(dialog.label.contains("¥68,350"), dialog.label)
    }

    @MainActor
    func testOpenQuickAddIntentAndPendingNotice() throws {
        launchQuickEntry(["--run-intent-open-quick-add"], seeded: false)
        XCTAssertFalse(app.textFields["quickAmount"].exists)
        app.terminate()
        launchQuickEntry(["--run-intent-open-quick-add", "--quick-due-rule"])
        XCTAssertTrue(app.textFields["quickAmount"].waitForExistence(timeout: 10))
        app.textFields["quickAmount"].typeText("650")
        app.buttons["quickSave"].tap()
        XCTAssertTrue(app.buttons["dismissCatchUp"].waitForExistence(timeout: 5))
        tap("dismissCatchUp")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "¥68,350")).firstMatch.exists)
    }

    @MainActor
    func testQuickCategoryRankingAndPresets() throws {
        launchQuickEntry(["--quick-ranking"])
        tap("addEntry")
        let buttons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "quickCategory-"))
        XCTAssertEqual(buttons.allElementsBoundByIndex.map(\.identifier), ["quickCategory-catHobby", "quickCategory-catTransport", "quickCategory-catDaily", "quickCategory-catFood"])
        app.terminate()
        launchQuickEntry(); tap("addEntry")
        XCTAssertEqual(buttons.allElementsBoundByIndex.map(\.identifier), ["quickCategory-catFood", "quickCategory-catDaily", "quickCategory-catOthers"])
    }

    @MainActor
    func testAvailableAIInformation() throws {
        app.launchEnvironment["WEALTHY_TEST_AI_AVAILABLE"] = "1"
        app.launchArguments = ["--cycle2a-test", "--cycle2b2-seed", "-v4.language", "en", "--screen", "settings"]
        launchApp()
        XCTAssertTrue(app.buttons["aiInfoLink"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.buttons["aiInfoLink"].label.contains("Available"))
    }

    @MainActor
    func testQuickEntryKeyboardLayoutAndEvidence() throws {
        for flags in [[], ["--dark"], ["--ax3"]] {
            launchQuickEntry(flags)
            let quick = app.buttons["addEntry"]
            XCTAssertTrue(quick.waitForExistence(timeout: 5))
            XCTAssertTrue(quick.isHittable)
            XCTAssertTrue(app.frame.contains(quick.frame))
            print("HOME_QUICK_FRAME flags=\(flags) frame=\(NSCoder.string(for: quick.frame))")
            tap("addEntry")
            XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
            let amount = app.textFields["quickAmount"]
            amount.typeText("650")
            let save = app.buttons["quickSave"]
            let label = app.staticTexts["quickAmountLabel"]
            let keyboardReady = NSPredicate { _, _ in
                guard let value = label.value as? String, let top = Double(value) else { return false }
                return top > 0 && top < self.app.frame.maxY
            }
            XCTAssertTrue(keyboardReady.evaluate(with: label) || XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: keyboardReady, object: label)], timeout: 5) == .completed)
            let keyboardTop = try XCTUnwrap(Double(label.value as? String ?? ""))
            print("KEYBOARD_TOP UIKit=\(keyboardTop) XCTest=\(NSCoder.string(for: app.keyboards.firstMatch.frame))")
            for element in [amount, save] {
                XCTAssertTrue(element.isHittable)
                XCTAssertTrue(app.frame.contains(element.frame))
                XCTAssertLessThanOrEqual(element.frame.maxY, keyboardTop)
                print("QUICK_LAYOUT flags=\(flags) id=\(element.identifier) frame=\(NSCoder.string(for: element.frame)) keyboardTop=\(keyboardTop)")
            }
            XCTAssertTrue((amount.value as? String ?? "").contains("650"))
            capture("c2b2-quick-" + (flags.first ?? "light"))
            try auditWithSwiftUIException("quick-add")
            app.terminate()
        }
    }

    @MainActor
    func testRecordExpenseIntentAndRelaunch() throws {
        for category in ["catFood", ""] {
            let disk = UUID().uuidString
            let flags = ["--disk-test", disk, "--run-intent-record-expense", "650"] + (category.isEmpty ? [] : [category])
            launchQuickEntry(flags)
            let dialog = app.staticTexts["intentDialog"]
            XCTAssertTrue(dialog.waitForExistence(timeout: 15))
            XCTAssertTrue(dialog.label.contains("650")); XCTAssertTrue(dialog.label.contains("69,350"))
            XCTAssertTrue(dialog.label.contains(category.isEmpty ? "Uncategorized" : "Food"))
            XCUIDevice.shared.press(.home)
            app.activate()
            XCTAssertTrue(dialog.waitForExistence(timeout: 10))
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "¥69,350")).firstMatch.exists)
            app.terminate()
            launchApp()
            XCTAssertTrue(dialog.waitForExistence(timeout: 15))
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "¥69,350")).firstMatch.exists)
            app.tabBars.buttons["Info"].tap()
            let rows = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "¥650"))
            for _ in 0..<10 { if rows.firstMatch.exists && rows.firstMatch.isHittable { break }; app.swipeUp() }
            XCTAssertEqual(rows.count, 1, app.debugDescription)
            XCTAssertTrue(rows.firstMatch.label.contains(category.isEmpty ? "Uncategorized" : "Food"))
            app.terminate()
        }
    }

    @MainActor
    func testSafeLineAndAIInformationEvidence() throws {
        for flags in [[], ["--dark"]] {
            launchQuickEntry(flags + ["--quick-safe-rule"])
            XCTAssertTrue(app.staticTexts["safeAmount"].label.contains("¥68,000"), app.debugDescription)
            tap("safeScheduled")
            XCTAssertTrue(app.staticTexts["Synthetic Thursday"].exists)
            capture("c2b2-safe-expanded-" + (flags.first ?? "light"))
            XCTAssertTrue(app.staticTexts["safeAmount"].isHittable)
            XCTAssertTrue(app.staticTexts["Synthetic Thursday"].isHittable)
            XCTAssertLessThan(app.staticTexts["safeAmount"].frame.maxY, app.buttons["addEntry"].frame.minY)
            print("SAFE_AUDIT_FRAME " + NSCoder.string(for: app.staticTexts["safeAmount"].frame))
            capture("c2b2-safe-audit-" + (flags.first ?? "light"))
            try auditWithSwiftUIException("home-safe-line")
            app.terminate()
        }
        launchQuickEntry()
        XCTAssertFalse(app.staticTexts["safeAmount"].exists)
        app.tabBars.buttons["Info"].tap(); tap("Settings")
        XCTAssertTrue(app.buttons["aiInfoLink"].label.contains("Not available on this iPhone"))
        capture("c2b2-ai-row")
        tap("aiInfoLink"); capture("c2b2-ai-detail")
        try auditWithSwiftUIException("ai-information")
    }
}
