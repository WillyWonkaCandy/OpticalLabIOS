import UIKit

public class CreateJobViewController: BaseScannerViewController {
    
    private let prefilledTray: String?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let trayTextField = UITextField()
    private let orderTextField = UITextField()
    private let patientTextField = UITextField()
    private let customerTextField = UITextField()
    private let frameTextField = UITextField()
    private let prioritySegment = UISegmentedControl(items: ["Normal", "Rush", "Remake"])
    
    // Prescription OD
    private let odSphField = UITextField()
    private let odCylField = UITextField()
    private let odAxisField = UITextField()
    private let odAddField = UITextField()
    private let odPdField = UITextField()
    
    // Prescription OS
    private let osSphField = UITextField()
    private let osCylField = UITextField()
    private let osAxisField = UITextField()
    private let osAddField = UITextField()
    private let osPdField = UITextField()
    
    private let saveButton = UIButton(type: .custom)
    
    public init(prefilledTray: String? = nil) {
        self.prefilledTray = prefilledTray
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "New Optical Job"
        setupUI()
        
        if let tray = prefilledTray, !tray.isEmpty {
            trayTextField.text = tray
            orderTextField.text = tray
        }
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupField(trayTextField, placeholder: "Tray / Job Number (Required)")
        setupField(orderTextField, placeholder: "EyeCloud Order # (Optional)")
        setupField(patientTextField, placeholder: "Patient Name")
        setupField(customerTextField, placeholder: "Doctor / Account")
        setupField(frameTextField, placeholder: "Frame Model / Style")
        
        prioritySegment.selectedSegmentIndex = 0
        prioritySegment.tintColor = OpticalLabTheme.primary
        
        // Rx Fields
        setupNumericField(odSphField, placeholder: "OD SPH (+0.00)")
        setupNumericField(odCylField, placeholder: "OD CYL (-0.00)")
        setupNumericField(odAxisField, placeholder: "OD AXIS (0-180)")
        setupNumericField(odAddField, placeholder: "OD ADD (+0.00)")
        setupNumericField(odPdField, placeholder: "OD PD (mm)")
        odPdField.text = "31.0"
        
        setupNumericField(osSphField, placeholder: "OS SPH (+0.00)")
        setupNumericField(osCylField, placeholder: "OS CYL (-0.00)")
        setupNumericField(osAxisField, placeholder: "OS AXIS (0-180)")
        setupNumericField(osAddField, placeholder: "OS ADD (+0.00)")
        setupNumericField(osPdField, placeholder: "OS PD (mm)")
        osPdField.text = "31.0"
        
        OpticalLabTheme.styleRuggedButton(saveButton, backgroundColor: OpticalLabTheme.accent)
        saveButton.setTitle("Save Job to Database", for: .normal)
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        
        // Assemble Stack
        let odRow1 = makeHorizontalRow([odSphField, odCylField, odAxisField])
        let odRow2 = makeHorizontalRow([odAddField, odPdField])
        
        let osRow1 = makeHorizontalRow([osSphField, osCylField, osAxisField])
        let osRow2 = makeHorizontalRow([osAddField, osPdField])
        
        let odLabel = makeSectionLabel("Right Eye (O.D.) Prescription")
        let osLabel = makeSectionLabel("Left Eye (O.S.) Prescription")
        let generalLabel = makeSectionLabel("Order Information")
        
        let formStack = UIStackView(arrangedSubviews: [
            generalLabel, trayTextField, orderTextField, patientTextField, customerTextField, frameTextField, prioritySegment,
            odLabel, odRow1, odRow2,
            osLabel, osRow1, osRow2,
            saveButton
        ])
        formStack.translatesAutoresizingMaskIntoConstraints = false
        formStack.axis = .vertical
        formStack.spacing = 12
        contentView.addSubview(formStack)
        
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
            
            formStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            formStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
            formStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            formStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.font = UIFont.systemFont(ofSize: 15)
        field.backgroundColor = OpticalLabTheme.cardBackground
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    private func setupNumericField(_ field: UITextField, placeholder: String) {
        setupField(field, placeholder: placeholder)
        field.keyboardType = .numbersAndPunctuation
        field.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
    }
    
    private func makeHorizontalRow(_ views: [UIView]) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: views)
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }
    
    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = OpticalLabTheme.primary
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        return label
    }
    
    @objc private func handleSave() {
        let tray = trayTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !tray.isEmpty else {
            showError("Tray number is required")
            return
        }
        
        let priority = prioritySegment.titleForSegment(at: prioritySegment.selectedSegmentIndex) ?? "Normal"
        let job = OpticalJob(
            trayNumber: tray,
            orderNumber: orderTextField.text ?? "",
            patientName: patientTextField.text ?? "",
            customerName: customerTextField.text ?? "",
            priority: priority,
            frameModel: frameTextField.text ?? "",
            odSphere: Double(odSphField.text ?? "") ?? 0.0,
            odCylinder: Double(odCylField.text ?? "") ?? 0.0,
            odAxis: Int(odAxisField.text ?? "") ?? 0,
            odAdd: Double(odAddField.text ?? "") ?? 0.0,
            odPd: Double(odPdField.text ?? "") ?? 31.0,
            osSphere: Double(osSphField.text ?? "") ?? 0.0,
            osCylinder: Double(osCylField.text ?? "") ?? 0.0,
            osAxis: Int(osAxisField.text ?? "") ?? 0,
            osAdd: Double(osAddField.text ?? "") ?? 0.0,
            osPd: Double(osPdField.text ?? "") ?? 31.0
        )
        
        let rowId = DatabaseManager.shared.insertJob(job)
        if rowId > 0 {
            SoundFeedbackManager.shared.playSuccessBeep()
            navigationController?.popViewController(animated: true)
        } else {
            showError("Could not save job. A tray with this number may already exist.")
        }
    }
    
    private func showError(_ msg: String) {
        let alert = UIAlertController(title: "Save Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, completion: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override public func onBarcodeScanned(barcode: String, symbology: String) {
        super.onBarcodeScanned(barcode: barcode, symbology: symbology)
        if trayTextField.text?.isEmpty ?? true {
            trayTextField.text = barcode
        } else if orderTextField.text?.isEmpty ?? true {
            orderTextField.text = barcode
        }
    }
}
