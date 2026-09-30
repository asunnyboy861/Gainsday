import SwiftData
import Foundation
import UIKit

@Model
final class Exercise {
    @Attribute(.unique) var id: String
    var name: String
    var equipment: String
    var level: String
    var mechanic: String
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var instructions: [String]
    var isCustom: Bool

    init(id: String, name: String, equipment: String = "", level: String = "",
         mechanic: String = "", primaryMuscles: [String] = [], secondaryMuscles: [String] = [],
         instructions: [String] = [], isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.equipment = equipment
        self.level = level
        self.mechanic = mechanic
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.instructions = instructions
        self.isCustom = isCustom
    }

    var isLowerBody: Bool {
        let lower = ["glutes", "hamstrings", "quads", "calves", "adductors", "abductors"]
        return !Set(primaryMuscles).isDisjoint(with: lower)
    }
}

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var name: String
    var notes: String
    var deletedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \SetEntry.session)
    var entries: [SetEntry] = []

    init(id: UUID = UUID(), date: Date = .now, name: String = "Workout") {
        self.id = id
        self.date = date
        self.name = name
        self.notes = ""
        self.deletedAt = nil
    }

    var totalVolume: Double { entries.reduce(0) { $0 + $1.weight * Double($1.reps) } }
}

@Model
final class SetEntry {
    @Attribute(.unique) var id: UUID
    var weight: Double
    var reps: Int
    var rpe: Double
    var createdAt: Date
    var editedAt: Date
    var deviceID: String
    var exercise: Exercise?
    var session: WorkoutSession?

    init(weight: Double, reps: Int, exercise: Exercise?, session: WorkoutSession?, rpe: Double = 0) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.createdAt = .now
        self.editedAt = .now
        self.deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        self.exercise = exercise
        self.session = session
    }
}

@Model
final class ProgressPhoto {
    @Attribute(.unique) var id: UUID
    var date: Date
    var photoData: Data
    var pose: String
    var bodyWeight: Double

    init(date: Date, photoData: Data, pose: String, bodyWeight: Double = 0) {
        self.id = UUID()
        self.date = date
        self.photoData = photoData
        self.pose = pose
        self.bodyWeight = bodyWeight
    }
}

@Model
final class Plan {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \PlanDay.plan)
    var days: [PlanDay] = []

    init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

@Model
final class PlanDay {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    var exerciseNames: [String]
    var plan: Plan?

    init(name: String, sortOrder: Int = 0, exerciseNames: [String] = []) {
        self.id = UUID()
        self.name = name
        self.sortOrder = sortOrder
        self.exerciseNames = exerciseNames
    }
}
