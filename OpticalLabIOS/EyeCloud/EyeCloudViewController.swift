import UIKit
import WebKit

public class EyeCloudViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, BarcodeScanListener {
    
    private var webView: WKWebView!
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    // Top Navigation & Action Controls
    private let topNavBar = UIView()
    private let backButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)
    private let refreshButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let homeButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    
    // Bottom Quick Action Bar
    private let bottomActionBar = UIView()
    private let scanButton = UIButton(type: .custom)
    private let importButton = UIButton(type: .custom)
    
    // Barcode Injection Notification Toast
    private let toastLabel = UILabel()
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = OpticalLabTheme.background
        
        setupTopBar()
        setupWebView()
        setupBottomBar()
        setupToast()
        
        HardwareBarcodeScannerManager.shared.addListener(self)
        loadPortal()
    }
    
    deinit {
        HardwareBarcodeScannerManager.shared.removeListener(self)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    private func setupTopBar() {
        topNavBar.backgroundColor = OpticalLabTheme.primary
        topNavBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topNavBar)
        
        backButton.setTitle("◀", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
        
        forwardButton.setTitle("▶", for: .normal)
        forwardButton.setTitleColor(.white, for: .normal)
        forwardButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        forwardButton.addTarget(self, action: #selector(handleForward), for: .touchUpInside)
        
        refreshButton.setTitle("🔄", for: .normal)
        refreshButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        refreshButton.addTarget(self, action: #selector(handleRefresh), for: .touchUpInside)
        
        titleLabel.text = "EyeCloud Pro (NYCCT)"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        titleLabel.textAlignment = .center
        
        homeButton.setTitle("🏠", for: .normal)
        homeButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        homeButton.addTarget(self, action: #selector(handleHome), for: .touchUpInside)
        
        settingsButton.setTitle("⚙️", for: .normal)
        settingsButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        settingsButton.addTarget(self, action: #selector(handleSettings), for: .touchUpInside)
        
        let stack = UIStackView(arrangedSubviews: [backButton, forwardButton, refreshButton, titleLabel, homeButton, settingsButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = 8
        topNavBar.addSubview(stack)
        
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.progressTintColor = OpticalLabTheme.accent
        progressView.trackTintColor = .clear
        view.addSubview(progressView)
        
        NSLayoutConstraint.activate([
            topNavBar.topAnchor.constraint(equalTo: view.safeAreaTopAnchor()),
            topNavBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topNavBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topNavBar.heightAnchor.constraint(equalToConstant: 44),
            
            stack.leadingAnchor.constraint(equalTo: topNavBar.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: topNavBar.trailingAnchor, constant: -12),
            stack.centerYAnchor.constraint(equalTo: topNavBar.centerYAnchor),
            
            progressView.topAnchor.constraint(equalTo: topNavBar.bottomAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 3)
        ])
    }
    
    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.preferences.javaScriptEnabled = true
        
        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.bounces = true
        view.addSubview(webView)
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
    }
    
    private func setupBottomBar() {
        bottomActionBar.backgroundColor = OpticalLabTheme.cardBackground
        bottomActionBar.layer.borderWidth = 1.0
        bottomActionBar.layer.borderColor = OpticalLabTheme.cardBorder.cgColor
        bottomActionBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomActionBar)
        
        OpticalLabTheme.styleRuggedButton(scanButton, backgroundColor: OpticalLabTheme.accent)
        scanButton.setTitle("⚡ Scan to Field", for: .normal)
        scanButton.addTarget(self, action: #selector(handleTriggerCameraScan), for: .touchUpInside)
        
        OpticalLabTheme.styleOutlinedButton(importButton, borderColor: OpticalLabTheme.primary, titleColor: OpticalLabTheme.primary)
        importButton.setTitle("📥 Import to Lab", for: .normal)
        importButton.addTarget(self, action: #selector(handleImportJob), for: .touchUpInside)
        
        let barStack = UIStackView(arrangedSubviews: [scanButton, importButton])
        barStack.translatesAutoresizingMaskIntoConstraints = false
        barStack.axis = .horizontal
        barStack.spacing = 10
        barStack.distribution = .fillEqually
        bottomActionBar.addSubview(barStack)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomActionBar.topAnchor),
            
            bottomActionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomActionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomActionBar.bottomAnchor.constraint(equalTo: view.safeAreaBottomAnchor()),
            bottomActionBar.heightAnchor.constraint(equalToConstant: 60),
            
            barStack.leadingAnchor.constraint(equalTo: bottomActionBar.leadingAnchor, constant: 12),
            barStack.trailingAnchor.constraint(equalTo: bottomActionBar.trailingAnchor, constant: -12),
            barStack.centerYAnchor.constraint(equalTo: bottomActionBar.centerYAnchor)
        ])
    }
    
    private func setupToast() {
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        toastLabel.backgroundColor = UIColor(red: 15/255.0, green: 23/255.0, blue: 42/255.0, alpha: 0.9)
        toastLabel.textColor = .white
        toastLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        toastLabel.textAlignment = .center
        toastLabel.layer.cornerRadius = 8
        toastLabel.layer.masksToBounds = true
        toastLabel.alpha = 0.0
        view.addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: bottomActionBar.topAnchor, constant: -16),
            toastLabel.heightAnchor.constraint(equalToConstant: 38),
            toastLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -40)
        ])
    }
    
    public func loadPortal() {
        let urlStr = EyeCloudSettings.shared.portalUrl
        guard let url = URL(string: urlStr) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            progressView.progress = Float(webView.estimatedProgress)
            progressView.isHidden = webView.estimatedProgress >= 1.0
        } else {
            super.observeValue(forKeyPath: keyPath, of object: change, context: context)
        }
    }
    
    // MARK: - Barcode Injection
    
    public func onBarcodeScanned(barcode: String, symbology: String) {
        guard isViewLoaded && view.window != nil else { return }
        
        let settings = EyeCloudSettings.shared
        guard settings.isAutoInject else {
            showToast("Scanned: \(barcode)")
            return
        }
        
        let cleanBarcode = barcode.replacingOccurrences(of: "'", with: "\\'")
        let pressEnter = settings.isAutoEnter
        
        // JavaScript injection that finds active element or standard barcode input in EyeCloud Pro
        let js = """
        (function() {
            var val = '\(cleanBarcode)';
            var target = document.activeElement;
            if (!target || (target.tagName !== 'INPUT' && target.tagName !== 'TEXTAREA')) {
                target = document.querySelector('input[name*="barcode" i], input[id*="barcode" i], input[placeholder*="barcode" i], input[name*="search" i], input[type="search" i], input[name*="tray" i], input[name*="order" i]');
            }
            if (target) {
                target.focus();
                target.value = val;
                target.dispatchEvent(new Event('input', { bubbles: true }));
                target.dispatchEvent(new Event('change', { bubbles: true }));
                \(pressEnter ? "var enter = new KeyboardEvent('keydown', { key: 'Enter', keyCode: 13, which: 13, bubbles: true }); target.dispatchEvent(enter);" : "")
                return true;
            }
            return false;
        })();
        """
        
        webView.evaluateJavaScript(js) { [weak self] (result, error) in
            self?.showToast("Injected barcode: \(barcode)")
        }
    }
    
    private func showToast(_ message: String) {
        toastLabel.text = "  \(message)  "
        UIView.animate(withDuration: 0.25, animations: {
            self.toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2.2, options: [], animations: {
                self.toastLabel.alpha = 0.0
            }, completion: nil)
        }
    }
    
    // MARK: - Actions
    
    @objc private func handleBack() {
        if webView.canGoBack { webView.goBack() }
    }
    
    @objc private func handleForward() {
        if webView.canGoForward { webView.goForward() }
    }
    
    @objc private func handleRefresh() {
        webView.reload()
    }
    
    @objc private func handleHome() {
        loadPortal()
    }
    
    @objc private func handleTriggerCameraScan() {
        let scannerVC = BarcodeScannerViewController()
        scannerVC.delegate = self
        present(scannerVC, animated: true, completion: nil)
    }
    
    @objc private func handleSettings() {
        let alert = UIAlertController(title: "EyeCloud Pro Connection", message: "Configure optical portal endpoint:", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Portal URL"
            tf.text = EyeCloudSettings.shared.portalUrl
        }
        alert.addTextField { tf in
            tf.placeholder = "Practice ID"
            tf.text = EyeCloudSettings.shared.practiceId
        }
        
        alert.addAction(UIAlertAction(title: "Save & Reload", style: .default) { [weak self] _ in
            if let newUrl = alert.textFields?[0].text, !newUrl.isEmpty {
                EyeCloudSettings.shared.portalUrl = newUrl
            }
            if let newPractice = alert.textFields?[1].text, !newPractice.isEmpty {
                EyeCloudSettings.shared.practiceId = newPractice
            }
            self?.loadPortal()
        })
        
        alert.addAction(UIAlertAction(title: "Reset Default", style: .destructive) { [weak self] _ in
            EyeCloudSettings.shared.portalUrl = EyeCloudSettings.defaultUrl
            EyeCloudSettings.shared.practiceId = EyeCloudSettings.defaultPracticeId
            self?.loadPortal()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, completion: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func handleImportJob() {
        let alert = UIAlertController(title: "Import EyeCloud Job", message: "Enter or scan EyeCloud Order / Tray #:", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Tray or Order #"
        }
        
        alert.addAction(UIAlertAction(title: "Import / Open", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
            
            if let existing = DatabaseManager.shared.getJob(byTrayNumber: text) {
                let detailVC = JobDetailViewController(jobId: existing.id)
                self?.navigationController?.pushViewController(detailVC, animated: true)
            } else {
                let createVC = CreateJobViewController(prefilledTray: text)
                self?.navigationController?.pushViewController(createVC, animated: true)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, completion: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - WKNavigationDelegate
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
        if let title = webView.title, !title.isEmpty {
            titleLabel.text = title
        }
    }
}

extension EyeCloudViewController: CameraBarcodeScannerDelegate {
    public func didScanBarcode(code: String, format: String) {
        onBarcodeScanned(barcode: code, symbology: format)
    }
}
