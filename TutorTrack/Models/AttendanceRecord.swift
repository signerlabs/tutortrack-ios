//
//  AttendanceRecord.swift
//  TutorTrack
//
//  SwiftData @Model：单次出勤记录。一名学员 → 多条记录。
//

import Foundation
import SwiftData

@Model
final class AttendanceRecord {
    var id: UUID
    /// 上课/标记的日期（截到日粒度，热力图按日聚合）
    var date: Date
    /// 出勤状态 rawValue
    var statusRaw: String
    /// 本节课评语（≤ 50 字，AI 周报的核心数据源）
    var noteText: String
    /// 反向关系（Student.attendances 的 inverse）
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
