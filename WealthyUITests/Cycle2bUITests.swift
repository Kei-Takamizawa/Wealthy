@preconcurrency import XCTest

extension Cycle2aUITests {
    @MainActor
    func testC2bDynamicTypeGrowth() throws {
        let screens: [(String, [(String, Bool)])] = [
            ("rule-form", [("Category", false), ("Day of month", false)]),
            ("home", [("Not a balance", false), ("Spent", false), ("¥2,900", false),
                      ("This week", false), ("M", false), ("Quick add", false), ("I spent nothing today", false)])
        ]
        for (screen, targets) in screens {
            var baseline: [String: CGFloat] = [:]
            for ax3 in [false, true] {
                if screen == "home" {
                    app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", "en", "-v4.currency", "JPY", "--screen", "home"] + (ax3 ? ["--ax3"] : [])
                    launchApp()
                    XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "ledgerLoading").firstMatch.waitForNonExistence(timeout: 30))
                } else { launchC2b(screen, flags: ax3 ? ["--ax3"] : []) }
                for (name, button) in targets {
                    let element = button ? app.buttons[name].firstMatch : app.staticTexts[name].firstMatch
                    for _ in 0..<10 {
                        if element.exists && app.frame.contains(element.frame) && element.isHittable { break }
                        app.swipeUp()
                    }
                    XCTAssertTrue(element.exists, "\(screen): missing \(name), AX3=\(ax3)")
                    guard element.exists else { continue }
                    let frame = element.frame
                    print("DYNAMIC_TYPE_FRAME screen=\(screen) element=\(name) ax3=\(ax3) frame=\(NSCoder.string(for: frame)) window=\(NSCoder.string(for: app.frame))")
                    XCTAssertTrue(app.frame.contains(frame), "\(screen): \(name) outside window, AX3=\(ax3), frame=\(frame), window=\(app.frame)")
                    if ax3 {
                        if let height = baseline[name] {
                            XCTAssertGreaterThan(frame.height, height, "\(screen): \(name) did not grow at AX3")
                        } else { XCTFail("\(screen): no default measurement for \(name)") }
                    } else { baseline[name] = frame.height }
                }
                app.terminate()
            }
        }
    }

    @MainActor
    func testC2bInfoEntryPointsAndPushedSwipe() throws {
        launchSeededWorkflow()
        app.tabBars.buttons["Info"].tap()
        tap("fixedCostsLink")
        XCTAssertTrue(app.navigationBars["Fixed costs"].waitForExistence(timeout: 5))
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.45))
        start.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.45)))
        XCTAssertTrue(app.tabBars.buttons["Info"].isSelected)
        XCTAssertTrue(app.navigationBars["Fixed costs"].exists)
        app.navigationBars.buttons.firstMatch.tap()
        tap("calendarLink")
        XCTAssertTrue(app.navigationBars["Calendar"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        tap("analysisLink")
        XCTAssertTrue(app.navigationBars["Analysis"].waitForExistence(timeout: 5))
    }
}

