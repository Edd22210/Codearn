import SwiftUI

// MARK: - Tutorial Step Model

struct TutorialStep {
    let title: String
    let body: String
    let arrowDirection: ArrowDirection
    /// Absolute Y from top of screen (points). nil = welcome card (centred).
    let anchorAbsoluteY: CGFloat?
    let anchorX: CGFloat  // 0–1 fraction of screen width

    enum ArrowDirection {
        case up, down, none
    }
}

// MARK: - Matrix Rain Column

private struct MatrixColumn: View {
    let x: CGFloat
    let screenHeight: CGFloat
    let symbols: [String]
    let speed: Double
    let opacity: Double

    @State private var offset: CGFloat = 0

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<symbols.count, id: \.self) { i in
                Text(symbols[i])
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(
                        i == symbols.count - 1
                            ? AppTheme.hackerGreen
                            : AppTheme.hackerGreen.opacity(Double(i) / Double(symbols.count) * opacity)
                    )
            }
        }
        .offset(y: offset)
        .onAppear {
            offset = -screenHeight * 0.3
            withAnimation(.linear(duration: speed).repeatForever(autoreverses: false)) {
                offset = screenHeight * 1.1
            }
        }
        .position(x: x, y: screenHeight / 2)
    }
}
// MARK: - Tutorial Overlay

struct TutorialOverlayView: View {
    @Binding var isPresented: Bool
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var currentStep = 0
    @State private var glowPulse = false

    // Left panel: SwiftUI snippets
    private let leftLines = [
        "import SwiftUI",
        "",
        "struct Hero: View {",
        "  @State var xp = 0",
        "  @State var lvl = 1",
        "",
        "  var body: some View {",
        "    VStack {",
        "      Text(\"Lv \\(lvl)\")",
        "        .font(.largeTitle)",
        "        .bold()",
        "      Button(\"Grind\") {",
        "        xp += 100",
        "        if xp >= 500 {",
        "          lvl += 1",
        "          xp = 0",
        "        }",
        "      }",
        "    }",
        "  }",
        "}",
        "",
        "// keep building 🔥",
    ]

    // Right panel: Java + Python
    private let rightLines = [
        "public class Main {",
        "  public static void",
        "    main(String[] a) {",
        "",
        "    int xp = 0;",
        "    int lvl = 1;",
        "",
        "    for (int i = 0;",
        "         i < 100; i++)",
        "      xp += grind(i);",
        "  }",
        "}",
        "",
        "# Python mode",
        "def fib(n):",
        "  if n <= 1:",
        "    return n",
        "  return (fib(n-1)",
        "        + fib(n-2))",
        "",
        "print(fib(10))",
        "# => 55",
        "# hack the planet",
    ]

    // Matrix rain symbol sets
    private let matrixSymbols: [[String]] = [
        ["0","1","0","1","1","0","0","1","0","1","1","0","0","1"],
        ["{","}","(",")","[","]",";","=","<",">","!","?","/","*"],
        ["α","β","λ","Σ","π","δ","∞","√","≠","≤","≥","∈","⊕","∧"],
        ["0","1","0","0","1","1","0","1","0","0","1","0","1","1"],
    ]

    // Steps — anchorAbsoluteY measured from the TOP of the physical screen.
    // MenuView layout (iPhone ~844pt screen, nav bar + status ~96pt):
    //   Nav bar bottom edge   ≈  96pt
    //   "Codearn" title+pad   ≈ 210pt of content  → bottom edge ≈ 306pt
    //   Default VStack spacing ≈ 8pt between items
    //   Button height = 50pt
    //   Button 1 centre (Coding Languages): ≈ 330pt
    //   Button 2 centre (Account):          ≈ 388pt
    //   Button 3 centre (Settings):         ≈ 446pt
    private let steps: [TutorialStep] = [
        TutorialStep(
            title: "Welcome to Codearn",
            body: "Learn to code through interactive lessons, earn XP, and beat boss fights. Let's take a quick tour.",
            arrowDirection: .none,
            anchorAbsoluteY: nil,
            anchorX: 0.5
        ),
        TutorialStep(
            title: "Coding Languages",
            body: "Tap here to pick a language — Java, SwiftUI, Python, or HTML — and start your adventure.",
            arrowDirection: .up,
            anchorAbsoluteY: 330,
            anchorX: 0.5
        ),
        TutorialStep(
            title: "Your Account",
            body: "See your profile, XP earned, and progress across all languages.",
            arrowDirection: .up,
            anchorAbsoluteY: 388,
            anchorX: 0.5
        ),
        TutorialStep(
            title: "Settings",
            body: "Toggle dark mode or replay this tutorial any time from here.",
            arrowDirection: .up,
            anchorAbsoluteY: 446,
            anchorX: 0.5
        ),
    ]

