import UIKit

public class JobDetailViewController: BaseScannerViewController {
    
    private let jobId: Int64
    private var job: OpticalJob?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let trayLabel = UILabel()
    private let stageBadge = UILabel()
    private let patientLabel = UILabel()
    private let orderLabel = UILabel()
    
    private let rxCard = UIView()
    private let odLabel = UILabel()
    private let osLabel = UILabel()
    
    private let allocationCard = UIView()
    private let odAllocLabel = UILabel()
    private let osAllocLabel = UILabel()
    private let allocateOdButton = UIButton(type: .system)
    private let allocateOsButton = UIButton(type: .system)
    
    private let edgerLabel = UILabel()
    private let frameLabel = UILabel()
    
    private let advanceStageButton = UIButton(type: .custom)
    private let startQcButton = UIButton(type: .custom)
    
    public init(jobId: Int64) {
        self.jobId = jobId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Job Details"
        setupUI()
        loadJob()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadJob()
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        trayLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        trayLabel.textColor = OpticalLabTheme.textPrimary
        
        stageBadge.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        stageBadge.textColor = .white
        stageBadge.layer.cornerRadius = 8
        stageBadge.layer.masksToBounds = true
        stageBadge.textAlignment = .center
        
        patientLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        patientLabel.textColor = OpticalLabTheme.textSecondary
        
        orderLabel.font = UIFont.systemFont(ofSize: 13)
        orderLabel.textColor = OpticalLabTheme.textMuted
        
        // Rx Card
        OpticalLabTheme.styleCardView(rxCard)
        rxCard.translatesAutoresizingMaskIntoConstraints = false
        
        let rxTitle = UILabel()
        rxTitle.text = "Prescription (Rx)"
        rxTitle.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        rxTitle.textColor = OpticalLabTheme.primary
        
        odLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        odLabel.numberOfLines = 0
        osLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        osLabel.numberOfLines = 0
        
        let rxStack = UIStackView(arrangedSubviews: [rxTitle, odLabel, osLabel])
        rxStack.translatesAutoresizingMaskIntoConstraints = false
        rxStack.axis = .vertical
        rxStack.spacing = 8
        rxCard.addSubview(rxStack)
        
        // Allocation Card
        OpticalLabTheme.styleCardView(allocationCard)
        allocationCard.translatesAutoresizingMaskIntoConstraints = false
        
        let allocTitle = UILabel()
        allocTitle.text = "Lens Blank Allocation"
        allocTitle.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        allocTitle.textColor = OpticalLabTheme.primary
        
        odAllocLabel.font = UIFont.systemFont(ofSize: 13)
        osAllocLabel.font = UIFont.systemFont(ofSize: 13)
        
        allocateOdButton.setTitle("Pick OD Lens", for: .normal)
        allocateOdButton.addTarget(self, action: #selector(handleAllocateOd), for: .touchUpInside)
        
        allocateOsButton.setTitle("Pick OS Lens", for: .normal)
        allocateOsButton.addTarget(self, action: #selector(handleAllocateOs), for: .touchUpInside)
        
        let odRow = UIStackView(arrangedSubviews: [odAllocLabel, allocateOdButton])
        odRow.axis = .horizontal
        odRow.distribution = .equalSpacing
        
        let osRow = UIStackView(arrangedSubviews: [osAllocLabel, allocateOsButton])
        osRow.axis = .horizontal
        osRow.distribution = .equalSpacing
        
        let allocStack = UIStackView(arrangedSubviews: [allocTitle, odRow, osRow])
        allocStack.translatesAutoresizingMaskIntoConstraints = false
        allocStack.axis = .vertical
        allocStack.spacing = 8
        allocationCard.addSubview(allocStack)
        
        // Actions
        OpticalLabTheme.styleRuggedButton(advanceStageButton, backgroundColor: OpticalLabTheme.accent)
        advanceStageButton.translatesAutoresizingMaskIntoConstraints = false
        advanceStageButton.addTarget(self, action: #selector(handleAdvanceStage), for: .touchUpInside)
        
        OpticalLabTheme.styleRuggedButton(startQcButton, backgroundColor: OpticalLabTheme.success)
        startQcButton.translatesAutoresizingMaskIntoConstraints = false
        startQcButton.setTitle("Verify ANSI Z80.1 Inspection", for: .normal)
        startQcButton.addTarget(self, action: #selector(handleStartQc), for: .touchUpInside)
        
        frameLabel.font = UIFont.systemFont(ofSize: 13)
        frameLabel.textColor = OpticalLabTheme.textSecondary
        edgerLabel.font = UIFont.systemFont(ofSize: 13)
        edgerLabel.textColor = OpticalLabTheme.textSecondary
        
        let headerRow = UIStackView(arrangedSubviews: [trayLabel, stageBadge])
        headerRow.translatesAutoresizingMaskIntoConstraints = false
        headerRow.axis = .horizontal
        headerRow.distribution = .equalSpacing
        
        contentView.addSubview(headerRow)
        contentView.addSubview(patientLabel)
        contentView.addSubview(orderLabel)
        contentView.addSubview(rxCard)
        contentView.addSubview(allocationCard)
        contentView.addSubview(frameLabel)
        contentView.addSubview(edgerLabel)
        contentView.addSubview(advanceStageButton)
        contentView.addSubview(startQcButton)
        
        patientLabel.translatesAutoresizingMaskIntoConstraints = false
        orderLabel.translatesAutoresizingMaskIntoConstraints = false
        frameLabel.translatesAutoresizingMaskIntoConstraints = false
        edgerLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            headerRow.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stageBadge.heightAnchor.constraint(equalToConstant: 28),
            stageBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
            
            patientLabel.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 6),
            patientLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            patientLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            orderLabel.topAnchor.constraint(equalTo: patientLabel.bottomAnchor, constant: 4),
            orderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            orderLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            rxCard.topAnchor.constraint(equalTo: orderLabel.bottomAnchor, constant: 14),
            rxCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rxCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            rxStack.topAnchor.constraint(equalTo: rxCard.topAnchor, constant: 12),
            rxStack.bottomAnchor.constraint(equalTo: rxCard.bottomAnchor, constant: -12),
            rxStack.leadingAnchor.constraint(equalTo: rxCard.leadingAnchor, constant: 12),
            rxStack.trailingAnchor.constraint(equalTo: rxCard.trailingAnchor, constant: -12),
            
            allocationCard.topAnchor.constraint(equalTo: rxCard.bottomAnchor, constant: 12),
            allocationCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            allocationCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            allocStack.topAnchor.constraint(equalTo: allocationCard.topAnchor, constant: 12),
            allocStack.bottomAnchor.constraint(equalTo: allocationCard.bottomAnchor, constant: -12),
            allocStack.leadingAnchor.constraint(equalTo: allocationCard.leadingAnchor, constant: 12),
            allocStack.trailingAnchor.constraint(equalTo: allocationCard.trailingAnchor, constant: -12),
            
            frameLabel.topAnchor.constraint(equalTo: allocationCard.bottomAnchor, constant: 12),
            frameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            frameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            edgerLabel.topAnchor.constraint(equalTo: frameLabel.bottomAnchor, constant: 4),
            edgerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            edgerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            advanceStageButton.topAnchor.constraint(equalTo: edgerLabel.bottomAnchor, constant: 18),
            advanceStageButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            advanceStageButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            advanceStageButton.heightAnchor.constraint(equalToConstant: 48),
            
            startQcButton.topAnchor.constraint(equalTo: advanceStageButton.bottomAnchor, constant: 10),
            startQcButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            startQcButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            startQcButton.heightAnchor.constraint(equalToConstant: 48),
            startQcButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func loadJob() {
        guard let current = DatabaseManager.shared.getJob(byId: jobId) else { return }
        self.job = current
        
        trayLabel.text = "Tray: \(current.trayNumber)"
        stageBadge.text = " \(current.stage.displayName) "
        stageBadge.backgroundColor = current.stage.stageColor
        
        patientLabel.text = current.patientName.isEmpty ? "Walk-in Patient" : "Patient: \(current.patientName)"
        orderLabel.text = "Order: \(current.orderNumber.isEmpty ? "N/A" : current.orderNumber) • Customer: \(current.customerName.isEmpty ? "NYCCT Lab" : current.customerName)"
        
        let odAddStr = current.odAdd > 0 ? String(format: " Add: +%.2f", current.odAdd) : ""
        let osAddStr = current.osAdd > 0 ? String(format: " Add: +%.2f", current.osAdd) : ""
        
        odLabel.text = "OD (Right): \(current.odRxString)\(odAddStr) • PD: \(current.odPd)mm"
        osLabel.text = "OS (Left):  \(current.osRxString)\(osAddStr) • PD: \(current.osPd)mm"
        
        odAllocLabel.text = "OD Lens: \(current.odLensBarcode.isEmpty ? "Not allocated" : current.odLensBarcode)"
        osAllocLabel.text = "OS Lens: \(current.osLensBarcode.isEmpty ? "Not allocated" : current.osLensBarcode)"
        
        frameLabel.text = "Frame: \(current.frameModel.isEmpty ? "Standard" : current.frameModel) (\(current.frameType.label))"
        edgerLabel.text = "Edger Machine: \(current.edgerMachine.isEmpty ? "Nidek ME-1200" : current.edgerMachine)"
        
        let nextStage = current.stage.next()
        if current.stage == .completed {
            advanceStageButton.setTitle("✓ Job Completed", for: .normal)
            advanceStageButton.backgroundColor = OpticalLabTheme.success
            advanceStageButton.isEnabled = false
        } else {
            advanceStageButton.setTitle("Advance to: \(nextStage.displayName)", for: .normal)
            advanceStageButton.backgroundColor = OpticalLabTheme.accent
            advanceStageButton.isEnabled = true
        }
    }
    
    @objc private func handleAdvanceStage() {
        guard let next = DatabaseManager.shared.advanceJobStage(jobId: jobId) else { return }
        SoundFeedbackManager.shared.playSuccessBeep()
        loadJob()
    }
    
    @objc private func handleStartQc() {
        guard let current = job else { return }
        let qcVC = QcInspectionViewController(job: current)
        navigationController?.pushViewController(qcVC, animated: true)
    }
    
    @objc private func handleAllocateOd() {
        promptAllocateLens(eye: "OD")
    }
    
    @objc private func handleAllocateOs() {
        promptAllocateLens(eye: "OS")
    }
    
    private func promptAllocateLens(eye: String) {
        let alert = UIAlertController(title: "Allocate \(eye) Lens", message: "Scan lens envelope or enter barcode:", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Lens Barcode"
            tf.autocapitalizationType = .allCharacters
        }
        alert.addAction(UIAlertAction(title: "Allocate & Deduct Stock", style: .default) { [weak self] _ in
            guard let barcode = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !barcode.isEmpty,
                  let self = self else { return }
            _ = DatabaseManager.shared.allocateLens(jobId: self.jobId, eye: eye, lensBarcode: barcode)
            self.loadJob()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, completion: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override public func onBarcodeScanned(barcode: String, symbology: String) {
        super.onBarcodeScanned(barcode: barcode, symbology: symbology)
        
        // If a lens barcode is scanned, prompt to assign to OD or OS
        let alert = UIAlertController(title: "Assign Scanned Lens", message: "Barcode: \(barcode)\nAssign to OD (Right) or OS (Left)?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Right Eye (OD)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            _ = DatabaseManager.shared.allocateLens(jobId: self.jobId, eye: "OD", lensBarcode: barcode)
            self.loadJob()
        })
        alert.addAction(UIAlertAction(title: "Left Eye (OS)", style: .default) { [weak self] _ in
            guard let self = self else { return }
            _ = DatabaseManager.shared.allocateLens(jobId: self.jobId, eye: "OS", lensBarcode: barcode)
            self.loadJob()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, completion: nil))
        present(alert, animated: true, completion: nil)
    }
}
