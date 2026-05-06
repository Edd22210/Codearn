//
//  CodearnApp.swift
//  Codearn
//
//  Created by Eduardo D. Camacho on 4/22/26.
//

import SwiftUI

enum AppTheme {
    static let darkBackground = Color(red: 0.08, green: 0.08, blue: 0.09)
    static let darkSurface = Color(red: 0.14, green: 0.14, blue: 0.16)

    static func background(isDarkMode: Bool) -> Color {
        isDarkMode ? darkBackground : Color(.systemBackground)
    }

    static func surface(isDarkMode: Bool) -> Color {
        isDarkMode ? darkSurface : Color(.systemGray6)
    }

    static func text(isDarkMode: Bool) -> Color {
        isDarkMode ? .white : .primary
    }

    static func buttonBackground(isDarkMode: Bool) -> Color {
        isDarkMode ? darkSurface : .black
    }

    static func buttonBorder(isDarkMode: Bool) -> Color {
        isDarkMode ? Color.white.opacity(0.2) : Color.clear
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
