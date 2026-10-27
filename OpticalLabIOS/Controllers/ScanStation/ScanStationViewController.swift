import UIKit

public class ScanStationViewController: BaseScannerViewController, UITableViewDataSource, UITableViewDelegate {
    
    private struct ScanHistoryItem {
        let code: String
        let title: String
        let detail: String
        let timestamp: Date
        let isSuccess: Bool
    }
    
    private var history: [ScanHistoryItem] = []
    
    // Result Card
    private let resultCard = UIView()
    private let badgeLabel = UILabel()
    private let codeLabel = UILabel()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let primaryActionButton = UIButton(type: .custom)
    private let secondaryActionButton = UIButton(type: .custom)
    
    // History Table
    private let historyTable = UITableView(frame: .zero, style: .plain)
    private let historyTitleLabel = UILabel()
    private let historyEmptyLabel = UILabel()
    
    private var lastScannedJob: OpticalJob?
    private var lastScannedLens: LensItem?
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Scan Station"
        setupUI()
    }
    
    private func setupUI() {
        OpticalLabTheme.styleCardView(resultCard)
        resultCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(resultCard)
        
        badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        badgeLabel.textColor = .white
        badgeLabel.backgroundColor = OpticalLabTheme.textMuted
        badgeLabel.layer.cornerRadius = 6
        badgeLabel.layer.masksToBounds = true
        badgeLabel.textAlignment = .center
        badgeLabel.text = " READY FOR SCAN "
        
        codeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        codeLabel.textColor = OpticalLabTheme.textPrimary
        codeLabel.text = "Waiting for Barcode..."
        
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = OpticalLabTheme.primary
        titleLabel.text = "Scan tray, lens packet, or action barcode"
        
        detailLabel.font = UIFont.systemFont(ofSize: 13)
        detailLabel.textColor = OpticalLabTheme.textSecondary
        detailLabel.numberOfLines = 0
        detailLabel.text = "Compatible with Bluetooth scanners & camera reader."
        
        OpticalLabTheme.styleRuggedButton(primaryActionButton, backgroundColor: OpticalLabTheme.accent)
        primaryActionButton.setTitle("Open Ticket", for: .normal)
        primaryActionButton.isHidden = true
        primaryActionButton.addTarget(self, action: #selector(handlePrimaryAction), for: .touchUpInside)
        
        OpticalLabTheme.styleOutlinedButton(secondaryActionButton, borderColor: OpticalLabTheme.primary, titleColor: OpticalLabTheme.primary)
        secondaryActionButton.setTitle("Advance Stage", for: .normal)
        secondaryActionButton.isHidden = true
        secondaryActionButton.addTarget(self, action: #selector(handleSecondaryAction), for: .touchUpInside)
        
        let buttonRow = UIStackView(arrangedSubviews: [primaryActionButton, secondaryActionButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 10
        buttonRow.distribution = .fillEqually
        
        let cardStack = UIStackView(arrangedSubviews: [badgeLabel, codeLabel, titleLabel, detailLabel, buttonRow])
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        cardStack.axis = .vertical
        cardStack.spacing = 8
        resultCard.addSubview(cardStack)
        
        historyTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        historyTitleLabel.text = "Recent Station Scans"
        historyTitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        historyTitleLabel.textColor = OpticalLabTheme.textPrimary
        view.addSubview(historyTitleLabel)
        
        historyTable.translatesAutoresizingMaskIntoConstraints = false
        historyTable.backgroundColor = .clear
        historyTable.dataSource = self
        historyTable.delegate = self
        view.addSubview(historyTable)
        
        historyEmptyLabel.translatesAutoresizingMaskIntoConstraints = false
        historyEmptyLabel.text = "No barcodes scanned this session."
        historyEmptyLabel.textColor = OpticalLabTheme.textMuted
        historyEmptyLabel.font = UIFont.systemFont(ofSize: 13)
        historyEmptyLabel.textAlignment = .center
        view.addSubview(historyEmptyLabel)
        
        NSLayoutConstraint.activate([
            resultCard.topAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: 12),
            resultCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            resultCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            
            cardStack.topAnchor.constraint(equalTo: resultCard.topAnchor, constant: 14),
            cardStack.bottomAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: -14),
            cardStack.leadingAnchor.constraint(equalTo: resultCard.leadingAnchor, constant: 14),
            cardStack.trailingAnchor.constraint(equalTo: resultCard.trailingAnchor, constant: -14),
            badgeLabel.heightAnchor.constraint(equalToConstant: 24),
            badgeLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 160),
            
            primaryActionButton.heightAnchor.constraint(equalToConstant: 44),
            secondaryActionButton.heightAnchor.constraint(equalToConstant: 44),
            
            historyTitleLabel.topAnchor.constraint(equalTo: resultCard.bottomAnchor, constant: 16),
            historyTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            historyTable.topAnchor.constraint(equalTo: historyTitleLabel.bottomAnchor, constant: 8),
            historyTable.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            historyTable.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            historyTable.bottomAnchor.constraint(equalTo: view.safeAreaBottomAnchor()),
            
            historyEmptyLabel.centerXAnchor.constraint(equalTo: historyTable.centerXAnchor),
            historyEmptyLabel.centerYAnchor.constraint(equalTo: historyTable.centerYAnchor)
        ])
    }
    
    override public func onBarcodeScanned(barcode: String, symbology: String) {
        super.onBarcodeScanned(barcode: barcode, symbology: symbology)
        processScan(barcode: barcode)
    }
    
    private func processScan(barcode: String) {
        let parsed = BarcodeActionParser.parse(barcode)
        
        // 1. Check Job Tray
        let trayKey = (parsed.type == .jobTray) ? parsed.payload : barcode
        if let job = DatabaseManager.shared.getJob(byTrayNumber: trayKey) {
            handleJobFound(job: job, barcode: barcode)
            return
        }
        
        // 2. Check Lens Blank
        if let lens = DatabaseManager.shared.getLens(byBarcode: barcode) {
            handleLensFound(lens: lens, barcode: barcode)
            return
        }
        
        // 3. Check Command Barcodes
        switch parsed.type {
        case .commandNextStage:
            if let job = lastScannedJob, let next = DatabaseManager.shared.advanceJobStage(jobId: job.id) {
                badgeLabel.text = " COMMAND EXECUTED "
                badgeLabel.backgroundColor = OpticalLabTheme.success
                titleLabel.text = "Advanced Tray \(job.trayNumber) to \(next.displayName)"
                detailLabel.text = "Pipeline updated successfully."
                addHistory(code: barcode, title: "Next Stage Command", detail: "Tray \(job.trayNumber) advanced to \(next.displayName)", isSuccess: true)
                SoundFeedbackManager.shared.playSuccessBeep()
            } else {
                showScanFailure(code: barcode, title: "No Active Job to Advance", detail: "Scan a job tray first, then scan ACTION:NEXT_STAGE")
            }
            return
            
        case .commandQcPass:
            if let job = lastScannedJob {
                _ = DatabaseManager.shared.advanceJobStage(jobId: job.id)
                badgeLabel.text = " QC PASSED "
                badgeLabel.backgroundColor = OpticalLabTheme.success
                titleLabel.text = "Tray \(job.trayNumber) Approved"
                detailLabel.text = "Job marked completed & ready."
                addHistory(code: barcode, title: "QC Pass Command", detail: "Approved Tray \(job.trayNumber)", isSuccess: true)
                SoundFeedbackManager.shared.playSuccessBeep()
            } else {
                showScanFailure(code: barcode, title: "No Active Job for QC", detail: "Scan a tray first.")
            }
            return
            
        default:
            break
        }
        
        // 4. Unknown barcode -> prompt options
        showScanFailure(code: barcode, title: "Unrecognized Barcode", detail: "Not found in optical jobs or lens inventory.")
    }
    
    private func handleJobFound(job: OpticalJob, barcode: String) {
        lastScannedJob = job
        lastScannedLens = nil
        
        badgeLabel.text = " OPTICAL LAB JOB "
        badgeLabel.backgroundColor = job.stage.stageColor
        codeLabel.text = "Tray: \(job.trayNumber)"
        titleLabel.text = "\(job.patientName.isEmpty ? "Standard Patient" : job.patientName) • \(job.stage.displayName)"
        detailLabel.text = "OD: \(job.odRxString)\nOS: \(job.osRxString)\nFrame: \(job.frameModel) (\(job.frameType.label))"
        
        primaryActionButton.setTitle("Open Ticket", for: .normal)
        primaryActionButton.isHidden = false
        
        secondaryActionButton.setTitle("Advance Stage", for: .normal)
        secondaryActionButton.isHidden = (job.stage == .completed)
        
        addHistory(code: barcode, title: "Tray \(job.trayNumber)", detail: "\(job.stage.displayName) - \(job.patientName)", isSuccess: true)
        SoundFeedbackManager.shared.playSuccessBeep()
    }
    
    private func handleLensFound(lens: LensItem, barcode: String) {
        lastScannedLens = lens
        lastScannedJob = nil
        
        badgeLabel.text = " LENS BLANK "
        badgeLabel.backgroundColor = lens.isLowStock ? OpticalLabTheme.warning : OpticalLabTheme.success
        codeLabel.text = lens.powerString
        titleLabel.text = "\(lens.brand) - \(lens.lensType.label) (\(lens.material.label))"
        detailLabel.text = "In Stock: \(lens.quantityOnHand) • Location: \(lens.binLocation.isEmpty ? "Unassigned" : lens.binLocation)"
        
        primaryActionButton.setTitle("+1 Stock Intake", for: .normal)
        primaryActionButton.isHidden = false
        
        secondaryActionButton.setTitle("-1 Stock Deduct", for: .normal)
        secondaryActionButton.isHidden = false
        
        addHistory(code: barcode, title: "Lens \(lens.brand)", detail: "\(lens.powerString) • Qty: \(lens.quantityOnHand)", isSuccess: true)
        SoundFeedbackManager.shared.playSuccessBeep()
    }
    
    private func showScanFailure(code: String, title: String, detail: String) {
        lastScannedJob = nil
        lastScannedLens = nil
        
        badgeLabel.text = " UNKNOWN CODE "
        badgeLabel.backgroundColor = OpticalLabTheme.danger
        codeLabel.text = code
        titleLabel.text = title
        detailLabel.text = detail
        
        primaryActionButton.setTitle("+ Create New Job", for: .normal)
        primaryActionButton.isHidden = false
        
        secondaryActionButton.setTitle("+ Add Lens Blank", for: .normal)
        secondaryActionButton.isHidden = false
        
        addHistory(code: code, title: title, detail: detail, isSuccess: false)
        SoundFeedbackManager.shared.playErrorBeep()
    }
    
    private func addHistory(code: String, title: String, detail: String, isSuccess: Bool) {
        let item = ScanHistoryItem(code: code, title: title, detail: detail, timestamp: Date(), isSuccess: isSuccess)
        history.insert(item, at: 0)
        historyEmptyLabel.isHidden = !history.isEmpty
        historyTable.reloadData()
    }
    
    @objc private func handlePrimaryAction() {
        if let job = lastScannedJob {
            let detailVC = JobDetailViewController(jobId: job.id)
            navigationController?.pushViewController(detailVC, animated: true)
        } else if let lens = lastScannedLens {
            _ = DatabaseManager.shared.adjustLensStock(barcode: lens.barcode, delta: 1)
            SoundFeedbackManager.shared.playSuccessBeep()
            if let refreshed = DatabaseManager.shared.getLens(byBarcode: lens.barcode) {
                handleLensFound(lens: refreshed, barcode: lens.barcode)
            }
        } else {
            // Create job
            let createVC = CreateJobViewController(prefilledTray: codeLabel.text)
            navigationController?.pushViewController(createVC, animated: true)
        }
    }
    
    @objc private func handleSecondaryAction() {
        if let job = lastScannedJob {
            _ = DatabaseManager.shared.advanceJobStage(jobId: job.id)
            SoundFeedbackManager.shared.playSuccessBeep()
            if let refreshed = DatabaseManager.shared.getJob(byId: job.id) {
                handleJobFound(job: refreshed, barcode: job.trayNumber)
            }
        } else if let lens = lastScannedLens {
            _ = DatabaseManager.shared.adjustLensStock(barcode: lens.barcode, delta: -1)
            SoundFeedbackManager.shared.playSuccessBeep()
            if let refreshed = DatabaseManager.shared.getLens(byBarcode: lens.barcode) {
                handleLensFound(lens: refreshed, barcode: lens.barcode)
            }
        } else {
            // Create lens
            let createVC = CreateLensViewController(prefilledBarcode: codeLabel.text)
            navigationController?.pushViewController(createVC, animated: true)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return history.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "HistoryCell")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HistoryCell")
            cell?.backgroundColor = .clear
            cell?.selectionStyle = .none
        }
        let item = history[indexPath.row]
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timeStr = formatter.string(from: item.timestamp)
        
        cell?.textLabel?.text = "\(timeStr) • \(item.title)"
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        cell?.textLabel?.textColor = item.isSuccess ? OpticalLabTheme.textPrimary : OpticalLabTheme.danger
        
        cell?.detailTextLabel?.text = "\(item.code) - \(item.detail)"
        cell?.detailTextLabel?.font = UIFont.systemFont(ofSize: 12)
        cell?.detailTextLabel?.textColor = OpticalLabTheme.textSecondary
        return cell!
    }
}
