//
//  CourseType.swift
//  TutorTrack
//
//  Course-type enum with 5 presets (Overseas Marketing / Lobster Rig /
//  Claude Code / AI Growth / SwiftUI Advanced). Each course carries:
//    - Display name (Chinese)
//    - Course color (loaded from Assets.xcassets ColorSet)
//    - SF Symbol icon (used as student avatar fallback)
//    - Template dictionary (used by WeeklyReportEngine to compose AI paragraphs)
//
//  Note: the raw values are kept as piano / english / coding / math / art —
//  purely internal codenames. Engine and MockSeed switches need no changes;
//  observers only ever see the updated displayName.
//

import SwiftUI

enum CourseType: String, Codable, CaseIterable {
    case piano       // Overseas Marketing
    case english     // Lobster Rig (AI inference hardware)
    case coding      // Claude Code
    case math        // AI Growth
    case art         // SwiftUI Advanced

    // MARK: - Display name

    var displayName: String {
        switch self {
        case .piano:   "出海营销"
        case .english: "龙虾配置"
        case .coding:  "Claude Code"
        case .math:    "AI 增长"
        case .art:     "SwiftUI 进阶"
        }
    }

    // MARK: - Course color (Assets.xcassets/Colors/)

    var color: Color {
        switch self {
        case .piano:   Color("CoursePink")
        case .english: Color("CourseBlue")
        case .coding:  Color("CoursePurple")
        case .math:    Color("CourseOrange")
        case .art:     Color("CourseGreen")
        }
    }

    // MARK: - Avatar SF Symbol

    var iconName: String {
        switch self {
        case .piano:   "globe.americas.fill"
        case .english: "cpu.fill"
        case .coding:  "terminal.fill"
        case .math:    "chart.line.uptrend.xyaxis"
        case .art:     "swift"
        }
    }

    // MARK: - Template dictionary (raw material for AI weekly report)

    /// Typical practice-content keywords for this course. The AI paragraph
    /// engine deterministically picks from these using week-index + student id.
    var practiceKeywords: [String] {
        switch self {
        case .piano:
            return [
                "TikTok Shop 短视频脚本",
                "Meta Ads CBO 出价测试",
                "红人 affiliate 谈合作",
                "Amazon Listing A+ 优化",
                "Shopify Subscriptions 配置",
                "像素回传调试",
                "DTC 落地页转化优化",
                "GMV 单量爬坡复盘"
            ]
        case .english:
            return [
                "双 4090 NVLink 跑通",
                "70B Q4 量化对比 INT8",
                "vLLM PagedAttention 调参",
                "Flash Attention 2 编译",
                "Llama.cpp KV cache 调优",
                "Ollama 多模型并发",
                "MLX Swift M3 Ultra 本地推理",
                "TGI 部署压测"
            ]
        case .coding:
            return [
                "PreToolUse Hook 阻断脚本",
                "Subagent 并行任务调度",
                "Skills 触发条件设计",
                "MCP Server 自定义工具",
                "TaskCreate 拆分长任务",
                "CLAUDE.md 项目记忆维护",
                "Slash Command 自定义",
                "Plan Mode 工作流"
            ]
        case .math:
            return [
                "Aha Moment 漏斗拆解",
                "Cohort Retention 周表",
                "病毒系数 K 值测算",
                "LP → Signup 转化优化",
                "Activation 关键事件设计",
                "Referral 病毒裂变设计",
                "Onboarding 流失点分析",
                "PMF 信号识别"
            ]
        case .art:
            return [
                "Layout 协议自定义",
                "matchedGeometryEffect 动画",
                "Observable + iOS 17 数据流",
                "Concurrency + MainActor 隔离",
                "SwiftData @Model 关系建模",
                "PhaseAnimator 多阶段动画",
                "Charts 自定义 ChartContent",
                "Liquid Glass 材质实践"
            ]
        }
    }

    /// Evaluation keywords (a few positive / improvement phrases each;
    /// the AI engine picks sentences based on attendance rate).
    var evaluationKeywords: (positive: [String], improvement: [String]) {
        switch self {
        case .piano:
            return (
                positive: ["素材产能稳定", "ROAS 表现亮眼", "选品节奏成熟", "竞品分析深入"],
                improvement: ["LP 转化率偏低", "TikTok 算法理解需深入", "复购漏斗待打通", "供应链备货偏保守"]
            )
        case .english:
            return (
                positive: ["显存测算精确", "量化方案选型合理", "推理速度对标 SOTA", "硬件预算控制好"],
                improvement: ["散热方案待优化", "电源冗余偏紧", "驱动兼容性踩坑", "PCIe 通道数没榨干"]
            )
        case .coding:
            return (
                positive: ["hooks 思路清晰", "subagent prompt 自洽", "上下文管理精细", "记忆系统组织规范"],
                improvement: ["MCP 工具拆分过细", "Skills 触发条件太宽", "agent 协作链路不顺", "Plan 阶段铺得太大"]
            )
        case .math:
            return (
                positive: ["北极星指标定义清晰", "归因模型搭得稳", "实验节奏稳定", "用户访谈结论扎实"],
                improvement: ["假设验证偏慢", "实验样本量不够大", "数据看板维度太杂", "PMF 信号判断偏主观"]
            )
        case .art:
            return (
                positive: ["视图结构清晰", "动画细腻自然", "状态隔离干净", "性能优化敏感"],
                improvement: ["MainActor 边界把握偏紧", "重绘开销待优化", "Layout 嵌套层级偏深", "依赖注入方式偏老派"]
            )
        }
    }
}
