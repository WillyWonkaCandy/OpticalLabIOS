import UIKit

/// High-contrast theme and design tokens optimized for iPhone 6 and newer running iOS 12.0+.
/// Avoids iOS 13+ only symbols (SF Symbols) and semantic colors, guaranteeing native rendering on iOS 12.5.8.
public enum OpticalLabTheme {
    
    // MARK: - Color Palette
    public static let primary = UIColor(red: 30/255.0, green: 58/255.0, blue: 138/255.0, alpha: 1.0)       // #1E3A8A
    public static let primaryDark = UIColor(red: 15/255.0, green: 23/255.0, blue: 42/255.0, alpha: 1.0)     // #0F172A
    public static let primaryLight = UIColor(red: 59/255.0, green: 130/255.0, blue: 246/255.0, alpha: 1.0)  // #3B82F6
    public static let accent = UIColor(red: 2/255.0, green: 132/255.0, blue: 199/255.0, alpha: 1.0)        // #0284C7
    
    public static let success = UIColor(red: 22/255.0, green: 163/255.0, blue: 74/255.0, alpha: 1.0)       // #16A34A
    public static let warning = UIColor(red: 217/255.0, green: 119/255.0, blue: 6/255.0, alpha: 1.0)       // #D97706
    public static let danger = UIColor(red: 220/255.0, green: 38/255.0, blue: 38/255.0, alpha: 1.0)        // #DC2626
    
    public static let background = UIColor(red: 248/255.0, green: 250/255.0, blue: 252/255.0, alpha: 1.0)  // #F8FAFC
    public static let cardBackground = UIColor.white
    public static let cardBorder = UIColor(red: 226/255.0, green: 232/255.0, blue: 240/255.0, alpha: 1.0) // #E2E8F0
    
    public static let textPrimary = UIColor(red: 15/255.0, green: 23/255.0, blue: 42/255.0, alpha: 1.0)
    public static let textSecondary = UIColor(red: 100/255.0, green: 116/255.0, blue: 139/255.0, alpha: 1.0)
    public static let textMuted = UIColor(red: 148/255.0, green: 163/255.0, blue: 184/255.0, alpha: 1.0)
    
    // MARK: - Rugged Button Styling
    public static func styleRuggedButton(_ button: UIButton, backgroundColor: UIColor = accent, titleColor: UIColor = .white, cornerRadius: CGFloat = 8.0) {
        button.backgroundColor = backgroundColor
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        button.layer.cornerRadius = cornerRadius
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        
        // Ensure touch target is at least 48pt for glove accessibility on iPhone 6
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
    }
    
    public static func styleOutlinedButton(_ button: UIButton, borderColor: UIColor = accent, titleColor: UIColor = accent, cornerRadius: CGFloat = 8.0) {
        button.backgroundColor = .clear
        button.setTitleColor(titleColor, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = cornerRadius
        button.layer.borderWidth = 1.5
        button.layer.borderColor = borderColor.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }
    
    public static func styleCardView(_ view: UIView) {
        view.backgroundColor = cardBackground
        view.layer.cornerRadius = 10.0
        view.layer.borderWidth = 1.0
        view.layer.borderColor = cardBorder.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.06
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4.0
    }
    
    // MARK: - Native Vector Icon Generation (iOS 12 Compatible without SF Symbols)
    public static func createIcon(named: String, size: CGSize = CGSize(width: 25, height: 25), color: UIColor = primary) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return UIImage()
        }
        
        ctx.setFillColor(color.cgColor)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(1.8)
        
        let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
        
