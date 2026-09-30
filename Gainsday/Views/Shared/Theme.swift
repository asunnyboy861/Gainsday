import SwiftUI

enum Theme {
    static let charcoal = Color(uiColor: .systemBackground)
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let orange = Color(red: 1.0, green: 0.45, blue: 0.1)
    static let gold = Color(red: 1.0, green: 0.78, blue: 0.2)
    static let cyan = Color(red: 0.2, green: 0.8, blue: 0.9)

    static func rounded(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
