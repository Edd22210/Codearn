import SwiftUI

// MARK: - Models

enum LessonStep: Identifiable {
    case info(id: UUID = UUID(), title: String, body: String, code: String?)
    case multipleChoice(id: UUID = UUID(), question: String, choices: [String], correctIndex: Int, explanation: String)
    case fillBlank(id: UUID = UUID(), prompt: String, codePrefix: String, answer: String, codeSuffix: String, hint: String)
    
    var id: UUID {
        switch self {
        case .info(let id, _, _, _): return id
        case .multipleChoice(let id, _, _, _, _): return id
        case .fillBlank(let id, _, _, _, _, _): return id
        }
    }
}

struct Lesson: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let steps: [LessonStep]
}

struct CodingChallenge: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let difficulty: String // "Beginner" / "Intermediate" / "Advanced"
    let description: String
    let starterCode: String
    let solutionCode: String
    let hints: [String]
    let testCases: [String] // descriptions of what correct output looks like
}

// MARK: - Interactive Lesson View

struct InteractiveLessonView: View {
    private enum LessonPhase: Int, CaseIterable {
        case explain
        case example
        case task
        case check
    }
    
    let lesson: Lesson
    var onComplete: (() -> Void)? = nil
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var currentStep = 0
    @State private var selectedChoice: Int? = nil
    @State private var fillAnswer = ""
    @State private var answered = false
    @State private var isCorrect = false
    @State private var showExplanation = false
    @State private var lessonComplete = false
    @Environment(\.dismiss) private var dismiss
    
    var step: LessonStep { lesson.steps[currentStep] }
    var progress: Double { Double(currentStep) / Double(lesson.steps.count) }
    
    private var currentPhase: LessonPhase {
        switch step {
        case .info(_, _, _, let code):
            return code == nil ? .explain : .example
        case .multipleChoice:
            return currentStep == lesson.steps.count - 1 ? .check : .task
        case .fillBlank:
            return currentStep == lesson.steps.count - 1 ? .check : .task
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.background(isDarkMode: isDarkMode)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(AppTheme.surface(isDarkMode: isDarkMode))
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geo.size.width * progress)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(height: 6)
                
                if lessonComplete {
                    completionView
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            lessonHeader
                            phaseTracker
                            
                            switch step {
                            case .info(_, let title, let body, let code):
                                infoStep(title: title, body: body, code: code)
                            case .multipleChoice(_, let question, let choices, let correctIndex, let explanation):
                                multipleChoiceStep(question: question, choices: choices, correctIndex: correctIndex, explanation: explanation)
                            case .fillBlank(_, let prompt, let codePrefix, let answer, let codeSuffix, let hint):
                                fillBlankStep(prompt: prompt, codePrefix: codePrefix, answer: answer, codeSuffix: codeSuffix, hint: hint)
                            }
                        }
                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        .padding()
                    }
                    
                    VStack {
                        Divider()
                        nextButton.padding()
                    }
                }
            }
        }
        .navigationTitle(lesson.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func infoStep(title: String, body: String, code: String?) -> some View {
        lessonCard(title: currentPhaseTitle) {
            Text(title).font(.title2).bold()
            Text(body).font(.body)
            if let code = code {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Original Example").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(code)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                    .background(AppTheme.background(isDarkMode: isDarkMode))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
    
    func multipleChoiceStep(question: String, choices: [String], correctIndex: Int, explanation: String) -> some View {
        lessonCard(title: currentPhaseTitle) {
            Text(question).font(.title2).bold()
            ForEach(choices.indices, id: \.self) { i in
                Button {
                    if !answered {
                        selectedChoice = i
                        isCorrect = (i == correctIndex)
                        answered = true
                        showExplanation = true
                    }
                } label: {
                    HStack {
                        Text(choices[i]).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode)).multilineTextAlignment(.leading)
                        Spacer()
                        if answered {
                            if i == correctIndex { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                            else if i == selectedChoice { Image(systemName: "xmark.circle.fill").foregroundStyle(.red) }
                        }
                    }
                    .padding()
                    .background(choiceBackground(index: i, correct: correctIndex))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(choiceBorder(index: i, correct: correctIndex), lineWidth: 2))
                }
                .disabled(answered)
            }
            if showExplanation {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: isCorrect ? "lightbulb.fill" : "info.circle.fill")
                        .foregroundStyle(isCorrect ? .yellow : .blue)
                    Text(explanation).font(.callout).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                }
                .padding()
                .background(AppTheme.background(isDarkMode: isDarkMode))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.opacity)
            }
        }
    }
    
    func choiceBackground(index: Int, correct: Int) -> Color {
        guard answered else { return AppTheme.surface(isDarkMode: isDarkMode) }
        if index == correct { return Color.green.opacity(0.15) }
        if index == selectedChoice { return Color.red.opacity(0.15) }
        return AppTheme.surface(isDarkMode: isDarkMode)
    }
    
    func choiceBorder(index: Int, correct: Int) -> Color {
        guard answered else { return Color.clear }
        if index == correct { return .green }
        if index == selectedChoice { return .red }
        return Color.clear
    }
    
    func fillBlankStep(prompt: String, codePrefix: String, answer: String, codeSuffix: String, hint: String) -> some View {
        lessonCard(title: currentPhaseTitle) {
            Text(prompt).font(.title2).bold()
            Text("Fill in the blank to complete the code:").font(.subheadline).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 0) {
                    Text(codePrefix).font(.system(.body, design: .monospaced))
                    TextField("?", text: $fillAnswer)
                        .font(.system(.body, design: .monospaced))
                        .frame(minWidth: 60)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(answered ? (isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)) : Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(answered ? (isCorrect ? Color.green : Color.red) : Color.blue, lineWidth: 1.5))
                        .disabled(answered)
                    Text(codeSuffix).font(.system(.body, design: .monospaced))
                }
                .padding()
            }
            .background(AppTheme.background(isDarkMode: isDarkMode))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            if !answered {
                HStack {
                    Image(systemName: "questionmark.circle").foregroundStyle(.blue)
                    Text("Hint: \(hint)").font(.caption).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                }
            }
            if answered {
                HStack(spacing: 8) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(isCorrect ? .green : .red)
                    Text(isCorrect ? "Correct! Great job." : "Not quite. The answer is \"\(answer)\".")
                        .font(.callout).foregroundStyle(isCorrect ? .green : .red)
                }
                .padding()
                .background((isCorrect ? Color.green : Color.red).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    var lessonHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lesson.title)
                .font(.title2.bold())
            Text("Step \(currentStep + 1) of \(lesson.steps.count)")
                .font(.caption.bold())
                .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode).opacity(0.7))
        }
        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
        .padding(.top)
    }
    
    var phaseTracker: some View {
        HStack(spacing: 10) {
            ForEach(Array(LessonPhase.allCases.enumerated()), id: \.offset) { index, phase in
                VStack(spacing: 6) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .frame(width: 28, height: 28)
                        .background(phaseBackground(for: phase))
                        .foregroundStyle(phaseForeground(for: phase))
                        .clipShape(Circle())
                    Text(title(for: phase))
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode).opacity(currentPhase.rawValue >= phase.rawValue ? 0.9 : 0.45))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    var currentPhaseTitle: String {
        title(for: currentPhase)
    }
    
    private func title(for phase: LessonPhase) -> String {
        switch phase {
        case .explain: return "Explain"
        case .example: return "Example"
        case .task: return "Task"
        case .check: return "Check"
        }
    }
    
    private func phaseBackground(for phase: LessonPhase) -> Color {
        currentPhase.rawValue >= phase.rawValue ? .blue : Color.gray.opacity(0.2)
    }
    
    private func phaseForeground(for phase: LessonPhase) -> Color {
        currentPhase.rawValue >= phase.rawValue ? .white : .gray
    }
    
    func lessonCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.blue)
            content()
        }
        .padding(18)
        .background(AppTheme.surface(isDarkMode: isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    var nextButton: some View {
        Button {
            switch step {
            case .info:
                advance()
            case .multipleChoice:
                if answered { advance() }
            case .fillBlank(_, _, _, let answer, _, _):
                if !answered {
                    isCorrect = fillAnswer.trimmingCharacters(in: .whitespaces).lowercased() == answer.lowercased()
                    answered = true
                } else {
                    advance()
                }
            }
        } label: {
            HStack {
                Spacer()
                Text(buttonLabel).bold()
                Spacer()
            }
            .padding()
            .background(buttonEnabled ? Color.blue : Color(.systemGray4))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!buttonEnabled)
    }
    
    var buttonLabel: String {
        switch step {
        case .info: return currentStep == lesson.steps.count - 1 ? "Finish" : "Continue"
        case .multipleChoice: return answered ? (currentStep == lesson.steps.count - 1 ? "Finish" : "Next") : "Choose an answer"
        case .fillBlank:
            if !answered { return "Check Answer" }
            return currentStep == lesson.steps.count - 1 ? "Finish" : "Next"
        }
    }
    
    var buttonEnabled: Bool {
        switch step {
        case .info: return true
        case .multipleChoice: return answered
        case .fillBlank:
            if answered { return true }
            return !fillAnswer.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    func advance() {
        if currentStep + 1 >= lesson.steps.count {
            lessonComplete = true
        } else {
            currentStep += 1
            selectedChoice = nil
            fillAnswer = ""
            answered = false
            isCorrect = false
            showExplanation = false
        }
    }
    
    var completionView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "star.fill").font(.system(size: 80)).foregroundStyle(.yellow)
            Text("Lesson Complete!").font(.largeTitle).bold()
            Text("You finished \"\(lesson.title)\".").font(.title3).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode)).multilineTextAlignment(.center)
            Spacer()
            Button { dismiss() } label: {
                Text("Back to Lessons").bold()
                    .frame(maxWidth: .infinity).padding()
                    .background(Color.blue).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .padding()
        .onAppear {
            onComplete?()
        }
    }
}

// MARK: - Coding Challenge View

struct CodingChallengeDetailView: View {
    let challenge: CodingChallenge
    var onComplete: (() -> Void)? = nil
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var userCode: String = ""
    @State private var showSolution = false
    @State private var showHints = false
    @State private var currentHint = 0
    @State private var submitted = false
    @Environment(\.dismiss) private var dismiss
    
    var difficultyColor: Color {
        switch challenge.difficulty {
        case "Beginner": return .green
        case "Intermediate": return .orange
        default: return .red
        }
    }
    
    init(challenge: CodingChallenge, onComplete: (() -> Void)? = nil) {
        self.challenge = challenge
        self.onComplete = onComplete
        _userCode = State(initialValue: challenge.starterCode)
    }
    
    var body: some View {
        ZStack {
            AppTheme.background(isDarkMode: isDarkMode)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                
                    // Header
                    HStack {
                        Image(systemName: challenge.icon).font(.title).foregroundStyle(.white)
                        VStack(alignment: .leading) {
                            Text(challenge.title).font(.title2).bold()
                            Text(challenge.difficulty)
                                .font(.caption).bold()
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(difficultyColor.opacity(0.15))
                                .foregroundStyle(isDarkMode ? .white : difficultyColor)
                                .clipShape(Capsule())
                        }
                        Spacer()
                    }
                
                    Divider()
                
                    // Description
                    Text("Challenge").font(.headline)
                    Text(challenge.description).font(.body).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                
                    // Expected output
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Expected Output:").font(.headline)
                        ForEach(challenge.testCases, id: \.self) { tc in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle").foregroundStyle(.green)
                                Text(tc).font(.system(.callout, design: .monospaced))
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                    // Code Editor
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Your Code:").font(.headline)
                            Spacer()
                            Button {
                                userCode = challenge.starterCode
                                submitted = false
                                showSolution = false
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                            }
                        }
                        TextEditor(text: $userCode)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .padding(8)
                            .scrollContentBackground(.hidden)
                            .background(AppTheme.surface(isDarkMode: isDarkMode))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.buttonBorder(isDarkMode: isDarkMode), lineWidth: 1))
                    }
                
                    // Hints
                    if !challenge.hints.isEmpty {
                        Button {
                            withAnimation { showHints.toggle() }
                        } label: {
                            Label(showHints ? "Hide Hints" : "Show a Hint", systemImage: "lightbulb.fill")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        }
                    
                        if showHints {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(0...currentHint, id: \.self) { i in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("\(i + 1).").bold().foregroundStyle(.white)
                                        Text(challenge.hints[i]).font(.callout)
                                    }
                                }
                                if currentHint < challenge.hints.count - 1 {
                                    Button("Next Hint →") { currentHint += 1 }
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                                }
                            }
                            .padding()
                            .background(Color.orange.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .transition(.opacity)
                        }
                    }
                
                    // Submit / Solution buttons
                    Button {
                        submitted = true
                        onComplete?()
                    } label: {
                        Text("Submit Solution")
                            .bold().frame(maxWidth: .infinity).padding()
                            .background(Color.blue).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                
                    if submitted {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                                Text("Nice work submitting! Run your code in Xcode or a playground to verify the output matches above.")
                                    .font(.callout)
                                    .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                
                    Button {
                        withAnimation { showSolution.toggle() }
                    } label: {
                        Label(showSolution ? "Hide Solution" : "Show Solution", systemImage: "eye.fill")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                    }
                
                    if showSolution {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Solution:").font(.headline)
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(challenge.solutionCode)
                                    .font(.system(.body, design: .monospaced))
                                    .padding()
                            }
                            .background(AppTheme.surface(isDarkMode: isDarkMode))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .transition(.opacity)
                    }
                }
                .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                .padding()
            }
        }
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Challenges List View

