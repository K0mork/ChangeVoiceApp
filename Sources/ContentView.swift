import SwiftUI

struct ContentView: View {
    @StateObject private var audio = VoiceAudioController()
    @Environment(\.scenePhase) private var scenePhase

    private let ink = Color(red: 0.11, green: 0.12, blue: 0.14)
    private let paper = Color(red: 0.96, green: 0.94, blue: 0.89)
    private let red = Color(red: 0.78, green: 0.16, blue: 0.19)

    var body: some View {
        ZStack {
            paper.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    introduction
                    controlPanel
                    actionButton
                    safetyNote
                    footer
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.light)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                audio.setForeground(true)
            case .background:
                audio.setForeground(false)
            case .inactive:
                break
            @unknown default:
                audio.setForeground(false)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            BowTieMark(color: red)
                .frame(width: 31, height: 23)
            Text("VOICE STUDIO")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(ink)
            Spacer()
            HStack(spacing: 7) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(audio.isRunning ? "LIVE" : "STANDBY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.1)
                    .foregroundStyle(ink.opacity(0.72))
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(.white.opacity(0.7), in: Capsule())
            .overlay(Capsule().stroke(ink.opacity(0.08), lineWidth: 1))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(audio.isRunning ? "動作中" : "待機中")
        }
        .padding(.bottom, 4)
    }

    private var introduction: some View {
        VStack(spacing: 9) {
            Text("声を、少しだけ\n変えてみる。")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .tracking(-1.1)
                .lineSpacing(1)
                .multilineTextAlignment(.center)
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)

            Text("マイクの声をリアルタイムに加工します")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ink.opacity(0.6))

