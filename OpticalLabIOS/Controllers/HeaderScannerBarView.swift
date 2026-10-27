import UIKit

public protocol HeaderScannerBarDelegate: AnyObject {
    func didTapCameraScan()
    func didTapManualScan()
    func didTapEyeCloud()
    func didTapSettings()
}

public class HeaderScannerBarView: UIView, BarcodeScanListener {
    
    public weak var delegate: HeaderScannerBarDelegate?
    
    private let statusIndicator = UIView()
    private let statusLabel = UILabel()
    private let subLabel = UILabel()
    
    private let scanButton = UIButton(type: .custom)
    private let cameraButton = UIButton(type: .custom)
    private let manualButton = UIButton(type: .custom)
    private let eyeCloudButton = UIButton(type: .custom)
    private let settingsButton = UIButton(type: .custom)
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        HardwareBarcodeScannerManager.shared.addListener(self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        HardwareBarcodeScannerManager.shared.addListener(self)
    }
    
    deinit {
        HardwareBarcodeScannerManager.shared.removeListener(self)
    }
    
    private func setupView() {
        backgroundColor = OpticalLabTheme.primaryDark
        
        statusIndicator.translatesAutoresizingMaskIntoConstraints = false
        statusIndicator.backgroundColor = OpticalLabTheme.success
        statusIndicator.layer.cornerRadius = 6
        statusIndicator.layer.masksToBounds = true
        addSubview(statusIndicator)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Optical Scanner Ready"
        statusLabel.textColor = .white
        statusLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        addSubview(statusLabel)
        
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        subLabel.text = "Bluetooth / Camera Active"
        subLabel.textColor = UIColor(red: 147/255.0, green: 197/255.0, blue: 253/255.0, alpha: 1.0)
        subLabel.font = UIFont.systemFont(ofSize: 11)
        addSubview(subLabel)
        
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.setTitle("Camera", for: .normal)
        cameraButton.setTitleColor(.white, for: .normal)
        cameraButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        cameraButton.layer.cornerRadius = 6
        cameraButton.layer.borderWidth = 1.0
        cameraButton.layer.borderColor = OpticalLabTheme.accent.cgColor
        cameraButton.backgroundColor = OpticalLabTheme.accent
        cameraButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)
        cameraButton.addTarget(self, action: #selector(handleCamera), for: .touchUpInside)
        addSubview(cameraButton)
        
        manualButton.translatesAutoresizingMaskIntoConstraints = false
        manualButton.setTitle("Manual", for: .normal)
        manualButton.setTitleColor(.white, for: .normal)
        manualButton.titleLabel?.font = UIFont.systemFont(ofSize: 11)
        manualButton.layer.cornerRadius = 6
        manualButton.layer.borderWidth = 1.0
        manualButton.layer.borderColor = UIColor.white.withAlphaComponent(0.4).cgColor
        manualButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        manualButton.addTarget(self, action: #selector(handleManual), for: .touchUpInside)
        addSubview(manualButton)
        
        eyeCloudButton.translatesAutoresizingMaskIntoConstraints = false
        eyeCloudButton.setTitle("☁️", for: .normal)
        eyeCloudButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        eyeCloudButton.layer.cornerRadius = 6
        eyeCloudButton.backgroundColor = UIColor(red: 30/255.0, green: 41/255.0, blue: 59/255.0, alpha: 1.0)
        eyeCloudButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        eyeCloudButton.addTarget(self, action: #selector(handleEyeCloud), for: .touchUpInside)
        addSubview(eyeCloudButton)
        
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.setTitle("⚙️", for: .normal)
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        settingsButton.layer.cornerRadius = 6
        settingsButton.backgroundColor = UIColor(red: 30/255.0, green: 41/255.0, blue: 59/255.0, alpha: 1.0)
        settingsButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        settingsButton.addTarget(self, action: #selector(handleSettings), for: .touchUpInside)
        addSubview(settingsButton)
        
        NSLayoutConstraint.activate([
            statusIndicator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            statusIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            statusIndicator.widthAnchor.constraint(equalToConstant: 12),
            statusIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusIndicator.trailingAnchor, constant: 8),
            statusLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: cameraButton.leadingAnchor, constant: -8),
            
            subLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
            subLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 2),
            subLabel.trailingAnchor.constraint(lessThanOrEqualTo: cameraButton.leadingAnchor, constant: -8),
            
            settingsButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            settingsButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            settingsButton.heightAnchor.constraint(equalToConstant: 34),
            
            eyeCloudButton.trailingAnchor.constraint(equalTo: settingsButton.leadingAnchor, constant: -4),
            eyeCloudButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            eyeCloudButton.heightAnchor.constraint(equalToConstant: 34),
            
            manualButton.trailingAnchor.constraint(equalTo: eyeCloudButton.leadingAnchor, constant: -4),
            manualButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            manualButton.heightAnchor.constraint(equalToConstant: 34),
            
            cameraButton.trailingAnchor.constraint(equalTo: manualButton.leadingAnchor, constant: -4),
            cameraButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            cameraButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }
    
    public func onBarcodeScanned(barcode: String, symbology: String) {
        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "Scanned: \(barcode)"
            self?.subLabel.text = "\(symbology) • Ready for next scan"
        }
    }
    
    @objc private func handleCamera() {
        delegate?.didTapCameraScan()
    }
    
    @objc private func handleManual() {
        delegate?.didTapManualScan()
    }
    
    @objc private func handleEyeCloud() {
        delegate?.didTapEyeCloud()
    }
    
    @objc private func handleSettings() {
        delegate?.didTapSettings()
    }
}
