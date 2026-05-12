//
//  MockSeed.swift
//  TutorTrack
//
//  First-launch seed: 5 mock students, one per course type, each with the past
//  2 weeks of randomized attendance records + notes. This way any student picked
//  in a screen recording already has data to drive the AI weekly report.
//

import Foundation
import SwiftData

@MainActor
enum MockSeed {

    /// Main entry: seed data if the store is empty
    static func seedIfNeeded(in context: ModelContext) {
        do {
            let count = try context.fetchCount(FetchDescriptor<Student>())
            guard count == 0 else { return }

            let students = makeMockStudents()
            for s in students {
                context.insert(s)
            }

            // Inject the past 14 days of attendance for every student
            for s in students {
                let records = makeMockAttendances(for: s)
                for r in records {
                    r.student = s
                    context.insert(r)
                }
                // Lessons attended = number of present records
                s.attendedLessons = records.filter { $0.status == .present }.count
            }

            try context.save()
        } catch {
            print("[MockSeed] Failed to write seed data: \(error)")
        }
    }

    // MARK: - Student templates

    /// 5 students, one per course type. Name + total lessons + attended +
    /// contact + notes are all pre-filled.
    private static func makeMockStudents() -> [Student] {
        [
            Student(
                name: "Alex",
                courseType: .piano,
                totalLessons: 30,
                parentContact: "@alex_tiktok · WeChat: AlexDTC",
                notes: "TikTok Shop 美区跑量阶段，目标单日 GMV 5 万美金；当前卡在素材产能与 CBO 出价节奏。"
            ),
            Student(
                name: "Mark",
                courseType: .english,
                totalLessons: 24,
                parentContact: "Telegram: @mark_rig · mark@local-ai.dev",
                notes: "准备组双 4090 工作站本地跑 70B Q4 量化；纠结 vLLM vs SGLang，关注 PagedAttention 调参。"
            ),
            Student(
                name: "思源",
                courseType: .coding,
                totalLessons: 20,
                parentContact: "X / GitHub: @siyuan-builds",
                notes: "想把日常 dev workflow 全部 agent 化；hooks 已上手，subagent 调度不熟，想自己造 MCP 工具。"
            ),
            Student(
                name: "老陈",
                courseType: .math,
                totalLessons: 16,
                parentContact: "微信：chenchen-growth · 小红书：老陈的 SaaS 笔记",
                notes: "DTC 品牌增长 op，目标做出 1 万付费用户的 SaaS；当前 LP→Signup 转化 8%，想冲到 15%+。"
            ),
            Student(
                name: "灰灰",
                courseType: .art,
                totalLessons: 12,
                parentContact: "X: @grey_swiftui · 小红书：灰灰玩 iOS",
                notes: "iOS 7 年经验，正上手 iOS 26 新特性（Liquid Glass / Foundation Models）；当前在做独立 App。"
            )
        ]
    }

    // MARK: - Attendance records (past 14 days)

    /// Generate randomized attendance records for one student over the past 14 days.
    /// - Roughly 70% present, small share of absent / excused
    /// - On class days there is a 70% chance a note (<= 50 chars) is written,
    ///   drawn from the course template dictionary
    /// - Deterministic: seeded by the student's name hash so the same student
    ///   sees the same history on every launch
    private static func makeMockAttendances(for student: Student) -> [AttendanceRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Deterministic seed: hash of the student name
        var generator = SeededGenerator(seed: UInt64(abs(student.name.hashValue)))

        let course = student.courseType
        var records: [AttendanceRecord] = []

        // Tutoring centers usually run 2-3 classes per week — schedule on even-day offsets
        for offset in 0..<14 {
            // One class every other day (even offset)
            guard offset % 2 == 0 else { continue }
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }

            // 70% present / 20% absent / 10% excused
            let roll = Int.random(in: 0..<100, using: &generator)
            let status: AttendanceStatus
            if roll < 70 {
                status = .present
            } else if roll < 90 {
                status = .absent
            } else {
                status = .excused
            }

            // 70% chance to leave a note; present picks positive + improvement,
            // absent / excused records a reason
            let noteText: String = {
                guard Int.random(in: 0..<100, using: &generator) < 70 else { return "" }
                switch status {
                case .present:
                    let practice = course.practiceKeywords.randomElement(using: &generator) ?? ""
                    let pos = course.evaluationKeywords.positive.randomElement(using: &generator) ?? ""
                    let imp = course.evaluationKeywords.improvement.randomElement(using: &generator) ?? ""
                    // Pick 2 out of 3 to keep screen recordings non-repetitive
                    let parts = [practice, pos, imp]
                        .filter { !$0.isEmpty }
                        .shuffled(using: &generator)
                        .prefix(2)
                    return parts.joined(separator: "，")
                case .absent:
                    return ["临时项目冲突", "身体不适未到", "客户突发会议"].randomElement(using: &generator) ?? ""
                case .excused:
                    return ["提前申请请假", "出差/差旅安排", "线下活动冲突"].randomElement(using: &generator) ?? ""
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

// MARK: - Deterministic RNG (LCG)

/// A simple deterministic random number generator. Swift's standard
/// `SystemRandomNumberGenerator` does not guarantee reproducibility, so we
/// ship a small custom one to keep mock data identical across launches.
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
