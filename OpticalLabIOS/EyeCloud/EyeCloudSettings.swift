import Foundation

public final class EyeCloudSettings {
    public static let shared = EyeCloudSettings()
    
    public static let defaultUrl = "http://web.opticalpos.com/pos/login/nycct"
    public static let defaultPracticeId = "nycct"
    
    private let keyUrl = "pref_eyecloud_url"
    private let keyPractice = "pref_eyecloud_practice"
    private let keyAutoInject = "pref_auto_inject_barcode"
    private let keyAutoEnter = "pref_auto_enter_key"
    
    private let defaults = UserDefaults.standard
    
    private init() {
        if defaults.object(forKey: keyAutoInject) == nil {
            defaults.set(true, forKey: keyAutoInject)
        }
        if defaults.object(forKey: keyAutoEnter) == nil {
            defaults.set(true, forKey: keyAutoEnter)
        }
    }
    
    public var portalUrl: String {
        get { return defaults.string(forKey: keyUrl) ?? EyeCloudSettings.defaultUrl }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: keyUrl) }
    }
    
    public var practiceId: String {
        get { return defaults.string(forKey: keyPractice) ?? EyeCloudSettings.defaultPracticeId }
        set { defaults.set(newValue.trimmingCharacters(in: .whitespacesAndNewlines), forKey: keyPractice) }
    }
    
    public var isAutoInject: Bool {
        get { return defaults.bool(forKey: keyAutoInject) }
        set { defaults.set(newValue, forKey: keyAutoInject) }
    }
    
    public var isAutoEnter: Bool {
        get { return defaults.bool(forKey: keyAutoEnter) }
        set { defaults.set(newValue, forKey: keyAutoEnter) }
    }
}
