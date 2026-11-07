import SwiftUI

/// Calendar navigation changes the selected presentation month, not ledger values.
struct MonthControl: View {
    @Environment(LedgerSession.self) private var session
    @Binding var date: Date
    var title: String { date.formatted(.dateTime.year().month(.wide).locale(session.locale)) }
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.body.weight(.semibold)).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            HStack { previous; Spacer(); next }
        }
    }
    private var previous: some View { Button { shift(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.buttonStyle(.borderless).accessibilityLabel(session.t("previousMonth")) }
    private var next: some View { Button { shift(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }.buttonStyle(.borderless).accessibilityLabel(session.t("nextMonth")) }
    private func shift(_ offset: Int) {
        let calendar = Calendar(identifier: .gregorian)
        guard let first = calendar.date(from: calendar.dateComponents([.year, .month], from: date)), let next = calendar.date(byAdding: .month, value: offset, to: first) else { return }
        date = next
    }
}
