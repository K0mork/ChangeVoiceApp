import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var audio = VoiceAudioController()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    private let red = Color(red: 0.66, green: 0.045, blue: 0.075)
    private let brightRed = Color(red: 0.91, green: 0.12, blue: 0.14)
    private let charcoal = Color(red: 0.035, green: 0.043, blue: 0.052)

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let dialSize = min(size.height * 0.80, size.width * 0.36)

            ZStack {
                Color(red: 0.025, green: 0.028, blue: 0.032)

                BowTieChassis(red: red, highlight: brightRed)
                    .padding(.horizontal, size.width * 0.012)
                    .padding(.vertical, size.height * 0.035)
                    .shadow(color: .black.opacity(0.58), radius: 32, x: 0, y: 23)

                HStack(spacing: size.height * 0.16) {
                    VoiceDial(
                        value: Binding(
                            get: { (audio.pitchSemitones + 6) / 12 },
                            set: { audio.pitchSemitones = ($0 * 12) - 6 }
                        ),
                        diameter: dialSize,
                        accessibilityValue: String(format: "%+.1f セミトーン", audio.pitchSemitones),
                        accessibilityLabel: "声の高さ",
                        accessibilityIdentifier: "pitch-dial"
                    )

                    VoiceDial(
                        value: Binding(
                            get: { (audio.tone + 1) / 2 },
                            set: { audio.tone = ($0 * 2) - 1 }
                        ),
                        diameter: dialSize,
                        accessibilityValue: String(format: "%+.0f", audio.tone * 100),
                        accessibilityLabel: "声の響き",
                        accessibilityIdentifier: "tone-dial"
                    )
                }
                .frame(width: size.width * 0.87, height: size.height * 0.88)
                .position(x: size.width / 2, y: size.height / 2)

                MuteControl(isRunning: audio.isRunning, isEnabled: !audio.permissionDenied, action: audio.toggleMute)
                    .position(x: size.width / 2, y: size.height / 2)

                if audio.permissionDenied {
                    Button {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            openURL(settingsURL)
                        }
                    } label: {
                        Image(systemName: "mic.slash.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(red: 1, green: 0.76, blue: 0.52))
                            .frame(width: 42, height: 42)
                            .background(.black.opacity(0.55), in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.32), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("設定でマイクを許可")
                    .accessibilityHint("アプリの設定を開きます")
                    .position(x: size.width * 0.945, y: size.height * 0.13)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .background(charcoal)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .onAppear {
            audio.activateForForeground()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                audio.activateForForeground()
            case .background:
                audio.enterBackground()
            case .inactive:
                // iOS presents microphone permission while the app is inactive.
                break
            @unknown default:
                audio.enterBackground()
            }
        }
    }
}

private struct BowTieChassis: View {
    let red: Color
    let highlight: Color

    var body: some View {
        Canvas { context, size in
            let left = wingPath(size: size, isLeft: true)
            let right = wingPath(size: size, isLeft: false)
            let gradient = Gradient(stops: [
                .init(color: highlight.opacity(0.94), location: 0),
                .init(color: red, location: 0.45),
                .init(color: Color(red: 0.30, green: 0.015, blue: 0.035), location: 1)
            ])
            let shading = GraphicsContext.Shading.linearGradient(
                gradient,
                startPoint: CGPoint(x: size.width * 0.2, y: 0),
                endPoint: CGPoint(x: size.width * 0.8, y: size.height)
            )

            context.addFilter(.shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 12))
            context.fill(left, with: shading)
            context.fill(right, with: shading)
            context.stroke(left, with: .color(.white.opacity(0.28)), lineWidth: 1.5)
            context.stroke(right, with: .color(.white.opacity(0.28)), lineWidth: 1.5)

            var leftFold = Path()
            leftFold.move(to: CGPoint(x: size.width * 0.31, y: size.height * 0.12))
            leftFold.addQuadCurve(
                to: CGPoint(x: size.width * 0.31, y: size.height * 0.88),
                control: CGPoint(x: size.width * 0.21, y: size.height * 0.5)
            )
            var rightFold = Path()
            rightFold.move(to: CGPoint(x: size.width * 0.69, y: size.height * 0.12))
            rightFold.addQuadCurve(
                to: CGPoint(x: size.width * 0.69, y: size.height * 0.88),
                control: CGPoint(x: size.width * 0.79, y: size.height * 0.5)
            )
            context.stroke(leftFold, with: .color(.white.opacity(0.1)), lineWidth: 1)
            context.stroke(rightFold, with: .color(.black.opacity(0.22)), lineWidth: 1)
        }
        .overlay {
            BowTieShape()
                .stroke(.black.opacity(0.42), lineWidth: 1)
                .padding(1)
        }
        .overlay {
            CenterKnot()
                .fill(
                    LinearGradient(
                        colors: [highlight, red, Color(red: 0.37, green: 0.02, blue: 0.045)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(CenterKnot().stroke(.white.opacity(0.32), lineWidth: 1))
                .frame(width: 64, height: 102)
                .shadow(color: .black.opacity(0.45), radius: 9, x: 0, y: 6)
        }
        .accessibilityHidden(true)
    }

    private func wingPath(size: CGSize, isLeft: Bool) -> Path {
        let left = BowTieShape.leftWing(in: size)
        guard !isLeft else { return left }
        return left.applying(CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -size.width, y: 0))
    }
}

private struct BowTieShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Self.leftWing(in: rect.size)
        let right = path.applying(CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: -rect.width, y: 0))
        path.addPath(right)
        return path
    }

    static func leftWing(in size: CGSize) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: size.width * 0.465, y: size.height * 0.34))
        path.addCurve(
            to: CGPoint(x: size.width * 0.035, y: size.height * 0.07),
            control1: CGPoint(x: size.width * 0.32, y: size.height * 0.24),
            control2: CGPoint(x: size.width * 0.11, y: size.height * 0.055)
        )
        path.addCurve(
            to: CGPoint(x: size.width * 0.035, y: size.height * 0.93),
            control1: CGPoint(x: -size.width * 0.015, y: size.height * 0.34),
            control2: CGPoint(x: -size.width * 0.015, y: size.height * 0.66)
        )
        path.addCurve(
            to: CGPoint(x: size.width * 0.465, y: size.height * 0.66),
            control1: CGPoint(x: size.width * 0.11, y: size.height * 0.945),
            control2: CGPoint(x: size.width * 0.32, y: size.height * 0.76)
        )
        path.addLine(to: CGPoint(x: size.width * 0.465, y: size.height * 0.34))
        path.closeSubpath()
        return path
    }
}

