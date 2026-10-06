import XCTest

@MainActor final class Cycle2aUITests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.harrison.Wealthy")
    override func setUpWithError() throws { continueAfterFailure = false }
    func capture(_ name: String) {
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "ledgerLoading").firstMatch.waitForNonExistence(timeout: 30), app.debugDescription)
        XCTAssertEqual(app.alerts.count, 0, app.debugDescription)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    func tap(_ label: String) {
        let button = app.buttons[label].firstMatch
        for _ in 0..<8 { if button.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(button.waitForExistence(timeout: 5), app.debugDescription); button.tap()
    }
    func enter(_ identifier: String, _ text: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 10), app.debugDescription)
        field.tap(); let old = field.value as? String ?? ""; field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count + 1)); field.typeText(text)
    }
    func onboard(_ language: String = "en", flags: [String] = []) throws {
        app.launchArguments = ["--cycle2a-test", "-v4.language", language, "-v4.currency", "JPY", "-v4.onboarded", "NO"] + flags
        app.launch()
        if app.staticTexts["Apple Intelligence is required"].waitForExistence(timeout: 2) { XCTFail("Real Apple Intelligence availability gate is closed; no bypass used."); throw NSError(domain: "Cycle2aTests", code: 1) }
        XCTAssertTrue(app.buttons["onboardingNext"].waitForExistence(timeout: 20), app.debugDescription)
        capture("onboarding-language-\(language)-\(flags.joined(separator: "-"))"); app.buttons["onboardingNext"].tap(); capture("onboarding-currency-\(language)-\(flags.joined(separator: "-"))"); app.buttons["onboardingNext"].tap()
        enter("onboardingAmount", "40000"); capture("onboarding-target-\(language)-\(flags.joined(separator: "-"))"); tap("onboardingNext"); capture("onboarding-child-\(language)-\(flags.joined(separator: "-"))"); tap("onboardingNext")
        XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 10), app.debugDescription); capture("empty-home-\(language)-\(flags.joined(separator: "-"))-" + flags.joined(separator: "-"))
    }
    func testOnboardingEntryTaxNoSpendTarget() throws {
        try onboard()
        tap("addEntry"); enter("entryAmount", "2400"); capture("entry")
        app.buttons["entryCategory"].tap(); tap("Food")
        app.buttons["entryService"].tap(); tap("Takeout (8%)")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "¥177")).firstMatch.waitForExistence(timeout: 5), app.debugDescription)
        tap("saveEntry"); tap("noSpend"); capture("home-with-entry")
        tap("Targets"); enter("overallTarget", "50000"); tap("saveGoals")
        tap("Info"); capture("info"); tap("Consumption tax"); capture("tax")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "¥177")).firstMatch.waitForExistence(timeout: 5), app.debugDescription)
    }
    func testLocalizedOnboarding() throws {
        for language in ["ja", "es", "ko"] { try onboard(language); app.terminate() }
    }
    func testScreenMatrix() throws {
        for language in ["en", "ja", "es", "ko"] {
            for variant in ["light", "dark", "ax3"] {
                for screen in ["home", "voice", "info", "goals", "edit", "tax", "child-setup", "child-detail", "settings", "result", "month-result", "no-ai"] {
                    app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", language, "-v4.currency", "JPY", "--screen", screen]
                    if variant == "dark" { app.launchArguments.append("--dark") }
                    if variant == "ax3" { app.launchArguments.append("--ax3") }
                    app.launch()
                    XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15)); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 10))
                    capture("matrix-\(language)-\(variant)-\(screen)")
                    app.terminate()
                }
            }
        }
    }
    func testResultAndAccessibilityVariants() throws {
        for flags in [["--few"], ["--over"], ["--opaque", "--reduce-motion", "--ax3"]] {
            app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", "en", "--screen", "result"] + flags
            app.launch(); XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15)); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 10)); capture("result-" + flags.joined(separator: "-")); app.terminate()
        }
    }

    func testAdditionalSetupMatrix() throws {
        for language in ["en", "ja", "es", "ko"] {
            for flags in [["--dark"], ["--ax3"]] { try onboard(language, flags: flags); app.terminate() }
        }
    }
    func testNavigationMatrix() throws {
        for language in ["en", "ja", "es", "ko"] {
            for variant in ["light", "dark", "ax3"] {
                for screen in ["home", "voice", "info"] {
                    app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", language, "-v4.currency", "JPY", "--screen", screen]
                    if variant == "dark" { app.launchArguments.append("--dark") }
                    if variant == "ax3" { app.launchArguments.append("--ax3") }
                    app.launch(); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 15)); capture("matrix-\(language)-\(variant)-\(screen)"); app.terminate()
                }
            }
        }
    }
    func testManualTaxAndMetadataSurviveReopening() throws {
        try onboard()
        tap("addEntry"); enter("entryAmount", "2400")
        app.buttons["entryCategory"].tap(); tap("Food")
        app.buttons["entryService"].tap(); tap("Takeout (8%)")
        app.buttons["entryTaxRate"].tap(); tap("10%")
        app.swipeUp(); app.switches["Needs review"].firstMatch.tap()
        tap("saveEntry"); tap("Info")
        let row = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "¥2,400")).firstMatch
        for _ in 0..<10 { if row.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
        XCTAssertTrue(app.buttons["entryTaxRate"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["entryTaxRate"].label.contains("10%"), app.debugDescription)
        XCTAssertTrue(app.buttons["entryCategory"].label.contains("Food"), app.debugDescription)
        capture("manual-tax-preserved")
    }
    func testChildEnvelopeAndLicenseFlow() throws {
        try onboard(); tap("Info"); tap("Child envelope setup")
        app.switches["Use child envelope"].firstMatch.tap(); tap("Targets"); tap("setTargetManually"); enter("overallTarget", "80000"); tap("saveGoals")
        app.navigationBars.buttons.firstMatch.tap()
        for _ in 0..<6 { app.swipeDown() }
        tap("Child envelope"); tap("To island"); tap("addEntry"); enter("entryAmount", "3600"); tap("Child envelope")
        app.buttons["entryCategory"].tap(); tap("Food"); app.buttons["entryService"].tap(); tap("Takeout (8%)"); tap("saveEntry")
        tap("Info"); tap("Consumption tax")
        XCTAssertTrue(app.staticTexts["¥266"].waitForExistence(timeout: 5), app.debugDescription); capture("child-tax")
        app.navigationBars.buttons.firstMatch.tap()
        for _ in 0..<8 { app.swipeDown() }; tap("To island"); tap("Settings"); tap("Font licenses")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Copyright 2020")).firstMatch.waitForExistence(timeout: 5), app.debugDescription)
        capture("font-licenses")
    }

    func testHomeWithFiftyThousandPersistedEntries() throws {
        app.launchArguments = ["--cycle2a-test", "--cycle2a-performance", "-v4.language", "en", "-v4.currency", "JPY"]
        app.launch()
        XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 120), app.debugDescription)
        app.terminate()
        var samples: [Double] = []
        for _ in 0..<5 {
            let start = Date()
            app.launch()
            XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 30), app.debugDescription)
            samples.append(Date().timeIntervalSince(start))
            XCTAssertEqual(app.alerts.count, 0)
            app.terminate()
        }
        let proof = XCTAttachment(string: "Launch call to Home accessibility readiness, seconds: \(samples). Includes XCTest launch/idle overhead; excludes fixture creation; warm persisted store. Not GPU first-frame timing.")
        proof.name = "home-50000-performance"; proof.lifetime = .keepAlways; add(proof)
        print("HOME_50000_LAUNCH_TO_ACCESSIBILITY_READY_SECONDS \(samples)")
    }

    func audit(_ screen: String) throws {
            app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", "en", "--screen", screen]
            app.launch()
            XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 15))
            if screen == "result" {
                let explanation = app.staticTexts["resultLateDetail"]
                for _ in 0..<6 { if explanation.isHittable { break }; app.swipeUp() }
                XCTAssertTrue(explanation.isHittable, app.debugDescription)
            }
            capture("audit-preview-\(screen)")
            var issues: [String] = []
            try app.performAccessibilityAudit(for: [.contrast, .textClipped, .hitRegion, .sufficientElementDescription]) { issue in
                issues.append("\(issue.auditType): \(issue.compactDescription) / \(issue.detailedDescription) / \(issue.element?.debugDescription ?? "No element")")
                return true // Collect every issue; the explicit assertion below rejects all of them.
            }
            let proof = XCTAttachment(string: issues.joined(separator: "\n")); proof.name = "audit-\(screen)"; proof.lifetime = .keepAlways; add(proof)
            XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
            app.terminate()
    }

    func testHomeAccessibilityAudit() throws { try audit("home") }
    func testResultAccessibilityAudit() throws { try audit("result") }
    func testEntryAccessibilityAudit() throws { try audit("edit") }

    func testChildAndResultMatrix() throws {
        for language in ["en", "ja", "es", "ko"] {
            for variant in ["light", "dark", "ax3"] {
                for screen in ["child-setup", "child-detail", "result", "month-result"] {
                    app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", language, "-v4.currency", "JPY", "--screen", screen]
                    if variant == "dark" { app.launchArguments.append("--dark") }
                    if variant == "ax3" { app.launchArguments.append("--ax3") }
                    app.launch(); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 15))
                    capture("matrix-\(language)-\(variant)-\(screen)"); app.terminate()
                }
            }
        }
    }

    func testGoalsUnsetMatrix() throws {
        for language in ["en", "ja", "es", "ko"] {
            for variant in ["light", "dark", "ax3"] {
                app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--unset", "-v4.language", language, "-v4.currency", "JPY", "--screen", "goals"]
                if variant == "dark" { app.launchArguments.append("--dark") }
                if variant == "ax3" { app.launchArguments.append("--ax3") }
                app.launch(); XCTAssertTrue(app.buttons["setTargetManually"].waitForExistence(timeout: 15))
                XCTAssertFalse(app.textFields["overallTarget"].exists)
                capture("matrix-\(language)-\(variant)-goals-unset")
                app.buttons["setTargetManually"].tap(); XCTAssertTrue(app.textFields["overallTarget"].exists); app.terminate()
            }
        }
    }

    func testFormMatrix() throws {
        for language in ["en", "ja", "es", "ko"] {
            for variant in ["light", "dark", "ax3"] {
                for screen in ["goals", "edit"] {
                    app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", language, "-v4.currency", "JPY", "--screen", screen]
                    if variant == "dark" { app.launchArguments.append("--dark") }
                    if variant == "ax3" { app.launchArguments.append("--ax3") }
                    app.launch(); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 15))
                    capture("matrix-\(language)-\(variant)-\(screen)"); app.terminate()
                }
            }
        }
    }

    func launchSeededWorkflow() {
        app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--reduce-motion", "-v4.language", "en", "-v4.currency", "JPY"]
        app.launch(); XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 15))
    }
    func testIncomeEntry() throws {
        launchSeededWorkflow(); tap("addEntry"); enter("entryAmount", "12000")
        app.buttons["Income"].tap(); app.buttons["entryCategory"].tap(); tap("Salary")
        XCTAssertFalse(app.buttons["entryTaxRate"].exists); capture("income-entry")
        tap("saveEntry"); tap("Info"); tap("Consumption tax")
        XCTAssertTrue(app.staticTexts["¥218"].waitForExistence(timeout: 5), app.debugDescription)
    }
    func testChildSupportDefaults() throws {
        launchSeededWorkflow(); tap("addEntry"); enter("entryAmount", "50000")
        app.buttons["Child envelope"].tap(); app.buttons["entryCategory"].tap(); tap("Child support payment")
        XCTAssertTrue(app.buttons["entryTaxRate"].label.contains("Tax-exempt"), app.debugDescription)
        XCTAssertEqual(app.switches["Fixed cost"].firstMatch.value as? String, "1")
        capture("child-support-defaults"); tap("saveEntry"); tap("Info"); app.buttons["Child envelope"].tap(); tap("Consumption tax")
        XCTAssertTrue(app.staticTexts["¥266"].waitForExistence(timeout: 5), app.debugDescription)
    }
    func testNormalNewStoreLaunch() throws {
        app.launchArguments = ["--cycle2a-test", "--disk-test", UUID().uuidString]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingNext"].waitForExistence(timeout: 30), app.debugDescription)
        capture("normal-new-store-onboarding")
    }

    func testPagerNavigation() throws {
        launchSeededWorkflow()
        XCTAssertTrue(app.buttons["page-1"].isSelected)
        tap("homeVoice"); XCTAssertTrue(app.buttons["page-0"].isSelected)
        tap("voiceInfo"); XCTAssertTrue(app.buttons["page-2"].isSelected)
        tap("infoIsland"); XCTAssertTrue(app.buttons["page-1"].isSelected)
        app.swipeLeft(); XCTAssertTrue(app.buttons["page-2"].isSelected)
        app.swipeRight(); XCTAssertTrue(app.buttons["page-1"].isSelected)
        app.swipeRight(); XCTAssertTrue(app.buttons["page-0"].isSelected)
        capture("pager-voice")
    }
    func testChildInfoMatrix() throws {
        for language in ["en", "ja", "es", "ko"] {
            for variant in ["light", "dark", "ax3"] {
                app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--child-info", "-v4.language", language, "-v4.currency", "JPY", "--screen", "info-child"]
                if variant == "dark" { app.launchArguments.append("--dark") }
                if variant == "ax3" { app.launchArguments.append("--ax3") }
                app.launch(); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 15))
                capture("matrix-\(language)-\(variant)-info-child"); app.terminate()
            }
        }
    }

    func testNoSpendDayFromEmptyLedger() throws {
        try onboard(flags: ["--reduce-motion"])
        tap("noSpend")
        XCTAssertTrue(app.staticTexts["1 days logged"].firstMatch.waitForExistence(timeout: 5), app.debugDescription)
        capture("no-spend-empty-day")
    }

    func testKoreanAmountsMatrix() throws {
        for screen in ["home", "info", "info-child", "child-detail", "result", "month-result"] {
            app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--ax3", "-v4.language", "ko", "-v4.currency", "JPY", "--screen", screen]
            if screen == "info-child" { app.launchArguments.append("--child-info") }
            app.launch(); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 15))
            capture("matrix-ko-ax3-\(screen)"); app.terminate()
        }
    }

    func testExistingChildSetupRemainsEnabled() throws {
        app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", "en", "--screen", "child-setup"]
        app.launch(); XCTAssertTrue(app.switches["Use child envelope"].firstMatch.waitForExistence(timeout: 15))
        XCTAssertEqual(app.switches["Use child envelope"].firstMatch.value as? String, "1")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Food")).firstMatch.waitForExistence(timeout: 5), app.debugDescription)
        capture("existing-child-setup")
    }
    func testChildSetupMatrix() throws {
        for language in ["en", "ja", "es", "ko"] {
            for variant in ["light", "dark", "ax3"] {
                app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", language, "-v4.currency", "JPY", "--screen", "child-setup"]
                if variant == "dark" { app.launchArguments.append("--dark") }
                if variant == "ax3" { app.launchArguments.append("--ax3") }
                app.launch(); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 15))
                capture("matrix-\(language)-\(variant)-child-setup"); app.terminate()
            }
        }
    }

}

