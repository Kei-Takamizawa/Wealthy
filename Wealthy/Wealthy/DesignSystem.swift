import SwiftUI

nonisolated enum V4 {
    nonisolated static func color(_ light: UInt, _ dark: UInt, _ scheme: ColorScheme) -> Color {
        let value = scheme == .dark ? dark : light
        return Color(red: Double((value >> 16) & 0xFF) / 255, green: Double((value >> 8) & 0xFF) / 255, blue: Double(value & 0xFF) / 255)
    }
    static func primary(_ scheme: ColorScheme) -> Color { color(0x2E4A7D, 0xA9C0EE, scheme) }
    static func ok(_ scheme: ColorScheme) -> Color { color(0x2E6B3F, 0x8FD3A0, scheme) }
    static func over(_ scheme: ColorScheme) -> Color { color(0x7B3F63, 0xDDA8C8, scheme) }
    static func watch(_ scheme: ColorScheme) -> Color { color(0x8A5A00, 0xF5CF7A, scheme) }
    static func expense(_ scheme: ColorScheme) -> Color { color(0xA8352A, 0xFF9E8E, scheme) }
}
