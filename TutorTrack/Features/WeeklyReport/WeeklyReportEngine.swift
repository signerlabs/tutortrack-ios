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
//  4. **Reads like an LLM**: returned aiParagraph is Markdown-friendly English
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

    /// Compose a parent-facing paragraph.
    /// Structure: [attendance summary] + [practice highlights] + [evaluation (positive + improvement)] + [next-step suggestion]
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
        let topic = practicedTopics.first ?? courseType.practiceKeywords.first ?? "core fundamentals"

        // Attendance summary sentence
        let attendanceSentence: String
        if attendedDays >= 3 {
            attendanceSentence = "Attended \(attendedDays) sessions this week with steady form. "
        } else if attendedDays >= 1 {
            let absentPart = absentCount > 0 ? " with \(absentCount) absence\(absentCount > 1 ? "s" : "")" : ""
            attendanceSentence = "Attended \(attendedDays) session\(attendedDays > 1 ? "s" : "") this week\(absentPart). "
        } else {
            // Fallback: no attendance this week
            let excusedPart = excusedCount > 0 ? " (\(excusedCount) excused)" : ""
            return "**\(studentName)** has no sessions on record this week\(excusedPart). Recommend syncing on current progress and scheduling the next session soon."
        }

        // Practice-highlight sentence
        let practiceSentence: String
        if practicedTopics.count >= 3 {
            let p1 = practicedTopics[0]
            let p2 = practicedTopics[1]
            let p3 = practicedTopics[2]
            practiceSentence = "Focused on **\(p1)**, \(p2), and \(p3); "
        } else if !practicedTopics.isEmpty {
            practiceSentence = "Concentrated practice on **\(topic)**; "
        } else {
            practiceSentence = "Progressed steadily against the week's plan; "
        }

        // Evaluation sentence
        let posPart = positive.joined(separator: " and ")
        let impPart = improvement.first ?? "the details still need polish"
        let evalSentence = "overall showing \(posPart). Next phase, focus on \(impPart). "

        // Next-step suggestion (tailored to the vibe-coding audience context)
        let suggestionPool: [String]
        switch courseType {
        case .piano:        // Overseas Marketing
            suggestionPool = [
                "Next week, deconstruct 3 top-GMV creatives and distill a repeatable hook formula.",
                "Run a small-budget ABO vs CBO test to validate the current bid hypothesis.",
                "Reminder: creative throughput > targeting strategy — lock the scripting pipeline first."
            ]
        case .english:      // Lobster Rig
            suggestionPool = [
                "Next week, benchmark vLLM vs SGLang on the same model and write up the results.",
                "Reminder: solve cooling and PSU headroom before chasing peak tokens/s.",
                "Try INT4 vs INT8 quantization side-by-side and log VRAM usage and accuracy loss."
            ]
        case .coding:       // Claude Code
            suggestionPool = [
                "Next week, wrap one real workflow into a Skill or Subagent.",
                "Reminder: keep Plan phases under 5 steps — split into Subagents past that to avoid context bloat.",
                "Add logging to your hooks and review which rules fire most often."
            ]
        case .math:         // AI Growth
            suggestionPool = [
                "This week, design one LP A/B experiment targeting +20% Signup.",
                "Reminder: cohort retention needs D1/D7/D30 read together — single-point reads mislead.",
                "Interview 3 churned users to find the real Onboarding sticking point."
            ]
        case .art:          // SwiftUI Advanced
            suggestionPool = [
                "Next week, build a flow-tag layout with a custom Layout protocol.",
                "Reminder: don't overload MainActor — push IO-heavy work to a background actor.",
                "Break a PhaseAnimator multi-step animation into a screencast for your portfolio."
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
