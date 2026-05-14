//
//  CodearnApp.swift
//  Codearn
//
//  Created by Eduardo D. Camacho & Evelyn V. Huber on 4/22/26.
//
//hhhhuhuhuhhuhuhuhh
import SwiftUI
@preconcurrency import AVFoundation

enum AppTheme {
    // red and greed hacker palette
    static let hackerGreen       = Color(red: 0.00, green: 1.00, blue: 0.42)   // #00FF6B
    static let hackerGreenDim    = Color(red: 0.00, green: 0.75, blue: 0.32)   // #00BF51
    static let hackerGreenGlow   = Color(red: 0.00, green: 1.00, blue: 0.42).opacity(0.18)
    static let darkBackground    = Color(red: 0.04, green: 0.05, blue: 0.04)   // near-black with green tint
    static let darkSurface       = Color(red: 0.08, green: 0.11, blue: 0.08)   // dark green-tinted panel
    static let lightBackground   = Color(red: 0.94, green: 0.97, blue: 0.94)
    static let lightSurface      = Color(red: 0.87, green: 0.92, blue: 0.87)
    
    static func background(isDarkMode: Bool) -> Color {
        isDarkMode ? darkBackground : lightBackground
    }
    
    static func surface(isDarkMode: Bool) -> Color {
        isDarkMode ? darkSurface : lightSurface
    }
    
    static func text(isDarkMode: Bool) -> Color {
        isDarkMode ? hackerGreen : Color(red: 0.08, green: 0.22, blue: 0.08)
    }
    
    static func buttonBackground(isDarkMode: Bool) -> Color {
        isDarkMode ? darkSurface : Color(red: 0.06, green: 0.18, blue: 0.06)
    }
    
    static func buttonBorder(isDarkMode: Bool) -> Color {
        isDarkMode ? hackerGreen.opacity(0.55) : hackerGreenDim.opacity(0.6)
    }
    
    // accent used for highlights, progres bars, active states
    static func accent(isDarkMode: Bool) -> Color {
        isDarkMode ? hackerGreen : hackerGreenDim
    }
}

enum AppSound {
    private static let player = TonePlayer()
    private static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "isSoundEnabled") as? Bool ?? true
    }

    static func tap() {
        guard isEnabled else { return }
        player.play(frequency: 420, duration: 0.03, volume: 0.10)
    }

    static func next() {
        guard isEnabled else { return }
        player.play(frequency: 340, duration: 0.028, volume: 0.09)
    }
    
    static func success() {
        guard isEnabled else { return }
        player.playSequence([
            (frequency: 520, duration: 0.05, volume: 0.2),
            (frequency: 660, duration: 0.07, volume: 0.2)
        ])
    }
    
    static func warning() {
        guard isEnabled else { return }
        player.playSequence([
            (frequency: 320, duration: 0.06, volume: 0.2),
            (frequency: 260, duration: 0.08, volume: 0.22)
        ])
    }
    
    static func toggle(_ isOn: Bool) {
        guard isEnabled else { return }
        player.play(frequency: isOn ? 500 : 380, duration: 0.035, volume: 0.11)
    }
}

private final class TonePlayer {
    private let sampleRate: Double = 44_100
    
    func play(frequency: Double, duration: Double, volume: Float) {
        playSequence([(frequency: frequency, duration: duration, volume: volume)])
    }
    
    func playSequence(_ notes: [(frequency: Double, duration: Double, volume: Float)]) {
        Task {
            for note in notes {
                await MainActor.run {
                    self.playTone(frequency: note.frequency, duration: note.duration, volume: note.volume)
                }
                let sleepNanos = UInt64((note.duration + 0.01) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: sleepNanos)
            }
        }
    }
    
    @MainActor
    private func playTone(frequency: Double, duration: Double, volume: Float) {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        let theta = 2.0 * Double.pi * frequency / sampleRate
        if let channelData = buffer.floatChannelData?[0] {
            for frame in 0..<Int(frameCount) {
                // Short fade-in/fade-out to avoid click artifacts.
                let progress = Double(frame) / Double(max(Int(frameCount) - 1, 1))
                let envelope = min(progress * 12, (1 - progress) * 12, 1)
                channelData[frame] = Float(sin(theta * Double(frame))) * volume * Float(max(envelope, 0))
            }
        }
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
            try engine.start()
            
            player.scheduleBuffer(buffer, at: nil, options: [.interrupts])
            player.play()
            
            let stopDelay = duration + 0.03
            DispatchQueue.main.asyncAfter(deadline: .now() + stopDelay) {
                player.stop()
                engine.stop()
            }
        } catch {
            engine.stop()
        }
    }
}

@main
struct CodearnApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showSplash = true
    @State private var splashIsExiting = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MenuView(userName: "T")
                    .opacity(showSplash && !splashIsExiting ? 0 : 1)
                    .scaleEffect(showSplash && !splashIsExiting ? 1.02 : 1.0)
                    .animation(.easeOut(duration: 0.38), value: splashIsExiting)
                    .animation(.easeOut(duration: 0.25), value: showSplash)

                if showSplash {
                    SplashView(isDarkMode: isDarkMode, isExiting: splashIsExiting)
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .tint(isDarkMode ? .white : .blue)
            .task {
                try? await Task.sleep(nanoseconds: 950_000_000)
                withAnimation(.easeInOut(duration: 0.42)) {
                    splashIsExiting = true
                }
                try? await Task.sleep(nanoseconds: 430_000_000)
                showSplash = false
            }
        }
    }
}
private struct SplashView: View {
    let isDarkMode: Bool
    let isExiting: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            AppTheme.background(isDarkMode: isDarkMode)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 54, weight: .black))
                    .foregroundStyle(AppTheme.accent(isDarkMode: isDarkMode))
                    .scaleEffect(pulse ? 1.04 : 0.96)
                Text("Codearn")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.text(isDarkMode: isDarkMode))
            }
            .opacity(isExiting ? 0 : 1)
            .scaleEffect(isExiting ? 1.08 : 1.0)
            .offset(y: isExiting ? -24 : 0)
            .animation(.easeInOut(duration: 0.42), value: isExiting)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
        }
        .onAppear {
            pulse = true
        }
    }
}
