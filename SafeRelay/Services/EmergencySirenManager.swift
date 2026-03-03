//
// EmergencySirenManager.swift
// SafeRelay
//

import Foundation
#if os(iOS)
import AudioToolbox
#elseif os(macOS)
import AppKit
#endif

@MainActor
final class EmergencySirenManager {
    static let shared = EmergencySirenManager()
    
    private var isPlaying = false
    private var sirenTimer: Timer?
    
    private init() {}
    
    func playSiren(duration: TimeInterval = 5.0) {
        guard !isPlaying else { return }
        isPlaying = true
        
        var elapsed: TimeInterval = 0
        sirenTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            #if os(iOS)
            AudioServicesPlaySystemSound(SystemSoundID(1021))
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            #elseif os(macOS)
            NSSound.beep()
            #endif
            
            elapsed += 1.0
            if elapsed >= duration {
                self.stopSiren()
            }
        }
        sirenTimer?.fire()
    }
    
    func stopSiren() {
        sirenTimer?.invalidate()
        sirenTimer = nil
        isPlaying = false
    }
}
