import SwiftUI

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

enum Theme {
    static let headerGradient = LinearGradient(
        colors: [Color(hex: 0x0F7F9C), Color(hex: 0x0E7490), Color(hex: 0x134E6B)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let background = Color(hex: 0xF2F7FA)
    static let card = Color.white
    static let primary = Color(hex: 0x0E7490)

    static func clsColor(_ cls: String) -> Color {
        switch cls {
        case "PMO": return Color(hex: 0x0E7490)
        case "OTC": return Color(hex: 0x059669)
        case "UH":  return Color(hex: 0xDC2626)
        case "VET": return Color(hex: 0x7C3AED)
        default:    return Color(hex: 0x94A3B8)
        }
    }

    static func clsName(_ cls: String) -> String {
        DrugRepository.clsOrder.first { $0.code == cls }?.label ?? "未分類"
    }

    /// 千分位格式: 9126 → "9,126"
    static func fmt(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = ","
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}