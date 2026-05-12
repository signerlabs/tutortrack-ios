//
//  Date+Week.swift
//  TutorTrack
//
//  Week-range and week-index helpers. The AI weekly report engine combines
//  "student id + week index" into a deterministic seed.
//

import Foundation

extension Date {
    /// Monday 00:00 of the current week (firstWeekday = 2, i.e. Monday-first).
    var startOfWeek: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2 // Monday
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Sunday 23:59:59 of the current week.
    var endOfWeek: Date {
        let calendar = Calendar.current
        let end = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? self
        return calendar.date(byAdding: .second, value: -1, to: end) ?? end
    }

    /// Week index (used as a deterministic seed; monotonically increasing across years).
    var weekIndex: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        let year = components.yearForWeekOfYear ?? 2026
        let week = components.weekOfYear ?? 1
        return year * 100 + week
    }

    /// Week-range display ("5/5 - 5/11").
    var weekRangeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return "\(formatter.string(from: startOfWeek)) - \(formatter.string(from: endOfWeek))"
    }
}
