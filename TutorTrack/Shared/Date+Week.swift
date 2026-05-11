//
//  Date+Week.swift
//  TutorTrack
//
//  本周区间 + 周次工具。AI 周报引擎用「学员 id + 周次」做 deterministic seed。
//

import Foundation

extension Date {
    /// 本周一 00:00（以中国/iOS 默认 firstWeekday=2 周一为首日为约定）
    var startOfWeek: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // 周一
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// 本周日 23:59:59
    var endOfWeek: Date {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? self
        return calendar.date(byAdding: .second, value: -1, to: end) ?? end
    }

    /// 周次编号（用于 deterministic seed，跨年也单调递增）
    var weekIndex: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        let year = components.yearForWeekOfYear ?? 2026
        let week = components.weekOfYear ?? 1
        return year * 100 + week
    }

    /// 本周区间显示（"5/5 - 5/11"）
    var weekRangeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
}
