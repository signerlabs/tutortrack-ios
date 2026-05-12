//
//  WeeklyReportEngine.swift
//  TutorTrack
//
//  AI weekly report generator (pure local mock, zero network, deterministic).
//
//  Design notes:
//  1. **Deterministic**: the same student + same week always yields the same report.
//     - seed = student.id.hashValue ^ date.weekIndex
//     - Uses a custom LCG-based RandomNumberGenerator to bypass the system RNG,
//       which does not guarantee reproducibility.
//  2. **Data-driven**: ingests the student's AttendanceRecord set for the week
//     and scans noteText for matches against practiceKeywords.
//     - Hits go straight into practicedTopics.
//     - If hits < 3, fall back to picking 2 from practiceKeywords at random.
//  3. **AI paragraph composition**: roughly 80 chars; choose positive vs.
//     improvement templates based on attendance days, then append a parent-facing
//     suggestion.
//  4. **Reads like an LLM**: returned aiParagraph is Markdown-friendly Chinese
//     prose, ready to feed straight into SWMarkdownText.
//

import Foundation
import SwiftData  // The engine only reads @Model instance properties — it does
                  // not call any SwiftData API. We still import it defensively
                  // because the project rule is "any file using a SwiftData
                  // @Model must import SwiftData at the top" (covers future
                  // extensions like caching into ModelContext).

// MARK: - Public data structures

struct WeeklyReport {
    /// Student name
    let studentName: String
    /// Course type
    let courseType: CourseType
    /// Week range display ("5/5 - 5/11")
    let weekRange: String
    /// Attended days (distinct days where status == .present)
    let attendedDays: Int
    /// Absent count
    let absentCount: Int
    /// Excused count
    let excusedCount: Int
    /// Topics hit / selected for the bullet list (3-5 entries)
    let practicedTopics: [String]
    /// AI-style paragraph (~80 chars, Markdown-friendly)
    let aiParagraph: String
    /// Generation timestamp (shown in PDF footer)
    let generatedAt: Date
}

// MARK: - Engine

enum WeeklyReportEngine {

    /// Main entry: generate a report for a student in a given week.
    /// - Parameters:
    ///   - student: the student
    ///   - weekOf: any date inside the target week (internally collapsed to startOfWeek/endOfWeek)
    /// - Returns: WeeklyReport
    static func generate(for student: Student, weekOf date: Date) -> WeeklyReport {
        // 1. Compute the week range
        let weekStart = date.startOfWeek
        let weekEnd = date.endOfWeek
        let weekRange = weekRangeText(start: weekStart, end: weekEnd)

        // 2. Filter the student's attendance to this week
        let weekRecords = student.attendances.filter { r in
            r.date >= weekStart && r.date <= weekEnd
        }

        // 3. Tally the three buckets
        let presentRecords = weekRecords.filter { $0.status == .present }
        let attendedDays = Set(presentRecords.map { Calendar.current.startOfDay(for: $0.date) }).count
        let absentCount = weekRecords.filter { $0.status == .absent }.count
        let excusedCount = weekRecords.filter { $0.status == .excused }.count

        // 4. Build the deterministic RNG
        let seed = stableSeed(studentID: student.id, weekIndex: date.weekIndex)
        var rng = LCGGenerator(seed: seed)

        // 5. Keyword extraction: scan notes for practiceKeywords hits
        let practicedTopics = extractPracticeTopics(
            from: presentRecords,
            courseType: student.courseType,
            rng: &rng
        )

        // 6. Compose the AI paragraph
        let paragraph = composeParagraph(
            studentName: student.name,
            courseType: student.courseType,
            attendedDays: attendedDays,
            absentCount: absentCount,
            excusedCount: excusedCount,
            practicedTopics: practicedTopics,
            rng: &rng
        )

        return WeeklyReport(
            studentName: student.name,
            courseType: student.courseType,
            weekRange: weekRange,
            attendedDays: attendedDays,
            absentCount: absentCount,
            excusedCount: excusedCount,
            practicedTopics: practicedTopics,
            aiParagraph: paragraph,
            generatedAt: Date()
        )
    }

    // MARK: - Keyword extraction

    /// Scan the week's notes for course keywords and use the hits as practicedTopics.
    /// If fewer than 3 hits, deterministically top up from practiceKeywords.
    private static func extractPracticeTopics(
        from records: [AttendanceRecord],
        courseType: CourseType,
        rng: inout LCGGenerator
    ) -> [String] {
        let allKeywords = courseType.practiceKeywords
        var hits: [String] = []
        var seen = Set<String>()

        for r in records {
            let note = r.noteText
            guard !note.isEmpty else { continue }
            for kw in allKeywords {
                if note.contains(kw), !seen.contains(kw) {
                    hits.append(kw)
                    seen.insert(kw)
                }
            }
        }

        // At least 3 hits — return up to 5
        if hits.count >= 3 {
            return Array(hits.prefix(5))
        }

        // Fewer than 3 hits — deterministically pad from the unused keywords up to 3-4
        let unused = allKeywords.filter { !seen.contains($0) }
        let needed = max(0, 3 - hits.count)
        let supplemented = shuffled(unused, using: &rng).prefix(needed)
        return hits + supplemented
    }

    // MARK: - AI paragraph composition

