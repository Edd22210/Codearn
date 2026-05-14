import SwiftUI
import UIKit

struct MenuView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false
    @State private var tutorialAnchors: [String: CGPoint] = [:]
    @State private var menuLoaded = false
    var userName: String

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var titleSize: CGFloat { isPad ? 120 : 84 }
    private var buttonWidth: CGFloat { isPad ? 340 : 250 }
    private var buttonHeight: CGFloat { isPad ? 62 : 50 }
    private var contentSpacing: CGFloat { isPad ? 22 : 14 }
    private var topPadding: CGFloat { isPad ? 48 : 20 }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(isDarkMode: isDarkMode)
                    .ignoresSafeArea()
                
                VStack(spacing: contentSpacing) {
                    Text("Codearn")
                        .font(.custom("Arial", size: titleSize))
                        .bold()
                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        .padding(.top, topPadding)
                        .opacity(menuLoaded ? 1 : 0)
                        .offset(y: menuLoaded ? 0 : -18)
                        .animation(.easeOut(duration: 0.75), value: menuLoaded)
                    
                    NavigationLink {
                        LanguageView()
                    } label: {
                        menuButtonLabel("Coding Languages", delay: 0.05)
                    }
                    .simultaneousGesture(TapGesture().onEnded { AppSound.tap() })
                    NavigationLink {
                        CertificatesView(userName: userName)
                    } label: {
                        menuButtonLabel("Certificates", delay: 0.10)
                    }
                    .simultaneousGesture(TapGesture().onEnded { AppSound.tap() })
                    
                    NavigationLink {
                        SettingsView()
                    } label: {
                        menuButtonLabel("Settings", delay: 0.15)
                    }
                    .simultaneousGesture(TapGesture().onEnded { AppSound.tap() })
                    
                    Spacer()
                }
                .frame(maxWidth: isPad ? 520 : 360)
                .padding(.horizontal, 20)
                
                // Tutorial overlay shown on first launch
                if showTutorial {
                    TutorialOverlayView(isPresented: $showTutorial, anchorPoints: tutorialAnchors)
                        .zIndex(10)
                        .onChange(of: showTutorial) { _, newVal in
                            if !newVal { hasSeenTutorial = true }
                        }
                }
            }
            .coordinateSpace(name: "menu")
            .onPreferenceChange(TutorialAnchorPreferenceKey.self) { tutorialAnchors = $0 }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.78)) {
                menuLoaded = true
            }
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
    
    private func menuButtonLabel(_ title: String, delay: Double) -> some View {
        let buttonFill = isDarkMode ? AppTheme.buttonBackground(isDarkMode: true) : AppTheme.surface(isDarkMode: false)
        let buttonText = isDarkMode ? Color.white : AppTheme.text(isDarkMode: false)

        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .frame(width: buttonWidth, height: buttonHeight)
                .foregroundStyle(buttonFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppTheme.buttonBorder(isDarkMode: isDarkMode), lineWidth: 1)
                )
            Text(title)
                .foregroundStyle(buttonText)
                .font(.title2)
        }
        .opacity(menuLoaded ? 1 : 0)
        .offset(y: menuLoaded ? 0 : 20)
        .scaleEffect(menuLoaded ? 1 : 0.96)
        .animation(.interpolatingSpring(stiffness: 200, damping: 18).delay(delay), value: menuLoaded)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: TutorialAnchorPreferenceKey.self,
                    value: [title: CGPoint(x: proxy.frame(in: .named("menu")).midX, y: proxy.frame(in: .named("menu")).midY)]
                )
            }
        )
    }
}

