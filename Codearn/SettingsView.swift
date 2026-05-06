import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isDeveloperMode") private var isDeveloperMode = false

    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $isDarkMode)
            }
            
            Section("Developer") {
                Toggle("Developer Mode", isOn: $isDeveloperMode)
                Text("Unlocks every SwiftUI adventure lesson for testing without completing the path.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.background(isDarkMode: isDarkMode))
        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
        .navigationTitle("Settings")
    }
}
