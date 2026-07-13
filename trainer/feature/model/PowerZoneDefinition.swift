import SwiftUI
import libfitness

public struct PowerZoneDefinition: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let range: ClosedRange<Int>
    public let hexColor: UInt64
    
    public init(id: String, name: String, range: ClosedRange<Int>, hexColor: UInt64) {
        self.id = id
        self.name = name
        self.range = range
        self.hexColor = hexColor
    }
    
    public var swiftColor: Color {
        // hexColor is AARRGGBB as a UInt64
        let alpha = Double((hexColor >> 24) & 0xFF) / 255.0
        let red = Double((hexColor >> 16) & 0xFF) / 255.0
        let green = Double((hexColor >> 8) & 0xFF) / 255.0
        let blue = Double(hexColor & 0xFF) / 255.0

        return Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    public static let allZones: [PowerZoneDefinition] = [
        PowerZoneDefinition(id: "zone1", name: "Recovery", range: 0...50, hexColor: PowerZoneColorCompanion.shared.ZONE1),
        PowerZoneDefinition(id: "zone2", name: "Endurance", range: 51...75, hexColor: PowerZoneColorCompanion.shared.ZONE2),
        PowerZoneDefinition(id: "zone3", name: "Tempo", range: 76...87, hexColor: PowerZoneColorCompanion.shared.ZONE3),
        PowerZoneDefinition(id: "zone4", name: "Sweet Spot", range: 88...94, hexColor: PowerZoneColorCompanion.shared.ZONE4),
        PowerZoneDefinition(id: "zone5", name: "Threshold", range: 95...105, hexColor: PowerZoneColorCompanion.shared.ZONE5),
        PowerZoneDefinition(id: "zone6", name: "VO2 Max", range: 106...120, hexColor: PowerZoneColorCompanion.shared.ZONE6),
        PowerZoneDefinition(id: "zone7", name: "Anaerobic", range: 121...Int.max, hexColor: PowerZoneColorCompanion.shared.ZONE7)
    ]
    
    public static func zone(forPowerPercentage percentage: Int) -> PowerZoneDefinition {
        return allZones.first { $0.range.contains(percentage) } ?? allZones[0]
    }
}

extension PowerZoneDefinition {
    public static func color(forPowerPercentage percentage: Double) -> Color {
        let p = Int(percentage.rounded())
        return zone(forPowerPercentage: p).swiftColor
    }
}
