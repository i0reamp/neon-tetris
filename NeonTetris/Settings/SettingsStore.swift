import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("NeonTetris.soundEnabled") var soundEnabled: Bool = true {
        didSet { SoundEngine.shared.isEnabled = soundEnabled; objectWillChange.send() }
    }
    @AppStorage("NeonTetris.hapticsEnabled") var hapticsEnabled: Bool = true {
        didSet { HapticsManager.shared.isEnabled = hapticsEnabled; objectWillChange.send() }
    }
    @AppStorage("NeonTetris.visualIntensityRaw") private var visualIntensityRaw: String = VisualIntensity.high.rawValue

    var visualIntensity: VisualIntensity {
        get { VisualIntensity(rawValue: visualIntensityRaw) ?? .high }
        set { visualIntensityRaw = newValue.rawValue; objectWillChange.send() }
    }

    init() {
        SoundEngine.shared.isEnabled = soundEnabled
        HapticsManager.shared.isEnabled = hapticsEnabled
    }
}
