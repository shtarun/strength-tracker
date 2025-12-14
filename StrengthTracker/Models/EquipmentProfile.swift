import Foundation
import SwiftData

@Model
final class EquipmentProfile {
    var id: UUID
    var location: Location
    var hasAdjustableDumbbells: Bool
    var hasBarbell: Bool
    var hasRack: Bool
    var hasCables: Bool
    var hasPullUpBar: Bool
    var hasBands: Bool
    var hasBench: Bool
    var hasMachines: Bool
    var hasMicroplates: Bool
    var availablePlatesData: Data? // Stored as JSON
    var dumbbellIncrementsData: Data? // Stored as JSON

    @Relationship(inverse: \UserProfile.equipmentProfile) var userProfile: UserProfile?

    init(
        id: UUID = UUID(),
        location: Location = .gym,
        hasAdjustableDumbbells: Bool = true,
        hasBarbell: Bool = true,
        hasRack: Bool = true,
        hasCables: Bool = true,
        hasPullUpBar: Bool = true,
        hasBands: Bool = false,
        hasBench: Bool = true,
        hasMachines: Bool = true,
        hasMicroplates: Bool = false
    ) {
        self.id = id
        self.location = location
        self.hasAdjustableDumbbells = hasAdjustableDumbbells
        self.hasBarbell = hasBarbell
        self.hasRack = hasRack
        self.hasCables = hasCables
        self.hasPullUpBar = hasPullUpBar
        self.hasBands = hasBands
        self.hasBench = hasBench
        self.hasMachines = hasMachines
        self.hasMicroplates = hasMicroplates
        self.availablePlatesData = try? JSONEncoder().encode(Self.defaultPlates)
        self.dumbbellIncrementsData = try? JSONEncoder().encode(Self.defaultDumbbellIncrements)
    }

    static let defaultPlates: [Double] = [1.25, 2.5, 5, 10, 15, 20, 25]
    static let defaultDumbbellIncrements: [Double] = Array(stride(from: 2.5, through: 50, by: 2.5))

    var availablePlates: [Double] {
        get {
            guard let data = availablePlatesData else { return Self.defaultPlates }
            return (try? JSONDecoder().decode([Double].self, from: data)) ?? Self.defaultPlates
        }
        set {
            availablePlatesData = try? JSONEncoder().encode(newValue)
        }
    }

    var dumbbellIncrements: [Double] {
        get {
            guard let data = dumbbellIncrementsData else { return Self.defaultDumbbellIncrements }
            return (try? JSONDecoder().decode([Double].self, from: data)) ?? Self.defaultDumbbellIncrements
        }
        set {
            dumbbellIncrementsData = try? JSONEncoder().encode(newValue)
        }
    }

    var availableEquipment: Set<Equipment> {
        var equipment: Set<Equipment> = [.bodyweight]

        if hasBarbell { equipment.insert(.barbell) }
        if hasAdjustableDumbbells { equipment.insert(.dumbbell) }
        if hasCables { equipment.insert(.cable) }
        if hasMachines { equipment.insert(.machine) }
        if hasPullUpBar { equipment.insert(.pullUpBar) }
        if hasBands { equipment.insert(.bands) }
        if hasRack { equipment.insert(.rack) }
        if hasBench { equipment.insert(.bench) }

        return equipment
    }

    func canPerform(exercise: Exercise) -> Bool {
        let required = Set(exercise.equipmentRequired)
        return required.isSubset(of: availableEquipment)
    }

    static func gymPreset() -> EquipmentProfile {
        EquipmentProfile(
            location: .gym,
            hasAdjustableDumbbells: true,
            hasBarbell: true,
            hasRack: true,
            hasCables: true,
            hasPullUpBar: true,
            hasBands: false,
            hasBench: true,
            hasMachines: true,
            hasMicroplates: false
        )
    }

    static func homePreset() -> EquipmentProfile {
        EquipmentProfile(
            location: .home,
            hasAdjustableDumbbells: true,
            hasBarbell: false,
            hasRack: false,
            hasCables: false,
            hasPullUpBar: true,
            hasBands: true,
            hasBench: true,
            hasMachines: false,
            hasMicroplates: false
        )
    }
}