private struct TutorialAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGPoint] = [:]
    
    static func reduce(value: inout [String : CGPoint], nextValue: () -> [String : CGPoint]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct CertificatesView: View {
    let userName: String
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var refreshID = UUID()
    @State private var showCards = false

    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var columns: [GridItem] {
        if isPad {
            return [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]
        }
        return [GridItem(.flexible())]
    }
    
    var body: some View {
        ZStack {
            AppTheme.background(isDarkMode: isDarkMode)
                .ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: isPad ? 20 : 16) {
                    ForEach(Array(CertificateProgressStore.languages.enumerated()), id: \.element) { index, language in
                        certificateCard(for: language, delay: Double(index) * 0.05)
                    }
                }
                .padding(isPad ? 24 : 16)
                .id(refreshID)
            }
        }
        .navigationTitle("Certificates")
        .onAppear {
            refreshID = UUID()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                showCards = true
            }
        }
    }
    
    private func certificateCard(for language: String, delay: Double) -> some View {
        let earned = CertificateProgressStore.isCertificateEarned(language: language)
        let completedChallenges = CertificateProgressStore.completedChallengeCount(language: language)
        let totalChallenges = CertificateProgressStore.totalChallengeCount(language: language)
        let bossCompleted = CertificateProgressStore.isBossCompleted(language: language)
        let style = certificateStyle(for: language)
        
        return ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20)
                .fill(style.gradient)
                .shadow(color: style.accent.opacity(0.25), radius: 18, x: 0, y: 10)
            
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(earned ? Color.yellow.opacity(0.8) : style.accent.opacity(0.55), lineWidth: earned ? 2 : 1)

            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 110, height: 110)
                .padding(.top, 8)
                .padding(.trailing, 8)
            
            Image(systemName: style.iconName)
                .font(.system(size: 80, weight: .black))
                .foregroundStyle(Color.white.opacity(0.16))
                .padding(.top, 12)
                .padding(.trailing, 12)

            VStack(spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(language)
                            .font(.system(.title, design: .monospaced, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text(style.tagline)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.78))
                    }
                    
                    Spacer()
                    
                    Image(systemName: earned ? "rosette.fill" : "lock.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(earned ? Color.yellow : Color.white.opacity(0.86))
                        .padding(10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                
                Text("Certificate of Completion")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.95))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(earned ? "Awarded to \(displayName)" : "Complete every challenge and clear the language boss to unlock.")
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.82))
                    .multilineTextAlignment(.leading)
                
                VStack(alignment: .leading, spacing: 10) {
                    progressRow(title: "Challenges", isComplete: completedChallenges == totalChallenges && totalChallenges > 0, value: "\(completedChallenges)/\(totalChallenges)")
                    progressRow(title: "Boss", isComplete: bossCompleted, value: bossCompleted ? "Cleared" : "Needed")
                }
                .padding(.top, 2)
                
                HStack {
                    Label(style.detailLabel, systemImage: style.detailIcon)
                        .font(.caption.bold())
                        .foregroundStyle(Color.white.opacity(0.9))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                    
                    Spacer()
                    if earned {
                        Text("Earned")
                            .font(.caption.bold())
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(24)
            .padding(.top, 20)
            .blur(radius: earned ? 0 : 5)
            .overlay {
                if !earned {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(isDarkMode ? 0.28 : 0.18))
                }
            }

            if !earned {
                lockOverlay(
                    challengeStatus: "\(completedChallenges)/\(totalChallenges) challenges completed",
                    bossStatus: bossCompleted ? "Boss cleared" : "Boss not cleared"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: isPad ? 280 : 250)
        .opacity(showCards ? 1 : 0)
        .offset(y: showCards ? 0 : 24)
        .scaleEffect(showCards ? 1 : 0.98)
        .animation(.spring(response: 0.75, dampingFraction: 0.78).delay(delay), value: showCards)
    }

    private func lockOverlay(challengeStatus: String, bossStatus: String) -> some View {
        ZStack {
            VStack(spacing: 10) {
                Circle()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: isPad ? 82 : 72, height: isPad ? 82 : 72)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .font(.system(size: isPad ? 30 : 24, weight: .bold))
                            .foregroundStyle(.white)
                    )

                VStack(spacing: 4) {
                    Text("Unlock requirements")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.95))
                    Text(challengeStatus)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                    Text(bossStatus)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.24))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private var displayName: String {
        userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Codearn Student" : userName
    }
    
    private func certificateStyle(for language: String) -> (iconName: String, accent: Color, gradient: LinearGradient, tagline: String, detailLabel: String, detailIcon: String) {
        switch language {
        case "Java":
            return (
                iconName: "cup.and.heat.waves.fill",
                accent: Color.orange,
                gradient: LinearGradient(
                    colors: [Color(red: 0.55, green: 0.22, blue: 0.00), Color(red: 0.90, green: 0.46, blue: 0.00)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                tagline: "Brewed for performance",
                detailLabel: "Write once, run anywhere",
                detailIcon: "flame.fill"
            )
        case "Swift UI":
            return (
                iconName: "swift",
                accent: Color.blue,
                gradient: LinearGradient(
                    colors: [Color(red: 0.08, green: 0.20, blue: 0.42), Color(red: 0.0, green: 0.67, blue: 0.71)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                tagline: "Build sleek Apple interfaces",
                detailLabel: "Fast, modern UI",
                detailIcon: "sparkles"
            )
        case "Python":
            return (
                iconName: "apple.terminal.fill",
                accent: Color.purple,
                gradient: LinearGradient(
                    colors: [Color(red: 0.22, green: 0.00, blue: 0.48), Color(red: 0.54, green: 0.17, blue: 0.89)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                tagline: "Automate, analyze, and explore",
                detailLabel: "Readable, powerful scripts",
                detailIcon: "terminal.fill"
            )
        case "HTML":
            return (
                iconName: "chevron.left.forwardslash.chevron.right",
                accent: Color.cyan,
                gradient: LinearGradient(
                    colors: [Color(red: 0.00, green: 0.32, blue: 0.38), Color(red: 0.00, green: 0.76, blue: 0.65)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                tagline: "Structure the web with style",
                detailLabel: "Markup for modern pages",
                detailIcon: "chevron.left.slash.chevron.right"
            )
        default:
            return (
                iconName: "star.fill",
                accent: AppTheme.accent(isDarkMode: isDarkMode),
                gradient: LinearGradient(
                    colors: [AppTheme.accent(isDarkMode: isDarkMode), AppTheme.accent(isDarkMode: isDarkMode).opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                tagline: "Earned with dedication",
                detailLabel: "Certificate unlocked",
                detailIcon: "seal.fill"
            )
        }
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