    /// Compose a ~80-character parent-facing paragraph.
    /// Structure: [attendance summary] + [practice highlights] + [evaluation (positive + improvement)] + [parent suggestion]
    private static func composeParagraph(
        studentName: String,
        courseType: CourseType,
        attendedDays: Int,
        absentCount: Int,
        excusedCount: Int,
        practicedTopics: [String],
        rng: inout LCGGenerator
    ) -> String {
        let evals = courseType.evaluationKeywords
        let positive = pick(from: evals.positive, count: 2, using: &rng)
        let improvement = pick(from: evals.improvement, count: 1, using: &rng)
        let topic = practicedTopics.first ?? courseType.practiceKeywords.first ?? "基础练习"

        // Attendance summary sentence
        let attendanceSentence: String
        if attendedDays >= 3 {
            attendanceSentence = "本周出勤 \(attendedDays) 次，状态稳定。"
        } else if attendedDays >= 1 {
            attendanceSentence = "本周共上课 \(attendedDays) 次\(absentCount > 0 ? "，另有 \(absentCount) 次缺勤" : "")。"
        } else {
            // Fallback: no attendance this week
            return "本周 **\(studentName)** 没有上课记录\(excusedCount > 0 ? "（请假 \(excusedCount) 次）" : "")，建议主动同步当前进度，尽快约下一次课。"
        }

        // Practice-highlight sentence
        let practiceSentence: String
        if practicedTopics.count >= 3 {
            let p1 = practicedTopics[0]
            let p2 = practicedTopics[1]
            let p3 = practicedTopics[2]
            practiceSentence = "重点训练了 **\(p1)**、\(p2) 与 \(p3)，"
        } else if !practicedTopics.isEmpty {
            practiceSentence = "围绕 **\(topic)** 进行了集中练习，"
        } else {
            practiceSentence = "围绕本周既定计划稳步推进，"
        }

        // Evaluation sentence
        let posPart = positive.joined(separator: "、")
        let impPart = improvement.first ?? "细节需打磨"
        let evalSentence = "整体表现\(posPart)，下一阶段建议关注 \(impPart)。"

        // Next-step suggestion (tailored to the vibe-coding audience context)
        let suggestionPool: [String]
        switch courseType {
        case .piano:        // Overseas Marketing
            suggestionPool = [
                "建议下周复盘 3 条 TopGMV 素材，提炼可复制的 hook 公式。",
                "可跑一组 ABO vs CBO 小预算测试，验证当前出价假设。",
                "提醒：素材产能优先级 > 投放策略，先把脚本流水线稳住。"
            ]
        case .english:      // Lobster Rig
            suggestionPool = [
                "建议下周对比 vLLM 与 SGLang 同模型推理速度，出一份测评。",
                "提醒：散热与电源冗余先解决，再追极致 token/s。",
                "可尝试 INT4 与 INT8 量化对照，记录显存占用与精度损失。"
            ]
        case .coding:       // Claude Code
            suggestionPool = [
                "建议下周选 1 个真实工作流封装成 Skill 或 Subagent。",
                "提醒：Plan 阶段控制在 5 步以内，超过就拆 Subagent 避免上下文爆炸。",
                "可给 hooks 加日志，复盘哪些规则生效频次最高。"
            ]
        case .math:         // AI Growth
            suggestionPool = [
                "建议本周设计 1 个 LP A/B 实验，目标 Signup +20%。",
                "提醒：Cohort Retention 要看 D1/D7/D30 三条线，单点容易误判。",
                "可访谈 3 位流失用户，找出 Onboarding 真正卡点。"
            ]
        case .art:          // SwiftUI Advanced
            suggestionPool = [
                "建议下周用自定义 Layout 实现一个流式标签布局。",
                "提醒：MainActor 别滥用，IO 密集型放后台 actor 更顺。",
                "可把 PhaseAnimator 多阶段动画拆解录屏，作为作品集素材。"
            ]
        }
        let suggestion = pick(from: suggestionPool, count: 1, using: &rng).first ?? ""

        return "\(attendanceSentence)\(practiceSentence)\(evalSentence)\(suggestion)"
    }

    // MARK: - Utilities

    private static func stableSeed(studentID: UUID, weekIndex: Int) -> UInt64 {
        // UUID hash is not guaranteed stable across processes in Swift. Pull
        // 64 bits straight out of the UUID byte buffer instead.
        let uuid = studentID.uuid
        // Pack the 16 bytes into two UInt64s, then xor them together.
        let bytes: [UInt8] = [
            uuid.0, uuid.1, uuid.2, uuid.3, uuid.4, uuid.5, uuid.6, uuid.7,
            uuid.8, uuid.9, uuid.10, uuid.11, uuid.12, uuid.13, uuid.14, uuid.15
        ]
        var hi: UInt64 = 0
        var lo: UInt64 = 0
        for i in 0..<8 {
            hi = (hi << 8) | UInt64(bytes[i])
            lo = (lo << 8) | UInt64(bytes[i + 8])
        }
        return hi ^ lo ^ UInt64(bitPattern: Int64(weekIndex))
    }

    /// Simple deterministic shuffle (Fisher-Yates on top of our own RNG)
    private static func shuffled<T>(_ arr: [T], using rng: inout LCGGenerator) -> [T] {
        var a = arr
        guard a.count > 1 else { return a }
        for i in stride(from: a.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            a.swapAt(i, j)
        }
        return a
    }

    /// Deterministically pick `count` items (no duplicates; returns all when count exceeds the array)
    private static func pick<T>(from arr: [T], count: Int, using rng: inout LCGGenerator) -> [T] {
        let shuffledArr = shuffled(arr, using: &rng)
        return Array(shuffledArr.prefix(count))
    }

    /// Week-range display text
    private static func weekRangeText(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Linear Congruential RNG (deterministic)

/// Linear Congruential Generator (LCG) using the Numerical Recipes constants.
/// The same seed always yields the same sequence — independent of system
/// state, stable across processes and devices.
/// Algorithmically distinct from MockSeed.SeededGenerator (xorshift64) on
/// purpose, so the two files stay decoupled.
struct LCGGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // A seed of 0 would freeze the LCG at 0 — fall back to a safe constant.
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        // Numerical Recipes constants for 64-bit LCG
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
