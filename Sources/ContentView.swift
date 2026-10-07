import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var audio = VoiceAudioController()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    private let bodyRed = Color(red: 0.66, green: 0.045, blue: 0.075)
    private let edgeRed = Color(red: 0.84, green: 0.095, blue: 0.12)

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let dialDiameter = min(size.height * 0.56, size.width * 0.28)

            ZStack {
                Color(red: 0.025, green: 0.028, blue: 0.032)

                BowTieChassis(bodyRed: bodyRed, edgeRed: edgeRed)
                    .padding(.horizontal, size.width * 0.012)
                    .padding(.vertical, size.height * 0.008)
                    .shadow(color: .black.opacity(0.42), radius: 18, x: 0, y: 12)

                HStack(spacing: 0) {
                    VoiceDial(
                        value: Binding(
                            get: { (audio.pitchSemitones + 6) / 12 },
                            set: { audio.pitchSemitones = ($0 * 12) - 6 }
                        ),
                        diameter: dialDiameter,
                        label: "声の高さ",
                        valueDescription: String(format: "%+.1f セミトーン", audio.pitchSemitones),
                        identifier: "pitch-dial"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    VoiceDial(
                        value: Binding(
                            get: { (audio.tone + 1) / 2 },
                            set: { audio.tone = ($0 * 2) - 1 }
                        ),
                        diameter: dialDiameter,
                        label: "声の響き",
                        valueDescription: String(format: "%+.0f", audio.tone * 100),
                        identifier: "tone-dial"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: size.width, height: size.height)

                CenterControl(
                    isRunning: audio.isRunning,
                    isRequestingPermission: audio.isRequestingPermission,
                    permissionDenied: audio.permissionDenied,
                    toggleMute: audio.toggleMute,
                    openSettings: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                )
                .position(x: size.width / 2, y: size.height / 2)
            }
            .frame(width: size.width, height: size.height)
            .clipped()
        }
        .background(Color(red: 0.025, green: 0.028, blue: 0.032))
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .onAppear { audio.activateForForeground() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                audio.activateForForeground()
            case .background:
                audio.enterBackground()
            case .inactive:
                // The microphone permission sheet temporarily makes the app inactive.
                break
            @unknown default:
                audio.enterBackground()
            }
        }
    }
}

private struct BowTieChassis: View {
    let bodyRed: Color
    let edgeRed: Color

    var body: some View {
        BowTieShape()
            .fill(
                LinearGradient(
                    colors: [edgeRed, bodyRed, Color(red: 0.54, green: 0.025, blue: 0.055)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(BowTieShape().stroke(.white.opacity(0.24), lineWidth: 1.2))
            .overlay {
                CenterKnotShape()
                    .fill(
                        LinearGradient(
                            colors: [edgeRed, bodyRed, Color(red: 0.47, green: 0.018, blue: 0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(CenterKnotShape().stroke(.white.opacity(0.25), lineWidth: 1))
                    .frame(width: 80, height: 118)
            }
            .accessibilityHidden(true)
    }
}

private struct BowTieShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }

        var path = Path()
        path.move(to: point(0.50, 0.29))
        path.addCurve(
            to: point(0.035, 0.075),
            control1: point(0.40, 0.20),
            control2: point(0.18, 0.045)
        )
        path.addCurve(
            to: point(0.035, 0.925),
            control1: point(-0.005, 0.31),
            control2: point(-0.005, 0.69)
        )
        path.addCurve(
            to: point(0.495, 0.71),
            control1: point(0.18, 0.955),
            control2: point(0.40, 0.80)
        )
        path.addCurve(
            to: point(0.965, 0.925),
            control1: point(0.60, 0.80),
            control2: point(0.82, 0.955)
        )
        path.addCurve(
            to: point(0.965, 0.075),
            control1: point(1.005, 0.69),
            control2: point(1.005, 0.31)
        )
        path.addCurve(
            to: point(0.50, 0.29),
            control1: point(0.82, 0.045),
            control2: point(0.60, 0.20)
        )
        path.closeSubpath()
        return path
    }
}

private struct CenterKnotShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }

        var path = Path()
        path.move(to: point(0.16, 0.02))
        path.addQuadCurve(to: point(0.84, 0.02), control: point(0.50, 0.08))
        path.addCurve(
            to: point(0.84, 0.98),
            control1: point(0.98, 0.25),
            control2: point(0.98, 0.75)
        )
        path.addQuadCurve(to: point(0.16, 0.98), control: point(0.50, 0.92))
        path.addCurve(
            to: point(0.16, 0.02),
            control1: point(0.02, 0.75),
            control2: point(0.02, 0.25)
        )
        path.closeSubpath()
        return path
    }
}

private struct VoiceDial: View {
    @Binding var value: Double
    let diameter: CGFloat
    let label: String
    let valueDescription: String
    let identifier: String