struct ChallengesView: View {
    let language: String
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var challenges: [CodingChallenge] {
        switch language {
            
            // ── JAVA CHALLENGES ───────────────────────────────────
        case "Java":
            return [
                CodingChallenge(
                    title: "Say Hello",
                    icon: "hand.wave.fill",
                    difficulty: "Beginner",
                    description: "Write a Java program that prints 'Hello, Codearn!' to the console.",
                    starterCode: "public class Main {\n    public static void main(String[] args) {\n        // Write your code here\n        \n    }\n}",
                    solutionCode: "public class Main {\n    public static void main(String[] args) {\n        System.out.println(\"Hello, Codearn!\");\n    }\n}",
                    hints: ["Use System.out.println()", "Put the text inside double quotes"],
                    testCases: ["Hello, Codearn!"]
                ),
                CodingChallenge(
                    title: "Sum of Two Numbers",
                    icon: "plus.circle.fill",
                    difficulty: "Beginner",
                    description: "Declare two integer variables a = 7 and b = 3, then print their sum.",
                    starterCode: "public class Main {\n    public static void main(String[] args) {\n        // Declare a and b\n        \n        // Print their sum\n        \n    }\n}",
                    solutionCode: "public class Main {\n    public static void main(String[] args) {\n        int a = 7;\n        int b = 3;\n        System.out.println(a + b);\n    }\n}",
                    hints: ["Use int to declare variables", "Use + to add them", "Print the result with System.out.println()"],
                    testCases: ["10"]
                ),
                CodingChallenge(
                    title: "Even or Odd",
                    icon: "divide.circle.fill",
                    difficulty: "Beginner",
                    description: "Write a program that checks if the number 14 is even or odd and prints the result.",
                    starterCode: "public class Main {\n    public static void main(String[] args) {\n        int number = 14;\n        // Use if/else and the % operator\n        \n    }\n}",
                    solutionCode: "public class Main {\n    public static void main(String[] args) {\n        int number = 14;\n        if (number % 2 == 0) {\n            System.out.println(\"Even\");\n        } else {\n            System.out.println(\"Odd\");\n        }\n    }\n}",
                    hints: ["Use % (modulo) to find the remainder", "If number % 2 == 0, it's even", "Use if/else to print the result"],
                    testCases: ["Even"]
                ),
                CodingChallenge(
                    title: "Count to 10",
                    icon: "list.number",
                    difficulty: "Beginner",
                    description: "Use a for loop to print the numbers 1 through 10, each on its own line.",
                    starterCode: "public class Main {\n    public static void main(String[] args) {\n        // Use a for loop\n        \n    }\n}",
                    solutionCode: "public class Main {\n    public static void main(String[] args) {\n        for (int i = 1; i <= 10; i++) {\n            System.out.println(i);\n        }\n    }\n}",
                    hints: ["Start your loop at i = 1", "Run while i <= 10", "Increment with i++"],
                    testCases: ["1", "2", "3", "... up to 10"]
                ),
                CodingChallenge(
                    title: "Multiplication Table",
                    icon: "xmark.circle.fill",
                    difficulty: "Intermediate",
                    description: "Print the multiplication table for 5 (5x1 through 5x10).",
                    starterCode: "public class Main {\n    public static void main(String[] args) {\n        // Loop from 1 to 10\n        \n    }\n}",
                    solutionCode: "public class Main {\n    public static void main(String[] args) {\n        for (int i = 1; i <= 10; i++) {\n            System.out.println(\"5 x \" + i + \" = \" + (5 * i));\n        }\n    }\n}",
                    hints: ["Use a for loop from 1 to 10", "Multiply 5 * i inside the loop", "Concatenate strings with +"],
                    testCases: ["5 x 1 = 5", "5 x 2 = 10", "... 5 x 10 = 50"]
                ),
                CodingChallenge(
                    title: "FizzBuzz",
                    icon: "sparkles",
                    difficulty: "Intermediate",
                    description: "Print numbers 1–20. For multiples of 3 print 'Fizz', for multiples of 5 print 'Buzz', for both print 'FizzBuzz'.",
                    starterCode: "public class Main {\n    public static void main(String[] args) {\n        for (int i = 1; i <= 20; i++) {\n            // Your logic here\n            \n        }\n    }\n}",
                    solutionCode: "public class Main {\n    public static void main(String[] args) {\n        for (int i = 1; i <= 20; i++) {\n            if (i % 3 == 0 && i % 5 == 0) {\n                System.out.println(\"FizzBuzz\");\n            } else if (i % 3 == 0) {\n                System.out.println(\"Fizz\");\n            } else if (i % 5 == 0) {\n                System.out.println(\"Buzz\");\n            } else {\n                System.out.println(i);\n            }\n        }\n    }\n}",
                    hints: ["Check FizzBuzz first (divisible by both 3 and 5)", "Use % to check divisibility", "Use else if to chain conditions"],
                    testCases: ["1", "2", "Fizz", "4", "Buzz", "Fizz", "...", "FizzBuzz (at 15)"]
                )
            ]
            
            // ── SWIFTUI CHALLENGES ────────────────────────────────
        case "Swift UI":
            return [
                CodingChallenge(
                    title: "Hello Label",
                    icon: "text.bubble.fill",
                    difficulty: "Beginner",
                    description: "Create a view that displays 'Hello, Codearn!' in a large, bold, blue font.",
                    starterCode: "struct HelloView: View {\n    var body: some View {\n        // Add your Text view here\n        \n    }\n}",
                    solutionCode: "struct HelloView: View {\n    var body: some View {\n        Text(\"Hello, Codearn!\")\n            .font(.largeTitle)\n            .bold()\n            .foregroundStyle(.blue)\n    }\n}",
                    hints: ["Use a Text view", "Chain .font(.largeTitle)", "Add .foregroundStyle(.blue)"],
                    testCases: ["Shows 'Hello, Codearn!' in large bold blue text"]
                ),
                CodingChallenge(
                    title: "Tap Counter",
                    icon: "hand.tap.fill",
                    difficulty: "Beginner",
                    description: "Build a view with a number that starts at 0 and a button that increases it by 1 each tap.",
                    starterCode: "struct CounterView: View {\n    // Add your @State variable here\n    \n    var body: some View {\n        VStack {\n            // Show the count\n            // Add a button\n        }\n    }\n}",
                    solutionCode: "struct CounterView: View {\n    @State private var count = 0\n\n    var body: some View {\n        VStack(spacing: 20) {\n            Text(\"\\(count)\")\n                .font(.system(size: 72, weight: .bold))\n            Button(\"Tap Me\") {\n                count += 1\n            }\n            .font(.title2)\n        }\n    }\n}",
                    hints: ["Declare @State private var count = 0", "Display count with Text(\"\\(count)\")", "Increment count inside the Button action"],
                    testCases: ["Shows 0 on launch", "Number increases by 1 each tap"]
                ),
                CodingChallenge(
                    title: "Color Card",
                    icon: "rectangle.fill",
                    difficulty: "Beginner",
                    description: "Create a rounded card with a blue background, white text saying 'SwiftUI', and padding.",
                    starterCode: "struct ColorCard: View {\n    var body: some View {\n        // Build your card here\n        \n    }\n}",
                    solutionCode: "struct ColorCard: View {\n    var body: some View {\n        Text(\"SwiftUI\")\n            .font(.largeTitle)\n            .bold()\n            .foregroundStyle(.white)\n            .padding(40)\n            .background(Color.blue)\n            .clipShape(RoundedRectangle(cornerRadius: 20))\n    }\n}",
                    hints: ["Start with a Text view", "Use .background(Color.blue)", "Use .clipShape(RoundedRectangle(cornerRadius: 20))"],
                    testCases: ["Blue rounded card", "White 'SwiftUI' text centered inside"]
                ),
                CodingChallenge(
                    title: "Toggle Switch",
                    icon: "switch.2",
                    difficulty: "Intermediate",
                    description: "Build a view with a Toggle. When on, show 'Lights On 💡'. When off, show 'Lights Off 🌑'.",
                    starterCode: "struct LightSwitch: View {\n    @State private var isOn = false\n\n    var body: some View {\n        VStack(spacing: 30) {\n            // Show the status text\n            \n            // Add the Toggle\n            \n        }\n        .padding()\n    }\n}",
                    solutionCode: "struct LightSwitch: View {\n    @State private var isOn = false\n\n    var body: some View {\n        VStack(spacing: 30) {\n            Text(isOn ? \"Lights On 💡\" : \"Lights Off 🌑\")\n                .font(.largeTitle)\n            Toggle(\"Light Switch\", isOn: $isOn)\n                .padding(.horizontal)\n        }\n        .padding()\n    }\n}",
                    hints: ["Use a ternary: isOn ? \"On\" : \"Off\"", "Toggle needs a binding: isOn: $isOn", "Wrap in a VStack"],
                    testCases: ["Shows 'Lights Off 🌑' initially", "Toggling shows 'Lights On 💡'"]
                ),
                CodingChallenge(
                    title: "Profile Card",
                    icon: "person.crop.circle.fill",
                    difficulty: "Intermediate",
                    description: "Build a profile card with a circular avatar (any system image), a name, and a subtitle below it.",
                    starterCode: "struct ProfileCard: View {\n    var body: some View {\n        VStack(spacing: 12) {\n            // Avatar circle\n            \n            // Name\n            \n            // Subtitle\n        }\n        .padding()\n        .background(Color(.systemGray6))\n        .clipShape(RoundedRectangle(cornerRadius: 20))\n    }\n}",
                    solutionCode: "struct ProfileCard: View {\n    var body: some View {\n        VStack(spacing: 12) {\n            Image(systemName: \"person.circle.fill\")\n                .font(.system(size: 80))\n                .foregroundStyle(.blue)\n            Text(\"Alex Coder\")\n                .font(.title2)\n                .bold()\n            Text(\"iOS Developer\")\n                .font(.subheadline)\n                .foregroundStyle(.secondary)\n        }\n        .padding(30)\n        .background(Color(.systemGray6))\n        .clipShape(RoundedRectangle(cornerRadius: 20))\n    }\n}",
                    hints: ["Use Image(systemName:) for the avatar", "Set a large font size with .font(.system(size: 80))", "Use .foregroundStyle(.secondary) for the subtitle"],
                    testCases: ["Circular avatar at top", "Name in bold below", "Subtitle in gray below name"]
                ),
                CodingChallenge(
                    title: "List of Items",
                    icon: "list.bullet.rectangle.fill",
                    difficulty: "Intermediate",
                    description: "Create a List that shows at least 5 programming languages, each with a globe icon on the left.",
                    starterCode: "struct LanguageList: View {\n    let languages = [\"Swift\", \"Python\", \"Java\", \"HTML\", \"JavaScript\"]\n\n    var body: some View {\n        // Build your List here\n        \n    }\n}",
                    solutionCode: "struct LanguageList: View {\n    let languages = [\"Swift\", \"Python\", \"Java\", \"HTML\", \"JavaScript\"]\n\n    var body: some View {\n        List(languages, id: \\.self) { lang in\n            Label(lang, systemImage: \"globe\")\n        }\n        .navigationTitle(\"Languages\")\n    }\n}",
                    hints: ["Use List(languages, id: \\.self)", "Use Label(text, systemImage:) inside", "Wrap in NavigationStack for a title"],
                    testCases: ["5 rows shown", "Each row has a globe icon", "Language name next to each icon"]
                )
            ]
            
            // ── PYTHON CHALLENGES ─────────────────────────────────
        case "Python":
            return [
                CodingChallenge(
                    title: "Say Hello",
                    icon: "hand.wave.fill",
                    difficulty: "Beginner",
                    description: "Write a Python program that prints 'Hello, Codearn!' to the console.",
                    starterCode: "# Write your code here\n",
                    solutionCode: "print(\"Hello, Codearn!\")",
                    hints: ["Use the print() function", "Put text inside double quotes"],
                    testCases: ["Hello, Codearn!"]
                ),
                CodingChallenge(
                    title: "Add Two Numbers",
                    icon: "plus.circle.fill",
                    difficulty: "Beginner",
                    description: "Create two variables a = 12 and b = 8, then print their sum.",
                    starterCode: "# Create variables a and b\n\n# Print their sum\n",
                    solutionCode: "a = 12\nb = 8\nprint(a + b)",
                    hints: ["Assign values without a type keyword", "Use + to add", "Print the result"],
                    testCases: ["20"]
                ),
                CodingChallenge(
                    title: "Even or Odd",
                    icon: "divide.circle.fill",
                    difficulty: "Beginner",
                    description: "Check if the number 9 is even or odd and print the result.",
                    starterCode: "number = 9\n# Use if/else and % to check\n",
                    solutionCode: "number = 9\nif number % 2 == 0:\n    print(\"Even\")\nelse:\n    print(\"Odd\")",
                    hints: ["Use % (modulo) — remainder after division", "If number % 2 == 0, it's even", "Don't forget the colon after if/else"],
                    testCases: ["Odd"]
                ),
                CodingChallenge(
                    title: "Count to 10",
                    icon: "list.number",
                    difficulty: "Beginner",
                    description: "Use a for loop to print numbers 1 through 10.",
                    starterCode: "# Use range() in your for loop\n",
                    solutionCode: "for i in range(1, 11):\n    print(i)",
                    hints: ["range(1, 11) gives 1 to 10", "Use: for i in range(...):", "Print i inside the loop"],
                    testCases: ["1", "2", "3", "... up to 10"]
                ),
                CodingChallenge(
                    title: "List Printer",
                    icon: "text.justify.left",
                    difficulty: "Beginner",
                    description: "Create a list of 5 of your favourite foods and print each one using a loop.",
                    starterCode: "# Create a list called foods\nfoods = []\n\n# Loop through and print each\n",
                    solutionCode: "foods = [\"Pizza\", \"Sushi\", \"Tacos\", \"Pasta\", \"Burgers\"]\n\nfor food in foods:\n    print(food)",
                    hints: ["Use square brackets [ ] to make a list", "Separate items with commas", "Use: for food in foods:"],
                    testCases: ["Pizza", "Sushi", "Tacos", "Pasta", "Burgers"]
                ),
                CodingChallenge(
                    title: "FizzBuzz",
                    icon: "sparkles",
                    difficulty: "Intermediate",
                    description: "Print numbers 1–20. Multiples of 3 → 'Fizz', multiples of 5 → 'Buzz', both → 'FizzBuzz'.",
                    starterCode: "for i in range(1, 21):\n    # Your logic here\n    pass\n",
                    solutionCode: "for i in range(1, 21):\n    if i % 3 == 0 and i % 5 == 0:\n        print(\"FizzBuzz\")\n    elif i % 3 == 0:\n        print(\"Fizz\")\n    elif i % 5 == 0:\n        print(\"Buzz\")\n    else:\n        print(i)",
                    hints: ["Check both conditions first (FizzBuzz)", "Use elif for additional conditions", "Use and to combine conditions"],
                    testCases: ["1", "2", "Fizz", "4", "Buzz", "...", "FizzBuzz at 15"]
                ),
                CodingChallenge(
                    title: "Simple Calculator",
                    icon: "plus.forwardslash.minus",
                    difficulty: "Intermediate",
                    description: "Write a function called calculate(a, b, op) that returns the result. op is '+', '-', '*', or '/'. Test it with a few calls.",
                    starterCode: "def calculate(a, b, op):\n    # Handle each operation\n    pass\n\n# Test your function\n",
                    solutionCode: "def calculate(a, b, op):\n    if op == '+':\n        return a + b\n    elif op == '-':\n        return a - b\n    elif op == '*':\n        return a * b\n    elif op == '/':\n        return a / b\n\nprint(calculate(10, 5, '+'))   # 15\nprint(calculate(10, 5, '-'))   # 5\nprint(calculate(10, 5, '*'))   # 50\nprint(calculate(10, 5, '/'))   # 2.0",
                    hints: ["Use if/elif to check op", "Return the result directly", "Test with print(calculate(...))"],
                    testCases: ["calculate(10, 5, '+') → 15", "calculate(10, 5, '*') → 50", "calculate(10, 5, '/') → 2.0"]
                )
            ]
            
            // ── HTML CHALLENGES ───────────────────────────────────
        case "HTML":
            return [
                CodingChallenge(
                    title: "Hello Page",
                    icon: "globe",
                    difficulty: "Beginner",
                    description: "Write a complete HTML page with a title of 'My Page' and an h1 that says 'Hello, Codearn!'.",
                    starterCode: "<!DOCTYPE html>\n<html>\n  <head>\n    <!-- Add a title here -->\n  </head>\n  <body>\n    <!-- Add an h1 here -->\n  </body>\n</html>",
                    solutionCode: "<!DOCTYPE html>\n<html>\n  <head>\n    <title>My Page</title>\n  </head>\n  <body>\n    <h1>Hello, Codearn!</h1>\n  </body>\n</html>",
                    hints: ["Use <title> inside <head>", "Use <h1> inside <body>", "Don't forget closing tags"],
                    testCases: ["Browser tab shows 'My Page'", "Page shows large heading 'Hello, Codearn!'"]
                ),
                CodingChallenge(
                    title: "About Me",
                    icon: "person.text.rectangle.fill",
                    difficulty: "Beginner",
                    description: "Create an HTML page with an h1 for your name, an h2 that says 'About Me', and a paragraph describing yourself.",
                    starterCode: "<!DOCTYPE html>\n<html>\n  <body>\n    <!-- Your name as h1 -->\n    \n    <!-- About Me as h2 -->\n    \n    <!-- A paragraph about you -->\n    \n  </body>\n</html>",
                    solutionCode: "<!DOCTYPE html>\n<html>\n  <body>\n    <h1>Alex Coder</h1>\n    <h2>About Me</h2>\n    <p>I am learning web development and loving every minute of it!</p>\n  </body>\n</html>",
                    hints: ["h1 is the biggest heading", "h2 is a slightly smaller heading", "Use <p> for paragraphs"],
                    testCases: ["Large name heading at top", "'About Me' subtitle below", "Paragraph of text below that"]
                ),
                CodingChallenge(
                    title: "Favourite List",
                    icon: "list.bullet",
                    difficulty: "Beginner",
                    description: "Create an unordered list of your 4 favourite hobbies with a heading above it.",
                    starterCode: "<!DOCTYPE html>\n<html>\n  <body>\n    <h2>My Hobbies</h2>\n    <!-- Create an unordered list -->\n    \n  </body>\n</html>",
                    solutionCode: "<!DOCTYPE html>\n<html>\n  <body>\n    <h2>My Hobbies</h2>\n    <ul>\n      <li>Coding</li>\n      <li>Gaming</li>\n      <li>Reading</li>\n      <li>Hiking</li>\n    </ul>\n  </body>\n</html>",
                    hints: ["Use <ul> to open the list", "Each item uses <li>", "Close the list with </ul>"],
                    testCases: ["'My Hobbies' heading shown", "4 bullet point items below"]
                ),
                CodingChallenge(
                    title: "Clickable Link",
                    icon: "link.circle.fill",
                    difficulty: "Beginner",
                    description: "Add a paragraph and a link below it that opens apple.com in a new tab.",
                    starterCode: "<!DOCTYPE html>\n<html>\n  <body>\n    <p>Check out this cool website:</p>\n    <!-- Add an anchor tag here -->\n    \n  </body>\n</html>",
                    solutionCode: "<!DOCTYPE html>\n<html>\n  <body>\n    <p>Check out this cool website:</p>\n    <a href=\"https://apple.com\" target=\"_blank\">Visit Apple</a>\n  </body>\n</html>",
                    hints: ["Use the <a> tag", "href sets the destination URL", "target=\"_blank\" opens in a new tab"],
                    testCases: ["Paragraph shown", "Clickable 'Visit Apple' link below", "Opens apple.com in a new tab"]
                ),
                CodingChallenge(
                    title: "Simple Table",
                    icon: "tablecells.fill",
                    difficulty: "Intermediate",
                    description: "Create an HTML table with a header row (Name, Age, City) and 3 data rows of people.",
                    starterCode: "<!DOCTYPE html>\n<html>\n  <body>\n    <table border=\"1\">\n      <!-- Add a header row -->\n      \n      <!-- Add 3 data rows -->\n      \n    </table>\n  </body>\n</html>",
                    solutionCode: "<!DOCTYPE html>\n<html>\n  <body>\n    <table border=\"1\">\n      <tr>\n        <th>Name</th>\n        <th>Age</th>\n        <th>City</th>\n      </tr>\n      <tr>\n        <td>Alex</td>\n        <td>20</td>\n        <td>Chicago</td>\n      </tr>\n      <tr>\n        <td>Sam</td>\n        <td>25</td>\n        <td>New York</td>\n      </tr>\n      <tr>\n        <td>Jordan</td>\n        <td>22</td>\n        <td>Austin</td>\n      </tr>\n    </table>\n  </body>\n</html>",
                    hints: ["Use <tr> for rows, <th> for header cells, <td> for data cells", "Header row uses <th> instead of <td>", "Each row is wrapped in <tr>...</tr>"],
                    testCases: ["Header row: Name | Age | City", "3 data rows below", "Table border visible"]
                ),
                CodingChallenge(
                    title: "Mini Portfolio",
                    icon: "briefcase.fill",
                    difficulty: "Intermediate",
                    description: "Build a mini portfolio page with: your name as h1, a short bio paragraph, an 'My Projects' h2, and an ordered list of 3 project names.",
                    starterCode: "<!DOCTYPE html>\n<html>\n  <head>\n    <title>My Portfolio</title>\n  </head>\n  <body>\n    <!-- Your content here -->\n    \n  </body>\n</html>",
                    solutionCode: "<!DOCTYPE html>\n<html>\n  <head>\n    <title>My Portfolio</title>\n  </head>\n  <body>\n    <h1>Alex Coder</h1>\n    <p>I'm a student learning web development. I love building things!</p>\n    <h2>My Projects</h2>\n    <ol>\n      <li>Personal Website</li>\n      <li>Weather App</li>\n      <li>To-Do List</li>\n    </ol>\n  </body>\n</html>",
                    hints: ["Use <h1> for your name", "Use <p> for the bio", "Use <ol> for an ordered (numbered) list"],
                    testCases: ["Name as h1", "Bio paragraph", "'My Projects' heading", "3 numbered project names"]
                )
            ]
            
        default:
            return []
        }
    }
    
