//
//  AttendanceStatus.swift
//  TutorTrack
//
//  Attendance-status enum (present / absent / excused) with color and
//  SF Symbol mappings; drives the three-color heatmap and the check-in chip.
//

import SwiftUI

enum AttendanceStatus: String, Codable, CaseIterable {
    case present  // Present
    case absent   // Absent
    case excused  // Excused

    var displayName: String {
        switch self {
        case .present: "出勤"
        case .absent:  "缺勤"
        case .excused: "请假"
        }
    }

    /// Heatmap / chip color
    var color: Color {
        switch self {
        case .present: .green
        case .absent:  .red
        case .excused: .gray
        }
    }

    var iconName: String {
        switch self {
        case .present: "checkmark.circle.fill"
        case .absent:  "xmark.circle.fill"
        case .excused: "questionmark.circle.fill"
        }
    }
}
