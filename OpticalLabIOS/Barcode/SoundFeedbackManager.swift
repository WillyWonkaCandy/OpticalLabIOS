import Foundation
import AudioToolbox
import UIKit

public final class SoundFeedbackManager {
    public static let shared = SoundFeedbackManager()
    
    private var feedbackGenerator: Any? = nil
    
    private init() {
        if #available(iOS 10.0, *) {
            feedbackGenerator = UINotificationFeedbackGenerator()
        }
    }
    
    public func playSuccessBeep() {
        // System Sound 1057 is the classic clean optical scanner confirmation beep
        AudioServicesPlaySystemSound(1057)
        vibrateShort()
    }
    
    public func playErrorBeep() {
        // System sound 1053 is an alert buzz
        AudioServicesPlaySystemSound(1053)
        vibrateError()
    }
    
    public func vibrateShort() {
        if #available(iOS 10.0, *), let gen = feedbackGenerator as? UINotificationFeedbackGenerator {
            gen.prepare()
            gen.notificationOccurred(.success)
        } else {
            // Standard ERM motor vibration for iPhone 6 / 6 Plus / 5s
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        }
    }
    
    public func vibrateError() {
        if #available(iOS 10.0, *), let gen = feedbackGenerator as? UINotificationFeedbackGenerator {
            gen.prepare()
            gen.notificationOccurred(.error)
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            }
        }
    }
}