    var body: some View {
        List(challenges) { challenge in
            NavigationLink(destination: CodingChallengeDetailView(challenge: challenge)) {
                HStack(spacing: 14) {
                    Image(systemName: challenge.icon)
                        .font(.title2)
                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(challenge.title).font(.headline)
                        HStack(spacing: 6) {
                            difficultyBadge(challenge.difficulty)
                            Text("\(challenge.hints.count) hints available")
                                .font(.caption).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("\(language) Challenges")
    }
    
    func difficultyBadge(_ difficulty: String) -> some View {
        let color: Color = difficulty == "Beginner" ? .green : difficulty == "Intermediate" ? .orange : .red
        return Text(difficulty)
            .font(.caption).bold()
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

// MARK: - Lessons Data

struct LessonsView: View {
    let language: String
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    var lessons: [Lesson] {
        switch language {
            
            // ── JAVA ──────────────────────────────────────────────
        case "Java":
            return [
                Lesson(title: "What is Java?", icon: "cup.and.saucer.fill", steps: [
                    .info(title: "Welcome to Java!", body: "Java is a popular programming language used to build apps, games, websites, and more. It was created in 1995 and is still one of the most used languages in the world.", code: nil),
                    .info(title: "Your First Program", body: "Every Java program needs a class and a main method. This is where your program starts running.", code: "public class MyApp {\n    public static void main(String[] args) {\n        System.out.println(\"Hello, World!\");\n    }\n}"),
                    .multipleChoice(question: "What does System.out.println() do?", choices: ["Deletes text", "Prints text to the screen", "Creates a new class", "Stores a number"], correctIndex: 1, explanation: "System.out.println() prints a line of text to the console — the most common tool for beginners!"),
                    .fillBlank(prompt: "Complete the print statement", codePrefix: "System.out.", answer: "println", codeSuffix: "(\"Hello!\");", hint: "The method that prints a line")
                ]),
                Lesson(title: "Variables", icon: "number", steps: [
                    .info(title: "What is a Variable?", body: "A variable is a named container that stores a value. In Java you must declare the type before using it.", code: "int age = 16;\nString name = \"Alex\";\nboolean isStudent = true;\ndouble gpa = 3.8;"),
                    .multipleChoice(question: "Which type stores text?", choices: ["int", "boolean", "String", "double"], correctIndex: 2, explanation: "String holds text — letters, words, or sentences. It's always capitalized in Java."),
                    .fillBlank(prompt: "Declare an integer called score set to 10", codePrefix: "int score = ", answer: "10", codeSuffix: ";", hint: "Just the number"),
                    .multipleChoice(question: "What is printed?\nint x = 5;\nSystem.out.println(x);", choices: ["x", "int", "5", "Nothing"], correctIndex: 2, explanation: "x holds 5, so printing x outputs 5.")
                ]),
                Lesson(title: "If / Else", icon: "arrow.triangle.branch", steps: [
                    .info(title: "Making Decisions", body: "An if/else lets your program choose what to do. If the condition is true, one block runs. Otherwise else runs.", code: "int age = 18;\nif (age >= 18) {\n    System.out.println(\"Adult\");\n} else {\n    System.out.println(\"Minor\");\n}"),
                    .multipleChoice(question: "If age = 15, what prints?", choices: ["Adult", "Minor", "Nothing", "Error"], correctIndex: 1, explanation: "15 is not >= 18 so the condition is false and else runs, printing 'Minor'."),
                    .fillBlank(prompt: "Complete the if statement", codePrefix: "if (score > 50) ", answer: "{", codeSuffix: "\n    System.out.println(\"Pass\");\n}", hint: "Opening curly brace"),
                    .multipleChoice(question: "What symbol means 'is equal to' in Java?", choices: ["=", "=>", "==", "!="], correctIndex: 2, explanation: "== compares two values. A single = assigns a value.")
                ]),
                Lesson(title: "Loops", icon: "repeat", steps: [
                    .info(title: "For Loops", body: "Loops repeat code. A for loop has 3 parts: start, condition, and update.", code: "for (int i = 0; i < 5; i++) {\n    System.out.println(\"Count: \" + i);\n}"),
                    .multipleChoice(question: "How many times does this loop run?\nfor (int i = 0; i < 3; i++)", choices: ["0", "2", "3", "4"], correctIndex: 2, explanation: "i starts at 0 and runs while i < 3 — so i = 0, 1, 2 — that's 3 times."),
                    .fillBlank(prompt: "Fill in the loop condition to run 5 times", codePrefix: "for (int i = 0; i < ", answer: "5", codeSuffix: "; i++)", hint: "How many times should it run?"),
                    .info(title: "While Loops", body: "A while loop keeps running as long as its condition is true. Be careful not to create an infinite loop!", code: "int count = 0;\nwhile (count < 3) {\n    System.out.println(count);\n    count++;\n}")
                ]),
                Lesson(title: "Methods", icon: "function", steps: [
                    .info(title: "What is a Method?", body: "A method is a reusable block of code with a name. You define it once and call it whenever you need it.", code: "public static void sayHello() {\n    System.out.println(\"Hello!\");\n}\n\n// Call it:\nsayHello();"),
                    .info(title: "Methods with Parameters", body: "Methods can accept input values called parameters, and can return a result.", code: "public static int add(int a, int b) {\n    return a + b;\n}\n\nint result = add(3, 5);\nSystem.out.println(result); // 8"),
                    .multipleChoice(question: "What keyword returns a value from a method?", choices: ["send", "output", "return", "print"], correctIndex: 2, explanation: "return sends a value back to whoever called the method. The method's declared type must match what you return."),
                    .fillBlank(prompt: "Complete the method signature", codePrefix: "public static int multiply(int a, int b) {\n    ", answer: "return", codeSuffix: " a * b;\n}", hint: "The keyword that sends back a value")
                ]),
                Lesson(title: "Arrays", icon: "square.grid.3x1.fill.below.line.grid.1x2", steps: [
                    .info(title: "What is an Array?", body: "An array stores multiple values of the same type in one variable. Each item has an index starting at 0.", code: "int[] scores = {90, 85, 78, 92};\nSystem.out.println(scores[0]); // 90\nSystem.out.println(scores[3]); // 92"),
                    .multipleChoice(question: "What is the index of the first item in an array?", choices: ["1", "-1", "0", "First"], correctIndex: 2, explanation: "Arrays are zero-indexed — the first element is always at index 0."),
                    .fillBlank(prompt: "Access the second element of the array", codePrefix: "int[] nums = {10, 20, 30};\nSystem.out.println(nums[", answer: "1", codeSuffix: "]);", hint: "Index of the second item"),
                    .multipleChoice(question: "How do you get the length of an array called arr?", choices: ["arr.size()", "length(arr)", "arr.length", "arr.count"], correctIndex: 2, explanation: "In Java, .length (no parentheses) gives you the number of elements in an array.")
                ])
            ]
            
            // ── SWIFT UI ──────────────────────────────────────────
        case "Swift UI":
            return [
                Lesson(title: "What is SwiftUI?", icon: "swift", steps: [
                    .info(title: "Welcome to SwiftUI!", body: "SwiftUI is Apple's modern framework for building apps on iPhone, iPad, Mac, and more. You describe what the UI looks like using Swift code.", code: nil),
                    .info(title: "Your First View", body: "Every SwiftUI screen is a View. The body property describes what appears on screen.", code: "struct ContentView: View {\n    var body: some View {\n        Text(\"Hello, World!\")\n    }\n}"),
                    .multipleChoice(question: "What property describes what a View displays?", choices: ["frame", "body", "content", "display"], correctIndex: 1, explanation: "The body property is required in every SwiftUI View. It returns the visual content."),
                    .fillBlank(prompt: "Show a text label", codePrefix: "", answer: "Text", codeSuffix: "(\"Hi\")", hint: "The SwiftUI view for showing text")
                ]),
                Lesson(title: "Modifiers", icon: "slider.horizontal.3", steps: [
                    .info(title: "What are Modifiers?", body: "Modifiers change how a view looks or behaves. Chain them with dot syntax. Order matters!", code: "Text(\"Hello!\")\n    .font(.title)\n    .foregroundStyle(.blue)\n    .padding()\n    .background(Color.yellow)"),
                    .multipleChoice(question: "Which modifier adds space around a view?", choices: [".spacing()", ".margin()", ".padding()", ".frame()"], correctIndex: 2, explanation: ".padding() adds empty space around all sides of a view."),
                    .fillBlank(prompt: "Make the text red", codePrefix: "Text(\"Stop\")\n    .", answer: "foregroundStyle", codeSuffix: "(.red)", hint: "The modifier that sets text color"),
                    .multipleChoice(question: "What does .bold() do?", choices: ["Changes color", "Makes font weight heavy", "Adds a border", "Hides the text"], correctIndex: 1, explanation: ".bold() applies a heavy font weight, making text stand out more.")
                ]),
                Lesson(title: "Buttons & State", icon: "hand.tap.fill", steps: [
                    .info(title: "Making Things Interactive", body: "@State lets you store data inside a view. When it changes, the view automatically updates.", code: "struct CounterView: View {\n    @State private var count = 0\n\n    var body: some View {\n        Button(\"Tap: \\(count)\") {\n            count += 1\n        }\n    }\n}"),
                    .multipleChoice(question: "What does @State do?", choices: ["Imports a library", "Stores data that updates the view when changed", "Creates a new screen", "Styles a button"], correctIndex: 1, explanation: "@State is a property wrapper that tells SwiftUI to re-render the view whenever the value changes."),
                    .fillBlank(prompt: "Declare a @State variable", codePrefix: "@State private var score = ", answer: "0", codeSuffix: "", hint: "A starting integer value"),
                    .multipleChoice(question: "How do you pass @State to a child view?", choices: ["Pass the value directly", "Use $ prefix for a Binding", "Use @Binding only", "Copy the variable"], correctIndex: 1, explanation: "The $ prefix converts a @State variable into a Binding, which lets child views read and write the value.")
                ]),
                Lesson(title: "Stacks", icon: "square.3.layers.3d", steps: [
                    .info(title: "VStack, HStack & ZStack", body: "Stacks arrange views. VStack = vertical, HStack = horizontal, ZStack = layered on top of each other.", code: "VStack {\n    Text(\"Top\")\n    Text(\"Bottom\")\n}\n\nHStack {\n    Text(\"Left\")\n    Text(\"Right\")\n}"),
                    .multipleChoice(question: "Which stack places views side by side?", choices: ["VStack", "ZStack", "HStack", "Grid"], correctIndex: 2, explanation: "HStack arranges its child views horizontally, side by side."),
                    .fillBlank(prompt: "Add spacing between VStack items", codePrefix: "VStack(spacing: ", answer: "16", codeSuffix: ") { ... }", hint: "A number like 16"),
                    .multipleChoice(question: "What does Spacer() do inside a stack?", choices: ["Adds a dividing line", "Pushes views apart by filling available space", "Creates a new column", "Adds padding"], correctIndex: 1, explanation: "Spacer() expands to fill all available space, pushing other views to the edges.")
                ]),
                Lesson(title: "Lists & Navigation", icon: "list.bullet.rectangle.fill", steps: [
                    .info(title: "Building Lists", body: "List displays a scrollable collection of rows. Give each item an identifier so SwiftUI can track them.", code: "let fruits = [\"Apple\", \"Banana\", \"Cherry\"]\n\nList(fruits, id: \\.self) { fruit in\n    Text(fruit)\n}"),
                    .info(title: "NavigationStack", body: "Wrap your view in a NavigationStack to enable navigation. Use NavigationLink to push to a new screen.", code: "NavigationStack {\n    List(fruits, id: \\.self) { fruit in\n        NavigationLink(fruit, destination: Text(fruit))\n    }\n    .navigationTitle(\"Fruits\")\n}"),
                    .multipleChoice(question: "What view enables screen-to-screen navigation?", choices: ["ScrollView", "NavigationStack", "ZStack", "TabView"], correctIndex: 1, explanation: "NavigationStack manages a navigation hierarchy and enables pushing new views onto the stack."),
                    .fillBlank(prompt: "Set the navigation bar title", codePrefix: "List { ... }\n    .", answer: "navigationTitle", codeSuffix: "(\"My List\")", hint: "The modifier that sets the nav bar label")
                ]),
                Lesson(title: "Images & SF Symbols", icon: "photo.fill", steps: [
                    .info(title: "SF Symbols", body: "Apple provides thousands of free icons called SF Symbols. Use Image(systemName:) to show them in your app.", code: "Image(systemName: \"star.fill\")\n    .font(.largeTitle)\n    .foregroundStyle(.yellow)"),
                    .info(title: "Sizing & Styling Images", body: "Use .font() to resize SF Symbols, or .frame() and .resizable() for image assets.", code: "Image(systemName: \"heart.fill\")\n    .font(.system(size: 60))\n    .foregroundStyle(.red)\n    .padding()"),
                    .multipleChoice(question: "How do you display an SF Symbol?", choices: ["Image(\"star\")", "Icon(systemName:)", "Image(systemName: \"star.fill\")", "SFSymbol(\"star\")"], correctIndex: 2, explanation: "Image(systemName:) is the correct initializer for SF Symbols. Pass the symbol's name as a string."),
                    .fillBlank(prompt: "Show a blue wifi symbol", codePrefix: "Image(systemName: \"wifi\")\n    .", answer: "foregroundStyle", codeSuffix: "(.blue)", hint: "Modifier that sets the icon color")
                ])
            ]
            
            // ── PYTHON ───────────────────────────────────────────
        case "Python":
            return [
                Lesson(title: "What is Python?", icon: "terminal.fill", steps: [
                    .info(title: "Welcome to Python!", body: "Python is one of the most beginner-friendly languages in the world, used for web apps, data science, AI, and automation. Its syntax reads almost like English.", code: nil),
                    .info(title: "Your First Line", body: "In Python, print text with the print() function. No semicolons or curly braces needed!", code: "print(\"Hello, World!\")"),
                    .multipleChoice(question: "How do you display text in Python?", choices: ["echo(\"text\")", "System.out.println()", "print(\"text\")", "display(\"text\")"], correctIndex: 2, explanation: "print() is Python's built-in function for outputting text."),
                    .fillBlank(prompt: "Print the word Hello", codePrefix: "print(\"", answer: "Hello", codeSuffix: "\")", hint: "The word you want to display")
                ]),
                Lesson(title: "Variables", icon: "number", steps: [
                    .info(title: "Variables in Python", body: "Python is dynamically typed — just write the name, =, and the value. Python figures out the type.", code: "name = \"Alex\"\nage = 16\nprice = 4.99\nis_student = True"),
                    .multipleChoice(question: "What type is: score = 100?", choices: ["str", "float", "bool", "int"], correctIndex: 3, explanation: "100 is a whole number with no decimal, so Python assigns int automatically."),
                    .fillBlank(prompt: "Create a variable set to 'Python'", codePrefix: "language = \"", answer: "Python", codeSuffix: "\"", hint: "The language name"),
                    .multipleChoice(question: "What does print(type(42)) output?", choices: ["<class 'str'>", "<class 'int'>", "<class 'float'>", "42"], correctIndex: 1, explanation: "42 is an integer, so type(42) returns <class 'int'>.")
                ]),
                Lesson(title: "If / Else", icon: "arrow.triangle.branch", steps: [
                    .info(title: "Conditions in Python", body: "Python uses if, elif, and else. Indentation (spaces) defines code blocks — no curly braces!", code: "age = 18\n\nif age >= 18:\n    print(\"Adult\")\nelse:\n    print(\"Minor\")"),
                    .multipleChoice(question: "How does Python group code in a block?", choices: ["Curly braces { }", "Parentheses ( )", "Indentation (spaces)", "Square brackets [ ]"], correctIndex: 2, explanation: "Python uses consistent indentation (usually 4 spaces) to define blocks."),
                    .fillBlank(prompt: "Complete the if statement", codePrefix: "if score > 50", answer: ":", codeSuffix: "\n    print(\"Pass\")", hint: "Python blocks start with this character"),
                    .multipleChoice(question: "What keyword replaces 'else if' in Python?", choices: ["elseif", "elsif", "elif", "else if"], correctIndex: 2, explanation: "Python uses elif (short for 'else if') for additional conditions.")
                ]),
                Lesson(title: "Loops", icon: "repeat", steps: [
                    .info(title: "For Loops", body: "Python's for loop iterates over a sequence. range() generates a sequence of numbers.", code: "for i in range(5):\n    print(i)\n\n# range(1, 6) gives 1, 2, 3, 4, 5\nfor i in range(1, 6):\n    print(i)"),
                    .multipleChoice(question: "What does range(3) produce?", choices: ["1, 2, 3", "0, 1, 2", "0, 1, 2, 3", "1, 2"], correctIndex: 1, explanation: "range(3) starts at 0 and goes up to (but not including) 3 — giving 0, 1, 2."),
                    .fillBlank(prompt: "Loop from 1 to 5 inclusive", codePrefix: "for i in range(1, ", answer: "6", codeSuffix: "):\n    print(i)", hint: "range stops before this number"),
                    .info(title: "While Loops", body: "While loops run as long as the condition is true. Always make sure the condition eventually becomes false!", code: "count = 0\nwhile count < 3:\n    print(count)\n    count += 1")
                ]),
                Lesson(title: "Functions", icon: "function", steps: [
                    .info(title: "Defining Functions", body: "Use def to create a function. Functions group reusable code under a name.", code: "def greet(name):\n    return f\"Hello, {name}!\"\n\nprint(greet(\"Codearn\"))  # Hello, Codearn!"),
                    .multipleChoice(question: "What keyword defines a function in Python?", choices: ["function", "func", "def", "fn"], correctIndex: 2, explanation: "def is short for 'define'. It tells Python you're creating a new function."),
                    .fillBlank(prompt: "Define a function called add", codePrefix: "", answer: "def", codeSuffix: " add(a, b):\n    return a + b", hint: "The keyword to define a function"),
                    .multipleChoice(question: "What does return do?", choices: ["Prints a value", "Ends the program", "Sends a value back to the caller", "Defines a variable"], correctIndex: 2, explanation: "return exits the function and sends a value back to wherever the function was called.")
                ]),
                Lesson(title: "Lists", icon: "list.bullet", steps: [
                    .info(title: "What is a List?", body: "A list stores multiple items in one variable. Items can be added, removed, or changed. Use square brackets.", code: "fruits = [\"apple\", \"banana\", \"cherry\"]\nprint(fruits[0])   # apple\nprint(len(fruits)) # 3"),
                    .multipleChoice(question: "What is the index of 'banana' in [\"apple\", \"banana\", \"cherry\"]?", choices: ["0", "1", "2", "banana"], correctIndex: 1, explanation: "Lists are zero-indexed. 'apple' is at 0, 'banana' is at 1, 'cherry' is at 2."),
                    .fillBlank(prompt: "Add an item to the list", codePrefix: "fruits = [\"apple\"]\nfruits.", answer: "append", codeSuffix: "(\"banana\")", hint: "The method that adds to the end of a list"),
                    .multipleChoice(question: "How do you get the number of items in a list called items?", choices: ["items.size()", "count(items)", "len(items)", "items.length"], correctIndex: 2, explanation: "len() is a built-in Python function that returns the number of items in a list, string, or other collection.")
                ])
            ]
            
            // ── HTML ─────────────────────────────────────────────
        case "HTML":
            return [
                Lesson(title: "What is HTML?", icon: "globe", steps: [
                    .info(title: "Welcome to HTML!", body: "HTML stands for HyperText Markup Language. It's the skeleton of every webpage — it tells the browser what content to show.", code: nil),
                    .info(title: "Tags", body: "HTML is written using tags. Most come in pairs — an opening and a closing tag (with /). Everything between them is the content.", code: "<h1>Hello!</h1>\n<p>This is a paragraph.</p>"),
                    .multipleChoice(question: "What does the / mean in </p>?", choices: ["Math operator", "Marks end of element", "Links to a page", "It's optional"], correctIndex: 1, explanation: "The / signals the tag is closing. Content sits between opening and closing tags."),
                    .fillBlank(prompt: "Write the closing tag for a paragraph", codePrefix: "<p>Hello!</", answer: "p", codeSuffix: ">", hint: "Same letter as the opening tag")
                ]),
                Lesson(title: "Headings & Paragraphs", icon: "text.alignleft", steps: [
                    .info(title: "Heading Tags", body: "HTML has 6 heading levels — h1 (biggest) to h6 (smallest). Use headings to organize your content.", code: "<h1>Main Title</h1>\n<h2>Section Title</h2>\n<h3>Subsection</h3>"),
                    .multipleChoice(question: "Which heading is the largest?", choices: ["<h6>", "<h3>", "<heading>", "<h1>"], correctIndex: 3, explanation: "<h1> is the most important and largest heading. Each page should have only one h1."),
                    .fillBlank(prompt: "Open a paragraph tag", codePrefix: "<", answer: "p", codeSuffix: ">My text</p>", hint: "One letter — the paragraph tag"),
                    .multipleChoice(question: "What does <br> do?", choices: ["Makes text bold", "Creates a line break", "Adds a border", "Links to a page"], correctIndex: 1, explanation: "<br> adds a line break. It's a self-closing tag with no content.")
                ]),
                Lesson(title: "Links & Images", icon: "link", steps: [
                    .info(title: "Anchor Tags", body: "The <a> tag creates a clickable link. The href attribute is the destination URL.", code: "<a href=\"https://apple.com\">Visit Apple</a>"),
                    .info(title: "Image Tags", body: "The <img> tag displays an image. It's self-closing. src is the image path, alt is the description.", code: "<img src=\"logo.png\" alt=\"Company Logo\">"),
                    .multipleChoice(question: "Which attribute sets the link destination?", choices: ["src", "alt", "href", "link"], correctIndex: 2, explanation: "href (Hypertext Reference) defines where a link goes."),
                    .fillBlank(prompt: "Complete the link tag", codePrefix: "<a ", answer: "href", codeSuffix: "=\"https://google.com\">Search</a>", hint: "The attribute setting the destination")
                ]),
                Lesson(title: "Lists", icon: "list.bullet", steps: [
                    .info(title: "Unordered & Ordered Lists", body: "Use <ul> for bullet lists and <ol> for numbered lists. Each item uses <li>.", code: "<ul>\n  <li>Apple</li>\n  <li>Banana</li>\n</ul>\n\n<ol>\n  <li>First</li>\n  <li>Second</li>\n</ol>"),
                    .multipleChoice(question: "Which tag creates a numbered list?", choices: ["<ul>", "<nl>", "<ol>", "<list>"], correctIndex: 2, explanation: "<ol> means Ordered List — items are numbered automatically by the browser."),
                    .fillBlank(prompt: "Add a list item", codePrefix: "<ul>\n  <", answer: "li", codeSuffix: ">Milk</li>\n</ul>", hint: "Two letters — the list item tag"),
                    .multipleChoice(question: "What does <ul> stand for?", choices: ["Underlined List", "Unordered List", "Universal Link", "Unlisted"], correctIndex: 1, explanation: "ul stands for Unordered List — a bullet list with no numbered order.")
                ]),
                Lesson(title: "Tables", icon: "tablecells.fill", steps: [
                    .info(title: "HTML Tables", body: "Tables organize data into rows and columns. Use <table>, <tr> (row), <th> (header cell), and <td> (data cell).", code: "<table>\n  <tr>\n    <th>Name</th>\n    <th>Age</th>\n  </tr>\n  <tr>\n    <td>Alex</td>\n    <td>20</td>\n  </tr>\n</table>"),
                    .multipleChoice(question: "Which tag creates a table row?", choices: ["<td>", "<th>", "<row>", "<tr>"], correctIndex: 3, explanation: "<tr> stands for Table Row. All cells for that row go inside <tr>."),
                    .fillBlank(prompt: "Create a header cell", codePrefix: "<tr>\n  <", answer: "th", codeSuffix: ">Name</th>\n</tr>", hint: "Two letters — table header cell"),
                    .multipleChoice(question: "What is the difference between <th> and <td>?", choices: ["No difference", "<th> is bold and centered by default", "<td> is for headers", "<th> is only for the last row"], correctIndex: 1, explanation: "<th> (table header) is bold and centered by default. <td> (table data) is normal weight and left-aligned.")
                ]),
                Lesson(title: "Forms", icon: "doc.text.fill", steps: [
                    .info(title: "HTML Forms", body: "Forms collect user input. Use <form> to wrap inputs, <input> for text fields, and <button> to submit.", code: "<form>\n  <input type=\"text\" placeholder=\"Your name\">\n  <input type=\"email\" placeholder=\"Email\">\n  <button type=\"submit\">Submit</button>\n</form>"),
                    .multipleChoice(question: "What tag wraps all form elements?", choices: ["<input>", "<group>", "<form>", "<field>"], correctIndex: 2, explanation: "<form> wraps all the inputs and controls that belong together."),
                    .fillBlank(prompt: "Create a text input", codePrefix: "<input type=\"", answer: "text", codeSuffix: "\" placeholder=\"Enter name\">", hint: "The type for a plain text field"),
                    .multipleChoice(question: "What type makes an input for passwords?", choices: ["secure", "hidden", "password", "private"], correctIndex: 2, explanation: "type=\"password\" hides the characters as the user types for security.")
                ])
            ]
            
        default:
            return []
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: isDarkMode
                    ? [Color.black, Color(red: 0.06, green: 0.06, blue: 0.17)]
                    : [Color(red: 0.98, green: 0.99, blue: 1.0), Color(red: 0.87, green: 0.93, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(language) Lesson Path")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Move through each lesson with the same explain, example, task, and check rhythm used in SwiftUI.")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.82))
                        
                        HStack(spacing: 12) {
                            lessonSelectorStat(title: "Lessons", value: "\(lessons.count)", color: .cyan)
                            lessonSelectorStat(title: "Steps", value: "\(lessons.map(\.steps.count).reduce(0, +))", color: .yellow)
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.11, green: 0.12, blue: 0.31), Color(red: 0.01, green: 0.63, blue: 0.76)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.16), lineWidth: 1)
                    )
                    
                    Text("Lesson Select")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        .padding(.horizontal, 4)
                    
                    ForEach(Array(lessons.enumerated()), id: \.element.id) { lessonIndex, lesson in
                        NavigationLink(destination: InteractiveLessonView(lesson: lesson)) {
                            lessonSelectionCard(lesson: lesson, index: lessonIndex)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("\(language) Lessons")
    }
    
    private func lessonSelectorStat(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.bold())
            Text(title.uppercased())
                .font(.caption2.bold())
                .tracking(1)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func lessonSelectionCard(lesson: Lesson, index: Int) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.18))
                    .frame(width: 62, height: 62)
                Image(systemName: lesson.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.blue)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(lesson.title)
                        .font(.headline.bold())
                    Spacer()
                    Text("Lesson \(index + 1)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
                
                Text("\(lesson.steps.count) guided steps")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode).opacity(0.78))
                
                Text("Explain, example, task, and check flow included.")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.surface(isDarkMode: isDarkMode).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Reusable Dropdown Content

private let languageDropdownMaxWidth: CGFloat = 600

struct LanguageDropdownContent: View {
    let language: String
    
    var body: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: LessonsView(language: language)) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(.blue)
                    Text("Lessons")
                        .foregroundStyle(.white)
                        .font(.title3).bold()
                }
            }
            
