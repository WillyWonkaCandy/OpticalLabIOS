import Foundation
import UIKit

public protocol BarcodeScanListener: AnyObject {
    func onBarcodeScanned(barcode: String, symbology: String)
}

public final class HardwareBarcodeScannerManager {
    public static let shared = HardwareBarcodeScannerManager()
    
    private var listeners = NSHashTable<AnyObject>.weakObjects()
    private var inputBuffer = ""
    private var lastKeyTime: Date = Date()
    private let lock = NSLock()
    
    private init() {}
    
    public func addListener(_ listener: BarcodeScanListener) {
        lock.lock()
        defer { lock.unlock() }
        listeners.add(listener)
    }
    
    public func removeListener(_ listener: BarcodeScanListener) {
        lock.lock()
        defer { lock.unlock() }
        listeners.remove(listener)
    }
    
    public func notifyBarcodeScanned(barcode: String, symbology: String = "Code128") {
        let clean = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        SoundFeedbackManager.shared.playSuccessBeep()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            let targets = self.listeners.allObjects.compactMap { $0 as? BarcodeScanListener }
            self.lock.unlock()
            
            for target in targets {
                target.onBarcodeScanned(barcode: clean, symbology: symbology)
            }
        }
    }
    
    /// Intercepts keystrokes from external Bluetooth barcode scanners (HID profile)
    public func handleKeyInput(_ text: String) -> Bool {
        let now = Date()
        if now.timeIntervalSince(lastKeyTime) > 0.4 {
            inputBuffer = ""
        }
        lastKeyTime = now
        
        if text == "\n" || text == "\r" {
            let barcode = inputBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            inputBuffer = ""
            if barcode.count >= 2 {
                notifyBarcodeScanned(barcode: barcode, symbology: "BluetoothScanner")
                return true
            }
            return false
        } else {
            inputBuffer.append(text)
            return false
        }
    }
}
