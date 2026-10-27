import UIKit

public class LensDetailViewController: BaseScannerViewController {
    
    private let lensId: Int64
    private var lens: LensItem?
    
    private let brandLabel = UILabel()
    private let barcodeLabel = UILabel()
    private let powerLabel = UILabel()
    private let detailsLabel = UILabel()
    private let binLabel = UILabel()
    private let stockLabel = UILabel()
    
    private let plusOneButton = UIButton(type: .custom)
    private let plusFiveButton = UIButton(type: .custom)
    private let minusOneButton = UIButton(type: .custom)
    
    public init(lensId: Int64) {
        self.lensId = lensId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Lens Details"
        setupUI()
        loadLens()
    }
    
    private func setupUI() {
        let card = UIView()
        OpticalLabTheme.styleCardView(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        
        brandLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        brandLabel.textColor = OpticalLabTheme.textPrimary
        
        barcodeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        barcodeLabel.textColor = OpticalLabTheme.textMuted
        
        powerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .bold)
        powerLabel.textColor = OpticalLabTheme.primary
        
        detailsLabel.font = UIFont.systemFont(ofSize: 14)
        detailsLabel.textColor = OpticalLabTheme.textSecondary
        detailsLabel.numberOfLines = 0
        
        binLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        binLabel.textColor = OpticalLabTheme.accent
        
        stockLabel.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
        stockLabel.textColor = OpticalLabTheme.textPrimary
        stockLabel.textAlignment = .center
        
        // Buttons
        OpticalLabTheme.styleRuggedButton(plusOneButton, backgroundColor: OpticalLabTheme.success)
        plusOneButton.setTitle("+1 Stock", for: .normal)
        plusOneButton.addTarget(self, action: #selector(handleAddOne), for: .touchUpInside)
        
        OpticalLabTheme.styleRuggedButton(plusFiveButton, backgroundColor: OpticalLabTheme.accent)
        plusFiveButton.setTitle("+5 Stock", for: .normal)
        plusFiveButton.addTarget(self, action: #selector(handleAddFive), for: .touchUpInside)
        
        OpticalLabTheme.styleOutlinedButton(minusOneButton, borderColor: OpticalLabTheme.danger, titleColor: OpticalLabTheme.danger)
        minusOneButton.setTitle("-1 Stock", for: .normal)
        minusOneButton.addTarget(self, action: #selector(handleMinusOne), for: .touchUpInside)
        
        let buttonStack = UIStackView(arrangedSubviews: [plusOneButton, plusFiveButton, minusOneButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 10
        buttonStack.distribution = .fillEqually
        
        let cardStack = UIStackView(arrangedSubviews: [
            brandLabel, barcodeLabel, powerLabel, detailsLabel, binLabel, stockLabel, buttonStack
        ])
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        cardStack.axis = .vertical
        cardStack.spacing = 14
        card.addSubview(cardStack)
        
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: 16),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            
            plusOneButton.heightAnchor.constraint(equalToConstant: 48),
            plusFiveButton.heightAnchor.constraint(equalToConstant: 48),
            minusOneButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func loadLens() {
        guard let current = DatabaseManager.shared.getLens(byId: lensId) else { return }
        self.lens = current
        
        brandLabel.text = current.brand
        barcodeLabel.text = "Barcode: \(current.barcode) • SKU: \(current.sku.isEmpty ? "N/A" : current.sku)"
        powerLabel.text = current.powerString
        detailsLabel.text = "\(current.lensType.label)\nMaterial: \(current.material.label)\nCoating: \(current.coating)\nDiameter: \(current.diameter)mm"
        binLabel.text = "Location: \(current.binLocation.isEmpty ? "Unassigned" : current.binLocation)"
        stockLabel.text = "In Stock: \(current.quantityOnHand)"
        
        if current.isLowStock {
            stockLabel.textColor = OpticalLabTheme.warning
        } else {
            stockLabel.textColor = OpticalLabTheme.success
        }
    }
    
    @objc private func handleAddOne() {
        adjustStock(delta: 1)
    }
    
    @objc private func handleAddFive() {
        adjustStock(delta: 5)
    }
    
    @objc private func handleMinusOne() {
        adjustStock(delta: -1)
    }
    
    private func adjustStock(delta: Int) {
        guard let current = lens else { return }
        _ = DatabaseManager.shared.adjustLensStock(barcode: current.barcode, delta: delta)
        SoundFeedbackManager.shared.playSuccessBeep()
        loadLens()
    }
}
