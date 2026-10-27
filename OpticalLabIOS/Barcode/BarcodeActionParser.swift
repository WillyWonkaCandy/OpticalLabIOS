import Foundation

public struct BarcodeActionParser {
    
    public enum ActionType {
        case jobTray
        case commandNextStage
        case commandQcPass
        case commandQcFail
        case commandStockIn
        case commandStockOut
        case unknown
    }
    
    public struct ParseResult {
        public let type: ActionType
        public let payload: String
        
        public init(type: ActionType, payload: String) {
            self.type = type
            self.payload = payload
        }
    }
    
    public static func parse(_ raw: String) -> ParseResult {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.uppercased()
        
        if upper.hasPrefix("TRAY-") || upper.hasPrefix("TRAY:") {
            let payload = trimmed.replacingOccurrences(of: "TRAY:", with: "", options: .caseInsensitive)
            return ParseResult(type: .jobTray, payload: payload)
        }
        
        if upper == "ACTION:NEXT_STAGE" || upper == "NEXT_STAGE" {
            return ParseResult(type: .commandNextStage, payload: trimmed)
        }
        if upper == "ACTION:QC_PASS" || upper == "QC_PASS" {
            return ParseResult(type: .commandQcPass, payload: trimmed)
        }
        if upper == "ACTION:QC_FAIL" || upper == "QC_FAIL" {
            return ParseResult(type: .commandQcFail, payload: trimmed)
        }
        if upper == "ACTION:STOCK_IN" || upper == "STOCK_IN" {
            return ParseResult(type: .commandStockIn, payload: trimmed)
        }
        if upper == "ACTION:STOCK_OUT" || upper == "STOCK_OUT" {
            return ParseResult(type: .commandStockOut, payload: trimmed)
        }
        
        return ParseResult(type: .unknown, payload: trimmed)
    }
}
