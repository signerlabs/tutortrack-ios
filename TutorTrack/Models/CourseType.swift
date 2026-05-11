//
//  CourseType.swift
//  TutorTrack
//
//  课程类型枚举，5 种预置（钢琴 / 英语 / 编程 / 数学 / 美术）。
//  每种课程附带：
//    - 显示名（中文）
//    - 课程色（从 Assets.xcassets 读 ColorSet）
//    - SF Symbol 图标（作为学员头像 fallback）
//    - 模板词典（WeeklyReportEngine 用来拼 AI 段落）
//

import SwiftUI

enum CourseType: String, Codable, CaseIterable {
    case piano
    case english
    case coding
    case math
    case art

    // MARK: - 显示名

    var displayName: String {
        switch self {
        case .piano:   "钢琴"
        case .english: "英语"
        case .coding:  "编程"
        case .math:    "数学"
        case .art:     "美术"
        }
    }

    // MARK: - 课程色（Assets.xcassets/Colors/）

    var color: Color {
        switch self {
        case .piano:   Color("CoursePink")
        case .english: Color("CourseBlue")
        case .coding:  Color("CoursePurple")
        case .math:    Color("CourseOrange")
        case .art:     Color("CourseGreen")
        }
    }

    // MARK: - 头像 SF Symbol

    var iconName: String {
        switch self {
        case .piano:   "music.note"
        case .english: "book.fill"
        case .coding:  "chevron.left.forwardslash.chevron.right"
        case .math:    "function"
        case .art:     "paintbrush.fill"
        }
    }

    // MARK: - 模板词典（AI 周报拼接素材）

    /// 本课程的典型练习内容关键词，AI 段落引擎按周次 + 学员 id 做 deterministic 选词
    var practiceKeywords: [String] {
        switch self {
        case .piano:
            return [
                "拜厄第 18 条",
                "哈农音阶练习",
                "C 大调和弦衔接",
                "右手力度控制",
                "三连音节奏",
                "踏板配合",
                "断奏与连奏切换",
                "G 大调音阶"
            ]
        case .english:
            return [
                "现在完成时句型",
                "日常口语对话",
                "高频单词 50 个",
                "时态混淆纠错",
                "课本 Unit 4 听力",
                "短文复述",
                "动词不规则变化",
                "阅读理解长难句"
            ]
        case .coding:
            return [
                "for 循环嵌套",
                "if-else 条件分支",
                "函数定义与调用",
                "变量作用域",
                "list 增删改查",
                "调试 print 排错",
                "字符串拼接",
                "import 模块使用"
            ]
        case .math:
            return [
                "一元二次方程",
                "勾股定理证明",
                "应用题理解",
                "几何图形辅助线",
                "因式分解",
                "函数图像分析",
                "概率基础",
                "数列求和"
            ]
        case .art:
            return [
                "素描线条流畅度",
                "色彩冷暖对比",
                "构图重心",
                "光影明暗关系",
                "速写人体比例",
                "水彩湿画法",
                "静物写生",
                "几何体块面分析"
            ]
        }
    }

    /// 评价关键词（褒贬中性各几个，AI 引擎按出勤率挑句子）
    var evaluationKeywords: (positive: [String], improvement: [String]) {
        switch self {
        case .piano:
            return (
                positive: ["节奏稳", "音色干净", "记谱准确", "练习专注"],
                improvement: ["指法偶有卡顿", "强弱处理待加强", "踏板使用偏多", "和弦衔接生"]
            )
        case .english:
            return (
                positive: ["口语流利", "发音清晰", "单词量增加", "对话反应快"],
                improvement: ["时态偶尔混淆", "听力细节漏听", "语法句型不够丰富", "书写笔画粗糙"]
            )
        case .coding:
            return (
                positive: ["逻辑清晰", "排错耐心", "代码注释完整", "课堂提问积极"],
                improvement: ["边界条件容易漏", "调试节奏偏慢", "函数命名待规范", "缩进格式偶尔混乱"]
            )
        case .math:
            return (
                positive: ["运算扎实", "证明步骤完整", "审题仔细", "速度稳定"],
                improvement: ["应用题理解偏慢", "几何辅助线难发现", "粗心看错符号", "公式套用机械"]
            )
        case .art:
            return (
                positive: ["想象力丰富", "色彩搭配大胆", "线条流畅", "课堂专注"],
                improvement: ["构图重心偏左", "光影对比偏弱", "细节刻画偏少", "落笔犹豫"]
            )
        }
    }
}
