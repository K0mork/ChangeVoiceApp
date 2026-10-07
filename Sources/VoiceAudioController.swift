import AVFAudio
import Foundation

@MainActor
final class VoiceAudioController: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var isRequestingPermission = false
    @Published private(set) var permissionDenied = false
    @Published var pitchSemitones = 0.0 {
        didSet { pitchUnit?.pitch = Float(pitchSemitones * 100) }
    }
    @Published var tone = 0.0 {
        didSet { applyTone() }
    }

    private let session = AVAudioSession.sharedInstance()
    private var engine: AVAudioEngine?
    private var pitchUnit: AVAudioUnitTimePitch?
    private var equalizer: AVAudioUnitEQ?
    private var observers: [NSObjectProtocol] = []
    private var permissionRequestID: UUID?
    private var isForeground = true
    private var isUserMuted = false
    private var requiresManualResume = false

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
                self?.stopForSystemChange()
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
                self?.stopForSystemChange()
            }
        })
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func activateForForeground() {
        isForeground = true
        guard !isUserMuted, !requiresManualResume else { return }
        requestPermissionAndStart()
    }

    func enterBackground() {
        isForeground = false
        permissionRequestID = nil
        isRequestingPermission = false
        stopEngine()
    }

    func toggleMute() {
        guard !isRequestingPermission, !permissionDenied else { return }
        if isRunning {
            isUserMuted = true
            stopEngine()
        } else {
            isUserMuted = false
            requiresManualResume = false
            requestPermissionAndStart()
        }
    }

    private func requestPermissionAndStart() {
        guard isForeground, !isRunning, !isRequestingPermission, !requiresManualResume, !isUserMuted else { return }
        let requestID = UUID()
        permissionRequestID = requestID
        isRequestingPermission = true
        permissionDenied = false

        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor [weak self] in
                guard let self, self.permissionRequestID == requestID else { return }
                self.permissionRequestID = nil
                self.isRequestingPermission = false
                guard self.isForeground else { return }
                guard granted else {
                    self.permissionDenied = true
                    return
                }
                self.startEngine()
            }
        }
    }

    private func startEngine() {
        guard isForeground, !isRunning, !requiresManualResume, !isUserMuted else { return }
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
            permissionDenied = false
        } catch {
            engine?.stop()
            engine = nil
            pitchUnit = nil
            equalizer = nil
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            isRunning = false
            requiresManualResume = true
        }
    }

    private func applyTone() {
        guard let bands = equalizer?.bands, bands.count >= 2 else { return }
        bands[0].gain = Float(-tone * 3)
        bands[1].gain = Float(tone * 5)
    }

    private func stopForSystemChange() {
        guard isRunning || isRequestingPermission else { return }
        requiresManualResume = true
        permissionRequestID = nil
        isRequestingPermission = false
        stopEngine()
    }

    private func stopEngine() {
        engine?.stop()
        engine = nil
        pitchUnit = nil
        equalizer = nil
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
        isRunning = false
    }

    private enum AudioError: Error {
        case noInput
    }
}
