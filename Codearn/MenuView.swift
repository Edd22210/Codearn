import SwiftUI

struct MenuView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
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
                        AccountView(userName: userName)
                    } label: {
                        menuButtonLabel("Account")
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        menuButtonLabel("Settings")
                    }

                    Spacer()
                }
            }
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


#Preview {
    MenuView(userName: "Yes")
}



