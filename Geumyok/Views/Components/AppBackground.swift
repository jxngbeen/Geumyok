import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif

enum AppCornerRadius {
    static let input: CGFloat = 16
    static let card: CGFloat = 18
    static let largeCard: CGFloat = 20
}


struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.05, blue: 0.06),
                Color(red: 0.08, green: 0.10, blue: 0.11),
                Color(red: 0.02, green: 0.04, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}


