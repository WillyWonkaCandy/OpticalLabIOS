import UIKit

open class BaseScannerViewController: UIViewController, HeaderScannerBarDelegate, CameraBarcodeScannerDelegate, BarcodeScanListener {
    
    public let headerBar = HeaderScannerBarView()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = OpticalLabTheme.background
        
        setupHeaderBar()
        HardwareBarcodeScannerManager.shared.addListener(self)
    }
    
    deinit {
        HardwareBarcodeScannerManager.shared.removeListener(self)
    }
    
    private func setupHeaderBar() {
        headerBar.delegate = self
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBar)
        
        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.safeAreaTopAnchor()),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBar.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    // MARK: - HeaderScannerBarDelegate
    
    public func didTapCameraScan() {
        let scannerVC = BarcodeScannerViewController()
        scannerVC.delegate = self
        present(scannerVC, animated: true, completion: nil)
    }
    
    public func didTapManualScan() {
        let alert = UIAlertController(title: "Manual Barcode Entry", message: "Enter lens or job tray barcode:", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "e.g. TRAY-101 or 793573180011"
            tf.autocapitalizationType = .allCharacters
        }
        alert.addAction(UIAlertAction(title: "Submit", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
            HardwareBarcodeScannerManager.shared.notifyBarcodeScanned(barcode: text, symbology: "ManualEntry")
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, completion: nil))
        present(alert, animated: true, completion: nil)
    }
    
    public func didTapEyeCloud() {
        if let tab = tabBarController {
            // Index 4 is EyeCloud
            tab.selectedIndex = 4
        } else {
            let eyeCloudVC = EyeCloudViewController()
            navigationController?.pushViewController(eyeCloudVC, animated: true)
        }
    }
    
    public func didTapSettings() {
        let settingsVC = ScannerSettingsViewController()
        navigationController?.pushViewController(settingsVC, animated: true)
    }
    
    // MARK: - CameraBarcodeScannerDelegate
    
    public func didScanBarcode(code: String, format: String) {
        onBarcodeScanned(barcode: code, symbology: format)
    }
    
    // MARK: - BarcodeScanListener
    
    open func onBarcodeScanned(barcode: String, symbology: String) {
        // Subclasses override
    }
    
    // Handle external Bluetooth scanner keyboard input
    override open func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        for press in presses {
            if let key = press.key {
                let text = key.characters
                if HardwareBarcodeScannerManager.shared.handleKeyInput(text) {
                    return
                }
            }
        }
        super.pressesBegan(presses, with: event)
    }
}
