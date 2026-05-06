import SwiftUI

struct MenuView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false
    var userName: String

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(isDarkMode: isDarkMode)
                    .ignoresSafeArea()

                VStack {
                    Text("Codearn")
                        .font(.custom("Arial", size: 100))
                        .bold()
                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        .padding()

                    NavigationLink {
                        LanguageView()
                    } label: {
                        menuButtonLabel("Coding Languages")
                    }
                    NavigationLink {
                        SettingsView()
                    } label: {
                        menuButtonLabel("Settings")
                    }

                    Spacer()
                }

                // Tutorial overlay shown on first launch
                if showTutorial {
                    TutorialOverlayView(isPresented: $showTutorial)
                        .zIndex(10)
                        .onChange(of: showTutorial) { _, newVal in
                            if !newVal { hasSeenTutorial = true }
                        }
                }
            }
        }
        .onAppear {
            if !hasSeenTutorial {
                // Small delay so the view is fully rendered first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation { showTutorial = true }
                }
            }
        }
        // Allow SettingsView to trigger the tutorial replay
        .onReceive(NotificationCenter.default.publisher(for: .replayTutorial)) { _ in
            hasSeenTutorial = false
            withAnimation { showTutorial = true }
        }
    }

    private func menuButtonLabel(_ title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .frame(width: 250, height: 50)
                .foregroundStyle(AppTheme.buttonBackground(isDarkMode: isDarkMode))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.buttonBorder(isDarkMode: isDarkMode), lineWidth: 1)
                )
            Text(title)
                .foregroundStyle(.white)
                .font(.title2)
        }
    }
}

extension Notification.Name {
    static let replayTutorial = Notification.Name("replayTutorial")
}


#Preview {
    MenuView(userName: "Yes")
}



