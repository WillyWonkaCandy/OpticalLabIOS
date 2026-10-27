import Foundation
import UIKit

public enum JobStage: String, CaseIterable {
    case newOrder = "NEW_ORDER"
    case stockAllocated = "STOCK_ALLOCATED"
    case layoutBlocking = "LAYOUT_BLOCKING"
    case cuttingEdging = "CUTTING_EDGING"
    case assemblyFitting = "ASSEMBLY_FITTING"
    case finalQc = "FINAL_QC"
    case completed = "COMPLETED"
    
    public var displayName: String {
        switch self {
        case .newOrder: return "New Order"
        case .stockAllocated: return "Stock Allocated"
        case .layoutBlocking: return "Layout & Blocking"
        case .cuttingEdging: return "Cutting & Edging"
        case .assemblyFitting: return "Assembly & Fit"
        case .finalQc: return "Final QC Inspection"
        case .completed: return "Completed & Ready"
        }
    }
    
    public var stageColor: UIColor {
        switch self {
        case .newOrder: return UIColor(red: 100/255.0, green: 116/255.0, blue: 139/255.0, alpha: 1.0)
        case .stockAllocated: return UIColor(red: 2/255.0, green: 132/255.0, blue: 199/255.0, alpha: 1.0)
        case .layoutBlocking: return UIColor(red: 217/255.0, green: 119/255.0, blue: 6/255.0, alpha: 1.0)
        case .cuttingEdging: return UIColor(red: 234/255.0, green: 88/255.0, blue: 12/255.0, alpha: 1.0)
        case .assemblyFitting: return UIColor(red: 124/255.0, green: 58/255.0, blue: 237/255.0, alpha: 1.0)
        case .finalQc: return UIColor(red: 13/255.0, green: 148/255.0, blue: 136/255.0, alpha: 1.0)
        case .completed: return UIColor(red: 22/255.0, green: 163/255.0, blue: 74/255.0, alpha: 1.0)
        }
    }
    
    public func next() -> JobStage {
        switch self {
        case .newOrder: return .stockAllocated
        case .stockAllocated: return .layoutBlocking
        case .layoutBlocking: return .cuttingEdging
        case .cuttingEdging: return .assemblyFitting
        case .assemblyFitting: return .finalQc
        case .finalQc: return .completed
        case .completed: return .completed
        }
    }
}