extension Cycle2aUITests {
    @MainActor
    func launchC2b(_ screen: String? = nil, flags: [String] = []) {
        app.launchArguments = ["--cycle2a-test", "--cycle2b-seed", "--reset-test-preferences", "-v4.language", "en", "-v4.currency", "JPY"] + flags
        if let screen { app.launchArguments += ["--screen", screen] }
        launchApp()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "ledgerLoading").firstMatch.waitForNonExistence(timeout: 30))
    }
    @MainActor
    func saveC2bRule() {
        let save = app.buttons["saveRule"]
        for _ in 0..<8 { if save.isHittable { break }; app.swipeDown() }
        XCTAssertTrue(save.isHittable, app.debugDescription)
        save.tap()
    }
    @MainActor
    func testC2bRuleLifecycle() throws {
        launchC2b("fixed-costs")
        XCTAssertTrue(app.staticTexts["Every Monday"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Every month on day 25"].firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Every year on April 1"].exists)
        tap("addRule")
        enter("ruleTitle", "New monthly")
        enter("ruleAmount", "4500")
        saveC2bRule()
        XCTAssertTrue(app.buttons["rule-New monthly"].waitForExistence(timeout: 5))
        tap("rule-New monthly")
        enter("ruleTitle", "Edited monthly")
        saveC2bRule()
        XCTAssertTrue(app.buttons["rule-Edited monthly"].waitForExistence(timeout: 5))
        app.buttons["ruleActions-Edited monthly"].tap()
        app.buttons["Pause"].tap(); app.buttons["Pause fixed cost"].tap()
        XCTAssertTrue(app.staticTexts["Paused"].waitForExistence(timeout: 5))
        app.buttons["ruleActions-Edited monthly"].tap()
        app.buttons["Resume"].tap(); app.buttons["Resume fixed cost"].tap()
        XCTAssertTrue(app.staticTexts["Paused"].waitForNonExistence(timeout: 5))
        app.buttons["ruleActions-Edited monthly"].tap()
        app.buttons["Delete fixed cost"].tap(); app.buttons["Delete"].tap()
        XCTAssertFalse(app.buttons["rule-Edited monthly"].exists)
    }
    @MainActor
    func testC2bRuleValidation() throws {
        launchC2b("rule-form")
        enter("ruleAmount", "0")
        saveC2bRule()
        XCTAssertTrue(app.staticTexts["Enter an amount greater than zero."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["saveRule"].exists)
    }
    @MainActor
    func testC2bCatchUpRelaunch() throws {
        let id = UUID().uuidString
        launchC2b(flags: ["--disk-test", id, "--cycle2b-catchup"])
        XCTAssertTrue(app.buttons["viewCatchUp"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["3 fixed costs were recorded while the app was closed"].exists)
        tap("viewCatchUp")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "postedEntry-")).count, 3)
        app.navigationBars.buttons.firstMatch.tap()
        tap("dismissCatchUp")
        XCTAssertFalse(app.buttons["viewCatchUp"].exists)
        app.terminate(); launchApp()
        XCTAssertTrue(app.tabBars.buttons["Info"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["viewCatchUp"].exists)
        app.tabBars.buttons["Info"].tap(); tap("calendarLink")
        tap("calendar-2026-10-01")
        XCTAssertTrue(app.buttons["dayEntry-Synthetic catch-up"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "dayEntry-Synthetic catch-up").count, 1)
    }
    @MainActor
    func testC2bCalendarAndDayDetail() throws {
        launchC2b("calendar")
        let day = app.buttons["calendar-2026-10-08"]
        XCTAssertTrue(day.waitForExistence(timeout: 10), app.debugDescription)
        XCTAssertTrue(day.label.contains("¥1,130"), day.label)
        XCTAssertTrue(day.label.contains("No-spend day"), day.label)
        day.tap()
        tap("dayEntry-Synthetic lunch")
        XCTAssertEqual(app.textFields["entryAmount"].value as? String, "¥800")
        app.navigationBars.buttons.firstMatch.tap()
        let toggle = app.switches["dayNoSpend"]
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertFalse(app.staticTexts["dayError"].exists, app.debugDescription)
        XCTAssertEqual(toggle.value as? String, "0", app.debugDescription)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["calendar-2026-10-08"].label.contains("No no-spend mark"))
        app.buttons["calendar-2026-10-08"].tap(); toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(toggle.value as? String, "1")
    }
    @MainActor
    func testC2bAnalysisValuesAndEmptyMonth() throws {
        launchC2b("analysis")
        let rows = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "analysis-")).allElementsBoundByIndex
        XCTAssertEqual(rows.count, 3)
        guard rows.count == 3 else { return }
        XCTAssertTrue(rows[0].label.contains("Food"), app.debugDescription)
        XCTAssertTrue(rows[0].label.contains("¥800")); XCTAssertTrue(rows[0].label.contains("¥600"))
        XCTAssertTrue(rows[1].label.contains("Transport"))
        XCTAssertTrue(rows[1].label.contains("¥330")); XCTAssertTrue(rows[1].label.contains("¥200"))
        app.buttons["Next month"].tap()
        XCTAssertTrue(app.staticTexts["emptyAnalysis"].waitForExistence(timeout: 5))
    }
    @MainActor
    func testC2bAccessibilityAndEvidence() throws {
        for mode in ["light", "dark", "ax3"] {
            for screen in ["fixed-costs", "rule-form", "calendar", "day-detail", "analysis", "catch-up"] {
                var flags: [String] = []
                if mode != "light" { flags.append("--" + mode) }
                if screen == "catch-up" { flags.append("--cycle2b-catchup") }
                launchC2b(screen, flags: flags.filter { $0 != "--ax3" })
                let title = ["fixed-costs": "Fixed costs", "rule-form": "Add fixed cost", "calendar": "Calendar", "analysis": "Analysis", "catch-up": "Recorded fixed costs"]
                if let title = title[screen] { XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 15), app.debugDescription) }
                if screen != "catch-up" && screen != "day-detail" { try auditWithSwiftUIException("\(screen)-\(mode)") }
                if mode == "ax3" {
                    app.terminate()
                    launchC2b(screen, flags: flags)
                }
                capture("c2b-\(screen)-\(mode)")
                app.terminate()
            }
        }
    }
}

