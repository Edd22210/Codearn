import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isDeveloperMode") private var isDeveloperMode = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var tutorialConfirmed = false

    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $isDarkMode)
            }

            Section("Help") {
                Button {
                    hasSeenTutorial = false
                    NotificationCenter.default.post(name: .replayTutorial, object: nil)
                    tutorialConfirmed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        tutorialConfirmed = false
                    }
                } label: {
                    HStack {
                        Label("Replay Tutorial", systemImage: "questionmark.circle.fill")
                            .foregroundStyle(AppTheme.accent(isDarkMode: isDarkMode))
                        Spacer()
                        if tutorialConfirmed {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3), value: tutorialConfirmed)
                }
                Text("Shows the intro walkthrough again on the main menu.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
