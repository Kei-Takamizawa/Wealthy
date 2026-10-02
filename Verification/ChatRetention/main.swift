import Foundation

// Run from the repository root:
// swiftc Wealthy/Wealthy/ChatRetentionPolicy.swift Verification/ChatRetention/main.swift -o /tmp/wealthy-chat-retention-checks
// /tmp/wealthy-chat-retention-checks
let now = Date(timeIntervalSince1970: 2_000_000_000)
let cases: [(label: String, age: TimeInterval, expected: Bool)] = [
    ("just under 24 hours", ChatRetentionPolicy.lifetime - 0.001, false),
    ("exactly 24 hours", ChatRetentionPolicy.lifetime, true),
    ("just over 24 hours", ChatRetentionPolicy.lifetime + 0.001, true),
    ("future timestamp", -1, false)
]

let failures = cases.compactMap { sample -> String? in
    let timestamp = now.addingTimeInterval(-sample.age)
    let actual = ChatRetentionPolicy.isExpired(timestamp, at: now)
    return actual == sample.expected ? nil : "\(sample.label): expected \(sample.expected), got \(actual)"
}

if failures.isEmpty {
    print("Passed \(cases.count) chat retention boundary checks.")
} else {
    failures.forEach { print("FAIL: \($0)") }
    exit(1)
}
