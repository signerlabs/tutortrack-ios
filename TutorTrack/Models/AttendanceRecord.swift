//
//  AttendanceRecord.swift
//  TutorTrack
//
//  SwiftData @Model: a single attendance record. One student -> many records.
//

import Foundation
import SwiftData

@Model
final class AttendanceRecord {
    var id: UUID
    /// Class / check-in date (truncated to day granularity; heatmap aggregates by day)
    var date: Date
    /// Attendance status rawValue
    var statusRaw: String
    /// Note for this session (<= 50 chars, primary data source for the AI weekly report)
    var noteText: String
    /// Reverse relationship (inverse of Student.attendances)
    var student: Student?

    init(
        id: UUID = UUID(),
        date: Date,
        status: AttendanceStatus,
        noteText: String = "",
        student: Student? = nil
    ) {
        self.id = id
        self.date = date
        self.statusRaw = status.rawValue
        self.noteText = noteText
        self.student = student
    }

    var status: AttendanceStatus {
        AttendanceStatus(rawValue: statusRaw) ?? .present
    }
}
