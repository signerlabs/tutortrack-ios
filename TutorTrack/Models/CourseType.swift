//
//  CourseType.swift
//  TutorTrack
//
//  Course-type enum with 5 presets (Overseas Marketing / Lobster Rig /
//  Claude Code / AI Growth / SwiftUI Advanced). Each course carries:
//    - Display name (English)
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
        case .piano:   "Overseas Marketing"
        case .english: "Lobster Rig"
        case .coding:  "Claude Code"
        case .math:    "AI Growth"
        case .art:     "SwiftUI Advanced"
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
                "TikTok Shop video scripting",
                "Meta Ads CBO bid testing",
                "Affiliate deal negotiation",
                "Amazon Listing A+ optimization",
                "Shopify Subscriptions setup",
                "Pixel postback debugging",
                "DTC landing page CRO",
                "GMV ramp-up review"
            ]
        case .english:
            return [
                "Dual 4090 NVLink bring-up",
                "70B Q4 vs INT8 benchmarking",
                "vLLM PagedAttention tuning",
                "Flash Attention 2 build",
                "Llama.cpp KV cache tuning",
                "Ollama multi-model concurrency",
                "MLX Swift on M3 Ultra inference",
                "TGI deployment load test"
            ]
        case .coding:
            return [
                "PreToolUse hook blocker script",
                "Subagent parallel scheduling",
                "Skills trigger condition design",
                "Custom MCP server tools",
                "TaskCreate long-task splitting",
                "CLAUDE.md project memory upkeep",
                "Custom slash command authoring",
                "Plan Mode workflow"
            ]
        case .math:
            return [
                "Aha-moment funnel breakdown",
                "Cohort retention weekly table",
                "Viral K-factor calculation",
                "LP -> Signup CRO",
                "Activation key-event design",
                "Referral viral loop design",
                "Onboarding drop-off analysis",
                "PMF signal detection"
            ]
        case .art:
            return [
                "Custom Layout protocol",
                "matchedGeometryEffect animation",
                "Observable + iOS 17 data flow",
                "Concurrency + MainActor isolation",
                "SwiftData @Model relationships",
                "PhaseAnimator multi-step animation",
                "Custom ChartContent in Charts",
                "Liquid Glass material in practice"
            ]
        }
    }

    /// Evaluation keywords (a few positive / improvement phrases each;
    /// the AI engine picks sentences based on attendance rate).
    var evaluationKeywords: (positive: [String], improvement: [String]) {
        switch self {
        case .piano:
            return (
                positive: ["steady creative output", "standout ROAS", "mature SKU selection cadence", "deep competitive teardown"],
                improvement: ["LP conversion still soft", "needs deeper TikTok algo intuition", "repeat-purchase funnel not wired up", "supply-chain stocking too conservative"]
            )
        case .english:
            return (
                positive: ["precise VRAM sizing", "well-reasoned quantization choice", "throughput close to SOTA", "tight hardware budget control"],
                improvement: ["cooling solution needs work", "power headroom too tight", "driver compat traps hit", "PCIe lanes underutilized"]
            )
        case .coding:
            return (
                positive: ["clean hook design", "self-consistent subagent prompts", "fine-grained context control", "well-organized memory system"],
                improvement: ["MCP tools fragmented too finely", "Skills triggers too broad", "agent handoffs not smooth", "Plan phase scoped too large"]
            )
        case .math:
            return (
                positive: ["clear north-star metric", "solid attribution model", "steady experiment cadence", "well-grounded user interviews"],
                improvement: ["hypothesis validation too slow", "sample size too small", "dashboard dimensions too noisy", "PMF read too subjective"]
            )
        case .art:
            return (
                positive: ["clear view structure", "smooth, natural animation", "clean state isolation", "sharp eye for performance"],
                improvement: ["MainActor boundary too tight", "redraw cost still to optimize", "Layout nesting too deep", "old-school dependency injection"]
            )
        }
    }
}
