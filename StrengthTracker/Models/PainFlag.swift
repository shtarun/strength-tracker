import Foundation
import SwiftData

@Model
final class PainFlag {
    var id: UUID
    var bodyPart: BodyPart
    var severity: PainSeverity
    var notes: String?
    var timestamp: Date
    var isResolved: Bool
    var resolvedAt: Date?

    @Relationship var exercise: Exercise?

    init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        bodyPart: BodyPart,
        severity: PainSeverity,
        notes: String? = nil,
        timestamp: Date = Date(),
        isResolved: Bool = false,
        resolvedAt: Date? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.bodyPart = bodyPart
        self.severity = severity
        self.notes = notes
        self.timestamp = timestamp
        self.isResolved = isResolved
        self.resolvedAt = resolvedAt
    }

    func resolve() {
        isResolved = true
        resolvedAt = Date()
    }

    var isRecent: Bool {
        guard !isResolved else { return false }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return timestamp > weekAgo
    }
}
