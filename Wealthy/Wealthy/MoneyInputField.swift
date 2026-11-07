import SwiftUI

/// Shows a localized currency amount when idle and an editable, ungrouped amount while focused.
struct MoneyInputField: View {
    @Environment(LedgerSession.self) private var session
    @Binding var text: String
    @FocusState private var internalFocus: Bool

    let label: String
    let identifier: String
    let font: Font
    var currencyCode: String? = nil
    var prompt: Text? = nil
    var foreground: Color? = nil
    var focus: FocusState<Bool>.Binding? = nil

    private var isFocused: Bool { (focus ?? $internalFocus).wrappedValue }

    var body: some View {
        TextField("", text: Binding(
            get: { isFocused ? text : session.formattedInput(text, code: currencyCode) },
            set: { text = $0 }
        ), prompt: prompt)
        .focused(focus ?? $internalFocus)
        .onChange(of: isFocused) { _, focused in
            guard focused, let value = try? session.parse(text, code: currencyCode) else { return }
            text = session.input(value, code: currencyCode)
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
