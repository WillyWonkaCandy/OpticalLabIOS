import UIKit

public class ScannerSettingsViewController: BaseScannerViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Scanner & Lab Setup"
        setupUI()
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        let cardBluetooth = makeCard(
            title: "1. Bluetooth / Wireless Scanner Pairing",
            description: "To connect Socket Mobile, Zebra, Inateck, or Eyoyo rugged barcode scanners to your iPhone 6:\n\n1. Open iOS [Settings] -> [Bluetooth] and pair your scanner in Basic HID Keyboard mode.\n2. In your scanner manual, scan the programming barcode for 'Add CR / Enter Suffix'.\n3. This app will automatically capture scanned barcodes with zero lag, triggering optical lab lookups instantly."
        )
        
        let cardCamera = makeCard(
            title: "2. AVFoundation Camera Scanner",
            description: "High-speed camera scanner with integrated LED torch support. Supports Code 128, EAN-13, Data Matrix, QR, and Code 39 from lens packaging."
        )
        
        let cardEyeCloud = makeCard(
            title: "3. EyeCloud Pro (OpticalPOS)",
            description: "Direct connection to http://web.opticalpos.com/pos/login/nycct with automatic barcode injection into web forms on scan. Cleartext HTTP enabled for iOS 12+."
        )
        
        let testBeepButton = UIButton(type: .custom)
        OpticalLabTheme.styleRuggedButton(testBeepButton, backgroundColor: OpticalLabTheme.accent)
        testBeepButton.setTitle("Test Scanner Beep & Vibration", for: .normal)
        testBeepButton.addTarget(self, action: #selector(handleTestBeep), for: .touchUpInside)
        
        let testCameraButton = UIButton(type: .custom)
        OpticalLabTheme.styleOutlinedButton(testCameraButton, borderColor: OpticalLabTheme.primary, titleColor: OpticalLabTheme.primary)
        testCameraButton.setTitle("Open Camera Scanner", for: .normal)
        testCameraButton.addTarget(self, action: #selector(handleTestCamera), for: .touchUpInside)
        
        let dbStatusLabel = UILabel()
        dbStatusLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        dbStatusLabel.textColor = OpticalLabTheme.textSecondary
        dbStatusLabel.textAlignment = .center
        dbStatusLabel.numberOfLines = 0
        let jobCount = DatabaseManager.shared.getAllJobs().count
        let lensCount = DatabaseManager.shared.getAllLenses().count
        dbStatusLabel.text = "Production Database Status: Clean Slate\nTotal Jobs: \(jobCount) | Total Lenses: \(lensCount)\n(Zero mock/demo data loaded)"
        
        let stack = UIStackView(arrangedSubviews: [
            cardBluetooth, cardCamera, cardEyeCloud, testBeepButton, testCameraButton, dbStatusLabel
        ])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            testBeepButton.heightAnchor.constraint(equalToConstant: 48),
            testCameraButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func makeCard(title: String, description: String) -> UIView {
        let card = UIView()
        OpticalLabTheme.styleCardView(card)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = OpticalLabTheme.primary
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        
        let descLabel = UILabel()
        descLabel.text = description
        descLabel.textColor = OpticalLabTheme.textSecondary
        descLabel.font = UIFont.systemFont(ofSize: 13)
        descLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [titleLabel, descLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 8
        card.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12)
        ])
        return card
    }
    
    @objc private func handleTestBeep() {
        SoundFeedbackManager.shared.playSuccessBeep()
    }
    
    @objc private func handleTestCamera() {
        didTapCameraScan()
    }
}
