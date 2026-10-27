import UIKit
import AVFoundation

public protocol CameraBarcodeScannerDelegate: AnyObject {
    func didScanBarcode(code: String, format: String)
}

public class BarcodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    public weak var delegate: CameraBarcodeScannerDelegate?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isScanning = true
    
    private let overlayView = UIView()
    private let targetBox = UIView()
    private let statusLabel = UILabel()
    private let flashButton = UIButton(type: .custom)
    private let closeButton = UIButton(type: .custom)
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isScanning = true
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                session.startRunning()
            }
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateOverlayMask()
    }
    
    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(for: .video) else {
            showCameraError("No camera hardware detected.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                showCameraError("Cannot attach camera input.")
                return
            }
        } catch {
            showCameraError("Camera access failed: \(error.localizedDescription)")
            return
        }
        
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // Optical barcodes: Code128, EAN13, DataMatrix, QR, Code39, ITF14, UPCE
            let desiredTypes: [AVMetadataObject.ObjectType] = [
                .code128, .ean13, .ean8, .qr, .dataMatrix, .code39, .code93, .upce, .pdf417, .itf14
            ]
            let availableTypes = output.availableMetadataObjectTypes
            output.metadataObjectTypes = desiredTypes.filter { availableTypes.contains($0) }
        } else {
            showCameraError("Cannot attach barcode reader metadata output.")
            return
        }
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        
        self.previewLayer = layer
        self.captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }
    
    private func setupUI() {
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.isUserInteractionEnabled = false
        view.addSubview(overlayView)
        
        targetBox.translatesAutoresizingMaskIntoConstraints = false
        targetBox.layer.borderColor = OpticalLabTheme.accent.cgColor
        targetBox.layer.borderWidth = 2.5
        targetBox.layer.cornerRadius = 8
        targetBox.backgroundColor = .clear
        view.addSubview(targetBox)
        
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "Align Lens / Job Barcode in Viewfinder"
        statusLabel.textColor = .white
        statusLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        statusLabel.textAlignment = .center
        statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        statusLabel.layer.cornerRadius = 6
        statusLabel.layer.masksToBounds = true
        view.addSubview(statusLabel)
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("✕ Close", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 8
        closeButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        view.addSubview(closeButton)
        
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.setTitle("💡 Torch", for: .normal)
        flashButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        flashButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        flashButton.layer.cornerRadius = 8
        flashButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        flashButton.addTarget(self, action: #selector(toggleTorch), for: .touchUpInside)
        view.addSubview(flashButton)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            targetBox.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            targetBox.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            targetBox.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            targetBox.heightAnchor.constraint(equalToConstant: 180),
            
            statusLabel.bottomAnchor.constraint(equalTo: targetBox.topAnchor, constant: -20),
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 36),
            statusLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -32),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaTopAnchor(), constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            flashButton.topAnchor.constraint(equalTo: view.safeAreaTopAnchor(), constant: 16),
            flashButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            flashButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func updateOverlayMask() {
        let boxFrame = targetBox.frame
        guard boxFrame.width > 0 else { return }
        
        let path = UIBezierPath(rect: view.bounds)
        let cutout = UIBezierPath(roundedRect: boxFrame, cornerRadius: 8)
        path.append(cutout)
        path.usesEvenOddFillRule = true
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard isScanning else { return }
        
        for obj in metadataObjects {
            if let readable = obj as? AVMetadataMachineReadableCodeObject,
               let val = readable.stringValue, !val.isEmpty {
                isScanning = false
                let format = readable.type.rawValue
                
                SoundFeedbackManager.shared.playSuccessBeep()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.dismiss(animated: true) {
                        self.delegate?.didScanBarcode(code: val, format: format)
                        HardwareBarcodeScannerManager.shared.notifyBarcodeScanned(barcode: val, symbology: format)
                    }
                }
                break
            }
        }
    }
    
    @objc private func handleClose() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = (device.torchMode == .on) ? .off : .on
            device.unlockForConfiguration()
            flashButton.setTitle(device.torchMode == .on ? "🔦 Off" : "💡 Torch", for: .normal)
        } catch {
            print("Torch error: \(error)")
        }
    }
    
    private func showCameraError(_ msg: String) {
        let alert = UIAlertController(title: "Camera Scanner", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true, completion: nil)
    }
}

// iOS 12 Safe Area fallback helper
extension UIView {
    public func safeAreaTopAnchor() -> NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.topAnchor
        }
        return topAnchor
    }
    
    public func safeAreaBottomAnchor() -> NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.bottomAnchor
        }
        return bottomAnchor
    }
}
