//
//  AttendanceCalendarView.swift
//  TutorTrack
//
//  出勤热力日历：基于 SWActivityHeatmap.FlowLayout 自建三色映射网格，
//  展示某位学员过去 60 天的出勤状态，并允许点空白日期补打卡。
//
//  色彩规则：
//    - present  → courseType.color（出勤=课程色，强化品牌识别）
//    - absent   → 红 .red.opacity(0.75)
//    - excused  → 灰 .gray.opacity(0.55)
//    - 无记录   → courseType.color.opacity(0.12)
//

import SwiftUI
import SwiftData

struct AttendanceCalendarView: View {
    let student: Student
    /// 展示的天数窗口（默认 60 天，与 SWActivityHeatmap 默认一致）
    var days: Int = 60
    /// 是否允许点击空白日期补打卡
    var allowBackfill: Bool = true

    @Environment(\.modelContext) private var modelContext

    /// 点击的"待签到日期"，非 nil 则弹 CheckInSheet
    @State private var pendingDate: Date?

    private let calendar = Calendar.current

    /// 按"日"聚合的出勤状态（同一天多条记录取最后一条的状态——演示场景每天最多一条）
    private var statusByDay: [Date: AttendanceStatus] {
        var dict: [Date: AttendanceStatus] = [:]
        for r in student.attendances {
            let day = calendar.startOfDay(for: r.date)
            dict[day] = r.status
        }
        return dict
    }

    /// 过去 N 天的日期数组（最旧 → 今天，与 SWActivityHeatmap.HeatmapGrid 顺序一致）
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
            // 标题行 + 图例
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

            // 三色图例
            legend

            // 网格（直接复用 SWActivityHeatmap.FlowLayout）
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

    // MARK: - 单元格

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
                // 今天加描边强调
                RoundedRectangle(cornerRadius: 3)
                    .stroke(
                        calendar.isDateInToday(date) ? Color.primary.opacity(0.5) : .clear,
                        lineWidth: 1
                    )
            )
            .onTapGesture {
                // 仅在 1) 允许补打卡 2) 该日期未来 7 天内（演示用，避免点太远）3) 不晚于今天
                guard allowBackfill else { return }
                let today = calendar.startOfDay(for: Date())
                guard date <= today else { return }
                pendingDate = date
            }
    }

    // MARK: - 图例

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
