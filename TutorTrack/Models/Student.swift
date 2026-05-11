//
//  Student.swift
//  TutorTrack
//
//  SwiftData @Model：学员档案。
//

import Foundation
import SwiftData

@Model
final class Student {
    /// 唯一 id（同时作为 AI 周报 deterministic seed）
    var id: UUID
    /// 姓名
    var name: String
    /// 课程类型（rawValue 持久化）
    var courseTypeRaw: String
    /// 已购买总课时
    var totalLessons: Int
    /// 已上完课时
    var attendedLessons: Int
    /// 家长联系方式
    var parentContact: String
    /// 自由备注（家长偏好 / 学习进度等）
    var notes: String
    /// 创建时间
    var createdAt: Date

    /// 一对多：出勤记录（级联删除）
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

    // MARK: - 派生属性

    /// 课程类型（不可持久化，从 raw 解析）
    var courseType: CourseType {
        CourseType(rawValue: courseTypeRaw) ?? .piano
    }

    /// 剩余课时
    var remainingLessons: Int {
        max(0, totalLessons - attendedLessons)
    }

    /// 进度（0...1），用于进度条
    var progress: Double {
        guard totalLessons > 0 else { return 0 }
        return min(1.0, Double(attendedLessons) / Double(totalLessons))
    }

    /// 是否需要提醒续费（剩余 ≤ 3 节）
    var needsRenewal: Bool {
        remainingLessons <= 3
    }
}