            NavigationLink(destination: ChallengesView(language: language)) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(.purple)
                    Text("Challenges")
                        .foregroundStyle(.white)
                        .font(.title3).bold()
                }
            }
        }
        .padding(.vertical, 12)
        .frame(maxWidth: languageDropdownMaxWidth)
    }
}

// MARK: - SwiftUI Adventure

enum SwiftUIAdventureActivity {
    case quiz(
        question: String,
        choices: [String],
        correctIndex: Int,
        explanation: String
    )
    case code(
        prompt: String,
        starterCode: String,
        validator: SwiftUICodeValidator,
        hints: [String],
        victoryMessage: String
    )
}

struct SwiftUICodeValidator {
    let requiredSnippets: [String]
    let forbiddenSnippets: [String]
}

struct SwiftUIAdventureNode: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let xpReward: Int
    let badge: String?
    let isBoss: Bool
    let lessonTitle: String
    let brief: String
    let lessonBody: String
    let exampleCode: String?
    let activity: SwiftUIAdventureActivity
}

struct SwiftUIAdventureProgress {
    var currentNodeIndex = 0
    var completedNodeIDs: Set<String> = []
    var xp = 0
    var streak = 0
    var badges: [String] = []
    
    func isUnlocked(index: Int) -> Bool {
        index <= currentNodeIndex
    }
    
