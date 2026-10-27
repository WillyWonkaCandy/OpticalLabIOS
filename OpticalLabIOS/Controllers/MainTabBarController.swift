import UIKit

public class MainTabBarController: UITabBarController {
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
    }
    
    private func setupTabs() {
        // 1. Lab Jobs
        let jobsVC = JobsListViewController()
        let jobsNav = UINavigationController(rootViewController: jobsVC)
        jobsNav.tabBarItem = UITabBarItem(
            title: "Jobs",
            image: OpticalLabTheme.createIcon(named: "jobs"),
            tag: 0
        )
        
        // 2. Lens Inventory
        let invVC = InventoryListViewController()
        let invNav = UINavigationController(rootViewController: invVC)
        invNav.tabBarItem = UITabBarItem(
            title: "Inventory",
            image: OpticalLabTheme.createIcon(named: "inventory"),
            tag: 1
        )
        
        // 3. Scan Station
        let scanVC = ScanStationViewController()
        let scanNav = UINavigationController(rootViewController: scanVC)
        scanNav.tabBarItem = UITabBarItem(
            title: "Scan Station",
            image: OpticalLabTheme.createIcon(named: "scanner"),
            tag: 2
        )
        
        // 4. ANSI Quality Control
        let qcVC = QcInspectionViewController()
        let qcNav = UINavigationController(rootViewController: qcVC)
        qcNav.tabBarItem = UITabBarItem(
            title: "Inspection",
            image: OpticalLabTheme.createIcon(named: "qc"),
            tag: 3
        )
        
        // 5. EyeCloud Pro Portal
        let eyeCloudVC = EyeCloudViewController()
        let eyeCloudNav = UINavigationController(rootViewController: eyeCloudVC)
        eyeCloudNav.tabBarItem = UITabBarItem(
            title: "EyeCloud",
            image: OpticalLabTheme.createIcon(named: "cloud"),
            tag: 4
        )
        
        viewControllers = [jobsNav, invNav, scanNav, qcNav, eyeCloudNav]
    }
    
    private func setupAppearance() {
        tabBar.tintColor = OpticalLabTheme.accent
        tabBar.barTintColor = OpticalLabTheme.cardBackground
        tabBar.isTranslucent = false
        
        // Navigation bar appearance for iOS 12+
        UINavigationBar.appearance().barTintColor = OpticalLabTheme.primary
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17, weight: .bold)
        ]
    }
}
