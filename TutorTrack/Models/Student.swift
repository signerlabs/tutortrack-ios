//
//  Student.swift
//  TutorTrack
//
//  SwiftData @Model: student profile.
//

import Foundation
import SwiftData

@Model
final class Student {
    /// Unique id (also used as the deterministic seed for the AI weekly report)
    var id: UUID
    /// Display name
    var name: String
    /// Course type (rawValue is persisted)
    var courseTypeRaw: String
    /// Total purchased lessons
    var totalLessons: Int
    /// Lessons already attended
    var attendedLessons: Int
    /// Parent / guardian contact
    var parentContact: String
    /// Free-form notes (parent preferences, learning progress, etc.)
    var notes: String
    /// Created at
    var createdAt: Date

    /// One-to-many: attendance records (cascade delete)
    @Relationship(deleteRule: .cascade, inverse: \AttendanceRecord.student)
    var attendances: [AttendanceRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        courseType: CourseType,
        totalLessons: Int,
        attendedLessons: Int = 0,
        parentContact: String = "",
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.courseTypeRaw = courseType.rawValue
        self.totalLessons = totalLessons
        self.attendedLessons = attendedLessons
        self.parentContact = parentContact
        self.notes = notes
        self.createdAt = createdAt
    }

    // MARK: - Derived properties

    /// Course type (non-persisted, derived from raw value)
    var courseType: CourseType {
        CourseType(rawValue: courseTypeRaw) ?? .piano
    }

    /// Lessons remaining
    var remainingLessons: Int {
        max(0, totalLessons - attendedLessons)
    }

    /// Progress (0...1), used to drive the progress bar
    var progress: Double {
        guard totalLessons > 0 else { return 0 }
        return min(1.0, Double(attendedLessons) / Double(totalLessons))
    }

    /// Whether to prompt a renewal (remaining <= 3 lessons)
    var needsRenewal: Bool {
        remainingLessons <= 3
    }
}