    private let sweep = 270.0
    private let accent = Color(red: 0.96, green: 0.18, blue: 0.18)

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.13, blue: 0.14), Color(red: 0.02, green: 0.023, blue: 0.027)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(Circle().stroke(.black, lineWidth: max(3, diameter * 0.018)))
                .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1).padding(diameter * 0.018))
                .shadow(color: .black.opacity(0.48), radius: diameter * 0.045, x: 0, y: diameter * 0.025)

            Circle()
                .stroke(.white.opacity(0.12), lineWidth: 1)
                .padding(diameter * 0.15)

            ForEach(0..<41, id: \.self) { index in
                let progress = Double(index) / 40
                Capsule()
                    .fill(progress <= value ? accent : .white.opacity(index.isMultiple(of: 5) ? 0.55 : 0.24))
                    .frame(
                        width: index.isMultiple(of: 5) ? max(2, diameter * 0.009) : max(1, diameter * 0.005),
                        height: index.isMultiple(of: 5) ? diameter * 0.036 : diameter * 0.021
                    )
                    .offset(y: -diameter * 0.425)
                    .rotationEffect(.degrees(-135 + progress * sweep))
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(red: 0.17, green: 0.18, blue: 0.19), Color(red: 0.045, green: 0.05, blue: 0.055)],
                        center: .init(x: 0.34, y: 0.28),
                        startRadius: 1,
                        endRadius: diameter * 0.33
                    )
                )
                .frame(width: diameter * 0.70, height: diameter * 0.70)
                .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))

            Capsule()
                .fill(LinearGradient(colors: [.white, accent, accent.opacity(0.8)], startPoint: .top, endPoint: .bottom))
                .frame(width: max(4, diameter * 0.022), height: diameter * 0.22)
                .offset(y: -diameter * 0.16)
                .rotationEffect(.degrees(-135 + value * sweep))

            Circle()
                .fill(Color(red: 0.035, green: 0.04, blue: 0.045))
                .frame(width: diameter * 0.12, height: diameter * 0.12)
                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
        }
        .frame(width: diameter, height: diameter)
        .contentShape(Circle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { updateValue(at: $0.location) })
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue(valueDescription)
        .accessibilityIdentifier(identifier)
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
        value = (min(135, max(-135, normalized)) + 135) / sweep
    }
}

private struct CenterControl: View {
    let isRunning: Bool
    let isRequestingPermission: Bool
    let permissionDenied: Bool
    let toggleMute: () -> Void
    let openSettings: () -> Void

    var body: some View {
        Button {
            if permissionDenied {
                openSettings()
            } else {
                toggleMute()
            }
        } label: {
            Group {
                if isRequestingPermission {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
            .frame(width: 42, height: 42)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.30, green: 0.032, blue: 0.052), Color(red: 0.075, green: 0.024, blue: 0.032)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Circle()
            )
            .shadow(color: .black.opacity(0.42), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isRequestingPermission)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(permissionDenied ? "アプリのマイク設定を開きます" : (isRunning ? "音声を消音します" : "音声を再開します"))
        .accessibilityIdentifier("center-control")
    }

    private var symbol: String {
        if permissionDenied { return "mic.slash.fill" }
        return isRunning ? "speaker.wave.2.fill" : "speaker.slash.fill"
    }

    private var accessibilityLabel: String {
        if permissionDenied { return "設定でマイクを許可" }
        return isRunning ? "消音" : "音声を再開"
    }
}