// Persisted onboarding uses a real disk ledger and isolated preferences, retained across process termination.
extension Cycle2aUITests {
    func testPersistedOnboardingRelaunch() throws {
        let id = UUID().uuidString
        app.launchArguments = ["--cycle2a-test", "--disk-test", id]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingNext"].waitForExistence(timeout: 20))
        app.buttons["language"].tap(); tap("Español")
        tap("onboardingNext")
        app.buttons["currency"].tap(); tap("KRW")
        tap("onboardingNext"); enter("onboardingAmount", "40000"); tap("onboardingNext"); tap("onboardingNext")
        XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 10)); capture("persisted-onboarding-home-before")
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["onboardingNext"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "40.000")).firstMatch.exists, app.debugDescription)
        XCTAssertTrue(app.buttons["homeInfo"].label.contains("Información"), app.debugDescription)
        capture("persisted-onboarding-home-after")
        tap("Ajustes"); XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "KRW")).firstMatch.exists, app.debugDescription)
        capture("persisted-onboarding-settings")
    }
    func testMonthResultStatesMatrix() throws {
        for state in ["achieved", "over", "few"] {
            for mode in ["light", "dark", "ax3"] {
                app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--month-" + state, "-v4.language", "en", "-v4.currency", "JPY", "--screen", "month-result"]
                if mode == "dark" { app.launchArguments.append("--dark") }
                if mode == "ax3" { app.launchArguments.append("--ax3") }
                app.launch(); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 15)); capture("month-result-\(state)-\(mode)"); app.terminate()
            }
        }
    }
    func testHomeAlwaysHousehold() throws {
        app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--child-info", "-v4.language", "en", "-v4.currency", "JPY"]
        app.launch(); XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 20))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "307,100")).firstMatch.exists, app.debugDescription)
        capture("home-household-child-selected")
        tap("homeInfo"); XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "76,400")).firstMatch.exists, app.debugDescription)
        capture("info-child-selected")
        tap("infoIsland"); XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "307,100")).firstMatch.exists, app.debugDescription)
    }
    func testLocalizedGroupedAmountFields() throws {
        for (language, goal, entry) in [("en", "¥310,000", "¥2,400"), ("ja", "¥310,000", "¥2,400"), ("es", "310.000 ¥", "2.400 ¥"), ("ko", "JP¥310,000", "JP¥2,400")] {
            for (screen, identifier, expected) in [("goals", "overallTarget", goal), ("edit", "entryAmount", entry)] {
                app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", language, "-v4.currency", "JPY", "--screen", screen]
                app.launch(); XCTAssertTrue(app.textFields[identifier].waitForExistence(timeout: 20))
                XCTAssertEqual(app.textFields[identifier].value as? String, expected)
                capture("grouped-\(language)-\(screen)"); app.terminate()
            }
        }
    }
    func testLaunchMetric1000() throws { try launchMetric(entries: 1000) }
    func testLaunchMetric10000() throws { try launchMetric(entries: 10000) }
    func testLaunchMetric50000() throws { try launchMetric(entries: 50000) }
    func testHomeInteractiveMetric1000() throws { try launchMetric(entries: 1000, interactive: true) }
    func testHomeInteractiveMetric10000() throws { try launchMetric(entries: 10000, interactive: true) }
    func testHomeInteractiveMetric50000() throws { try launchMetric(entries: 50000, interactive: true) }
    private func launchMetric(entries: Int, interactive: Bool = false) throws {
        app.launchArguments = ["--cycle2a-test", "--cycle2a-performance", "--entry-count", String(entries), "-v4.language", "en", "-v4.currency", "JPY"]
        if interactive { app.launchArguments.append("--measure-home-launch") }
        app.launch(); XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 120)); app.terminate()
        let options = XCTMeasureOptions(); options.iterationCount = 5
        let metrics: [XCTMetric] = interactive
            ? [XCTApplicationLaunchMetric(waitUntilResponsive: true)] + ["HomeInteractive", "StoreOpen", "Snapshot", "QuerySnapshot", "HomeRender"].map { XCTOSSignpostMetric(subsystem: "com.harrison.Wealthy", category: "LedgerLaunch", name: $0) }
            : [XCTApplicationLaunchMetric(waitUntilResponsive: false)]
        measure(metrics: metrics, options: options) {
            app.launch(); XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 60))
            if interactive { XCTAssertTrue(app.buttons["homeInfo"].isHittable); XCTAssertEqual(app.alerts.count, 0) }
            app.terminate()
        }
    }
}