private struct CenterKnot: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.18, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.82, y: 0), control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.08))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.5))
        path.addQuadCurve(to: CGPoint(x: rect.width * 0.82, y: rect.height), control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.92))
        path.addLine(to: CGPoint(x: rect.width * 0.18, y: rect.height))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height * 0.5), control: CGPoint(x: rect.width * 0.5, y: rect.height * 0.92))
        path.closeSubpath()
        return path
    }
}

private struct VoiceDial: View {
    @Binding var value: Double
    let diameter: CGFloat
    let accessibilityValue: String
    let accessibilityLabel: String
    let accessibilityIdentifier: String

    private let travel = 270.0
    private let accent = Color(red: 0.98, green: 0.20, blue: 0.19)

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.16, green: 0.17, blue: 0.18), Color(red: 0.018, green: 0.02, blue: 0.023)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(Circle().stroke(.black, lineWidth: 7))
                .overlay(Circle().stroke(.white.opacity(0.33), lineWidth: 1.2).padding(5))
                .shadow(color: .black.opacity(0.76), radius: diameter * 0.075, x: 0, y: diameter * 0.045)

            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 1)
                .padding(diameter * 0.15)

            ForEach(0..<41, id: \.self) { index in
                let progress = Double(index) / 40
                Capsule()
                    .fill(progress <= value ? accent : .white.opacity(index.isMultiple(of: 5) ? 0.65 : 0.28))
                    .frame(
                        width: index.isMultiple(of: 5) ? max(2, diameter * 0.009) : max(1, diameter * 0.005),
                        height: index.isMultiple(of: 5) ? diameter * 0.036 : diameter * 0.021
                    )
                    .offset(y: -diameter * 0.425)
                    .rotationEffect(.degrees(-135 + progress * travel))
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.2, green: 0.21, blue: 0.22), Color(red: 0.055, green: 0.06, blue: 0.065)],
                        center: .init(x: 0.34, y: 0.28),
                        startRadius: 1,
                        endRadius: diameter * 0.33
                    )
                )
                .frame(width: diameter * 0.69, height: diameter * 0.69)
                .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 1))
                .shadow(color: .black.opacity(0.62), radius: diameter * 0.04, x: 0, y: diameter * 0.03)

            Capsule()
                .fill(LinearGradient(colors: [.white, accent, Color(red: 0.46, green: 0.025, blue: 0.04)], startPoint: .top, endPoint: .bottom))
                .frame(width: max(5, diameter * 0.023), height: diameter * 0.255)
                .offset(y: -diameter * 0.17)
                .rotationEffect(.degrees(-135 + value * travel))
                .shadow(color: accent.opacity(0.5), radius: diameter * 0.018)

            Circle()
                .fill(Color(red: 0.06, green: 0.065, blue: 0.07))
                .frame(width: diameter * 0.12, height: diameter * 0.12)
                .overlay(Circle().stroke(.white.opacity(0.22), lineWidth: 1))

        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { updateValue(at: $0.location) })
        .accessibilityElement()
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityHint("回して調整します")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(1, value + 0.035)
            case .decrement: value = max(0, value - 0.035)
            @unknown default: break
            }
        }
    }

    private func updateValue(at point: CGPoint) {
        let center = CGPoint(x: diameter / 2, y: diameter / 2)
        let angle = atan2(point.y - center.y, point.x - center.x) * 180 / .pi + 90
        let normalized = angle > 180 ? angle - 360 : angle
        value = (min(135, max(-135, normalized)) + 135) / travel
    }
}

private struct MuteControl: View {
    let isRunning: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isRunning ? "speaker.wave.2.fill" : "speaker.slash.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .frame(width: 46, height: 46)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.32, green: 0.035, blue: 0.055), Color(red: 0.075, green: 0.025, blue: 0.032)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Circle()
                )
                .overlay(Circle().stroke(.white.opacity(0.32), lineWidth: 1))
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityLabel(isRunning ? "消音" : "音声を再開")
        .accessibilityHint(isRunning ? "音声入力と出力を停止します" : "マイクの許可後に音声を再開します")
        .accessibilityIdentifier("mute-control")
    }
}
