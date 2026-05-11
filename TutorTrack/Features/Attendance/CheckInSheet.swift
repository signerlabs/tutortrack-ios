//
//  CheckInSheet.swift
//  TutorTrack
//
//  签到 bottom sheet：
//  - SWTabButton 三段切状态（出勤 / 缺勤 / 请假）
//  - 多行 TextField 录入评语（≤ 50 字，onChange 自动截断）
//  - 确认：新建 AttendanceRecord(date:, status:, noteText:, student:)，
//    出勤状态 .present 时同步 student.attendedLessons += 1，try save() + SWAlert 反馈
//

import SwiftUI
import SwiftData

struct CheckInSheet: View {
    @Bindable var student: Student
    /// 签到日期；默认今天，AttendanceCalendarView 补打卡场景会传具体日期
    let date: Date
    @Environment(\.modelContext) private var modelContext

    /// 关闭 sheet 的回调
    let onClose: () -> Void

    @State private var status: AttendanceStatus = .present
    @State private var noteText: String = ""

    /// 评语字数上限（与 AttendanceRecord.noteText 注释保持一致）
    private let noteCharLimit = 50

    var body: some View {
        VStack(spacing: 18) {
            // 顶部 hero
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(student.courseType.color.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: status.iconName)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(status.color)
                        .contentTransition(.symbolEffect(.replace))
                }
                Text(student.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(date.formatted(.dateTime.year().month().day().weekday(.wide)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)

            // 状态切换：SWTabButton ×3
            // 注意：SWTabButton 内部硬编码 Color.accentColor，三段会共用 app accent 色
            // 区分靠左侧大圆头像的 SF Symbol（出勤=✓、缺勤=✗、请假=?）+ 状态色
            HStack(spacing: 10) {
                ForEach(AttendanceStatus.allCases, id: \.self) { s in
                    SWTabButton(
                        title: LocalizedStringKey(s.displayName),
                        isSelected: status == s
                    ) {
                        status = s
                    }
                }
            }

            // 评语输入
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("课堂评语", systemImage: "text.bubble")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(noteText.count) / \(noteCharLimit)")
                        .font(.caption2)
                        .foregroundStyle(noteText.count >= noteCharLimit ? Color.orange : Color.secondary)
                }

                TextField(
                    "如：拜厄第 18 条流畅，力度待加强",
                    text: $noteText,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: noteText) { _, newValue in
                    // ≤ 50 字硬截断（中文计 1 字符）
                    if newValue.count > noteCharLimit {
                        noteText = String(newValue.prefix(noteCharLimit))
                    }
                }
            }

            Spacer(minLength: 0)

            // 按钮组
            HStack(spacing: 10) {
                Button {
                    onClose()
                } label: {
                    Text("取消")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    confirm()
                } label: {
                    Text("签到")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(status.color)
            }
        }
        .padding(20)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func confirm() {
        // 创建出勤记录
        let record = AttendanceRecord(
            date: Calendar.current.startOfDay(for: date),
            status: status,
            noteText: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
            student: student
        )
        modelContext.insert(record)

        // 出勤才计入已上课时
        if status == .present {
            student.attendedLessons += 1
        }

        do {
            try modelContext.save()
            SWAlertManager.shared.show(.success, message: "\(student.name) 已记 \(status.displayName)")
        } catch {
            SWAlertManager.shared.show(.error, message: "签到失败：\(error.localizedDescription)")
        }
        onClose()
    }
}
