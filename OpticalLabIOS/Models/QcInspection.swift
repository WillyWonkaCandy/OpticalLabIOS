import Foundation

public struct QcInspection {
    public var id: Int64
    public var jobId: Int64
    public var trayNumber: String
    public var inspectorName: String
    public var inspectionDate: Date
    public var odSphOk: Bool
    public var odCylOk: Bool
    public var odAxisOk: Bool
    public var osSphOk: Bool
    public var osCylOk: Bool
    public var osAxisOk: Bool
    public var pdAligned: Bool
    public var cosmeticPassed: Bool
    public var bevelFitPassed: Bool
    public var passed: Bool
    public var notes: String
    
    public init(id: Int64 = 0,
                jobId: Int64,
                trayNumber: String,
                inspectorName: String = "",
                inspectionDate: Date = Date(),
                odSphOk: Bool = false,
                odCylOk: Bool = false,
                odAxisOk: Bool = false,
                osSphOk: Bool = false,
                osCylOk: Bool = false,
                osAxisOk: Bool = false,
                pdAligned: Bool = false,
                cosmeticPassed: Bool = false,
                bevelFitPassed: Bool = false,
                passed: Bool = false,
                notes: String = "") {
        self.id = id
        self.jobId = jobId
        self.trayNumber = trayNumber
        self.inspectorName = inspectorName
        self.inspectionDate = inspectionDate
        self.odSphOk = odSphOk
        self.odCylOk = odCylOk
        self.odAxisOk = odAxisOk
        self.osSphOk = osSphOk
        self.osCylOk = osCylOk
        self.osAxisOk = osAxisOk
        self.pdAligned = pdAligned
        self.cosmeticPassed = cosmeticPassed
        self.bevelFitPassed = bevelFitPassed
        self.passed = passed
        self.notes = notes
    }
}
