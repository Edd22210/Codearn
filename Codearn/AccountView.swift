import SwiftUI

struct AccountView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    var userName: String

    var body: some View {
        ZStack {
            AppTheme.background(isDarkMode: isDarkMode)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 200, height: 200)
                    .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))

                Text(userName)
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
            }
        }
    }
}
