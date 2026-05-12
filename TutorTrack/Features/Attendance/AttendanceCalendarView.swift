//
//  AttendanceCalendarView.swift
//  TutorTrack
//
//  Attendance heatmap calendar. Built on top of SWActivityHeatmap.FlowLayout
//  with a custom three-color mapping. Shows a student's past 60 days of
//  attendance and supports tapping an empty date to backfill a record.
//
//  Color rules:
//    - present  -> courseType.color (present == course color, reinforces brand)
//    - absent   -> red .red.opacity(0.75)
//    - excused  -> gray .gray.opacity(0.55)
//    - no entry -> courseType.color.opacity(0.12)
//

import SwiftUI
import SwiftData

struct AttendanceCalendarView: View {
    let student: Student
    /// Day window to render (default 60, matches SWActivityHeatmap)
    var days: Int = 60
    /// Whether tapping an empty date allows a backfill check-in
    var allowBackfill: Bool = true

    @Environment(\.modelContext) private var modelContext

    /// The tapped "pending check-in date"; non-nil presents CheckInSheet
    @State private var pendingDate: Date?

    private let calendar = Calendar.current

    /// Per-day attendance status (when multiple records exist on one day,
    /// the last wins — in this demo each day has at most one record).
    private var statusByDay: [Date: AttendanceStatus] {
        var dict: [Date: AttendanceStatus] = [:]
        for r in student.attendances {
            let day = calendar.startOfDay(for: r.date)
            dict[day] = r.status
        }
        return dict
    }

    /// Array of dates for the past N days (oldest -> today, matching the
    /// order in SWActivityHeatmap.HeatmapGrid)
    private var targetDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        var list: [Date] = []
        for i in stride(from: days - 1, through: 0, by: -1) {
            if let d = calendar.date(byAdding: .day, value: -i, to: today) {
                list.append(d)
            }
        }
        return list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row + legend
            HStack {
                Label("出勤热力", systemImage: "calendar.badge.checkmark")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.courseType.color)
                Spacer()
                Text("过去 \(days) 天")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Three-color legend
            legend

            // Grid (reuses SWActivityHeatmap.FlowLayout directly)
            SWActivityHeatmap.FlowLayout(spacing: 3) {
                ForEach(targetDays, id: \.self) { date in
                    cell(for: date)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(student.courseType.color.opacity(0.15), lineWidth: 1)
        )
        .sheet(isPresented: Binding(
            get: { pendingDate != nil },
            set: { if !$0 { pendingDate = nil } }
        )) {
            if let pendingDate {
                CheckInSheet(student: student, date: pendingDate) {
                    self.pendingDate = nil
                }
            }
        }
    }

    // MARK: - Cell

    private func cell(for date: Date) -> some View {
        let status = statusByDay[date]
        let fillColor: Color = {
            switch status {
            case .present:  return student.courseType.color
            case .absent:   return .red.opacity(0.75)
            case .excused:  return .gray.opacity(0.55)
            case .none:     return student.courseType.color.opacity(0.12)
            }
        }()

        return RoundedRectangle(cornerRadius: 3)
            .fill(fillColor)
            .frame(width: 18, height: 18)
            .overlay(
                // Stroke today's cell to emphasize it
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        calendar.isDateInToday(date) ? Color.primary.opacity(0.5) : .clear,
                        lineWidth: 1
                    )
            )
            .onTapGesture {
                // Only allow tap when 1) backfill is enabled and 2) the date is not in the future
                guard allowBackfill else { return }
                let today = calendar.startOfDay(for: Date())
                guard date <= today else { return }
                pendingDate = date
            }
    }

    // MARK: - Legend

    private var legend: some View {
        HStack(spacing: 12) {
            legendItem(color: student.courseType.color,    label: "出勤")
            legendItem(color: .red.opacity(0.75),          label: "缺勤")
            legendItem(color: .gray.opacity(0.55),         label: "请假")
            legendItem(color: student.courseType.color.opacity(0.12), label: "无")
            Spacer()
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
        }
    }
}