extension Cycle2aUITests {
    @MainActor
    func testC2bCatchUpFailureNamesRule() throws {
        launchC2b(flags: ["--cycle2b-failure"])
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Synthetic unavailable category")).firstMatch.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Choose an active category")).firstMatch.exists)
        XCTAssertFalse(app.buttons["viewCatchUp"].exists)
        tap("dismissCatchUp")
        XCTAssertTrue(app.tabBars.buttons["Info"].exists)
    }
    @MainActor
    func testC2bForegroundCatchUp() throws {
        launchC2b("fixed-costs")
        tap("addRule"); tap("ruleDay"); tap("11")
        for _ in 0..<8 { if app.textFields["ruleTitle"].isHittable { break }; app.swipeDown() }
        enter("ruleTitle", "Synthetic active rule"); enter("ruleAmount", "1200")
        saveC2bRule()
        XCTAssertTrue(app.buttons["rule-Synthetic active rule"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["1 fixed costs were recorded while the app was closed"].waitForExistence(timeout: 15), app.debugDescription)
        tap("dismissCatchUp")
        XCUIDevice.shared.press(.home); app.activate()
        XCTAssertTrue(app.buttons["addRule"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["viewCatchUp"].exists)
    }
    @MainActor
    func testC2bChildIsolation() throws {
        launchC2b(flags: ["--child-info"])
        XCTAssertTrue(app.tabBars.buttons["Info"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Info"].tap(); tap("fixedCostsLink")
        XCTAssertTrue(app.buttons["rule-Synthetic child rule"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["rule-Synthetic monthly"].exists)
        tap("rule-Synthetic child rule")
        XCTAssertEqual(app.buttons["ruleCategory"].value as? String, "Food", app.debugDescription)
        saveC2bRule()
        tap("rule-Synthetic child rule")
        XCTAssertEqual(app.buttons["ruleCategory"].value as? String, "Food", app.debugDescription)
        app.navigationBars.buttons.firstMatch.tap()
        app.navigationBars.buttons.firstMatch.tap(); tap("analysisLink")
        XCTAssertTrue(app.staticTexts["emptyAnalysis"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap(); tap("calendarLink")
        XCTAssertTrue(app.buttons["calendar-2026-10-08"].label.contains("¥0"))
        XCTAssertTrue(app.buttons["calendar-2026-10-08"].label.contains("No no-spend mark"))
    }
}

extension Cycle2aUITests {
    @MainActor
    func testC2bCatchUpWithPendingResults() throws {
        launchC2b(flags: ["--cycle2b-catchup", "--cycle2b-results"])
        // Existing ended-period results may appear first; the catch-up notice must follow.
        for _ in 0..<3 {
            if app.buttons["viewCatchUp"].exists { break }
            let result = app.scrollViews["resultSheet"]
            if result.waitForExistence(timeout: 5) {
                for _ in 0..<4 { if app.buttons["Done"].isHittable { break }; result.swipeUp() }
                app.buttons["Done"].tap()
            }
        }
        XCTAssertTrue(app.buttons["viewCatchUp"].waitForExistence(timeout: 10), app.debugDescription)
        tap("dismissCatchUp")
        XCTAssertTrue(app.tabBars.buttons["Info"].waitForExistence(timeout: 10))
    }
}

extension Cycle2aUITests {
    @MainActor
    func testC2bEditRuleKeepsItsCurrency() throws {
        launchC2b("fixed-costs", flags: ["--cycle2b-usd"])
        tap("rule-Synthetic dollar rule")
        XCTAssertEqual(app.textFields["ruleAmount"].value as? String, "$12.99")
        enter("ruleAmount", "15.25"); saveC2bRule()
        tap("rule-Synthetic dollar rule")
        XCTAssertEqual(app.textFields["ruleAmount"].value as? String, "$15.25")
    }
}
