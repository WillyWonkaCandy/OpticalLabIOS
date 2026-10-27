import UIKit

public class InventoryListViewController: BaseScannerViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var lenses: [LensItem] = []
    private var filteredLenses: [LensItem] = []
    
    private let searchBar = UISearchBar()
    private let emptyView = UILabel()
    private let addLensButton = UIButton(type: .custom)
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Lens Inventory"
        setupUI()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadLenses()
    }
    
    private func setupUI() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search Barcode, SPH, Brand, Bin"
        searchBar.barTintColor = OpticalLabTheme.background
        searchBar.delegate = self
        view.addSubview(searchBar)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = OpticalLabTheme.background
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(LensCardCell.self, forCellReuseIdentifier: "LensCardCell")
        view.addSubview(tableView)
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.text = "No lens blanks in inventory.\nTap '+ Add Lens' or scan a lens packet."
        emptyView.textColor = OpticalLabTheme.textMuted
        emptyView.font = UIFont.systemFont(ofSize: 15)
        emptyView.textAlignment = .center
        emptyView.numberOfLines = 0
        emptyView.isHidden = true
        view.addSubview(emptyView)
        
        OpticalLabTheme.styleRuggedButton(addLensButton, backgroundColor: OpticalLabTheme.accent)
        addLensButton.translatesAutoresizingMaskIntoConstraints = false
        addLensButton.setTitle("+ Add Lens Blank", for: .normal)
        addLensButton.addTarget(self, action: #selector(handleCreateLens), for: .touchUpInside)
        view.addSubview(addLensButton)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addLensButton.topAnchor, constant: -8),
            
            emptyView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            addLensButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addLensButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addLensButton.bottomAnchor.constraint(equalTo: view.safeAreaBottomAnchor(), constant: -8),
            addLensButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func loadLenses() {
        lenses = DatabaseManager.shared.getAllLenses()
        filterLenses()
    }
    
    private func filterLenses() {
        let query = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if query.isEmpty {
            filteredLenses = lenses
        } else {
            filteredLenses = lenses.filter {
                $0.barcode.lowercased().contains(query) ||
                $0.brand.lowercased().contains(query) ||
                $0.binLocation.lowercased().contains(query) ||
                $0.powerString.lowercased().contains(query)
            }
        }
        emptyView.isHidden = !filteredLenses.isEmpty
        tableView.reloadData()
    }
    
    @objc private func handleCreateLens() {
        let createVC = CreateLensViewController()
        navigationController?.pushViewController(createVC, animated: true)
    }
    
    override public func onBarcodeScanned(barcode: String, symbology: String) {
        super.onBarcodeScanned(barcode: barcode, symbology: symbology)
        
        if let lens = DatabaseManager.shared.getLens(byBarcode: barcode) {
            let detailVC = LensDetailViewController(lensId: lens.id)
            navigationController?.pushViewController(detailVC, animated: true)
        } else {
            // Lens not found in inventory -> offer to create it
            let alert = UIAlertController(title: "New Lens Scanned", message: "Barcode: \(barcode)\nThis lens is not yet in inventory. Add it now?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Add Lens Blank", style: .default) { [weak self] _ in
                let createVC = CreateLensViewController(prefilledBarcode: barcode)
                self?.navigationController?.pushViewController(createVC, animated: true)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, completion: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLenses.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LensCardCell", for: indexPath) as! LensCardCell
        cell.configure(with: filteredLenses[indexPath.row])
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let lens = filteredLenses[indexPath.row]
        let detailVC = LensDetailViewController(lensId: lens.id)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension InventoryListViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterLenses()
    }
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - LensCardCell
public class LensCardCell: UITableViewCell {
    
    private let cardView = UIView()
    private let brandLabel = UILabel()
    private let powerLabel = UILabel()
    private let typeLabel = UILabel()
    private let binLabel = UILabel()
    private let stockBadge = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        
        OpticalLabTheme.styleCardView(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        brandLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        brandLabel.textColor = OpticalLabTheme.textPrimary
        
        powerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .semibold)
        powerLabel.textColor = OpticalLabTheme.primary
        
        typeLabel.font = UIFont.systemFont(ofSize: 12)
        typeLabel.textColor = OpticalLabTheme.textSecondary
        
        binLabel.font = UIFont.systemFont(ofSize: 11)
        binLabel.textColor = OpticalLabTheme.textMuted
        
        stockBadge.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        stockBadge.textColor = .white
        stockBadge.layer.cornerRadius = 6
        stockBadge.layer.masksToBounds = true
        stockBadge.textAlignment = .center
        
        let headerRow = UIStackView(arrangedSubviews: [brandLabel, stockBadge])
        headerRow.axis = .horizontal
        headerRow.distribution = .equalSpacing
        
        let stack = UIStackView(arrangedSubviews: [headerRow, powerLabel, typeLabel, binLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        cardView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            
            stack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            
            stockBadge.heightAnchor.constraint(equalToConstant: 24),
            stockBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 64)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    public func configure(with item: LensItem) {
        brandLabel.text = item.brand
        powerLabel.text = item.powerString
        typeLabel.text = "\(item.lensType.label) • \(item.material.label)"
        binLabel.text = "Bin: \(item.binLocation.isEmpty ? "Unassigned" : item.binLocation) • \(item.barcode)"
        
        stockBadge.text = " Qty: \(item.quantityOnHand) "
        if item.quantityOnHand == 0 {
            stockBadge.backgroundColor = OpticalLabTheme.danger
        } else if item.isLowStock {
            stockBadge.backgroundColor = OpticalLabTheme.warning
        } else {
            stockBadge.backgroundColor = OpticalLabTheme.success
        }
    }
}
