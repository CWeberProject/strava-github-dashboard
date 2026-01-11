import SwiftUI

enum ActivityLevel: Int, CaseIterable {
    case none = 0
    case light = 1
    case moderate = 2
    case active = 3
    case veryActive = 4

    var color: Color {
        switch self {
        case .none:       return Color(hex: "#2D2D2D")
        case .light:      return Color(hex: "#5C3D1E")
        case .moderate:   return Color(hex: "#8B5A2B")
        case .active:     return Color(hex: "#D2691E")
        case .veryActive: return Color(hex: "#FF8C00")
        }
    }

    static func from(minutes: Int) -> ActivityLevel {
        switch minutes {
        case 0:      return .none
        case 1..<30: return .light
        case 30..<60: return .moderate
        case 60..<90: return .active
        default:     return .veryActive
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