    func isCompleted(_ node: SwiftUIAdventureNode) -> Bool {
        completedNodeIDs.contains(node.id)
    }
    
    mutating func complete(node: SwiftUIAdventureNode, index: Int, totalNodeCount: Int) {
        let isFirstClear = completedNodeIDs.insert(node.id).inserted
        
        if isFirstClear {
            xp += node.xpReward
            streak += 1
            
            if let badge = node.badge, !badges.contains(badge) {
                badges.append(badge)
            }
        }
        
        currentNodeIndex = min(max(currentNodeIndex, index + 1), totalNodeCount)
    }
}

private let swiftUIAdventureNodes: [SwiftUIAdventureNode] = [
    SwiftUIAdventureNode(
        id: "swiftui_boot",
        title: "What Is SwiftUI?",
        subtitle: "Learn how every SwiftUI screen starts.",
        icon: "sparkles.rectangle.stack.fill",
        accent: .cyan,
        xpReward: 40,
        badge: nil,
        isBoss: false,
        lessonTitle: "What is SwiftUI?",
        brief: "The arcade powers up when you know the core part of every SwiftUI screen.",
        lessonBody: "SwiftUI is Apple's modern framework for building apps on iPhone, iPad, Mac, and more. Every SwiftUI screen is a View, and the body property describes what appears on screen.",
        exampleCode: """
        struct ContentView: View {
            var body: some View {
                Text("Hello, World!")
            }
        }
        """,
        activity: .quiz(
            question: "Which property describes what a SwiftUI view shows on screen?",
            choices: ["frame", "body", "scene", "layer"],
            correctIndex: 1,
            explanation: "`body` is the required property that returns the visible interface."
        )
    ),
    SwiftUIAdventureNode(
        id: "modifier_sprint",
        title: "Modifiers",
        subtitle: "Style a label using SwiftUI modifiers.",
        icon: "paintpalette.fill",
        accent: .orange,
        xpReward: 55,
        badge: nil,
        isBoss: false,
        lessonTitle: "Modifiers",
        brief: "Modifiers stack in order. Build a title label that feels arcade-ready.",
        lessonBody: "Modifiers change how a view looks or behaves. Chain them with dot syntax, and remember that order matters.",
        exampleCode: """
        Text("Hello!")
            .font(.title)
            .foregroundStyle(.blue)
            .padding()
            .background(Color.yellow)
        """,
        activity: .code(
            prompt: "Make the text say \"Play\" with a title font and orange color.",
            starterCode: """
            struct PlayLabel: View {
                var body: some View {
                    Text("Play")
                }
            }
            """,
            validator: SwiftUICodeValidator(
                requiredSnippets: [
                    "Text(\"Play\")",
                    ".font(.title)",
                    ".foregroundStyle(.orange)"
                ],
                forbiddenSnippets: []
            ),
            hints: [
                "Start from the existing Text view.",
                "Add the font modifier first, then the color modifier."
            ],
            victoryMessage: "Modifiers chained correctly. The label is ready for the cabinet."
        )
    ),
    SwiftUIAdventureNode(
        id: "state_charge",
        title: "Buttons & State",
        subtitle: "Power the UI with reactive data.",
        icon: "bolt.fill",
        accent: .yellow,
        xpReward: 60,
        badge: "State Spark",
        isBoss: false,
        lessonTitle: "Buttons & State",
        brief: "SwiftUI reacts to changing data. Pick the tool that makes the view refresh.",
        lessonBody: "@State lets you store data inside a view. When it changes, the view automatically updates, which is what makes buttons and counters feel alive.",
        exampleCode: """
        struct CounterView: View {
            @State private var count = 0

            var body: some View {
                Button("Tap: \\(count)") {
                    count += 1
                }
            }
        }
        """,
        activity: .quiz(
            question: "Which property wrapper stores local data and refreshes the view when it changes?",
            choices: ["@Binding", "@State", "@Environment", "@ObservedObject"],
            correctIndex: 1,
            explanation: "`@State` owns local mutable data for a view and triggers redraws when updated."
        )
    ),
    SwiftUIAdventureNode(
        id: "stack_lanes",
        title: "Stacks",
        subtitle: "Arrange views in vertical lanes.",
        icon: "square.3.layers.3d.top.filled",
        accent: .mint,
        xpReward: 75,
        badge: nil,
        isBoss: false,
        lessonTitle: "Stacks",
        brief: "Layouts are the lanes of the arcade. Build a vertical stack with controlled spacing.",
        lessonBody: "Stacks arrange views. VStack places them vertically, HStack places them horizontally, and ZStack layers them on top of each other.",
        exampleCode: """
        VStack {
            Text("Top")
            Text("Bottom")
        }

        HStack {
            Text("Left")
            Text("Right")
        }
        """,
        activity: .code(
            prompt: "Create a VStack with 16 points of spacing that shows \"Top\" then \"Bottom\".",
            starterCode: """
            struct StackDrill: View {
                var body: some View {
                    VStack {
                        
                    }
                }
            }
            """,
            validator: SwiftUICodeValidator(
                requiredSnippets: [
                    "VStack",
                    "spacing:16",
                    "Text(\"Top\")",
                    "Text(\"Bottom\")"
                ],
                forbiddenSnippets: []
            ),
            hints: [
                "Add the spacing argument to the VStack initializer.",
                "Put each Text on its own line inside the stack."
            ],
            victoryMessage: "The layout lanes are stable. You can move on to the boss."
        )
    ),
    SwiftUIAdventureNode(
        id: "symbol_charge",
        title: "Images & SF Symbols",
        subtitle: "Charge up your screen with an SF Symbol.",
        icon: "photo.fill",
        accent: .indigo,
        xpReward: 85,
        badge: "Icon Scout",
        isBoss: false,
        lessonTitle: "Images & SF Symbols",
        brief: "Apple ships thousands of built-in symbols. Use one with the right initializer and style it correctly.",
        lessonBody: "Use Image(systemName:) to show an SF Symbol. You can style it with .font() and .foregroundStyle() to control its size and color.",
        exampleCode: """
        Image(systemName: "star.fill")
            .font(.largeTitle)
            .foregroundStyle(.yellow)
        """,
        activity: .code(
            prompt: "Show a blue wifi SF Symbol using Image(systemName:).",
            starterCode: """
            struct WifiBadge: View {
                var body: some View {
                    
                }
            }
            """,
            validator: SwiftUICodeValidator(
                requiredSnippets: [
                    "Image(systemName:\"wifi\")",
                    ".foregroundStyle(.blue)"
                ],
                forbiddenSnippets: []
            ),
            hints: [
                "Use the SF Symbol initializer, not an asset name.",
                "The original lesson uses .foregroundStyle() to set color."
            ],
            victoryMessage: "Signal locked in. The icon system is under control."
        )
    ),
    SwiftUIAdventureNode(
        id: "navigation_boss",
        title: "Navigation Boss",
        subtitle: "Build a list screen and clear the route.",
        icon: "gamecontroller.fill",
        accent: .pink,
        xpReward: 150,
        badge: "Boss Clear",
        isBoss: true,
        lessonTitle: "Lists & Navigation",
        brief: "Boss fight: build a list inside a NavigationStack and set the navigation title to mirror the original lesson.",
        lessonBody: "List displays a scrollable collection of rows. Wrap screens in a NavigationStack to enable navigation, and use .navigationTitle() to label the screen.",
        exampleCode: """
        NavigationStack {
            List(["Apple", "Banana", "Cherry"], id: \\.self) { fruit in
                NavigationLink(fruit, destination: Text(fruit))
            }
            .navigationTitle("Fruits")
        }
        """,
        activity: .code(
            prompt: "Create a NavigationStack with a List of \"Apple\" and \"Banana\", and set the title to \"Fruits\".",
            starterCode: """
            struct NavigationBossView: View {
                var body: some View {
                    
                }
            }
            """,
            validator: SwiftUICodeValidator(
                requiredSnippets: [
                    "NavigationStack",
                    "List([\"Apple\",\"Banana\"],id:\\.self)",
                    ".navigationTitle(\"Fruits\")"
                ],
                forbiddenSnippets: []
            ),
            hints: [
                "Start by wrapping everything in NavigationStack.",
                "Use List with an array and id: \\.self.",
                "Apply .navigationTitle(\"Fruits\") to the List."
            ],
            victoryMessage: "Boss defeated. You rebuilt the original lists and navigation lesson in arcade form."
        )
    )
]

