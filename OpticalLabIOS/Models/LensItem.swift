import Foundation

public struct LensItem {
    public var id: Int64
    public var barcode: String
    public var sku: String
    public var brand: String
    public var lensType: LensType
    public var material: LensMaterial
    public var coating: String
    public var sphere: Double
    public var cylinder: Double
    public var addPower: Double
    public var diameter: Int
    public var quantityOnHand: Int
    public var minThreshold: Int
    public var binLocation: String
    public var unitCost: Double
    public var updatedAt: Date
    
    public init(id: Int64 = 0,
                barcode: String,
                sku: String,
                brand: String,
                lensType: LensType,
                material: LensMaterial,
                coating: String,
                sphere: Double,
                cylinder: Double,
                addPower: Double = 0.0,
                diameter: Int = 70,
                quantityOnHand: Int = 0,
                minThreshold: Int = 2,
                binLocation: String = "",
                unitCost: Double = 0.0,
                updatedAt: Date = Date()) {
        self.id = id
        self.barcode = barcode
        self.sku = sku
        self.brand = brand
        self.lensType = lensType
        self.material = material
        self.coating = coating
        self.sphere = sphere
        self.cylinder = cylinder
        self.addPower = addPower
        self.diameter = diameter
        self.quantityOnHand = quantityOnHand
        self.minThreshold = minThreshold
        self.binLocation = binLocation
        self.unitCost = unitCost
        self.updatedAt = updatedAt
    }
    
    public var isLowStock: Bool {
        return quantityOnHand <= minThreshold
    }
    
    public var powerString: String {
        let sphStr = String(format: "%+.2f", sphere)
        let cylStr = String(format: "%+.2f", cylinder)
        var text = "SPH: \(sphStr) / CYL: \(cylStr)"
        if addPower > 0.01 {
            text += String(format: " / ADD: +%.2f", addPower)
        }
        return text
    }
    
    public var summaryString: String {
        return "\(brand) \(lensType.label) - \(material.label) - \(coating)"
    }
}
