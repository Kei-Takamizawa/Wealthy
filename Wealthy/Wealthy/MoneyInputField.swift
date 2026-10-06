import SwiftUI

/// Shows a localized currency amount when idle and an editable, ungrouped amount while focused.
struct MoneyInputField: View {
    @Environment(LedgerSession.self) private var session
    @Binding var text: String
    @FocusState private var isFocused: Bool

    let label: String
    let identifier: String
    let font: Font
    var prompt: Text? = nil
    var foreground: Color? = nil

    var body: some View {
        TextField("", text: Binding(
            get: { isFocused ? text : session.formattedInput(text) },
            set: { text = $0 }
        ), prompt: prompt)
        .focused($isFocused)
        .onChange(of: isFocused) { _, focused in
            guard focused, let value = try? session.parse(text) else { return }
            text = session.input(value)
        }
        .accessibilityLabel(label)
        .keyboardType(.decimalPad)
        .font(font)
        .monospacedDigit()
        .foregroundStyle(foreground ?? Color.primary)
        .frame(minHeight: 52)
        .accessibilityIdentifier(identifier)
    }
}