        switch named {
        case "jobs":
            // Clipboard / Job tray icon
            let body = CGRect(x: rect.minX + 2, y: rect.minY + 4, width: rect.width - 4, height: rect.height - 4)
            let clip = CGRect(x: rect.midX - 4, y: rect.minY + 1, width: 8, height: 5)
            ctx.stroke(body)
            ctx.fill(clip)
            // Lines
            ctx.strokeLineSegments(between: [
                CGPoint(x: body.minX + 4, y: body.minY + 6), CGPoint(x: body.maxX - 4, y: body.minY + 6),
                CGPoint(x: body.minX + 4, y: body.minY + 10), CGPoint(x: body.maxX - 4, y: body.minY + 10),
                CGPoint(x: body.minX + 4, y: body.minY + 14), CGPoint(x: body.maxX - 6, y: body.minY + 14)
            ])
            
        case "inventory", "lens":
            // Eyeglass lenses / double circle icon
            let r: CGFloat = (rect.width - 6) / 2
            let leftLens = CGRect(x: rect.minX + 1, y: rect.midY - r/2, width: r, height: r)
            let rightLens = CGRect(x: rect.maxX - r - 1, y: rect.midY - r/2, width: r, height: r)
            ctx.strokeEllipse(in: leftLens)
            ctx.strokeEllipse(in: rightLens)
            // Bridge
            ctx.strokeLineSegments(between: [
                CGPoint(x: leftLens.maxX, y: leftLens.midY),
                CGPoint(x: rightLens.minX, y: rightLens.midY)
            ])
            
        case "scanner":
            // Barcode vertical stripes
            let w = rect.width
            let h = rect.height
            let x0 = rect.minX
            let y0 = rect.minY
            let bars: [(CGFloat, CGFloat)] = [(0.1, 0.08), (0.24, 0.05), (0.35, 0.12), (0.52, 0.06), (0.65, 0.14), (0.85, 0.07)]
            for (offset, bw) in bars {
                ctx.fill(CGRect(x: x0 + w * offset, y: y0 + 2, width: max(1.5, w * bw), height: h - 4))
            }
            
        case "qc":
            // Checkmark in badge / seal
            let circleRect = rect.insetBy(dx: 1, dy: 1)
            ctx.strokeEllipse(in: circleRect)
            ctx.move(to: CGPoint(x: circleRect.minX + circleRect.width * 0.28, y: circleRect.midY))
            ctx.addLine(to: CGPoint(x: circleRect.minX + circleRect.width * 0.45, y: circleRect.midY + circleRect.height * 0.22))
            ctx.addLine(to: CGPoint(x: circleRect.minX + circleRect.width * 0.72, y: circleRect.midY - circleRect.height * 0.22))
            ctx.strokePath()
            
        case "cloud":
            // Cloud icon for EyeCloud Pro
            let w = rect.width
            let h = rect.height
            let x = rect.minX
            let y = rect.minY
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x + w * 0.25, y: y + h * 0.75))
            path.addLine(to: CGPoint(x: x + w * 0.85, y: y + h * 0.75))
            path.addArc(withCenter: CGPoint(x: x + w * 0.75, y: y + h * 0.55), radius: w * 0.2, startAngle: 0, endAngle: .pi * 1.5, clockwise: false)
            path.addArc(withCenter: CGPoint(x: x + w * 0.45, y: y + h * 0.45), radius: w * 0.25, startAngle: .pi * 1.8, endAngle: .pi * 1.1, clockwise: false)
            path.addArc(withCenter: CGPoint(x: x + w * 0.25, y: y + h * 0.6), radius: w * 0.16, startAngle: .pi * 1.3, endAngle: .pi * 0.5, clockwise: false)
            path.close()
            ctx.addPath(path.cgPath)
            ctx.strokePath()
            
        case "settings":
            // Gear icon
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius: CGFloat = rect.width * 0.25
            ctx.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            for i in 0..<8 {
                let angle = CGFloat(i) * (.pi / 4.0)
                let p1 = CGPoint(x: center.x + (radius + 2) * cos(angle), y: center.y + (radius + 2) * sin(angle))
                let p2 = CGPoint(x: center.x + (radius + 6) * cos(angle), y: center.y + (radius + 6) * sin(angle))
                ctx.strokeLineSegments(between: [p1, p2])
            }
            
        default:
            ctx.stroke(rect)
        }
        
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return img.withRenderingMode(.alwaysTemplate)
    }
}