            BowTieMark(color: red)
                .frame(width: 104, height: 62)
                .padding(.top, 4)
                .accessibilityHidden(true)
        }
    }

    private var controlPanel: some View {
        VStack(spacing: 18) {
            HStack {
                Text("TONE CONTROLS")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.7)
                Spacer()
                Text("INPUT  →  OUTPUT")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .foregroundStyle(.white.opacity(0.48))
            }
            .foregroundStyle(.white.opacity(0.78))

            HStack(spacing: 8) {
                DialView(
                    title: "PITCH",
                    subtitle: "声の高さ",
                    value: Binding(
                        get: { (audio.pitchSemitones + 6) / 12 },
                        set: { audio.pitchSemitones = ($0 * 12) - 6 }
                    ),
                    displayValue: String(format: "%+.1f", audio.pitchSemitones),
                    unit: "SEMITONES",
                    accent: Color(red: 0.92, green: 0.43, blue: 0.32)
                )

                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 1, height: 140)

                DialView(
                    title: "TONE",
                    subtitle: "声の響き",
                    value: Binding(
                        get: { (audio.tone + 1) / 2 },
                        set: { audio.tone = ($0 * 2) - 1 }
                    ),
                    displayValue: String(format: "%+.0f", audio.tone * 100),
                    unit: "WARM  /  BRIGHT",
                    accent: Color(red: 0.94, green: 0.72, blue: 0.40)
                )
            }

            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 10, weight: .bold))
                Text("つまみをドラッグして調整")
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Button("リセット") {
                    withAnimation(.easeOut(duration: 0.18)) {
                        audio.pitchSemitones = 0
                        audio.tone = 0
                    }
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.82))
                .accessibilityHint("高さと響きを初期値に戻します")
            }
            .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.17, blue: 0.19), ink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 26, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
        .shadow(color: ink.opacity(0.13), radius: 22, x: 0, y: 13)
    }

    private var actionButton: some View {
        VStack(spacing: 11) {
            Button {
                audio.toggle()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: audio.isRunning ? "stop.fill" : "waveform")
                        .font(.system(size: 14, weight: .black))
                    Text(audio.isRequestingPermission ? "許可を確認中…" : (audio.isRunning ? "変声を停止" : "マイクを開始"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 21)
                .frame(height: 58)
                .background(audio.isRunning ? ink : red, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: (audio.isRunning ? ink : red).opacity(0.2), radius: 12, x: 0, y: 7)
            }
            .buttonStyle(.plain)
            .disabled(audio.isRequestingPermission)
            .opacity(audio.isRequestingPermission ? 0.68 : 1)
            .accessibilityHint(audio.isRunning ? "マイク入力と音声出力をすぐに停止します" : "タップするとマイクの使用許可を確認します")

            HStack(spacing: 7) {
                Image(systemName: audio.statusKind == .attention ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 12))
                Text(audio.statusMessage)
                    .font(.system(size: 12, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(statusMessageColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(audio.statusKind == .attention ? .updatesFrequently : [])
        }
    }

    private var safetyNote: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(red)
                .padding(.top, 2)
            Text("スピーカーの音がマイクに戻るとハウリングします。開始時の音量は小さめです。周囲に配慮し、必要ならイヤホンをお使いください。")
                .font(.system(size: 11, weight: .medium))
                .lineSpacing(3)
                .foregroundStyle(ink.opacity(0.66))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack {
            Text("PITCH SHIFT ·  ±6 semitones")
            Spacer(minLength: 10)
            Text("TONE ·  EQ COLOR")
        }
        .font(.system(size: 8, weight: .bold, design: .monospaced))
        .tracking(0.45)
        .foregroundStyle(ink.opacity(0.42))
    }

    private var statusColor: Color {
        switch audio.statusKind {
        case .ready: return Color(red: 0.47, green: 0.62, blue: 0.48)
        case .active: return Color(red: 0.29, green: 0.66, blue: 0.42)
        case .attention: return Color(red: 0.81, green: 0.42, blue: 0.22)
        }
    }

    private var statusMessageColor: Color {
        audio.statusKind == .attention ? red : ink.opacity(0.62)
    }
}

private struct BowTieMark: View {
    var color: Color

    var body: some View {
        Canvas { context, size in
            let midX = size.width / 2
            let midY = size.height / 2
            let left = Path { path in
                path.move(to: CGPoint(x: midX - 4, y: midY - 8))
                path.addLine(to: CGPoint(x: size.width * 0.06, y: size.height * 0.08))
                path.addQuadCurve(to: CGPoint(x: size.width * 0.04, y: size.height * 0.5), control: CGPoint(x: size.width * 0.01, y: size.height * 0.3))
                path.addQuadCurve(to: CGPoint(x: size.width * 0.06, y: size.height * 0.92), control: CGPoint(x: size.width * 0.01, y: size.height * 0.7))
                path.addLine(to: CGPoint(x: midX - 4, y: midY + 8))
                path.closeSubpath()
            }
            let right = Path { path in
                path.move(to: CGPoint(x: midX + 4, y: midY - 8))
                path.addLine(to: CGPoint(x: size.width * 0.94, y: size.height * 0.08))
                path.addQuadCurve(to: CGPoint(x: size.width * 0.96, y: size.height * 0.5), control: CGPoint(x: size.width * 0.99, y: size.height * 0.3))
                path.addQuadCurve(to: CGPoint(x: size.width * 0.94, y: size.height * 0.92), control: CGPoint(x: size.width * 0.99, y: size.height * 0.7))
                path.addLine(to: CGPoint(x: midX + 4, y: midY + 8))
                path.closeSubpath()
            }
            context.fill(left, with: .linearGradient(Gradient(colors: [color.opacity(0.84), color]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: midX, y: size.height)))
            context.fill(right, with: .linearGradient(Gradient(colors: [color, color.opacity(0.78)]), startPoint: CGPoint(x: midX, y: 0), endPoint: CGPoint(x: size.width, y: size.height)))

            var leftFold = Path()
            leftFold.move(to: CGPoint(x: size.width * 0.30, y: size.height * 0.18))
            leftFold.addLine(to: CGPoint(x: midX - 2, y: midY))
            leftFold.addLine(to: CGPoint(x: size.width * 0.30, y: size.height * 0.82))
            context.stroke(leftFold, with: .color(.white.opacity(0.17)), lineWidth: max(1, size.width * 0.015))
            var rightFold = Path()
            rightFold.move(to: CGPoint(x: size.width * 0.70, y: size.height * 0.18))
            rightFold.addLine(to: CGPoint(x: midX + 2, y: midY))
            rightFold.addLine(to: CGPoint(x: size.width * 0.70, y: size.height * 0.82))
            context.stroke(rightFold, with: .color(.black.opacity(0.12)), lineWidth: max(1, size.width * 0.015))

            let knot = CGRect(x: midX - 4, y: midY - 8, width: 8, height: 16)
            context.fill(Path(roundedRect: knot, cornerRadius: 2), with: .color(color.opacity(0.9)))
        }
        .shadow(color: color.opacity(0.2), radius: 3, y: 2)
    }
}

private struct DialView: View {
    let title: String
    let subtitle: String
    @Binding var value: Double
    let displayValue: String
    let unit: String
    let accent: Color

    private let dialSize: CGFloat = 122
    private let travelDegrees = 270.0

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .tracking(1.8)
                .foregroundStyle(.white.opacity(0.9))
            Text(subtitle)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))

            ZStack {
                Circle()
                    .stroke(.white.opacity(0.09), lineWidth: 1)
                    .frame(width: dialSize - 3, height: dialSize - 3)
                ForEach(0..<25, id: \.self) { index in
                    Capsule()
                        .fill(indexProgress(index) <= value ? accent.opacity(0.9) : .white.opacity(0.22))
                        .frame(width: index.isMultiple(of: 4) ? 2.2 : 1.3, height: index.isMultiple(of: 4) ? 7 : 4)
                        .offset(y: -(dialSize / 2 - 2))
                        .rotationEffect(.degrees(-135 + Double(index) * (travelDegrees / 24)))
                }
                Circle()
                    .fill(
                        LinearGradient(colors: [Color(red: 0.30, green: 0.32, blue: 0.34), Color(red: 0.12, green: 0.13, blue: 0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 87, height: 87)
                    .overlay(Circle().stroke(.white.opacity(0.22), lineWidth: 1))
                    .shadow(color: .black.opacity(0.4), radius: 7, x: 0, y: 5)
                Circle()
                    .fill(accent)
                    .frame(width: 4, height: 25)
                    .offset(y: -31)
                    .rotationEffect(.degrees(-135 + value * travelDegrees))
                VStack(spacing: 1) {
                    Text(displayValue)
                        .font(.system(size: 21, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.white)
                    Text(unit)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .tracking(0.6)
                        .foregroundStyle(.white.opacity(0.48))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .offset(y: 8)
                .allowsHitTesting(false)
            }
            .frame(width: dialSize, height: dialSize)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in updateValue(at: gesture.location) }
            )
            .accessibilityElement()
            .accessibilityLabel(title == "PITCH" ? "声の高さ" : "声の響き")
            .accessibilityValue(displayValue + (title == "PITCH" ? " セミトーン" : " パーセント"))
            .accessibilityHint("上げ下げして調整します")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: value = min(1, value + 0.04)
                case .decrement: value = max(0, value - 0.04)
                @unknown default: break
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }

    private func indexProgress(_ index: Int) -> Double {
        Double(index) / 24
    }

    private func updateValue(at point: CGPoint) {
        let center = CGPoint(x: dialSize / 2, y: dialSize / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let angle = atan2(dy, dx) * 180 / .pi + 90
        let normalizedAngle = angle > 180 ? angle - 360 : angle
        let clamped = min(135, max(-135, normalizedAngle))
        value = (clamped + 135) / travelDegrees
    }
}
