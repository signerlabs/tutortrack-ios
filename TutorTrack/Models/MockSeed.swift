//
//  MockSeed.swift
//  TutorTrack
//
//  首启 seed：5 个 mock 学员，每课程类型一名，每人带过去 2 周的随机出勤记录 + 评语。
//  让录屏时随便点哪个学员都有数据可演示 AI 周报。
//

import Foundation
import SwiftData

@MainActor
enum MockSeed {

    /// 主入口：检测空库则灌入种子数据
    static func seedIfNeeded(in context: ModelContext) {
        do {
            let count = try context.fetchCount(FetchDescriptor<Student>())
            guard count == 0 else { return }

            let students = makeMockStudents()
            for s in students {
                context.insert(s)
            }

            // 为每位学员注入过去 14 天出勤
            for s in students {
                let records = makeMockAttendances(for: s)
                for r in records {
                    r.student = s
                    context.insert(r)
                }
                // 已上完课时 = 出勤次数
                s.attendedLessons = records.filter { $0.status == .present }.count
            }

            try context.save()
        } catch {
            print("[MockSeed] 种子数据写入失败：\(error)")
        }
    }

    // MARK: - 学员模板

    /// 5 个学员，每课程类型一名，姓名 + 总课时 + 已上 + 联系方式 + 备注全部预置
    private static func makeMockStudents() -> [Student] {
        [
            Student(
                name: "小明",
                courseType: .piano,
                totalLessons: 30,
                parentContact: "138****8801（妈妈）",
                notes: "喜欢古典曲目，对节奏更敏感；爸妈希望明年参加业余 5 级考试。"
            ),
            Student(
                name: "小红",
                courseType: .english,
                totalLessons: 24,
                parentContact: "139****2103（妈妈）",
                notes: "口语很自信，时态偶尔混乱；家长重点关注书面写作训练。"
            ),
            Student(
                name: "小李",
                courseType: .coding,
                totalLessons: 20,
                parentContact: "135****6677（爸爸）",
                notes: "对 Scratch 很感兴趣，准备过渡到 Python；逻辑思维不错，调试耐心待提升。"
            ),
            Student(
                name: "小张",
                courseType: .math,
                totalLessons: 16,
                parentContact: "137****9012（妈妈）",
                notes: "运算扎实但应用题理解偏慢；家长希望主攻应用题与几何证明。"
            ),
            Student(
                name: "小王",
                courseType: .art,
                totalLessons: 12,
                parentContact: "186****3456（爸爸）",
                notes: "想象力出色，构图大胆；偶尔细节刻画不足。家长希望保持兴趣为主。"
            )
        ]
    }

    // MARK: - 出勤记录（过去 14 天）

    /// 为单个学员生成过去 14 天的随机出勤记录。
    /// - 出勤率约 70%，缺勤 / 请假各占少量
    /// - 上课日有 70% 概率会留评语（≤ 50 字），评语随机抽课程模板词典
    /// - deterministic：用学员 name 的 hash 做种子，保证同一学员每次启动看到一致历史
    private static func makeMockAttendances(for student: Student) -> [AttendanceRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // deterministic seed：拿学员 name 做哈希
        var generator = SeededGenerator(seed: UInt64(abs(student.name.hashValue)))

        let course = student.courseType
        var records: [AttendanceRecord] = []

        // 训练机构通常每周 2-3 次课，这里取偶数天上课的方案
        for offset in 0..<14 {
            // 每隔一天上一次课（offset 偶数）
            guard offset % 2 == 0 else { continue }
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            // 70% 出勤 / 20% 缺勤 / 10% 请假
            let roll = Int.random(in: 0..<100, using: &generator)
            let status: AttendanceStatus
            if roll < 70 {
                status = .present
            } else if roll < 90 {
                status = .absent
            } else {
                status = .excused
            }

            // 70% 概率留评语；出勤优先留正面 + 改进点，缺勤 / 请假留事由
            let noteText: String = {
                guard Int.random(in: 0..<100, using: &generator) < 70 else { return "" }
                switch status {
                case .present:
                    let practice = course.practiceKeywords.randomElement(using: &generator) ?? ""
                    let pos = course.evaluationKeywords.positive.randomElement(using: &generator) ?? ""
                    let imp = course.evaluationKeywords.improvement.randomElement(using: &generator) ?? ""
                    // 三选二拼接（让录屏不重复）
                    let parts = [practice, pos, imp]
                        .filter { !$0.isEmpty }
                        .shuffled(using: &generator)
                        .prefix(2)
                    return parts.joined(separator: "，")
                case .absent:
                    return ["家中临时有事", "身体不适", "学校加课冲突"].randomElement(using: &generator) ?? ""
                case .excused:
                    return ["家长提前请假", "节假日出行", "学校文艺活动"].randomElement(using: &generator) ?? ""
                }
            }()

            records.append(AttendanceRecord(
                date: date,
                status: status,
                noteText: noteText
            ))
        }

        return records
    }
}

// MARK: - Deterministic RNG（线性同余）

/// 简单的 deterministic 随机数发生器。Swift 标准库 `SystemRandomNumberGenerator` 不保证可重复，
/// 我们要 mock 数据每次启动一致，所以自己实现一个。
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func next() -> UInt64 {
        // 线性同余：xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
