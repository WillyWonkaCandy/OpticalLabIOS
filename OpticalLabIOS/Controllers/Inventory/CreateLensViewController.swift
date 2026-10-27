import UIKit

public class CreateLensViewController: BaseScannerViewController {
    
    private let prefilledBarcode: String?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let barcodeField = UITextField()
    private let brandField = UITextField()
    private let coatingField = UITextField()
    private let binField = UITextField()
    
    private let sphField = UITextField()
    private let cylField = UITextField()
    private let addField = UITextField()
    private let qtyField = UITextField()
    private let minThresholdField = UITextField()
    
    private let typeSegment = UISegmentedControl(items: ["SV", "FT-28", "PAL"])
    private let materialSegment = UISegmentedControl(items: ["CR-39", "Poly 1.59", "Trivex", "High Index"])
    
    private let saveButton = UIButton(type: .custom)
    
    public init(prefilledBarcode: String? = nil) {
        self.prefilledBarcode = prefilledBarcode
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Lens Blank"
        setupUI()
        
        if let code = prefilledBarcode, !code.isEmpty {
            barcodeField.text = code
        }
    }
    
    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        setupField(barcodeField, placeholder: "Lens Barcode / Packet EAN (Required)")
        setupField(brandField, placeholder: "Brand (Essilor, Zeiss, Hoya, etc.)")
        brandField.text = "Essilor"
        setupField(coatingField, placeholder: "Coating (AR, Blue Blocker, HC)")
        coatingField.text = "AR Coating"
        setupField(binField, placeholder: "Bin Location (e.g. Rack A - Bin 04)")
        
        setupNumericField(sphField, placeholder: "SPH (+0.00)")
        sphField.text = "0.00"
        setupNumericField(cylField, placeholder: "CYL (-0.00)")
        cylField.text = "0.00"
        setupNumericField(addField, placeholder: "ADD (+0.00)")
        setupNumericField(qtyField, placeholder: "Initial Qty")
        qtyField.text = "2"
        setupNumericField(minThresholdField, placeholder: "Min Threshold")
        minThresholdField.text = "2"
        
        typeSegment.selectedSegmentIndex = 0
        materialSegment.selectedSegmentIndex = 1
        
        OpticalLabTheme.styleRuggedButton(saveButton, backgroundColor: OpticalLabTheme.accent)
        saveButton.setTitle("Save Lens to Inventory", for: .normal)
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        
        let powerRow = makeHorizontalRow([sphField, cylField, addField])
        let qtyRow = makeHorizontalRow([qtyField, minThresholdField])
        
        let formStack = UIStackView(arrangedSubviews: [
            makeLabel("Barcode & Identification"),
            barcodeField, brandField, binField, coatingField,
            makeLabel("Lens Type & Material"),
            typeSegment, materialSegment,
            makeLabel("Optical Powers (Diopters)"),
            powerRow,
            makeLabel("Stock Inventory"),
            qtyRow,
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
    
    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = OpticalLabTheme.primary
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        return label
    }
    
    @objc private func handleSave() {
        let barcode = barcodeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !barcode.isEmpty else {
            showError("Barcode is required")
            return
        }
        
        let typeMap: [LensType] = [.singleVision, .flatTopBifocal, .progressivePal]
        let selectedType = typeMap[typeSegment.selectedSegmentIndex]
        
        let matMap: [LensMaterial] = [.cr39, .polycarbonate, .trivex, .highIndex167]
        let selectedMat = matMap[materialSegment.selectedSegmentIndex]
        
        let lens = LensItem(
            barcode: barcode,
            sku: barcode,
            brand: brandField.text?.isEmpty == false ? brandField.text! : "Essilor",
            lensType: selectedType,
            material: selectedMat,
            coating: coatingField.text ?? "AR",
            sphere: Double(sphField.text ?? "") ?? 0.0,
            cylinder: Double(cylField.text ?? "") ?? 0.0,
            addPower: Double(addField.text ?? "") ?? 0.0,
            quantityOnHand: Int(qtyField.text ?? "") ?? 0,
            minThreshold: Int(minThresholdField.text ?? "") ?? 2,
            binLocation: binField.text ?? ""
        )
        
        let rowId = DatabaseManager.shared.insertLens(lens)
        if rowId > 0 {
            SoundFeedbackManager.shared.playSuccessBeep()
            navigationController?.popViewController(animated: true)
        } else {
            showError("Could not save lens. A lens with this barcode already exists.")
        }
    }
    
    private func showError(_ msg: String) {
        let alert = UIAlertController(title: "Save Error", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, completion: nil))
        present(alert, animated: true, completion: nil)
    }
    
    override public func onBarcodeScanned(barcode: String, symbology: String) {
        super.onBarcodeScanned(barcode: barcode, symbology: symbology)
        barcodeField.text = barcode
    }
}
