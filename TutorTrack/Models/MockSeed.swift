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
                notes: "Scaling TikTok Shop in the US, targeting $50K daily GMV; currently bottlenecked on creative output and CBO bid cadence."
            ),
            Student(
                name: "Mark",
                courseType: .english,
                totalLessons: 24,
                parentContact: "Telegram: @mark_rig · mark@local-ai.dev",
                notes: "Building a dual-4090 workstation for local 70B Q4 inference; weighing vLLM vs SGLang, focused on PagedAttention tuning."
            ),
            Student(
                name: "Siyuan",
                courseType: .coding,
                totalLessons: 20,
                parentContact: "X / GitHub: @siyuan-builds",
                notes: "Wants to agent-ify the entire dev workflow; comfortable with hooks, new to subagent orchestration, wants to ship custom MCP tools."
            ),
            Student(
                name: "Chen",
                courseType: .math,
                totalLessons: 16,
                parentContact: "WeChat: chenchen-growth · Xiaohongshu: Chen's SaaS Notes",
                notes: "DTC brand growth op, targeting 10K paid SaaS users; LP -> Signup conversion at 8%, wants to push past 15%."
            ),
            Student(
                name: "Grey",
                courseType: .art,
                totalLessons: 12,
                parentContact: "X: @grey_swiftui · Xiaohongshu: Grey on iOS",
                notes: "7 years of iOS experience, ramping up on iOS 26 (Liquid Glass / Foundation Models); shipping an indie app."
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
                    return parts.joined(separator: ", ")
                case .absent:
                    return ["Last-minute project conflict", "Out sick", "Unexpected client meeting"].randomElement(using: &generator) ?? ""
                case .excused:
                    return ["Requested time off in advance", "Travel / business trip", "Offline event conflict"].randomElement(using: &generator) ?? ""
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
