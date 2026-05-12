//
//  WeeklyReportEngine.swift
//  TutorTrack
//
//  AI 周报生成引擎（纯本地 mock，零网络，deterministic）。
//
//  设计要点：
//  1. **Deterministic**：同一学员同一周生成的报告完全一致。
//     - seed = student.id.hashValue ^ date.weekIndex
//     - 用自家 LCG（线性同余）实现 RandomNumberGenerator，绕开系统 RNG 的"不保证可重复"
//  2. **数据驱动**：吃本周该学员的 AttendanceRecord，扫描 noteText 中的关键词（命中 practiceKeywords）
//     - 命中关键词 → 直接挑出来作为 practicedTopics
//     - 没命中 → fallback 到 practiceKeywords 里随机挑 2 个
//  3. **AI 段落拼接**：80 字左右，按出勤天数选择正面/改进句模板，最后挂家长建议
//  4. **看起来像 LLM**：返回的 aiParagraph 是 markdown 友好的中文段落，可直接喂 SWMarkdownText
//

import Foundation
import SwiftData  // 虽然 Engine 只读 @Model 实例的属性，未直接用 SwiftData API；
                  // 但 CLAUDE.md 强约束"用 SwiftData @Model 的文件顶部 import SwiftData"，
                  // 防御性加上避免后续扩展（如本地缓存到 ModelContext）漏 import。

// MARK: - 公开数据结构

struct WeeklyReport {
    /// 学员姓名
    let studentName: String
    /// 课程类型
    let courseType: CourseType
    /// 周次区间显示（"5/5 - 5/11"）
    let weekRange: String
    /// 出勤天数（status == .present 的去重日数）
    let attendedDays: Int
    /// 缺勤次数
    let absentCount: Int
    /// 请假次数
    let excusedCount: Int
    /// 命中或挑选出的练习主题（3-5 条 bullet 用）
    let practicedTopics: [String]
    /// AI 风格段落（≈80 字，markdown 友好）
    let aiParagraph: String
    /// 生成时间（PDF 页脚显示）
    let generatedAt: Date
}

// MARK: - 引擎

enum WeeklyReportEngine {

    /// 主入口：生成指定学员指定周的报告
    /// - Parameters:
    ///   - student: 学员
    ///   - weekOf: 任意一个落在目标周内的日期（函数内部会取 startOfWeek/endOfWeek）
    /// - Returns: WeeklyReport
    static func generate(for student: Student, weekOf date: Date) -> WeeklyReport {
        // 1. 计算周区间
        let weekStart = date.startOfWeek
        let weekEnd = date.endOfWeek
        let weekRange = weekRangeText(start: weekStart, end: weekEnd)

        // 2. 过滤本周该学员的出勤记录
        let weekRecords = student.attendances.filter { r in
            r.date >= weekStart && r.date <= weekEnd
        }

        // 3. 统计三类计数
        let presentRecords = weekRecords.filter { $0.status == .present }
        let attendedDays = Set(presentRecords.map { Calendar.current.startOfDay(for: $0.date) }).count
        let absentCount = weekRecords.filter { $0.status == .absent }.count
        let excusedCount = weekRecords.filter { $0.status == .excused }.count

        // 4. 构建 deterministic RNG
        let seed = stableSeed(studentID: student.id, weekIndex: date.weekIndex)
        var rng = LCGGenerator(seed: seed)

        // 5. 关键词提取：扫描评语命中 practiceKeywords
        let practicedTopics = extractPracticeTopics(
            from: presentRecords,
            courseType: student.courseType,
            rng: &rng
        )

        // 6. 拼接 AI 段落
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

    // MARK: - 关键词提取

    /// 从本周评语中扫描课程关键词；命中即列入 practicedTopics
    /// 命中不足 3 条时，用 deterministic 方式从 practiceKeywords 补齐
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

        // 命中至少 3 条，前 5 条
        if hits.count >= 3 {
            return Array(hits.prefix(5))
        }

        // 不足 3 条，从未命中的关键词里 deterministic 补齐到 3-4 条
        let unused = allKeywords.filter { !seen.contains($0) }
        let needed = max(0, 3 - hits.count)
        let supplemented = shuffled(unused, using: &rng).prefix(needed)
        return hits + supplemented
    }