struct SwiftUIAdventureEntryView: View {
    @Binding var progress: SwiftUIAdventureProgress
    
    var body: some View {
        NavigationLink(destination: SwiftUIAdventureMapView(progress: $progress)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Adventure Map")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("Train, earn XP, and clear boss fights.")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.82))
                    }
                    Spacer()
                    Image(systemName: "arcade.stick.and.button")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                HStack(spacing: 10) {
                    adventureStatPill(title: "XP", value: "\(progress.xp)")
                    adventureStatPill(title: "Streak", value: "\(progress.streak)")
                    adventureStatPill(title: "Badges", value: "\(progress.badges.count)")
                }
                
                Text(progress.currentNodeIndex >= swiftUIAdventureNodes.count ? "Campaign complete" : "Next stop: \(swiftUIAdventureNodes[min(progress.currentNodeIndex, swiftUIAdventureNodes.count - 1)].title)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.white.opacity(0.92))
            }
            .padding(18)
            .frame(maxWidth: languageDropdownMaxWidth)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.13, green: 0.14, blue: 0.35), Color(red: 0.86, green: 0.19, blue: 0.51)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.pink.opacity(0.25), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }
    
    private func adventureStatPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.bold())
            Text(title.uppercased())
                .font(.caption2.bold())
                .tracking(0.8)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SwiftUIAdventureMapView: View {
    @Binding var progress: SwiftUIAdventureProgress
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isDeveloperMode") private var isDeveloperMode = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: isDarkMode
                    ? [Color.black, Color(red: 0.06, green: 0.06, blue: 0.17)]
                    : [Color(red: 0.98, green: 0.99, blue: 1.0), Color(red: 0.87, green: 0.93, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    adventureHUD
                    
                    Text("Stage Path")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        .padding(.horizontal, 4)
                    
                    ForEach(Array(swiftUIAdventureNodes.enumerated()), id: \.element.id) { index, node in
                        NavigationLink(destination: SwiftUIAdventureMissionView(node: node, index: index, progress: $progress)) {
                            adventureNodeCard(node: node, index: index)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isNodeUnlocked(index: index))
                    }
                }
                .padding()
            }
        }
        .navigationTitle("SwiftUI Arcade")
    }
    
    private var adventureHUD: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SwiftUI Hero Run")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Clear drills, stack XP, and beat the boss fight to finish the first arcade route.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.82))
            
            HStack(spacing: 12) {
                hudCard(title: "XP", value: "\(progress.xp)", color: .cyan)
                hudCard(title: "Streak", value: "\(progress.streak)", color: .yellow)
                hudCard(title: "Badges", value: "\(progress.badges.count)", color: .pink)
            }
            
            if !progress.badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(progress.badges, id: \.self) { badge in
                            Text(badge)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.14))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.12, blue: 0.31), Color(red: 0.01, green: 0.63, blue: 0.76)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }
    
    private func hudCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.bold())
            Text(title.uppercased())
                .font(.caption2.bold())
                .tracking(1)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func adventureNodeCard(node: SwiftUIAdventureNode, index: Int) -> some View {
        let unlocked = isNodeUnlocked(index: index)
        let completed = progress.isCompleted(node)
        
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(unlocked ? node.accent.opacity(0.22) : Color.gray.opacity(0.15))
                    .frame(width: 62, height: 62)
                Image(systemName: completed ? "checkmark.seal.fill" : node.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(unlocked ? node.accent : .gray)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(node.title)
                        .font(.headline.bold())
                    if node.isBoss {
                        Text("BOSS")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.18))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text(node.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode).opacity(unlocked ? 0.8 : 0.45))
                
                HStack(spacing: 10) {
                    Text("+\(node.xpReward) XP")
                    Text(completed ? "Cleared" : unlocked ? "Unlocked" : "Locked")
                }
                .font(.caption.bold())
                .foregroundStyle(unlocked ? node.accent : .gray)
            }
            
            Spacer()
            
            Image(systemName: unlocked ? "chevron.right.circle.fill" : "lock.fill")
                .font(.title3)
                .foregroundStyle(unlocked ? node.accent : .gray)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.surface(isDarkMode: isDarkMode).opacity(unlocked ? 0.96 : 0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(unlocked ? node.accent.opacity(0.45) : Color.gray.opacity(0.18), lineWidth: 1)
        )
        .opacity(unlocked ? 1 : 0.72)
    }
    
    private func isNodeUnlocked(index: Int) -> Bool {
        isDeveloperMode || progress.isUnlocked(index: index)
    }
}

