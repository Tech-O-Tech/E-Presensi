//
//  Haptics.swift
//  E-Presensi
//
//  Created by Dwi Amalia on 12/05/26.
//

import CoreHaptics
import UIKit

final class Haptics {
    private var engine: CHHapticEngine?

    func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            // Fallback jika gagal start engine
            engine = nil
        }
    }

    func playTap() {
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            let events = [
                CHHapticEvent(eventType: .hapticTransient,
                              parameters: [],
                              relativeTime: 0)
            ]
            do {
                let pattern = try CHHapticPattern(events: events, parameters: [])
                let player = try engine?.makePlayer(with: pattern)
                try player?.start(atTime: 0)
            } catch {
                // Fallback ke UIFeedbackGenerator
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        } else {
            // Fallback untuk perangkat/simulator tanpa haptik
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
