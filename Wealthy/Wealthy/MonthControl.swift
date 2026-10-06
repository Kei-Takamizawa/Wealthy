import SwiftUI

/// Calendar navigation changes the selected presentation month, not ledger values.
struct MonthControl: View {
    @Environment(LedgerSession.self) private var session
    @Environment(\.dynamicTypeSize) private var typeSize
    @Binding var date: Date
    var title: String { date.formatted(.dateTime.year().month(.wide).locale(session.locale)) }
    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: 8) { Text(title).font(.title3.bold()).multilineTextAlignment(.center); HStack { previous; Spacer(); next } }
        } else { HStack { previous; Spacer(); Text(title).font(.headline); Spacer(); next } }
    }
    private var previous: some View { Button { shift(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.accessibilityLabel(session.t("previousMonth")) }
    private var next: some View { Button { shift(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }.accessibilityLabel(session.t("nextMonth")) }
    private func shift(_ offset: Int) {
        let calendar = Calendar(identifier: .gregorian)
        guard let first = calendar.date(from: calendar.dateComponents([.year, .month], from: date)), let next = calendar.date(byAdding: .month, value: offset, to: first) else { return }
        date = next
    }
}
