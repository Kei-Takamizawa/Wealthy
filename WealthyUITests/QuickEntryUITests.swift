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
        app.buttons["quickAddToolbar"].tap(); interactions += 1
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
        tap("addEntry")
        XCTAssertTrue(app.textFields["quickAmount"].waitForExistence(timeout: 5), "The Home row also opens Quick add.")
        tap("quickSave")
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
            let quick = app.buttons["quickAddToolbar"]
            XCTAssertTrue(quick.waitForExistence(timeout: 5))
            XCTAssertTrue(quick.isHittable)
            XCTAssertTrue(app.frame.contains(quick.frame))
            print("HOME_QUICK_FRAME flags=\(flags) frame=\(NSCoder.string(for: quick.frame))")
            tap("quickAddToolbar")
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
    func auditScrollableHome(_ screen: String) throws {
        var pending: [String: (resolve: () -> XCUIElement?, label: String, identifier: String, issue: String, original: CGRect)] = [:]
        var verified: [String: CGRect] = [:]
        var evidence: [String] = []
        defer {
            let attachment = XCTAttachment(string: evidence.joined(separator: "\n"))
            attachment.name = "scrolled-audit-\(screen)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        func record(_ message: String) {
            evidence.append(message)
            print("SCROLLED_AUDIT \(message)")
        }
        func fullyVisible(_ element: XCUIElement) -> Bool {
            element.exists && !element.frame.isEmpty
                && element.frame.minY >= app.navigationBars.firstMatch.frame.maxY
                && element.frame.maxY <= app.tabBars.firstMatch.frame.minY
        }
        // Each position uses the full audit; only bar intersections may wait for a visible recheck.
        for position in 0..<8 {
            let settleStart = Date()
            func frames() -> [CGRect] {
                app.collectionViews["homePage"].cells.allElementsBoundByIndex.prefix(2).map(\.frame)
            }
            var previous = frames()
            var settled = false
            repeat {
                Thread.sleep(forTimeInterval: 0.5)
                let current = frames()
                settled = current == previous
                previous = current
            } while !settled && Date().timeIntervalSince(settleStart) < 10
            record("SETTLE screen=\(screen) position=\(position) seconds=\(Date().timeIntervalSince(settleStart)) settled=\(settled) frames=\(previous.count)")
            XCTAssertTrue(settled && !previous.isEmpty, "Home scrolling must stop before its audit")
            var visibleIssues: Set<String> = []
            try app.performAccessibilityAudit { issue in
                print("AUDIT_ISSUE screen=\(screen) type=\(issue.auditType) compact=\(issue.compactDescription) detailed=\(issue.detailedDescription) element=\(issue.element?.debugDescription ?? "<nil>")")
                if issue.auditType == .dynamicType,
                   issue.detailedDescription.contains("SwiftUI.AccessibilityNode"),
                   let element = issue.element, element.exists {
                    record("IGNORED_SWIFTUI_DYNAMIC_TYPE screen=\(screen) label=\(element.label) identifier=\(element.identifier) frame=\(NSCoder.string(for: element.frame))")
                    return true
                }
                let screenshot = self.app.screenshot()
                let name = "round6-\(screen)-position\(position)-\(issue.auditType)-\(issue.element?.label ?? "no-element")"
                let full = XCTAttachment(screenshot: screenshot)
                full.name = name + "-full"
                full.lifetime = .keepAlways
                self.add(full)
                if let element = issue.element, element.exists, let cgImage = screenshot.image.cgImage {
                    let scale = CGFloat(cgImage.width) / self.app.frame.width
                    let frame = element.frame.intersection(self.app.frame)
                    let pixels = CGRect(x: frame.minX * scale, y: frame.minY * scale,
                                        width: frame.width * scale, height: frame.height * scale)
                    if let crop = cgImage.cropping(to: pixels) {
                        let attachment = XCTAttachment(image: UIImage(cgImage: crop))
                        attachment.name = name + "-crop"
                        attachment.lifetime = .keepAlways
                        self.add(attachment)
                    }
                }
                record("ISSUE screen=\(screen) position=\(position) type=\(issue.auditType) label=\(issue.element?.label ?? "<nil>") frame=\(issue.element.map { NSCoder.string(for: $0.frame) } ?? "<nil>")")
                guard let element = issue.element, element.exists else { return false }
                let frame = element.frame
                let navigation = self.app.navigationBars.firstMatch.frame
                let tab = self.app.tabBars.firstMatch.frame
                guard !frame.isEmpty, frame.intersects(navigation) || frame.intersects(tab) else {
                    visibleIssues.insert("\(element.identifier)|\(element.label)")
                    record("FAIL screen=\(screen) position=\(position) label=\(element.label) identifier=\(element.identifier) type=\(issue.auditType) frame=\(NSCoder.string(for: frame)) navigation=\(NSCoder.string(for: navigation)) tab=\(NSCoder.string(for: tab))")
                    return false
                }
                let key = "\(element.elementType.rawValue)|\(element.identifier)|\(element.label)|\(frame.minX)|\(issue.auditType)"
                if let visibleFrame = verified[key] {
                    record("PREVIOUS_RECHECK screen=\(screen) position=\(position) label=\(element.label) identifier=\(element.identifier) type=\(issue.auditType) underBar=\(NSCoder.string(for: frame)) fullyVisible=\(NSCoder.string(for: visibleFrame))")
                    return true
                }
                if pending[key] == nil {
                    let label = element.label
                    let identifier = element.identifier
                    let elementType = element.elementType
                    // Audit elements bind to transient SwiftUI node IDs; resolve afresh after scrolling.
                    let resolve: () -> XCUIElement? = {
                        self.app.descendants(matching: elementType)
                            .matching(NSPredicate(format: "identifier == %@ AND label == %@", identifier, label))
                            .allElementsBoundByIndex.first { $0.exists && abs($0.frame.minX - frame.minX) < 1 }
                    }
                    pending[key] = (resolve, label, identifier, "\(issue.auditType)", frame)
                    record("DEFER screen=\(screen) position=\(position) label=\(element.label) identifier=\(element.identifier) type=\(issue.auditType) underBar=\(NSCoder.string(for: frame)) navigation=\(NSCoder.string(for: navigation)) tab=\(NSCoder.string(for: tab))")
                }
                return true
            }
            // A full audit just ran here. Any visible issue failed above instead of being deferred.
            for (key, item) in pending {
                guard let element = item.resolve(), fullyVisible(element) else { continue }
                let failed = visibleIssues.contains("\(item.identifier)|\(item.label)")
                record("RECHECK result=\(failed ? "FAIL" : "PASS") screen=\(screen) position=\(position) label=\(item.label) identifier=\(item.identifier) type=\(item.issue) underBar=\(NSCoder.string(for: item.original)) fullyVisible=\(NSCoder.string(for: element.frame)) navigation=\(NSCoder.string(for: app.navigationBars.firstMatch.frame)) tab=\(NSCoder.string(for: app.tabBars.firstMatch.frame))")
                XCTAssertTrue(fullyVisible(element))
                if !failed { verified[key] = element.frame }
                pending.removeValue(forKey: key)
            }
            if pending.isEmpty { return }
            if position < 7, let item = pending.sorted(by: { $0.key < $1.key }).first?.value {
                let top = app.navigationBars.firstMatch.frame.maxY
                let bottom = app.tabBars.firstMatch.frame.minY
                let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0))
                    .withOffset(CGVector(dx: 0, dy: (top + bottom) / 2))
                let currentFrame = item.resolve()?.frame ?? item.original
                let distance: CGFloat = currentFrame.minY < top ? 120 : -120
                start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: distance)),
                            withVelocity: .slow, thenHoldForDuration: 0.5)
            }
        }
        for item in pending.values {
            let current = item.resolve().map { NSCoder.string(for: $0.frame) } ?? "<not present>"
            record("UNRESOLVED screen=\(screen) label=\(item.label) identifier=\(item.identifier) type=\(item.issue) underBar=\(NSCoder.string(for: item.original)) current=\(current)")
            XCTFail("Deferred element not fully audited within 8 positions: \(item.label); identifier=\(item.identifier); original=\(item.original); current=\(current)")
        }
    }

    @MainActor
    func testHomeDarkAccessibilityAudit() throws {
        try audit("home", flags: ["--dark"])
    }

    @MainActor
    func testHomeActionLabelsAtDefaultAndAX3() throws {
        for flags in [[], ["--dark"], ["--ax3"], ["--dark", "--ax3"]] {
            launchQuickEntry(flags + ["--quick-safe-rule"])
            let noSpend = app.buttons["noSpend"]
            for _ in 0..<8 {
                if noSpend.exists, noSpend.frame.minY >= app.navigationBars.firstMatch.frame.maxY,
                   noSpend.frame.maxY <= app.tabBars.firstMatch.frame.minY { break }
                app.swipeUp()
            }
            XCTAssertTrue(noSpend.isHittable)
            XCTAssertGreaterThanOrEqual(noSpend.frame.height, 44)
            XCTAssertGreaterThanOrEqual(noSpend.frame.minY, app.navigationBars.firstMatch.frame.maxY)
            XCTAssertLessThanOrEqual(noSpend.frame.maxY, app.tabBars.firstMatch.frame.minY)
            let text = noSpend.staticTexts["I spent nothing today"]
            XCTAssertTrue(text.exists)
            XCTAssertTrue(noSpend.frame.contains(text.frame))
            print("HOME_ACTION_LAYOUT flags=\(flags) button=\(NSCoder.string(for: noSpend.frame)) text=\(NSCoder.string(for: text.frame))")
            capture("c2b2-home-actions-" + (flags.isEmpty ? "light" : flags.joined(separator: "-")))
            app.terminate()
        }
    }

    @MainActor
    func testSafeLineAndAIInformationEvidence() throws {
        for flags in [[], ["--dark"]] {
            launchQuickEntry(flags + ["--quick-safe-rule"])
            XCTAssertTrue(app.staticTexts["safeAmount"].label.contains("¥68,000"), app.debugDescription)
            let safeAmount = app.staticTexts["safeAmount"]
            let scheduled = app.buttons["safeScheduled"]
            for element in [safeAmount, scheduled] {
                XCTAssertTrue(element.isHittable)
                XCTAssertLessThan(element.frame.maxY, app.tabBars.firstMatch.frame.minY)
                print("SAFE_HOME_FRAME flags=\(flags) id=\(element.identifier) frame=\(NSCoder.string(for: element.frame))")
            }
            capture("c2b2-home-safe-" + (flags.first ?? "light"))
            try auditScrollableHome("home-safe-line-" + (flags.first ?? "light"))
            tap("safeScheduled")
            XCTAssertTrue(app.collectionViews["safeScheduledPage"].waitForExistence(timeout: 5))
            let title = app.staticTexts["Synthetic Thursday"]
            let amount = app.staticTexts["¥2,000"]
            for element in [title, amount] {
                XCTAssertTrue(element.exists)
                XCTAssertTrue(element.isHittable)
                XCTAssertTrue(app.frame.contains(element.frame))
                XCTAssertLessThan(element.frame.maxY, app.tabBars.firstMatch.frame.minY)
                print("SAFE_SCHEDULED_FRAME flags=\(flags) label=\(element.label) frame=\(NSCoder.string(for: element.frame))")
            }
            capture("c2b2-safe-scheduled-" + (flags.first ?? "light"))
            try auditWithSwiftUIException("safe-scheduled")
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
