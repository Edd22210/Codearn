import SwiftUI

struct LoginView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State public var userName = String()
    @State var password = String()

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(isDarkMode: isDarkMode)
                    .ignoresSafeArea()

                VStack {
                    Text("Codearn")
                        .font(.largeTitle)
                        .bold()
                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        .padding()

                    TextField("Enter UserName", text: $userName)
                        .textFieldStyle(.roundedBorder)
                        .padding()

                    SecureField("Enter UserName", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding()

                    NavigationLink {
                        MenuView(userName: userName)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 250, height: 50)
                                .foregroundStyle(AppTheme.buttonBackground(isDarkMode: isDarkMode))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(AppTheme.buttonBorder(isDarkMode: isDarkMode), lineWidth: 1)
                                )
                            Text("Login")
                                .foregroundStyle(.white)
                                .font(.title2)
                        }
                    }
                }
            }
        }
    }
}