    // MARK: - AI 段落拼接

    /// 拼接 80 字左右的家长汇报段落
    /// 结构：[本周出勤总结] + [练习要点串联] + [评价句（正面+改进）] + [家长建议]
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

        // 出勤总结句
        let attendanceSentence: String
        if attendedDays >= 3 {
            attendanceSentence = "本周出勤 \(attendedDays) 次，状态稳定。"
        } else if attendedDays >= 1 {
            attendanceSentence = "本周共上课 \(attendedDays) 次\(absentCount > 0 ? "，另有 \(absentCount) 次缺勤" : "")。"
        } else {
            // 兜底：本周无出勤
            return "本周 **\(studentName)** 没有上课记录\(excusedCount > 0 ? "（请假 \(excusedCount) 次）" : "")，建议主动同步当前进度，尽快约下一次课。"
        }

        // 练习要点串联
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

        // 评价句
        let posPart = positive.joined(separator: "、")
        let impPart = improvement.first ?? "细节需打磨"
        let evalSentence = "整体表现\(posPart)，下一阶段建议关注 \(impPart)。"

        // 下一阶段建议（适配 vibe coding 圈层语境）
        let suggestionPool: [String]
        switch courseType {
        case .piano:        // 出海营销
            suggestionPool = [
                "建议下周复盘 3 条 TopGMV 素材，提炼可复制的 hook 公式。",
                "可跑一组 ABO vs CBO 小预算测试，验证当前出价假设。",
                "提醒：素材产能优先级 > 投放策略，先把脚本流水线稳住。"
            ]
        case .english:      // 龙虾配置
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
        case .math:         // AI 增长
            suggestionPool = [
                "建议本周设计 1 个 LP A/B 实验，目标 Signup +20%。",
                "提醒：Cohort Retention 要看 D1/D7/D30 三条线，单点容易误判。",
                "可访谈 3 位流失用户，找出 Onboarding 真正卡点。"
            ]
        case .art:          // SwiftUI 进阶
            suggestionPool = [
                "建议下周用自定义 Layout 实现一个流式标签布局。",
                "提醒：MainActor 别滥用，IO 密集型放后台 actor 更顺。",
                "可把 PhaseAnimator 多阶段动画拆解录屏，作为作品集素材。"
            ]
        }
        let suggestion = pick(from: suggestionPool, count: 1, using: &rng).first ?? ""

        return "\(attendanceSentence)\(practiceSentence)\(evalSentence)\(suggestion)"
    }

    // MARK: - 工具

    private static func stableSeed(studentID: UUID, weekIndex: Int) -> UInt64 {
        // UUID hash 在 Swift 中不保证跨进程稳定。我们从 UUID 的字节直接取出 64 bit。
        let uuid = studentID.uuid
        // 把 16 字节拼成两个 UInt64，再异或
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

    /// 简易 deterministic shuffle（基于 Fisher-Yates + 我们自己的 RNG）
    private static func shuffled<T>(_ arr: [T], using rng: inout LCGGenerator) -> [T] {
        var a = arr
        guard a.count > 1 else { return a }
        for i in stride(from: a.count - 1, through: 1, by: -1) {
            let j = Int(rng.next() % UInt64(i + 1))
            a.swapAt(i, j)
        }
        return a
    }

    /// deterministic 从数组里取 count 个（不重复，count 大于数组长度时返回全部）
    private static func pick<T>(from arr: [T], count: Int, using rng: inout LCGGenerator) -> [T] {
        let shuffledArr = shuffled(arr, using: &rng)
        return Array(shuffledArr.prefix(count))
    }

    /// 周区间显示文本
    private static func weekRangeText(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - 线性同余 RNG（deterministic）

/// 线性同余生成器（LCG），Numerical Recipes 推荐参数。
/// 同一 seed 永远产生同一序列，不依赖系统状态，跨进程/跨设备稳定。
/// 与 MockSeed.SeededGenerator（xorshift64）算法不同——这里特意用 LCG 让两个文件各自独立、互不耦合。
struct LCGGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        // seed 为 0 会让 LCG 停在 0；用一个安全的 fallback
        self.state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        // Numerical Recipes constants for 64-bit LCG
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
