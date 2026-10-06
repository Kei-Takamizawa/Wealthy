import Foundation

enum ChatRetentionPolicy {
    static let lifetime: TimeInterval = 24 * 60 * 60

    static func isExpired(_ timestamp: Date, at now: Date) -> Bool {
        now.timeIntervalSince(timestamp) >= lifetime
    }
}
