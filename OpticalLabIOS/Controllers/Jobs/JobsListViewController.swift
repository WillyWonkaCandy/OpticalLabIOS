import UIKit

public class JobsListViewController: BaseScannerViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var jobs: [OpticalJob] = []
    private var filteredJobs: [OpticalJob] = []
    
    private let searchBar = UISearchBar()
    private let emptyView = UILabel()
    private let addJobButton = UIButton(type: .custom)
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Lab Jobs"
        setupUI()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadJobs()
    }
    
    private func setupUI() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.placeholder = "Search Tray, Order, or Patient"
        searchBar.barTintColor = OpticalLabTheme.background
        searchBar.delegate = self
        view.addSubview(searchBar)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = OpticalLabTheme.background
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(JobCardCell.self, forCellReuseIdentifier: "JobCardCell")
        view.addSubview(tableView)
        
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.text = "No optical lab jobs yet.\nTap '+ New Job' or scan a tray barcode."
        emptyView.textColor = OpticalLabTheme.textMuted
        emptyView.font = UIFont.systemFont(ofSize: 15)
        emptyView.textAlignment = .center
        emptyView.numberOfLines = 0
        emptyView.isHidden = true
        view.addSubview(emptyView)
        
        OpticalLabTheme.styleRuggedButton(addJobButton, backgroundColor: OpticalLabTheme.accent)
        addJobButton.translatesAutoresizingMaskIntoConstraints = false
        addJobButton.setTitle("+ New Job", for: .normal)
        addJobButton.addTarget(self, action: #selector(handleCreateJob), for: .touchUpInside)
        view.addSubview(addJobButton)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: headerBar.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: addJobButton.topAnchor, constant: -8),
            
            emptyView.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            addJobButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            addJobButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            addJobButton.bottomAnchor.constraint(equalTo: view.safeAreaBottomAnchor(), constant: -8),
            addJobButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func loadJobs() {
        jobs = DatabaseManager.shared.getAllJobs()
        filterJobs()
    }
    
    private func filterJobs() {
        let query = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if query.isEmpty {
            filteredJobs = jobs
        } else {
            filteredJobs = jobs.filter {
                $0.trayNumber.lowercased().contains(query) ||
                $0.orderNumber.lowercased().contains(query) ||
                $0.patientName.lowercased().contains(query)
            }
        }
        emptyView.isHidden = !filteredJobs.isEmpty
        tableView.reloadData()
    }
    
    @objc private func handleCreateJob() {
        let createVC = CreateJobViewController()
        navigationController?.pushViewController(createVC, animated: true)
    }
    
    override public func onBarcodeScanned(barcode: String, symbology: String) {
        super.onBarcodeScanned(barcode: barcode, symbology: symbology)
        
        let parsed = BarcodeActionParser.parse(barcode)
        let searchKey = parsed.type == .jobTray ? parsed.payload : barcode
        
        if let job = DatabaseManager.shared.getJob(byTrayNumber: searchKey) {
            let detailVC = JobDetailViewController(jobId: job.id)
            navigationController?.pushViewController(detailVC, animated: true)
        } else {
            // Search in list
            searchBar.text = searchKey
            filterJobs()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredJobs.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "JobCardCell", for: indexPath) as! JobCardCell
        cell.configure(with: filteredJobs[indexPath.row])
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let job = filteredJobs[indexPath.row]
        let detailVC = JobDetailViewController(jobId: job.id)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let job = filteredJobs[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            _ = DatabaseManager.shared.deleteJob(id: job.id)
            self?.loadJobs()
            completion(true)
        }
        deleteAction.backgroundColor = .systemRed
        
        let archiveAction = UIContextualAction(style: .normal, title: job.isArchived ? "Restore" : "Archive") { [weak self] (_, _, completion) in
            if job.isArchived {
                _ = DatabaseManager.shared.unarchiveJob(id: job.id)
            } else {
                _ = DatabaseManager.shared.archiveJob(id: job.id)
            }
            self?.loadJobs()
            completion(true)
        }
        archiveAction.backgroundColor = .systemOrange
        
        return UISwipeActionsConfiguration(actions: [deleteAction, archiveAction])
    }
}

extension JobsListViewController: UISearchBarDelegate {
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterJobs()
    }
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - JobCardCell
public class JobCardCell: UITableViewCell {
    
    private let cardView = UIView()
    private let trayLabel = UILabel()
    private let stageBadge = UILabel()
    private let patientLabel = UILabel()
    private let rxLabel = UILabel()
    private let frameLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        
        OpticalLabTheme.styleCardView(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        trayLabel.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        trayLabel.textColor = OpticalLabTheme.textPrimary
        
        stageBadge.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        stageBadge.textColor = .white
        stageBadge.layer.cornerRadius = 6
        stageBadge.layer.masksToBounds = true
        stageBadge.textAlignment = .center
        
        patientLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        patientLabel.textColor = OpticalLabTheme.textSecondary
        
        rxLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        rxLabel.textColor = OpticalLabTheme.primary
        
        frameLabel.font = UIFont.systemFont(ofSize: 12)
        frameLabel.textColor = OpticalLabTheme.textMuted
        
        let headerStack = UIStackView(arrangedSubviews: [trayLabel, stageBadge])
        headerStack.axis = .horizontal
        headerStack.distribution = .equalSpacing
        
        let fullStack = UIStackView(arrangedSubviews: [headerStack, patientLabel, rxLabel, frameLabel])
        fullStack.translatesAutoresizingMaskIntoConstraints = false
        fullStack.axis = .vertical
        fullStack.spacing = 6
        cardView.addSubview(fullStack)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            
            fullStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            fullStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            fullStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            fullStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            
            stageBadge.heightAnchor.constraint(equalToConstant: 24),
            stageBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    public func configure(with job: OpticalJob) {
        trayLabel.text = "Tray: \(job.trayNumber)"
        stageBadge.text = " \(job.stage.displayName) "
        stageBadge.backgroundColor = job.stage.stageColor
        
        let patient = job.patientName.isEmpty ? "Standard Lab Order" : job.patientName
        let order = job.orderNumber.isEmpty ? "" : " (Order #\(job.orderNumber))"
        patientLabel.text = "\(patient)\(order)"
        
        rxLabel.text = "OD: \(job.odRxString)  |  OS: \(job.osRxString)"
        frameLabel.text = "Frame: \(job.frameModel.isEmpty ? "Unspecified" : job.frameModel) • \(job.frameType.label)"
    }
}
