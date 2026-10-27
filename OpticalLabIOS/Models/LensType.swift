import Foundation

public enum LensType: String, CaseIterable {
    case singleVision = "SINGLE_VISION"
    case flatTopBifocal = "BIFOCAL_FT28"
    case progressivePal = "PROGRESSIVE_PAL"
    case occupationalComputer = "OCCUPATIONAL_OFFICE"
    case reading = "READING_SV"
    
    public var label: String {
        switch self {
        case .singleVision: return "Single Vision (SV)"
        case .flatTopBifocal: return "Flat-Top Bifocal (FT-28)"
        case .progressivePal: return "Progressive (PAL)"
        case .occupationalComputer: return "Office / Computer"
        case .reading: return "Reading (SV)"
        }
    }
}

public enum LensMaterial: String, CaseIterable {
    case cr39 = "CR39_150"
    case polycarbonate = "POLY_159"
    case trivex = "TRIVEX_153"
    case highIndex160 = "HIGH_INDEX_160"
    case highIndex167 = "HIGH_INDEX_167"
    case highIndex174 = "HIGH_INDEX_174"
    
    public var label: String {
        switch self {
        case .cr39: return "Standard Plastic (CR-39, 1.50)"
        case .polycarbonate: return "Polycarbonate (1.59 Impact Resistant)"
        case .trivex: return "Trivex (1.53 Ultra-Light/Drill)"
        case .highIndex160: return "High Index (1.60 Thin)"
        case .highIndex167: return "High Index (1.67 Ultra-Thin)"
        case .highIndex174: return "High Index (1.74 Aspheric Razor)"
        }
    }
}

public enum FrameType: String, CaseIterable {
    case plasticZyl = "PLASTIC_ZYL"
    case fullRimMetal = "FULL_RIM_METAL"
    case semiRimlessGrooved = "SEMI_RIMLESS_GROOVED"
    case rimlessDrill = "RIMLESS_DRILL_MOUNT"
    
    public var label: String {
        switch self {
        case .plasticZyl: return "Plastic / Acetate Full Rim"
        case .fullRimMetal: return "Metal Full Rim (Eyewire)"
        case .semiRimlessGrooved: return "Semi-Rimless (Nylon Cord / Grooved)"
        case .rimlessDrill: return "Rimless (3-Piece Drill Mount)"
        }
    }
}
