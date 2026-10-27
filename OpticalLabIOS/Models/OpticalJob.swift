import Foundation

public struct OpticalJob {
    public var id: Int64
    public var trayNumber: String
    public var orderNumber: String
    public var patientName: String
    public var customerName: String
    public var doctorName: String
    public var stage: JobStage
    public var priority: String
    public var frameModel: String
    public var frameType: FrameType
    public var edgerMachine: String
    
    // Prescription Right Eye (OD)
    public var odSphere: Double
    public var odCylinder: Double
    public var odAxis: Int
    public var odAdd: Double
    public var odPd: Double
    public var odSegHeight: Double
    public var odLensBarcode: String
    
    // Prescription Left Eye (OS)
    public var osSphere: Double
    public var osCylinder: Double
    public var osAxis: Int
    public var osAdd: Double
    public var osPd: Double
    public var osSegHeight: Double
    public var osLensBarcode: String
    
    public var notes: String
    public var isArchived: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var completedAt: Date?
    
    public init(id: Int64 = 0,
                trayNumber: String,
                orderNumber: String = "",
                patientName: String = "",
                customerName: String = "",
                doctorName: String = "",
                stage: JobStage = .newOrder,
                priority: String = "Normal",
                frameModel: String = "",
                frameType: FrameType = .fullRimPlastic,
                edgerMachine: String = "Nidek ME-1200",
                odSphere: Double = 0.0,
                odCylinder: Double = 0.0,
                odAxis: Int = 0,
                odAdd: Double = 0.0,
                odPd: Double = 31.0,
                odSegHeight: Double = 0.0,
                odLensBarcode: String = "",
                osSphere: Double = 0.0,
                osCylinder: Double = 0.0,
                osAxis: Int = 0,
                osAdd: Double = 0.0,
                osPd: Double = 31.0,
                osSegHeight: Double = 0.0,
                osLensBarcode: String = "",
                notes: String = "",
                isArchived: Bool = false,
                createdAt: Date = Date(),
                updatedAt: Date = Date(),
                completedAt: Date? = nil) {
        self.id = id
        self.trayNumber = trayNumber
        self.orderNumber = orderNumber
        self.patientName = patientName
        self.customerName = customerName
        self.doctorName = doctorName
        self.stage = stage
        self.priority = priority
        self.frameModel = frameModel
        self.frameType = frameType
        self.edgerMachine = edgerMachine
        self.odSphere = odSphere
        self.odCylinder = odCylinder
        self.odAxis = odAxis
        self.odAdd = odAdd
        self.odPd = odPd
        self.odSegHeight = odSegHeight
        self.odLensBarcode = odLensBarcode
        self.osSphere = osSphere
        self.osCylinder = osCylinder
        self.osAxis = osAxis
        self.osAdd = osAdd
        self.osPd = osPd
        self.osSegHeight = osSegHeight
        self.osLensBarcode = osLensBarcode
        self.notes = notes
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
    }
    
    public var odRxString: String {
        return String(format: "%+.2f  %+.2f x %03d", odSphere, odCylinder, odAxis)
    }
    
    public var osRxString: String {
        return String(format: "%+.2f  %+.2f x %03d", osSphere, osCylinder, osAxis)
    }
}
