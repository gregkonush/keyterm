import CoreHaptics
import UIKit

final class KeyboardHapticFeedback {
    private let fallbackGenerator = UISelectionFeedbackGenerator()
    private var hapticEngine: CHHapticEngine?
    private var supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private var engineStarted = false

    init() {
        configureEngineIfNeeded()
    }

    func prepare() {
        fallbackGenerator.prepare()
        configureEngineIfNeeded()
    }

    func emitKeyTap() {
        if playCoreHapticTap() {
            return
        }

        fallbackGenerator.selectionChanged()
        fallbackGenerator.prepare()
    }
}

private extension KeyboardHapticFeedback {
    func configureEngineIfNeeded() {
        guard supportsCoreHaptics else {
            return
        }
        guard hapticEngine == nil else {
            startEngineIfNeeded()
            return
        }

        do {
            let engine = try CHHapticEngine()
            engine.isAutoShutdownEnabled = true
            engine.stoppedHandler = { [weak self] _ in
                self?.engineStarted = false
            }
            engine.resetHandler = { [weak self] in
                self?.engineStarted = false
                self?.startEngineIfNeeded()
            }
            hapticEngine = engine
            try engine.start()
            engineStarted = true
        } catch {
            supportsCoreHaptics = false
            hapticEngine = nil
            engineStarted = false
        }
    }

    func startEngineIfNeeded() {
        guard supportsCoreHaptics, let hapticEngine else {
            return
        }
        guard !engineStarted else {
            return
        }

        do {
            try hapticEngine.start()
            engineStarted = true
        } catch {
            supportsCoreHaptics = false
            self.hapticEngine = nil
            engineStarted = false
        }
    }

    func playCoreHapticTap() -> Bool {
        guard supportsCoreHaptics, let hapticEngine else {
            return false
        }

        if !engineStarted {
            do {
                try hapticEngine.start()
                engineStarted = true
            } catch {
                supportsCoreHaptics = false
                self.hapticEngine = nil
                engineStarted = false
                return false
            }
        }

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.32)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.42)
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensity, sharpness],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            return true
        } catch {
            return false
        }
    }
}
