# Optical Lab ToughManager for iOS (iPhone 6 & Newer)

A native iOS application engineered for optical lens inventory management, prescription job tracking, CNC edging workflows, ANSI Z80.1 quality control verification, and direct integration with **EyeCloud Pro**.

Natively compatible with **iOS 12.5.8** (the final iOS release for iPhone 6 and iPhone 6 Plus) as well as all newer iPhone models running iOS 13 through iOS 17+.

---

## 📱 Device & OS Compatibility

- **Target Architecture**: 64-bit ARM (`arm64`), compatible with Apple A8 SoC (iPhone 6, iPhone 6 Plus) through modern A-series chips.
- **Minimum OS Version**: **iOS 12.0** (`IPHONEOS_DEPLOYMENT_TARGET = 12.0`).
- **Tested Hardware Form Factors**:
  - **iPhone 6 / 6 Plus** (4.7" & 5.5" Retina HD displays running iOS 12.5.8).
  - **iPhone 6s, 7, 8, SE (1st, 2nd, 3rd Gen)**.
  - **iPhone X, XS, 11, 12, 13, 14, 15, 16** (with automatic Safe Area and notch accommodation).
- **Zero iOS 13+ Dependency**:
  - Does NOT rely on SF Symbols (`UIImage(systemName:)`), ensuring icons render cleanly on iOS 12 using native CoreGraphics vector drawing.
  - Does NOT require `SceneDelegate` (full fallback in `AppDelegate` with `UIWindow` initialization).
  - Explicit theme colors (does not rely on iOS 13 semantic colors like `UIColor.systemBackground`).
  - Native SQLite3 (`libsqlite3.tbd`) with zero CocoaPods/SPM dependencies for rapid, lightweight deployment.

---

## 🔍 Barcode Scanning Subsystem

### 1. Bluetooth / Rugged Handheld Scanners
- Connect any Bluetooth optical scanner (e.g. Socket Mobile, Zebra CS4070, Inateck, Eyoyo, Honeywell):
  1. Pair scanner via iOS **Settings** -> **Bluetooth** in **HID Keyboard Mode**.
  2. Configure the scanner to send an **Enter / Carriage Return** suffix.
  3. `HardwareBarcodeScannerManager` buffers incoming keystrokes and fires `onBarcodeScanned(barcode:symbology:)` globally with zero lag, even if no text field is focused.

### 2. AVFoundation High-Speed Camera Scanner
- Back camera barcode reader with real-time target viewfinder and hardware torch (flashlight) toggle.
- Decodes:
  - 1D: Code 128, EAN-13, EAN-8, Code 39, Code 93, ITF-14, UPC-E.
  - 2D: Data Matrix, QR Code, PDF-417, Aztec.

### 3. Audio & Haptic Feedback
- Classic POS confirmation beep (`AudioServicesPlaySystemSound(1057)`).
- ERM motor vibration compatible with iPhone 6 / 6 Plus, and Taptic feedback on iPhone 7+.

---

## ☁️ EyeCloud Pro Integration (OpticalPOS)

- **Target URL**: `http://web.opticalpos.com/pos/login/nycct`
- **Default Practice ID**: `nycct`
- **App Transport Security (ATS)**: Configured in `Info.plist` with `NSAllowsArbitraryLoads` and domain exception for `opticalpos.com` so HTTP sessions load cleanly on iOS 12+.
- **Automated Barcode Field Injection**:
  - Whenever a barcode is scanned, `EyeCloudViewController` detects the active input field or search bar in EyeCloud Pro and dispatches `input`, `change`, and `Enter` key events.
  - On-screen toast banner confirms DOM injection.
- **Import to Local Lab Database**:
  - Tap "📥 Import to Lab" to enter or scan an EyeCloud order/tray number and immediately open or prefill the cutting/edging job ticket.

---

## 👓 Optical Lab Features

1. **Optical Lens Inventory**:
   - Sphere, Cylinder, Axis, Add Power, Refractive Index (CR-39, Poly, Trivex, 1.60, 1.67, 1.74), Coatings, Bin Locations.
   - Low stock threshold alerts and one-touch stock adjustments (+1, +5, -1).
2. **Job Work Pipeline**:
   - Trays advance through 7 discrete stages: `NEW_ORDER` $\to$ `STOCK_ALLOCATED` $\to$ `LAYOUT_BLOCKING` $\to$ `CUTTING_EDGING` $\to$ `ASSEMBLY_FITTING` $\to$ `FINAL_QC` $\to$ `COMPLETED`.
   - Scanning a lens blank assigns it to OD or OS and automatically decrements stock from inventory.
3. **ANSI Z80.1 Optical Inspection Checklist**:
   - Power tolerances (±0.13D for sphere and cylinder).
   - Cylinder axis tolerance verification.
   - Optical center & PD alignment check.
   - Cosmetic and bevel fit approval with inspector sign-off.
4. **Clean Production Database**:
   - Clean slate: **zero demo / mock data** pre-seeded into the SQLite database.

---

## 🚀 Building & Installing onto iPhone 6 (iOS 12.5.8)

### Option 1: Xcode (Mac)
1. Open `OpticalLabIOS.xcodeproj` in Xcode 10.2 or newer.
2. Connect your iPhone 6 via Lightning cable.
3. Select your device in the destination list and choose **Signing & Capabilities** to select your Apple Developer Team (free Apple ID or paid developer account).
4. Press **Cmd + R** to build and install.

### Option 2: Sideloadly / AltStore (Windows / Mac)
1. In Xcode, select **Product** -> **Archive** -> **Distribute App** -> **Development / Ad Hoc** to export `OpticalLab.ipa`.
2. Open **Sideloadly** or **AltStore** on Windows.
3. Drag `OpticalLab.ipa` into Sideloadly, connect your iPhone 6, and click **Start**.
4. On your iPhone 6, go to **Settings** -> **General** -> **Device Management** -> Trust the certificate.