    private var step: TutorialStep { steps[currentStep] }
    private var isLast: Bool { currentStep == steps.count - 1 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dimmed backdrop
                Color.black.opacity(0.80)
                    .ignoresSafeArea()
                    .onTapGesture { advance() }

                // Matrix rain — outermost columns only
                let rainPositions: [CGFloat]  = [12, 26, geo.size.width - 26, geo.size.width - 12]
                let rainSpeeds: [Double]      = [7.5, 11.0, 9.0, 13.5]
                let rainOpacities: [Double]   = [0.38, 0.24, 0.28, 0.34]
                ForEach(0..<4, id: \.self) { i in
                    MatrixColumn(
                        x: rainPositions[i],
                        screenHeight: geo.size.height,
                        symbols: matrixSymbols[i],
                        speed: rainSpeeds[i],
                        opacity: rainOpacities[i]
                    )
                }
                // Spotlight glow + pulsing ring around button
                if let anchorY = step.anchorAbsoluteY {
                    Circle()
                        .fill(AppTheme.hackerGreen.opacity(0.07))
                        .frame(width: 130, height: 130)
                        .position(x: geo.size.width * step.anchorX, y: anchorY)
                        .animation(.easeInOut(duration: 0.4), value: currentStep)

                    Circle()
                        .stroke(AppTheme.hackerGreen.opacity(glowPulse ? 0.0 : 0.78), lineWidth: 2)
                        .frame(
                            width:  glowPulse ? 160 : 112,
                            height: glowPulse ? 160 : 112
                        )
                        .position(x: geo.size.width * step.anchorX, y: anchorY)
                        .animation(
                            .easeOut(duration: 1.3).repeatForever(autoreverses: false),
                            value: glowPulse
                        )
                }

                // Tooltip card
                let cardY: CGFloat = {
                    if let anchorY = step.anchorAbsoluteY {
                        // Place card 86pt below the button centre
                        let proposed = anchorY + 86
                        // Clamp so it doesn't overflow bottom
                        let maxY = geo.size.height - 180
                        return min(proposed, maxY)
                    } else {
                        return geo.size.height * 0.5
                    }
                }()

                VStack(alignment: .leading, spacing: 0) {
                    if step.arrowDirection == .up {
                        Image(systemName: "arrowtriangle.up.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.hackerGreen)
                            .padding(.leading, 36)
                            .padding(.bottom, 1)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(step.title)
                                .font(.system(.headline, design: .monospaced, weight: .bold))
                                .foregroundStyle(AppTheme.hackerGreen)
                            Spacer()
                            Text("\(currentStep + 1) / \(steps.count)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(AppTheme.hackerGreen.opacity(0.55))
                        }

                        Text(step.body)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 12) {
                            // Pill-style step indicator
                            HStack(spacing: 5) {
                                ForEach(0..<steps.count, id: \.self) { i in
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(i == currentStep
                                              ? AppTheme.hackerGreen
                                              : Color.white.opacity(0.20))
                                        .frame(width: i == currentStep ? 20 : 6, height: 6)
                                        .animation(.spring(response: 0.3), value: currentStep)
                                }
                            }
                            Spacer()
                            Button { dismiss() } label: {
                                Text("Skip")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.42))
                            }
                            Button { advance() } label: {
                                Text(isLast ? "Got it ✓" : "Next →")
                                    .font(.system(.subheadline, design: .monospaced, weight: .bold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.hackerGreen)
                                    .foregroundStyle(.black)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                    .padding(18)
                    .background(Color(red: 0.04, green: 0.07, blue: 0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.hackerGreen.opacity(0.45), lineWidth: 1)
                    )
                    .shadow(color: AppTheme.hackerGreen.opacity(0.20), radius: 14)

                    if step.arrowDirection == .down {
                        Image(systemName: "arrowtriangle.down.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.hackerGreen)
                            .padding(.leading, 36)
                            .padding(.top, 1)
                    }
                }
                .padding(.horizontal, 50)  // breathing room from side panels
                .frame(maxWidth: 430)
                .position(x: geo.size.width / 2, y: cardY)
                .animation(.spring(response: 0.38, dampingFraction: 0.80), value: currentStep)
            }
        }
        .ignoresSafeArea()
        .onAppear { glowPulse = true }
        .transition(.opacity)
    }

    private func advance() {
        if isLast { dismiss() }
        else { withAnimation { currentStep += 1 } }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.25)) { isPresented = false }
    }
}
