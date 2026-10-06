import SwiftUI

enum V4 {
    nonisolated static func color(_ light: UInt, _ dark: UInt, _ scheme: ColorScheme) -> Color {
        let v = scheme == .dark ? dark : light
        return Color(red: Double((v >> 16) & 255) / 255, green: Double((v >> 8) & 255) / 255, blue: Double(v & 255) / 255)
    }
    static func paper(_ s: ColorScheme) -> Color { color(0xF5EEE1, 0x1B1915, s) }
    static func ink(_ s: ColorScheme) -> Color { color(0x2A251F, 0xF2EBDD, s) }
    static func ink2(_ s: ColorScheme) -> Color { color(0x5B5247, 0xC2B7A3, s) }
    static func line(_ s: ColorScheme) -> Color { color(0x857660, 0x8C8170, s) }
    static func primary(_ s: ColorScheme) -> Color { color(0x2E4A7D, 0xA9C0EE, s) }
    static func onPrimary(_ s: ColorScheme) -> Color { color(0xFFFFFF, 0x14213A, s) }
    static func ok(_ s: ColorScheme) -> Color { color(0x2E6B3F, 0x8FD3A0, s) }
    static func over(_ s: ColorScheme) -> Color { color(0x7B3F63, 0xDDA8C8, s) }
    static func watch(_ s: ColorScheme) -> Color { color(0x8A5A00, 0xF5CF7A, s) }
    static func expense(_ s: ColorScheme) -> Color { color(0xA8352A, 0xFF9E8E, s) }
    static func sunken(_ s: ColorScheme) -> Color { color(0xEDE3D1, 0x37332B, s) }
    static func heading(_ language: String, size: CGFloat = 34) -> Font {
        let name = language == "ja" ? "WealthyKleeOne-SemiBold" : language == "ko" ? "WealthyPoorStory-Regular" : "WealthyPatrickHand-Regular"
        return .custom(name, size: size, relativeTo: .title)
    }
}
struct Plate<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder var content: Content
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [V4.color(0xFFFFFF, 0x2F2B25, scheme), V4.color(0xFFF8EA, 0x25221E, scheme)], startPoint: .top, endPoint: .bottom), in: .rect(cornerRadius: 28))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(V4.ink(scheme).opacity(0.12), lineWidth: 0.5))
            .shadow(color: scheme == .dark ? .black.opacity(0.38) : V4.ink(scheme).opacity(0.12), radius: 17, y: 14)
    }
}
struct Row<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { content.frame(minHeight: 52).frame(maxWidth: .infinity, alignment: .leading) }
}
enum GlassLevel { case thin, regular, thick }
struct V4Glass: ViewModifier {
    var level: GlassLevel = .regular
    @Environment(\.accessibilityReduceTransparency) private var reduce
    @Environment(\.colorScheme) private var scheme
    func body(content: Content) -> some View {
        if reduce || (LedgerSession.isUITest && ProcessInfo.processInfo.arguments.contains("--opaque")) {
            content.background(V4.paper(scheme), in: .rect(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(V4.line(scheme), lineWidth: 1.5))
        } else {
            switch level {
            case .thin: content.glassEffect(.clear, in: .rect(cornerRadius: 24))
            case .regular: content.glassEffect(.regular, in: .rect(cornerRadius: 24))
            case .thick: content.glassEffect(.regular.tint(V4.paper(scheme).opacity(0.3)), in: .rect(cornerRadius: 24))
            }
        }
    }
}
struct Pill: View {
    @Environment(\.colorScheme) private var scheme
    let text: String
    let icon: String
    var body: some View { Label(text, systemImage: icon).font(.footnote.weight(.semibold)).padding(12).frame(minHeight: 44).modifier(V4Glass(level: .thin)) }
}
struct Sticker: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let label: String
    var body: some View { Label(label, systemImage: icon).font(.callout).foregroundStyle(V4.ok(scheme)).padding(12).background(V4.ok(scheme).opacity(0.12), in: .capsule).accessibilityElement(children: .combine) }
}
struct PrimaryButton: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var systemReduce
    private var reduce: Bool { systemReduce || (LedgerSession.isUITest && ProcessInfo.processInfo.arguments.contains("--reduce-motion")) }
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).multilineTextAlignment(.center).padding(.horizontal, 20).padding(.vertical, 14).frame(minHeight: 52)
            .foregroundStyle(V4.onPrimary(scheme)).background(V4.primary(scheme), in: .rect(cornerRadius: 26))
            .scaleEffect(configuration.isPressed && !reduce ? 0.97 : 1)
            .animation(reduce ? nil : .spring(duration: 0.4, bounce: 0.2), value: configuration.isPressed)
    }
}
