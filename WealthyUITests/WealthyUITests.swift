@preconcurrency import XCTest

final class Cycle2aUITests: XCTestCase {
    @MainActor lazy var app: XCUIApplication = {
        let application = XCUIApplication(bundleIdentifier: "com.harrison.Wealthy")
        if ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil {
            application.launchEnvironment["WEALTHY_CYCLE2A_TEST_AI_AVAILABLE"] = "1"
        }
        return application
    }()
    @MainActor
    func capture(_ name: String) {
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "ledgerLoading").firstMatch.waitForNonExistence(timeout: 30), app.debugDescription)
        XCTAssertEqual(app.alerts.count, 0, app.debugDescription)
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    @MainActor
    func tap(_ label: String) {
        let button = app.buttons[label].firstMatch
        @MainActor
        func unobscuredCenter() -> Bool {
            let bounds = app.frame
            let keyboard = app.keyboards.firstMatch
            let visibleBottom = keyboard.exists ? min(bounds.maxY, keyboard.frame.minY) : bounds.maxY
            return button.isHittable
                && button.frame.midX >= bounds.minX && button.frame.midX <= bounds.maxX
                && button.frame.midY >= bounds.minY && button.frame.midY < visibleBottom
        }
        for _ in 0..<12 { if unobscuredCenter() { break }; app.swipeUp() }
        XCTAssertTrue(button.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(unobscuredCenter(), "Button center is not visible above the keyboard: \(button.frame), keyboard: \(app.keyboards.firstMatch.frame)\n\(app.debugDescription)")
        button.tap()
    }
    @MainActor
    func enter(_ identifier: String, _ text: String) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 10), app.debugDescription)
        field.tap(); let old = field.value as? String ?? ""; field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count + 1)); field.typeText(text)
    }
    @MainActor
    func onboard(_ language: String = "en", flags: [String] = []) throws {
        app.launchArguments = ["--cycle2a-test", "-v4.language", language, "-v4.currency", "JPY", "-v4.onboarded", "NO"] + flags
        app.launch()
        if app.staticTexts["Apple Intelligence is required"].waitForExistence(timeout: 2) { XCTFail("Real Apple Intelligence availability gate is closed; no bypass used."); throw NSError(domain: "Cycle2aTests", code: 1) }
        XCTAssertTrue(app.buttons["onboardingNext"].waitForExistence(timeout: 20), app.debugDescription)
        capture("onboarding-language-\(language)-\(flags.joined(separator: "-"))"); app.buttons["onboardingNext"].tap(); capture("onboarding-currency-\(language)-\(flags.joined(separator: "-"))"); app.buttons["onboardingNext"].tap()
        enter("onboardingAmount", "40000"); capture("onboarding-target-\(language)-\(flags.joined(separator: "-"))"); tap("onboardingNext"); capture("onboarding-child-\(language)-\(flags.joined(separator: "-"))"); tap("onboardingNext")
        XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 10), app.debugDescription); capture("empty-home-\(language)-\(flags.joined(separator: "-"))-" + flags.joined(separator: "-"))
    }
    @MainActor
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
    @MainActor
    func testLocalizedOnboarding() throws {
        for language in ["ja", "es", "ko"] { try onboard(language); app.terminate() }
    }
    @MainActor
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
    @MainActor
    func testResultAndAccessibilityVariants() throws {
        for flags in [["--few"], ["--over"], ["--opaque", "--reduce-motion", "--ax3"]] {
            app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", "en", "--screen", "result"] + flags
            app.launch(); XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15)); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 10)); capture("result-" + flags.joined(separator: "-")); app.terminate()
        }
    }

    @MainActor

    func testAdditionalSetupMatrix() throws {
        for language in ["en", "ja", "es", "ko"] {
            for flags in [["--dark"], ["--ax3"]] { try onboard(language, flags: flags); app.terminate() }
        }
    }
    @MainActor
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
    @MainActor
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
    @MainActor
    func testChildEnvelopeAndLicenseFlow() throws {
        try onboard(); tap("Info"); tap("Child envelope setup")
        app.switches["Use child envelope"].firstMatch.tap(); tap("Targets"); tap("setTargetManually"); enter("overallTarget", "80000"); tap("saveGoals")
        app.navigationBars.buttons.firstMatch.tap()
        for _ in 0..<6 { app.swipeDown() }
        tap("Child envelope"); tap("To island"); tap("addEntry"); enter("entryAmount", "3600"); tap("Child envelope")
        app.buttons["entryCategory"].tap(); tap("Food"); app.buttons["entryService"].tap(); tap("Takeout (8%)"); tap("saveEntry")
        XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 10), app.debugDescription)
        tap("Info"); tap("Child envelope"); tap("Consumption tax")
        XCTAssertTrue(app.staticTexts["¥266"].waitForExistence(timeout: 5), app.debugDescription); capture("child-tax")
        app.navigationBars.buttons.firstMatch.tap()
        for _ in 0..<8 { app.swipeDown() }; tap("To island"); tap("Settings"); tap("Font licenses")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Copyright 2020")).firstMatch.waitForExistence(timeout: 5), app.debugDescription)
        capture("font-licenses")
    }

    @MainActor

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

    @MainActor

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
            let auditedScreen = screen
            try app.performAccessibilityAudit(for: [.contrast, .textClipped, .hitRegion, .sufficientElementDescription]) { issue in
                let element = issue.element
                let details = "\(issue.auditType): \(issue.compactDescription) / \(issue.detailedDescription) / label=\(element?.label ?? "<nil>") identifier=\(element?.identifier ?? "<nil>") frame=\(element.map { NSCoder.string(for: $0.frame) } ?? "<nil>") / \(element?.debugDescription ?? "No element")"
                issues.append(details)
                print("ACCESSIBILITY_AUDIT_ISSUE \(details)")
                let image = self.app.screenshot().image
                let crop: UIImage
                if let element, let cgImage = image.cgImage, self.app.frame.width > 0, self.app.frame.height > 0 {
                    let scaleX = CGFloat(cgImage.width) / self.app.frame.width
                    let scaleY = CGFloat(cgImage.height) / self.app.frame.height
                    let frame = element.frame
                    let rect = CGRect(x: max(0, (frame.minX - self.app.frame.minX - 24) * scaleX), y: max(0, (frame.minY - self.app.frame.minY - 24) * scaleY), width: min(CGFloat(cgImage.width), (frame.width + 48) * scaleX), height: min(CGFloat(cgImage.height), (frame.height + 48) * scaleY)).integral.intersection(CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
                    crop = rect.isNull || rect.isEmpty ? image : UIImage(cgImage: cgImage.cropping(to: rect) ?? cgImage)
                } else { crop = image }
                let attachment = XCTAttachment(image: crop); attachment.name = "audit-\(auditedScreen)-issue-\(issues.count)-crop"; attachment.lifetime = .keepAlways; self.add(attachment)
                return true // Collect every issue; the explicit assertion below rejects all of them.
            }
            let proof = XCTAttachment(string: issues.joined(separator: "\n")); proof.name = "audit-\(screen)"; proof.lifetime = .keepAlways; add(proof)
            XCTAssertTrue(issues.isEmpty, issues.joined(separator: "\n"))
            app.terminate()
    }

    @MainActor

    func testHomeAccessibilityAudit() throws { try audit("home") }
    @MainActor
    func testVoiceAccessibilityAudit() throws { try audit("voice") }
    @MainActor
    func testInfoAccessibilityAudit() throws { try audit("info") }
    @MainActor
    func testResultAccessibilityAudit() throws { try audit("result") }
    @MainActor
    func testEntryAccessibilityAudit() throws { try audit("edit") }

    @MainActor

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

    @MainActor

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

    @MainActor

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

    @MainActor

    func launchSeededWorkflow() {
        app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--reset-test-preferences", "--reduce-motion", "-v4.language", "en", "-v4.currency", "JPY"]
        app.launch(); XCTAssertTrue(app.tabBars.buttons["Island"].waitForExistence(timeout: 30), app.debugDescription)
        XCTAssertTrue(app.tabBars.buttons["Island"].isSelected, app.debugDescription)
    }
    @MainActor
    func testIncomeEntry() throws {
        launchSeededWorkflow(); tap("addEntry"); enter("entryAmount", "12000")
        app.buttons["Income"].tap(); app.buttons["entryCategory"].tap(); tap("Salary")
        XCTAssertFalse(app.buttons["entryTaxRate"].exists); capture("income-entry")
        tap("saveEntry"); tap("Info"); tap("Consumption tax")
        XCTAssertTrue(app.staticTexts["¥218"].waitForExistence(timeout: 5), app.debugDescription)
    }
    @MainActor
    func testChildSupportDefaults() throws {
        launchSeededWorkflow(); tap("addEntry"); enter("entryAmount", "50000")
        app.buttons["Child envelope"].tap(); app.buttons["entryCategory"].tap(); tap("Child support payment")
        XCTAssertTrue(app.buttons["entryTaxRate"].label.contains("Tax-exempt"), app.debugDescription)
        XCTAssertEqual(app.switches["Fixed cost"].firstMatch.value as? String, "1")
        capture("child-support-defaults"); tap("saveEntry"); tap("Info"); app.buttons["Child envelope"].tap(); tap("Consumption tax")
        XCTAssertTrue(app.staticTexts["¥266"].waitForExistence(timeout: 5), app.debugDescription)
    }
    @MainActor
    func testNormalNewStoreLaunch() throws {
        app.launchArguments = ["--cycle2a-test", "--disk-test", UUID().uuidString]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingNext"].waitForExistence(timeout: 30), app.debugDescription)
        capture("normal-new-store-onboarding")
    }

    @MainActor

    func testPagerNavigation() throws {
        app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--reset-test-preferences", "--reduce-motion", "-v4.language", "en", "-v4.currency", "JPY"]
        app.launch()
        let tabs = app.tabBars.buttons
        XCTAssertTrue(tabs["Voice"].waitForExistence(timeout: 20), app.debugDescription)
        XCTAssertTrue(tabs["Island"].isSelected, app.debugDescription)
        tabs["Voice"].tap(); XCTAssertTrue(tabs["Voice"].isSelected, app.debugDescription)
        tabs["Info"].tap(); XCTAssertTrue(tabs["Info"].isSelected, app.debugDescription)
        tabs["Island"].tap(); XCTAssertTrue(tabs["Island"].isSelected, app.debugDescription)
        capture("native-tab-bar")
    }

    @MainActor

    func testHorizontalSwipeRemovedAndVerticalScrollDoesNotSwitchTabs() throws {
        launchSeededWorkflow()
        let home = app.tabBars.buttons["Island"]
        let info = app.tabBars.buttons["Info"]
        XCTAssertTrue(home.isSelected, app.debugDescription)
        app.swipeUp()
        XCTAssertTrue(home.isSelected, "A vertical Home scroll must not select another tab.")
        app.swipeLeft()
        XCTAssertTrue(home.isSelected, "Horizontal tab paging was removed because it captured text-selection drags.")
        info.tap()
        XCTAssertTrue(info.isSelected, app.debugDescription)
        app.swipeUp()
        XCTAssertTrue(info.isSelected, "A vertical Info scroll must not select another tab.")
        app.swipeRight()
        XCTAssertTrue(info.isSelected, "Horizontal swipes no longer change tabs; use the standard tab bar.")
    }

    @MainActor

    func testEditorControlDragsDoNotSwitchTabs() throws {
        launchSeededWorkflow(); tap("addEntry")
        let home = app.tabBars.buttons["Island"]
        XCTAssertTrue(app.textFields["entryAmount"].waitForExistence(timeout: 10), app.debugDescription)
        app.swipeUp()
        XCTAssertTrue(app.buttons["saveEntry"].exists, "A vertical Edit scroll must keep the editor open.")

        let kind = app.buttons["Expense"]
        XCTAssertTrue(kind.exists)
        kind.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: kind.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)))
        XCTAssertTrue(app.buttons["saveEntry"].exists, "A segmented picker drag must not leave the editor.")

        let date = app.descendants(matching: .any).matching(identifier: "entryDate").firstMatch
        XCTAssertTrue(date.waitForExistence(timeout: 5), app.debugDescription)
        date.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: date.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)))
        XCTAssertTrue(app.buttons["saveEntry"].exists, "A date picker drag must not leave the editor.")

        let note = app.textFields["entryNote"]
        XCTAssertTrue(note.waitForExistence(timeout: 5), app.debugDescription)
        note.tap()
        note.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: note.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)))
        XCTAssertTrue(app.buttons["saveEntry"].exists, "A text-field selection drag must not leave the editor.")
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(home.isSelected, "Editor control drags must return to the same Home tab.")
    }

    @MainActor

    func testInfoSegmentedControlDragDoesNotSwitchTabs() throws {
        launchSeededWorkflow()
        let info = app.tabBars.buttons["Info"]
        info.tap()
        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10), app.debugDescription)
        picker.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.5))
            .press(forDuration: 0.1, thenDragTo: picker.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)))
        XCTAssertTrue(info.isSelected, "Dragging the Info envelope picker must not change tabs.")
    }
    @MainActor
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

    @MainActor

    func testNoSpendDayFromEmptyLedger() throws {
        try onboard(flags: ["--reduce-motion"])
        tap("noSpend")
        XCTAssertTrue(app.staticTexts["1 days logged"].firstMatch.waitForExistence(timeout: 5), app.debugDescription)
        capture("no-spend-empty-day")
    }

    @MainActor

    func testKoreanAmountsMatrix() throws {
        for screen in ["home", "info", "info-child", "child-detail", "result", "month-result"] {
            app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--ax3", "-v4.language", "ko", "-v4.currency", "JPY", "--screen", screen]
            if screen == "info-child" { app.launchArguments.append("--child-info") }
            app.launch(); XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 15))
            capture("matrix-ko-ax3-\(screen)"); app.terminate()
        }
    }

    @MainActor

    func testExistingChildSetupRemainsEnabled() throws {
        app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", "en", "--screen", "child-setup"]
        app.launch(); XCTAssertTrue(app.switches["Use child envelope"].firstMatch.waitForExistence(timeout: 15))
        XCTAssertEqual(app.switches["Use child envelope"].firstMatch.value as? String, "1")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Food")).firstMatch.waitForExistence(timeout: 5), app.debugDescription)
        capture("existing-child-setup")
    }
    @MainActor
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
    @MainActor
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
        XCTAssertTrue(app.tabBars.buttons["Información"].exists, app.debugDescription)
        capture("persisted-onboarding-home-after")
        tap("Ajustes"); XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "KRW")).firstMatch.exists, app.debugDescription)
        capture("persisted-onboarding-settings")
    }
    @MainActor
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
    @MainActor
    func testHomeAlwaysHousehold() throws {
        for mode in ["light", "dark"] {
            app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--child-info", "-v4.language", "en", "-v4.currency", "JPY"]
            if mode == "dark" { app.launchArguments.append("--dark") }
            app.launch(); XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 20))
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "307,100")).firstMatch.exists, app.debugDescription)
            XCTAssertTrue(app.staticTexts["homeWeeklyRemaining"].exists, app.debugDescription)
            XCTAssertTrue(app.tabBars.buttons["Info"].exists, app.debugDescription)
            capture("home-household-child-selected---\(mode)")
            app.tabBars.buttons["Info"].tap(); XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "76,400")).firstMatch.exists, app.debugDescription)
            capture("info-child-selected---\(mode)")
            app.tabBars.buttons["Home"].tap(); XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "307,100")).firstMatch.exists, app.debugDescription)
            app.terminate()
        }
    }
    @MainActor
    func testVoicePlaceholderIsShownOnce() throws {
        for mode in ["light", "dark"] {
            app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", "en", "--screen", "voice"]
            if mode == "dark" { app.launchArguments.append("--dark") }
            app.launch()
            XCTAssertTrue(app.staticTexts["Voice input is coming soon. For now, add entries by typing."].waitForExistence(timeout: 15), app.debugDescription)
            XCTAssertFalse(app.staticTexts["Voice input is unavailable right now."].exists, app.debugDescription)
            capture("voice-single-placeholder---\(mode)")
            app.terminate()
        }
    }
    @MainActor
    func testHomeAX3LanguageMatrix() throws {
        for language in ["en", "ja", "es", "ko"] {
            app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--ax3", "-v4.language", language, "-v4.currency", "JPY"]
            app.launch()
            XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 30), app.debugDescription)
            XCTAssertTrue(app.tabBars.buttons["Home"].isSelected, app.debugDescription)
            try app.performAccessibilityAudit(for: [.textClipped]) { issue in
                XCTFail("Home AX3 \(language): \(issue.compactDescription) / \(issue.detailedDescription)")
                return true
            }
            capture("home-ax3-\(language)")
            app.terminate()
        }
    }
    @MainActor
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
    @MainActor
    func testNativeScreenEvidenceLightAndDark() throws {
        let screens: [(String, String, [String])] = [
            ("voice", "voice", []),
            ("home", "home", []),
            ("info-household", "info", []),
            ("info-child", "info", ["--child-info"]),
            ("goals", "goals", []),
            ("goals-unset", "goals", ["--unset"]),
            ("edit", "edit", []),
            ("tax", "tax", []),
            ("result-week-achieved", "result", []),
            ("result-week-over", "result", ["--over"]),
            ("result-week-few", "result", ["--few"]),
            ("result-month-achieved", "month-result", ["--month-achieved"]),
            ("result-month-over", "month-result", ["--month-over"]),
            ("result-month-few", "month-result", ["--month-few"]),
            ("child-setup", "child-setup", []),
            ("child-detail", "child-detail", []),
            ("settings", "settings", [])
        ]
        for mode in ["light", "dark"] {
            for (name, screen, flags) in screens {
                app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", "en", "-v4.currency", "JPY", "--screen", screen] + flags
                if mode == "dark" { app.launchArguments.append("--dark") }
                app.launch()
                XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), app.debugDescription)
                XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 20), app.debugDescription)
                capture("native-\(name)-\(mode)")
                app.terminate()
            }
        }
    }
    @MainActor
    func testNativeHomeLanguageEvidence() throws {
        for language in ["en", "ja", "es", "ko"] {
            app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "-v4.language", language, "-v4.currency", "JPY"]
            app.launch()
            XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 30), app.debugDescription)
            capture("native-home-\(language)-light")
            app.terminate()
        }
        app.launchArguments = ["--cycle2a-test", "--cycle2a-seed", "--ax3", "-v4.language", "en", "-v4.currency", "JPY"]
        app.launch()
        XCTAssertTrue(app.collectionViews["homePage"].waitForExistence(timeout: 30), app.debugDescription)
        capture("native-home-en-ax3")
        app.terminate()
    }
    @MainActor
    func testNativeOnboardingEvidenceLightAndDark() throws {
        try onboard("en", flags: [])
        app.terminate()
        try onboard("en", flags: ["--dark"])
        app.terminate()
    }
    @MainActor
    func testLaunchMetric1000() throws { try launchMetric(entries: 1000) }
    @MainActor
    func testLaunchMetric10000() throws { try launchMetric(entries: 10000) }
    @MainActor
    func testLaunchMetric50000() throws { try launchMetric(entries: 50000) }
    @MainActor
    func testHomeInteractiveMetric1000() throws { try launchMetric(entries: 1000, interactive: true) }
    @MainActor
    func testHomeInteractiveMetric10000() throws { try launchMetric(entries: 10000, interactive: true) }
    @MainActor
    func testHomeInteractiveMetric50000() throws { try launchMetric(entries: 50000, interactive: true) }
    @MainActor
    private func launchMetric(entries: Int, interactive: Bool = false) throws {
        app.launchArguments = ["--cycle2a-test", "--cycle2a-performance", "--entry-count", String(entries), "-v4.language", "en", "-v4.currency", "JPY"]
        if interactive { app.launchArguments.append("--measure-home-launch") }
        let options = XCTMeasureOptions(); options.iterationCount = 5
        let metrics: [XCTMetric] = interactive
            ? [XCTApplicationLaunchMetric(waitUntilResponsive: true)] + ["FirstFrame", "HomeInteractive", "StoreOpen", "Snapshot", "QuerySnapshot", "HomeRender"].map { XCTOSSignpostMetric(subsystem: "com.harrison.Wealthy", category: "LedgerLaunch", name: $0) }
            : [XCTApplicationLaunchMetric(waitUntilResponsive: false)]
        measure(metrics: metrics, options: options) {
            app.launch(); XCTAssertTrue(app.buttons["addEntry"].waitForExistence(timeout: 60))
            if interactive { XCTAssertTrue(app.tabBars.buttons["Info"].isHittable); XCTAssertEqual(app.alerts.count, 0) }
            app.terminate()
        }
    }
}
