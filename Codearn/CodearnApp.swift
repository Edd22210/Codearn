//
//  CodearnApp.swift
//  Codearn
//
//  Created by Eduardo D. Camacho & Evelyn V. Huber on 4/22/26.
//

import SwiftUI

enum AppTheme {
    // Hacker palette
    static let hackerGreen       = Color(red: 0.00, green: 1.00, blue: 0.42)   // #00FF6B
    static let hackerGreenDim    = Color(red: 0.00, green: 0.75, blue: 0.32)   // #00BF51
    static let hackerGreenGlow   = Color(red: 0.00, green: 1.00, blue: 0.42).opacity(0.18)
    static let darkBackground    = Color(red: 0.04, green: 0.05, blue: 0.04)   // near-black with green tint
    static let darkSurface       = Color(red: 0.08, green: 0.11, blue: 0.08)   // dark green-tinted panel
    static let lightBackground   = Color(red: 0.94, green: 0.97, blue: 0.94)
    static let lightSurface      = Color(red: 0.87, green: 0.92, blue: 0.87)

    static func background(isDarkMode: Bool) -> Color {
        isDarkMode ? darkBackground : lightBackground
    }

    static func surface(isDarkMode: Bool) -> Color {
        isDarkMode ? darkSurface : lightSurface
    }

    static func text(isDarkMode: Bool) -> Color {
        isDarkMode ? hackerGreen : Color(red: 0.08, green: 0.22, blue: 0.08)
    }

    static func buttonBackground(isDarkMode: Bool) -> Color {
        isDarkMode ? darkSurface : Color(red: 0.06, green: 0.18, blue: 0.06)
    }

    static func buttonBorder(isDarkMode: Bool) -> Color {
        isDarkMode ? hackerGreen.opacity(0.55) : hackerGreenDim.opacity(0.6)
    }

    // Accent used for highlights, progress bars, active states
    static func accent(isDarkMode: Bool) -> Color {
        isDarkMode ? hackerGreen : hackerGreenDim
    }
}

@main
struct CodearnApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false

    var body: some Scene {
        WindowGroup {
            MenuView(userName: "T")
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .tint(isDarkMode ? .white : .blue)
        }
    }
}