struct SwiftUIAdventureMissionView: View {
    private enum MissionPhase: Int, CaseIterable {
        case explain
        case example
        case task
        case check
    }
    
    let node: SwiftUIAdventureNode
    let index: Int
    @Binding var progress: SwiftUIAdventureProgress
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @Environment(\.dismiss) private var dismiss
    @State private var missionPhase: MissionPhase = .explain
    @State private var selectedChoice: Int?
    @State private var editorText = ""
    @State private var feedback = ""
    @State private var feedbackColor: Color = .blue
    @State private var showFeedback = false
    @State private var revealedHints = 0
    
    init(node: SwiftUIAdventureNode, index: Int, progress: Binding<SwiftUIAdventureProgress>) {
        self.node = node
        self.index = index
        _progress = progress
        
        if case .code(_, let starterCode, _, _, _) = node.activity {
            _editorText = State(initialValue: starterCode)
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.background(isDarkMode: isDarkMode)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    missionHeader
                    phaseTracker
                    
                    switch missionPhase {
                    case .explain:
                        explainSection
                    case .example:
                        exampleSection
                    case .task:
                        taskSection
                    case .check:
                        checkSection
                    }
                    
                    Button(action: handlePrimaryAction) {
                        Text(primaryButtonTitle)
                            .font(.headline.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [node.accent, node.accent.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                    .disabled(primaryButtonDisabled)
                }
                .padding()
            }
        }
        .navigationTitle(node.title)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var missionHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(node.isBoss ? "Boss Fight" : "Training Run", systemImage: node.isBoss ? "flame.fill" : "sparkles")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(node.accent.opacity(0.14))
                    .foregroundStyle(node.accent)
                    .clipShape(Capsule())
                
                Spacer()
                
                Text("+\(node.xpReward) XP")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
            }
            
            Text(node.title)
                .font(.title.bold())
                .foregroundStyle(.white)
            
            Text(node.subtitle)
                .font(.title2.bold())
                .foregroundStyle(.white)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [node.accent.opacity(0.95), Color(red: 0.15, green: 0.09, blue: 0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    private var phaseTracker: some View {
        HStack(spacing: 10) {
            ForEach(Array(MissionPhase.allCases.enumerated()), id: \.offset) { phaseIndex, phase in
                VStack(spacing: 6) {
                    Text("\(phaseIndex + 1)")
                        .font(.caption.bold())
                        .frame(width: 28, height: 28)
                        .background(phaseCircleBackground(for: phase))
                        .foregroundStyle(phaseCircleForeground(for: phase))
                        .clipShape(Circle())
                    Text(phaseTitle(for: phase))
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode).opacity(missionPhase.rawValue >= phase.rawValue ? 0.9 : 0.45))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var explainSection: some View {
        lessonCard(title: "Explain") {
            Text(node.lessonTitle)
                .font(.caption.bold())
                .foregroundStyle(node.accent)
            Text("Core Idea")
                .font(.headline.bold())
            Text(node.lessonBody)
                .font(.body)
        }
    }
    
    @ViewBuilder
    private var exampleSection: some View {
        lessonCard(title: "Example") {
            Text("See It First")
                .font(.headline.bold())
            Text("Study the original lesson example before you try it yourself.")
                .font(.body)
            if let exampleCode = node.exampleCode {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Original Example")
                        .font(.subheadline.bold())
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(exampleCode)
                            .font(.system(.footnote, design: .monospaced))
                            .padding(12)
                    }
                    .background(AppTheme.background(isDarkMode: isDarkMode))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                Text("This lesson does not need a code sample before the task.")
                    .font(.body)
            }
        }
    }
    
    @ViewBuilder
    private var taskSection: some View {
        lessonCard(title: "Task") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Objective")
                    .font(.headline.bold())
                Text(node.brief)
                    .font(.body)
            }
        }
        
        switch node.activity {
        case .quiz(let question, let choices, _, _):
            quizSection(question: question, choices: choices)
        case .code(let prompt, _, _, let hints, _):
            codeSection(prompt: prompt, hints: hints)
        }
        
        if showFeedback {
            feedbackCard
        }
    }
    
    private var checkSection: some View {
        lessonCard(title: "Check") {
            Text(node.isBoss ? "Boss Review" : "Lesson Check")
                .font(.headline.bold())
            Text(feedback)
                .font(.body.weight(.semibold))
                .foregroundStyle(feedbackColor)
            Text(progress.isCompleted(node) ? "This lesson is now cleared on your adventure map." : "Finish to lock in the reward and move to the next lesson.")
                .font(.body)
        }
    }
    
    private var feedbackCard: some View {
        Text(feedback)
            .font(.callout.weight(.semibold))
            .foregroundStyle(feedbackColor)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(feedbackColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private func lessonCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.bold())
                .foregroundStyle(node.accent)
            content()
        }
        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
        .padding(18)
        .background(AppTheme.surface(isDarkMode: isDarkMode))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private func phaseTitle(for phase: MissionPhase) -> String {
        switch phase {
        case .explain: return "Explain"
        case .example: return "Example"
        case .task: return "Task"
        case .check: return "Check"
        }
    }
    
    private func phaseCircleBackground(for phase: MissionPhase) -> Color {
        missionPhase.rawValue >= phase.rawValue ? node.accent : Color.gray.opacity(0.2)
    }
    
    private func phaseCircleForeground(for phase: MissionPhase) -> Color {
        missionPhase.rawValue >= phase.rawValue ? .white : .gray
    }
    
    private var primaryButtonTitle: String {
        switch missionPhase {
        case .explain:
            return "Continue to Example"
        case .example:
            return "Start Task"
        case .task:
            return node.isBoss ? "Check Boss Fight" : "Check Answer"
        case .check:
            return progress.isCompleted(node) ? "Back to Map" : "Claim Reward"
        }
    }
    
    private var primaryButtonDisabled: Bool {
        switch missionPhase {
        case .task:
            switch node.activity {
            case .quiz:
                return selectedChoice == nil
            case .code:
                return editorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        default:
            return false
        }
    }
    
    private func handlePrimaryAction() {
        switch missionPhase {
        case .explain:
            missionPhase = .example
        case .example:
            missionPhase = .task
        case .task:
            submitMission()
        case .check:
            dismiss()
        }
    }
    
    private func quizSection(question: String, choices: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
            
            ForEach(choices.indices, id: \.self) { choiceIndex in
                Button {
                    selectedChoice = choiceIndex
                    showFeedback = false
                } label: {
                    HStack {
                        Text(choices[choiceIndex])
                            .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        Spacer()
                        if selectedChoice == choiceIndex {
                            Image(systemName: "scope")
                                .foregroundStyle(node.accent)
                        }
                    }
                    .padding()
                    .background(AppTheme.surface(isDarkMode: isDarkMode))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(selectedChoice == choiceIndex ? node.accent : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func codeSection(prompt: String, hints: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(prompt)
                .font(.title3.bold())
                .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
            
            TextEditor(text: $editorText)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: node.isBoss ? 260 : 200)
                .padding(10)
                .scrollContentBackground(.hidden)
                .background(AppTheme.surface(isDarkMode: isDarkMode))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(node.accent.opacity(0.3), lineWidth: 1)
                )
            
            if !hints.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(hints.prefix(revealedHints), id: \.self) { hint in
                        Label(hint, systemImage: "lightbulb.fill")
                            .font(.callout)
                            .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                    }
                    
                    if revealedHints < hints.count {
                        Button("Reveal Hint") {
                            revealedHints += 1
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(node.accent)
                    }
                }
                .padding(16)
                .background(node.accent.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
    }
    
    private func submitMission() {
        switch node.activity {
        case .quiz(_, _, let correctIndex, let explanation):
            guard let selectedChoice else {
                feedback = "Pick an answer before submitting."
                feedbackColor = .orange
                showFeedback = true
                return
            }
            
            guard selectedChoice == correctIndex else {
                feedback = "Not clear yet. Try again. \(explanation)"
                feedbackColor = .red
                showFeedback = true
                return
            }
            
            finishMission(message: explanation)
            
        case .code(_, _, let validator, _, let victoryMessage):
            let result = validateCode(editorText, validator: validator, for: node)
            
            guard result.isValid else {
                feedback = result.message
                feedbackColor = .red
                showFeedback = true
                return
            }
            
            finishMission(message: victoryMessage)
        }
    }
    
    private func finishMission(message: String) {
        progress.complete(node: node, index: index, totalNodeCount: swiftUIAdventureNodes.count)
        feedback = "\(message) +\(node.xpReward) XP earned."
        feedbackColor = .green
        showFeedback = true
        missionPhase = .check
    }
    
    private func validateCode(_ code: String, validator: SwiftUICodeValidator, for node: SwiftUIAdventureNode) -> (isValid: Bool, message: String) {
        if node.id == "stack_lanes" {
            return validateStacksCode(code)
        }
        
        let normalizedCode = normalized(code)
        let missingSnippets = validator.requiredSnippets.filter { !normalizedCode.contains(normalized($0)) }
        let blockedSnippets = validator.forbiddenSnippets.filter { normalizedCode.contains(normalized($0)) }
        
        if !missingSnippets.isEmpty {
            let missingList = missingSnippets.joined(separator: ", ")
            return (false, "Missing required code: \(missingList)")
        }
        
        if !blockedSnippets.isEmpty {
            let blockedList = blockedSnippets.joined(separator: ", ")
            return (false, "Remove blocked code before clearing the mission: \(blockedList)")
        }
        
        return (true, "Clear")
    }
    
    private func validateStacksCode(_ code: String) -> (isValid: Bool, message: String) {
        let normalizedCode = normalized(code)
        let hasVStack = normalizedCode.contains("VStack")
        let hasSpacing16 = normalizedCode.contains("spacing:16") || normalizedCode.contains("spacing:16.0")
        let hasTop = normalizedCode.contains("Text(\"Top\")")
        let hasBottom = normalizedCode.contains("Text(\"Bottom\")")
        
        if !hasVStack {
            return (false, "Missing required code: VStack")
        }
        
        if !hasSpacing16 {
            return (false, "Missing required code: spacing: 16")
        }
        
        if !hasTop || !hasBottom {
            return (false, "Missing required code: Text(\"Top\") and Text(\"Bottom\")")
        }
        
        return (true, "Clear")
    }
    
    private func normalized(_ value: String) -> String {
        value.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
    }
}

// MARK: - Generic Language Adventure

enum LanguageAdventureStageKind {
    case lesson(Lesson)
    case boss(CodingChallenge)
}

struct LanguageAdventureStage: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let accent: Color
    let xpReward: Int
    let badge: String?
    let isBoss: Bool
    let kind: LanguageAdventureStageKind
}

struct LanguageAdventureProgress {
    var currentStageIndex = 0
    var completedStageIDs: Set<String> = []
    var xp = 0
    var streak = 0
    var badges: [String] = []
    
    func isUnlocked(index: Int) -> Bool {
        index <= currentStageIndex
    }
    
    func isCompleted(_ stage: LanguageAdventureStage) -> Bool {
        completedStageIDs.contains(stage.id)
    }
    
    mutating func complete(stage: LanguageAdventureStage, index: Int, totalStageCount: Int) {
        let isFirstClear = completedStageIDs.insert(stage.id).inserted
        
        if isFirstClear {
            xp += stage.xpReward
            streak += 1
            
            if let badge = stage.badge, !badges.contains(badge) {
                badges.append(badge)
            }
        }
        
        currentStageIndex = min(max(currentStageIndex, index + 1), totalStageCount)
    }
}

private func adventureStages(for language: String) -> [LanguageAdventureStage] {
    let languageLessons = LessonsView(language: language).lessons
    let languageChallenges = ChallengesView(language: language).challenges
    
    var stages = languageLessons.enumerated().map { lessonIndex, lesson in
        LanguageAdventureStage(
            id: "\(language)-lesson-\(lessonIndex)-\(lesson.title)",
            title: lesson.title,
            subtitle: "\(lesson.steps.count) lesson steps to clear.",
            icon: lesson.icon,
            accent: .blue,
            xpReward: 45 + (lessonIndex * 10),
            badge: lessonIndex == languageLessons.count - 1 ? "\(language) Scholar" : nil,
            isBoss: false,
            kind: .lesson(lesson)
        )
    }
    
    let intermediateChallenge = languageChallenges.first { $0.difficulty != "Beginner" } ?? languageChallenges.last
    let finalChallenge = languageChallenges.last
    
    if let intermediateChallenge {
        stages.append(
            LanguageAdventureStage(
                id: "\(language)-boss-mid-\(intermediateChallenge.title)",
                title: "\(intermediateChallenge.title) Boss",
                subtitle: "Mini boss challenge for the \(language) route.",
                icon: "flame.fill",
                accent: .orange,
                xpReward: 140,
                badge: "\(language) Mini Boss",
                isBoss: true,
                kind: .boss(intermediateChallenge)
            )
        )
    }
    
    if let finalChallenge, finalChallenge.title != intermediateChallenge?.title {
        stages.append(
            LanguageAdventureStage(
                id: "\(language)-boss-final-\(finalChallenge.title)",
                title: "\(finalChallenge.title) Final Boss",
                subtitle: "Final boss challenge for the \(language) route.",
                icon: "crown.fill",
                accent: .pink,
                xpReward: 200,
                badge: "\(language) Boss Clear",
                isBoss: true,
                kind: .boss(finalChallenge)
            )
        )
    }
    
    return stages
}

struct LanguageAdventureEntryView: View {
    let language: String
    @Binding var progress: LanguageAdventureProgress
    
    private var stages: [LanguageAdventureStage] {
        adventureStages(for: language)
    }
    
    var body: some View {
        NavigationLink(destination: LanguageAdventureMapView(language: language, progress: $progress)) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(language) Adventure")
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                        Text("Earn XP, clear lessons, and beat boss fights.")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.82))
                    }
                    Spacer()
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                HStack(spacing: 10) {
                    adventureEntryPill(title: "XP", value: "\(progress.xp)")
                    adventureEntryPill(title: "Stages", value: "\(stages.count)")
                    adventureEntryPill(title: "Bosses", value: "\(stages.filter(\.isBoss).count)")
                }
                
                Text(progress.currentStageIndex >= stages.count ? "Campaign complete" : "Next stop: \(stages[min(progress.currentStageIndex, stages.count - 1)].title)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.white.opacity(0.92))
            }
            .padding(18)
            .frame(maxWidth: languageDropdownMaxWidth)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.08, green: 0.2, blue: 0.42), Color(red: 0.0, green: 0.67, blue: 0.71)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.blue.opacity(0.18), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }
    
    private func adventureEntryPill(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.bold())
            Text(title.uppercased())
                .font(.caption2.bold())
                .tracking(0.8)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct LanguageAdventureMapView: View {
    let language: String
    @Binding var progress: LanguageAdventureProgress
    
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("isDeveloperMode") private var isDeveloperMode = false
    
    private var stages: [LanguageAdventureStage] {
        adventureStages(for: language)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: isDarkMode
                    ? [Color.black, Color(red: 0.06, green: 0.06, blue: 0.17)]
                    : [Color(red: 0.98, green: 0.99, blue: 1.0), Color(red: 0.87, green: 0.93, blue: 1.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    genericAdventureHUD
                    
                    Text("Stage Path")
                        .font(.title2.bold())
                        .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
                        .padding(.horizontal, 4)
                    
                    ForEach(Array(stages.enumerated()), id: \.element.id) { stageIndex, stage in
                        NavigationLink(destination: LanguageAdventureStageView(stage: stage, index: stageIndex, totalStageCount: stages.count, progress: $progress)) {
                            genericStageCard(stage: stage, index: stageIndex)
                        }
                        .buttonStyle(.plain)
                        .disabled(!isStageUnlocked(index: stageIndex))
                    }
                }
                .padding()
            }
        }
        .navigationTitle("\(language) Arcade")
    }
    
    private var genericAdventureHUD: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(language) Hero Run")
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Train on lessons, build XP, and clear boss fights to finish the route.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.82))
            
            HStack(spacing: 12) {
                genericHUDCard(title: "XP", value: "\(progress.xp)", color: .cyan)
                genericHUDCard(title: "Streak", value: "\(progress.streak)", color: .yellow)
                genericHUDCard(title: "Badges", value: "\(progress.badges.count)", color: .pink)
            }
            
            if !progress.badges.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(progress.badges, id: \.self) { badge in
                            Text(badge)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.14))
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.12, blue: 0.31), Color(red: 0.01, green: 0.63, blue: 0.76)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
    }
    
    private func genericHUDCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.bold())
            Text(title.uppercased())
                .font(.caption2.bold())
                .tracking(1)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func genericStageCard(stage: LanguageAdventureStage, index: Int) -> some View {
        let unlocked = isStageUnlocked(index: index)
        let completed = progress.isCompleted(stage)
        
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(unlocked ? stage.accent.opacity(0.22) : Color.gray.opacity(0.15))
                    .frame(width: 62, height: 62)
                Image(systemName: completed ? "checkmark.seal.fill" : stage.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(unlocked ? stage.accent : .gray)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(stage.title)
                        .font(.headline.bold())
                    if stage.isBoss {
                        Text("BOSS")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.18))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }
                
                Text(stage.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode).opacity(unlocked ? 0.8 : 0.45))
                
                HStack(spacing: 10) {
                    Text("+\(stage.xpReward) XP")
                    Text(completed ? "Cleared" : unlocked ? "Unlocked" : "Locked")
                }
                .font(.caption.bold())
                .foregroundStyle(unlocked ? stage.accent : .gray)
            }
            
            Spacer()
            
            Image(systemName: unlocked ? "chevron.right.circle.fill" : "lock.fill")
                .font(.title3)
                .foregroundStyle(unlocked ? stage.accent : .gray)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(AppTheme.surface(isDarkMode: isDarkMode).opacity(unlocked ? 0.96 : 0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(unlocked ? stage.accent.opacity(0.45) : Color.gray.opacity(0.18), lineWidth: 1)
        )
        .opacity(unlocked ? 1 : 0.72)
    }
    
    private func isStageUnlocked(index: Int) -> Bool {
        isDeveloperMode || progress.isUnlocked(index: index)
    }
}

