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
                        CertificatesView(userName: userName)
                    } label: {
                        menuButtonLabel("Certificates")
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

struct CertificatesView: View {
    let userName: String
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var refreshID = UUID()
    
    var body: some View {
        ZStack {
            AppTheme.background(isDarkMode: isDarkMode)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(CertificateProgressStore.languages, id: \.self) { language in
                        certificateCard(for: language)
                    }
                }
                .padding()
                .id(refreshID)
            }
        }
        .navigationTitle("Certificates")
        .onAppear {
            refreshID = UUID()
        }
    }
    
    private func certificateCard(for language: String) -> some View {
        let earned = CertificateProgressStore.isCertificateEarned(language: language)
        let completedChallenges = CertificateProgressStore.completedChallengeCount(language: language)
        let totalChallenges = CertificateProgressStore.totalChallengeCount(language: language)
        let bossCompleted = CertificateProgressStore.isBossCompleted(language: language)
        
        return VStack(spacing: 14) {
            HStack {
                Image(systemName: earned ? "rosette" : "lock.fill")
                    .font(.title)
                    .foregroundStyle(earned ? .yellow : .gray)
                Spacer()
                Text(earned ? "EARNED" : "LOCKED")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((earned ? Color.green : Color.gray).opacity(0.16))
                    .foregroundStyle(earned ? .green : .gray)
                    .clipShape(Capsule())
            }
            
            VStack(spacing: 6) {
                Text("Certificate of Completion")
                    .font(.title2.bold())
                Text(language)
                    .font(.system(.title, design: .monospaced, weight: .bold))
                    .foregroundStyle(earned ? .blue : AppTheme.text(isDarkMode: isDarkMode).opacity(0.7))
                Text(earned ? "Awarded to \(displayName)" : "Complete every challenge and clear the language boss to unlock.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode).opacity(0.75))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                progressRow(title: "Challenges", isComplete: completedChallenges == totalChallenges && totalChallenges > 0, value: "\(completedChallenges)/\(totalChallenges)")
                progressRow(title: "Boss", isComplete: bossCompleted, value: bossCompleted ? "Cleared" : "Needed")
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface(isDarkMode: isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(earned ? Color.yellow.opacity(0.7) : AppTheme.buttonBorder(isDarkMode: isDarkMode), lineWidth: earned ? 2 : 1)
        )
    }
    
    private var displayName: String {
        userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Codearn Student" : userName
    }
    
    private func progressRow(title: String, isComplete: Bool, value: String) -> some View {
        HStack {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? .green : .gray)
            Text(title)
                .font(.subheadline.bold())
            Spacer()
            Text(value)
                .font(.caption.bold())
                .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode).opacity(0.75))
        }
    }
}

extension Notification.Name {
    static let replayTutorial = Notification.Name("replayTutorial")
}


#Preview {
    MenuView(userName: "Yes")
}



