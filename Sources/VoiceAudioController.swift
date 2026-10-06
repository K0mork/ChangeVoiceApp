import AVFAudio
import Foundation

@MainActor
final class VoiceAudioController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var isRequestingPermission = false
    @Published private(set) var statusMessage = "準備ができています"
    @Published private(set) var statusKind: StatusKind = .ready
    @Published var pitchSemitones = 0.0 {
        didSet { pitchUnit?.pitch = Float(pitchSemitones * 100) }
    }
    @Published var tone = 0.0 {
        didSet { applyTone() }
    }

    enum StatusKind: Equatable {
        case ready, active, attention
    }

    private let session = AVAudioSession.sharedInstance()
    private var engine: AVAudioEngine?
    private var pitchUnit: AVAudioUnitTimePitch?
    private var equalizer: AVAudioUnitEQ?
    private var observers: [NSObjectProtocol] = []
    private var permissionRequestID: UUID?
    private var isForeground = true

    init() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { [weak self] note in
            guard let rawType = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  AVAudioSession.InterruptionType(rawValue: rawType) == .began else { return }
            Task { @MainActor [weak self] in
                self?.stop(message: "通話などで一時停止しました")
            }
        })
        observers.append(center.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: .main
        ) { [weak self] note in
            guard let rawReason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: rawReason),
                  reason != .categoryChange else { return }
            Task { @MainActor [weak self] in
                guard self?.isRunning == true else { return }
                self?.stop(message: "音声の接続先が変わったため停止しました")
            }
        })
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func toggle() {
        guard !isRequestingPermission else { return }
        if isRunning {
            stop(message: "停止しました")
        } else {
            requestPermissionAndStart()
        }
    }

    func setForeground(_ isForeground: Bool) {
        self.isForeground = isForeground
        guard !isForeground else { return }
        if isRequestingPermission {
            permissionRequestID = nil
            isRequestingPermission = false
            statusKind = .attention
            statusMessage = "画面に戻ってからもう一度開始してください"
        }
        if isRunning {
            stop(message: "画面を離れたため停止しました")
        }
    }

    private func requestPermissionAndStart() {
        let requestID = UUID()
        permissionRequestID = requestID
        isRequestingPermission = true
        statusKind = .ready
        statusMessage = "マイクの使用許可を確認しています…"
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self, self.permissionRequestID == requestID else { return }
                self.permissionRequestID = nil
                self.isRequestingPermission = false
                guard self.isForeground else { return }
                guard granted else {
                    self.statusKind = .attention
                    self.statusMessage = "マイクの使用が許可されていません。設定から変更できます"
                    return
                }
                self.startEngine()
            }
        }
    }

    private func startEngine() {
        guard !isRunning, isForeground else { return }
        do {
            try session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try session.setActive(true)

            let newEngine = AVAudioEngine()
            let pitch = AVAudioUnitTimePitch()
            pitch.rate = 1
            pitch.pitch = Float(pitchSemitones * 100)

            let eq = AVAudioUnitEQ(numberOfBands: 2)
            let low = eq.bands[0]
            low.filterType = .lowShelf
            low.frequency = 180
            low.bandwidth = 0.7
            low.gain = Float(-tone * 3)
            low.bypass = false

            let high = eq.bands[1]
            high.filterType = .highShelf
            high.frequency = 3_200
            high.bandwidth = 0.7
            high.gain = Float(tone * 5)
            high.bypass = false

            let input = newEngine.inputNode
            let format = input.outputFormat(forBus: 0)
            guard format.channelCount > 0, format.sampleRate > 0 else {
                throw AudioError.noInput
            }

            newEngine.attach(pitch)
            newEngine.attach(eq)
            newEngine.connect(input, to: pitch, format: format)
            newEngine.connect(pitch, to: eq, format: format)
            newEngine.connect(eq, to: newEngine.mainMixerNode, format: format)
            newEngine.mainMixerNode.outputVolume = 0.18
            newEngine.prepare()
            try newEngine.start()

            engine = newEngine
            pitchUnit = pitch
            equalizer = eq
            isRunning = true
            statusKind = .active
            statusMessage = "変声中 · 音量は控えめです"
        } catch {
            engine?.stop()
            engine = nil
            pitchUnit = nil
            equalizer = nil
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            statusKind = .attention
            statusMessage = "音声を開始できませんでした。マイクと出力を確認してください"
        }
    }

    private func applyTone() {
        guard let bands = equalizer?.bands, bands.count >= 2 else { return }
        bands[0].gain = Float(-tone * 3)
        bands[1].gain = Float(tone * 5)
    }

    private func stop(message: String) {
        permissionRequestID = nil
        isRequestingPermission = false
        engine?.stop()
        engine = nil
        pitchUnit = nil
        equalizer = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        isRunning = false
        statusKind = message == "停止しました" ? .ready : .attention
        statusMessage = message
    }

    private enum AudioError: Error {
        case noInput
    }
}
