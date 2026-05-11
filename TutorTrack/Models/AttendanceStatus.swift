//
//  AttendanceStatus.swift
//  TutorTrack
//
//  出勤状态枚举（出勤 / 缺勤 / 请假），附颜色与 SF Symbol 映射，
//  用于热力图三色显示 + 签到状态 chip。
//

import SwiftUI

enum AttendanceStatus: String, Codable, CaseIterable {
    case present  // 出勤
    case absent   // 缺勤
    case excused  // 请假

    var displayName: String {
        switch self {
        case .present: "出勤"
        case .absent:  "缺勤"
        case .excused: "请假"
        }
    }

    /// 热力图 / chip 颜色
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