struct LanguageAdventureStageView: View {
    let stage: LanguageAdventureStage
    let index: Int
    let totalStageCount: Int
    @Binding var progress: LanguageAdventureProgress
    
    var body: some View {
        switch stage.kind {
        case .lesson(let lesson):
            InteractiveLessonView(lesson: lesson, onComplete: {
                progress.complete(stage: stage, index: index, totalStageCount: totalStageCount)
            })
        case .boss(let challenge):
            CodingChallengeDetailView(challenge: challenge, onComplete: {
                progress.complete(stage: stage, index: index, totalStageCount: totalStageCount)
            })
        }
    }
}

// MARK: - Main Language View

struct LanguageView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var javaExpanded = false
    @State private var swiftExpanded = false
    @State private var pythonExpanded = false
    @State private var htmlExpanded = false
    @State private var javaProgress = LanguageAdventureProgress()
    @State private var pythonProgress = LanguageAdventureProgress()
    @State private var htmlProgress = LanguageAdventureProgress()
    @State private var swiftUIProgress = SwiftUIAdventureProgress()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(isDarkMode: isDarkMode)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    DisclosureGroup(isExpanded: $javaExpanded) {
                        LanguageAdventureEntryView(language: "Java", progress: $javaProgress)
                    } label: {
                        Text("Java").font(.title).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode)).padding(.vertical, 10)
                    }
                    .frame(maxWidth: languageDropdownMaxWidth)
                    .padding(.horizontal)
                    .accentColor(AppTheme.text(isDarkMode: isDarkMode))
                    
                    Divider().frame(maxWidth: languageDropdownMaxWidth)
                    
                    DisclosureGroup(isExpanded: $swiftExpanded) {
                        SwiftUIAdventureEntryView(progress: $swiftUIProgress)
                    } label: {
                        Text("Swift UI").font(.title).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode)).padding(.vertical, 10)
                    }
                    .frame(maxWidth: languageDropdownMaxWidth)
                    .padding(.horizontal)
                    .accentColor(AppTheme.text(isDarkMode: isDarkMode))
                    
                    Divider().frame(maxWidth: languageDropdownMaxWidth)
                    
                    DisclosureGroup(isExpanded: $pythonExpanded) {
                        LanguageAdventureEntryView(language: "Python", progress: $pythonProgress)
                    } label: {
                        Text("Python").font(.title).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode)).padding(.vertical, 10)
                    }
                    .frame(maxWidth: languageDropdownMaxWidth)
                    .padding(.horizontal)
                    .accentColor(AppTheme.text(isDarkMode: isDarkMode))
                    
                    Divider().frame(maxWidth: languageDropdownMaxWidth)
                    
                    DisclosureGroup(isExpanded: $htmlExpanded) {
                        LanguageAdventureEntryView(language: "HTML", progress: $htmlProgress)
                    } label: {
                        Text("HTML").font(.title).foregroundStyle(AppTheme.text(isDarkMode: isDarkMode)).padding(.vertical, 10)
                    }
                    .frame(maxWidth: languageDropdownMaxWidth)
                    .padding(.horizontal)
                    .accentColor(AppTheme.text(isDarkMode: isDarkMode))
                    
                    Divider().frame(maxWidth: languageDropdownMaxWidth)
                    
                    Spacer()
                }
            }
            .navigationTitle("Languages")
        }
    }
}

#Preview {
    LanguageView()
}

#Preview("Stacks Mission") {
    NavigationStack {
        SwiftUIAdventureMissionView(
            node: swiftUIAdventureNodes.first { $0.id == "stack_lanes" }!,
            index: 3,
            progress: .constant(SwiftUIAdventureProgress(currentNodeIndex: swiftUIAdventureNodes.count))
        )
    }
}
