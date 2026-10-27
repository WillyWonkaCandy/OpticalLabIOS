import UIKit

public class QcInspectionViewController: BaseScannerViewController {
    
    private let job: OpticalJob?
    private var selectedJob: OpticalJob?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let headerLabel = UILabel()
    private let rxLabel = UILabel()
    private let inspectorField = UITextField()
    
    // ANSI Z80.1 Verification Switches
    private let switchOdSph = UISwitch()
    private let switchOdCyl = UISwitch()
    private let switchOdAxis = UISwitch()
    private let switchOsSph = UISwitch()
    private let switchOsCyl = UISwitch()
    private let switchOsAxis = UISwitch()
    private let switchPd = UISwitch()
    private let switchCosmetic = UISwitch()
    private let switchBevel = UISwitch()
    
    private let approveButton = UIButton(type: .custom)
    private let rejectButton = UIButton(type: .custom)
    
    public init(job: OpticalJob? = nil) {
        self.job = job
        self.selectedJob = job
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "ANSI Z80.1 Inspection"
        setupUI()
        updateJobDisplay()
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        headerLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        headerLabel.textColor = OpticalLabTheme.textPrimary
        
        rxLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        rxLabel.textColor = OpticalLabTheme.primary
        rxLabel.numberOfLines = 0
        
        inspectorField.placeholder = "Inspector Initials / Name (Required)"
        inspectorField.borderStyle = .roundedRect
        inspectorField.font = UIFont.systemFont(ofSize: 15)
        inspectorField.backgroundColor = OpticalLabTheme.cardBackground
        inspectorField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        // Rows
        let rowOdSph = makeSwitchRow(title: "OD Sphere (±0.13D Tol.)", control: switchOdSph)
        let rowOdCyl = makeSwitchRow(title: "OD Cylinder (±0.13D Tol.)", control: switchOdCyl)
        let rowOdAxis = makeSwitchRow(title: "OD Axis Alignment", control: switchOdAxis)
        let rowOsSph = makeSwitchRow(title: "OS Sphere (±0.13D Tol.)", control: switchOsSph)
        let rowOsCyl = makeSwitchRow(title: "OS Cylinder (±0.13D Tol.)", control: switchOsCyl)
        let rowOsAxis = makeSwitchRow(title: "OS Axis Alignment", control: switchOsAxis)
        let rowPd = makeSwitchRow(title: "Optical Center & PD Match", control: switchPd)
        let rowCosmetic = makeSwitchRow(title: "Cosmetic Check (Scratch/Craze Free)", control: switchCosmetic)
        let rowBevel = makeSwitchRow(title: "Bevel & Frame Fit Secure", control: switchBevel)
        
        OpticalLabTheme.styleRuggedButton(approveButton, backgroundColor: OpticalLabTheme.success)
        approveButton.setTitle("✓ Approve & Mark Completed", for: .normal)
        approveButton.addTarget(self, action: #selector(handleApprove), for: .touchUpInside)
        
        OpticalLabTheme.styleOutlinedButton(rejectButton, borderColor: OpticalLabTheme.danger, titleColor: OpticalLabTheme.danger)
        rejectButton.setTitle("✕ Reject / Remake Required", for: .normal)
        rejectButton.addTarget(self, action: #selector(handleReject), for: .touchUpInside)
        
        let card = UIView()
        OpticalLabTheme.styleCardView(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let cardStack = UIStackView(arrangedSubviews: [
            makeSectionTitle("1. Lensometer Power Verification"),
            rowOdSph, rowOdCyl, rowOdAxis, rowOsSph, rowOsCyl, rowOsAxis,
            makeSectionTitle("2. Alignment & Fitting"),
            rowPd, rowBevel,
            makeSectionTitle("3. Quality & Optics"),
            rowCosmetic
        ])
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        cardStack.axis = .vertical
        cardStack.spacing = 10
        card.addSubview(cardStack)
        
        let mainStack = UIStackView(arrangedSubviews: [
            headerLabel, rxLabel, inspectorField, card, approveButton, rejectButton
        ])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.spacing = 14
        contentView.addSubview(mainStack)
        
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
            
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            
            approveButton.heightAnchor.constraint(equalToConstant: 48),
            rejectButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func updateJobDisplay() {
        if let current = selectedJob {
            headerLabel.text = "Inspection: Tray \(current.trayNumber)"
            rxLabel.text = "OD: \(current.odRxString) • OS: \(current.osRxString)\nPatient: \(current.patientName.isEmpty ? "Walk-in" : current.patientName)"
        } else {
            headerLabel.text = "Scan Tray Barcode to Inspect"
            rxLabel.text = "No job currently loaded. Scan tray barcode with camera or Bluetooth."
        }
    }
    
    private func makeSwitchRow(title: String, control: UISwitch) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = OpticalLabTheme.textPrimary
        
        control.onTintColor = OpticalLabTheme.success
        
        let stack = UIStackView(arrangedSubviews: [label, control])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }
    
    private func makeSectionTitle(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = OpticalLabTheme.primary
        label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        return label
    }
    
    @objc private func handleApprove() {
        guard let current = selectedJob else {
            showError("Please scan or select a job tray first.")
            return
        }
        
        let inspector = inspectorField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !inspector.isEmpty else {
            showError("Inspector name or initials required.")
            return
        }
        
        let allChecked = switchOdSph.isOn && switchOdCyl.isOn && switchOdAxis.isOn &&
                         switchOsSph.isOn && switchOsCyl.isOn && switchOsAxis.isOn &&
                         switchPd.isOn && switchCosmetic.isOn && switchBevel.isOn
        
        guard allChecked else {
            showError("All ANSI Z80.1 checkpoints must be verified to pass inspection.")
            return
        }
        
        let qc = QcInspection(
            jobId: current.id,
            trayNumber: current.trayNumber,
            inspectorName: inspector,
            odSphOk: switchOdSph.isOn,
            odCylOk: switchOdCyl.isOn,
            odAxisOk: switchOdAxis.isOn,
            osSphOk: switchOsSph.isOn,
            osCylOk: switchOsCyl.isOn,
            osAxisOk: switchOsAxis.isOn,
            pdAligned: switchPd.isOn,
            cosmeticPassed: switchCosmetic.isOn,
            bevelFitPassed: switchBevel.isOn,
            passed: true
        )
        
        _ = DatabaseManager.shared.insertQcInspection(qc)
        
        // Mark job as completed
        var updated = current
        updated.stage = .completed
        updated.completedAt = Date()
        _ = DatabaseManager.shared.updateJob(updated)
        
        SoundFeedbackManager.shared.playSuccessBeep()
        
        let successAlert = UIAlertController(title: "QC Passed", message: "Tray \(current.trayNumber) approved and marked Completed & Ready.", preferredStyle: .alert)
        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(successAlert, animated: true, completion: nil)
    }
    
    @objc private func handleReject() {
        guard let current = selectedJob else { return }
        let alert = UIAlertController(title: "Flag for Remake", message: "Specify reason for failing inspection:", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "e.g. Scratched coating, axis off by 8°"
        }
        alert.addAction(UIAlertAction(title: "Submit Failure", style: .destructive) { [weak self] _ in
            let reason = alert.textFields?.first?.text ?? "Failed inspection"
            var updated = current
            updated.priority = "Remake"
            updated.stage = .cuttingEdging
            updated.notes = (updated.notes.isEmpty ? "" : updated.notes + "\n") + "[QC REJECT]: \(reason)"
            _ = DatabaseManager.shared.updateJob(updated)
            SoundFeedbackManager.shared.playErrorBeep()
            self?.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, completion: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func showError(_ msg: String) {
        let alert = UIAlertController(title: "QC Inspection", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, completion: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override public func onBarcodeScanned(barcode: String, symbology: String) {
        super.onBarcodeScanned(barcode: barcode, symbology: symbology)
        let parsed = BarcodeActionParser.parse(barcode)
        let trayKey = (parsed.type == .jobTray) ? parsed.payload : barcode
        if let found = DatabaseManager.shared.getJob(byTrayNumber: trayKey) {
            selectedJob = found
            updateJobDisplay()
            SoundFeedbackManager.shared.playSuccessBeep()
        }
    }
}
