import SwiftUI

enum AppColor {
    static let green = Color(hex: "#66AD89") // 主色
    static let red   = Color(hex: "#C76B6B")
    static let orange = Color(hex: "#E0A15F")
    static let yellow = Color(hex: "#E6D37A")
    static let blue = Color(hex: "#6B9FC7")
    static let purple = Color(hex: "#9A7BC7")
    static let pink = Color(hex: "#D88AA8")
    static let gray = Color(hex: "#9AA7A0")

    static func from(hex: String) -> Color {
        Color(hex: hex)
    }
}
