//
//  AttendanceHomeView.swift
//  TutorTrack
//
//  「出勤」Tab 主页：
//  - 顶部「今日签到」：今天还没签到的学员列表，每位 1 个签到按钮
//    （演示阶段简化：任何学员任何时候都能签到，没有"今天有课"的排课系统）
//  - 中部 picker 切换学员
//  - 下部 AttendanceCalendarView 展示该学员热力图（过去 60 天）
//

import SwiftUI
import SwiftData

struct AttendanceHomeView: View {
    @Query(sort: \Student.createdAt, order: .reverse) private var allStudents: [Student]
    @Environment(\.modelContext) private var modelContext

    /// 当前选中学员的 UUID（不用 PersistentIdentifier，UUID 是值类型且 Student.id 已具备）
    @State private var focusedStudentID: UUID?
    /// 待签到的学员（非 nil 弹 CheckInSheet）
    @State private var checkingInStudent: Student?

    private let calendar = Calendar.current

    /// 今天 0 点（按日聚合的边界）
    private var today: Date { calendar.startOfDay(for: Date()) }

    /// 当前聚焦的学员实例
    private var focusedStudent: Student? {
        guard let id = focusedStudentID else { return allStudents.first }
        return allStudents.first { $0.id == id } ?? allStudents.first
    }

    /// 该学员今天是否已签到
    private func hasCheckedInToday(_ s: Student) -> Bool {
        s.attendances.contains { calendar.isDateInToday($0.date) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 今日签到区
                todaySection

                // 学员选择 + 热力图
                if let focused = focusedStudent {
                    studentPicker(selected: focused)
                    AttendanceCalendarView(student: focused)
                        .padding(.horizontal)
                } else {
                    emptyState
                        .padding(.top, 60)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color("WarmIvory").ignoresSafeArea())
        .navigationTitle("出勤")
        .sheet(isPresented: Binding(
            get: { checkingInStudent != nil },
            set: { if !$0 { checkingInStudent = nil } }
        )) {
            if let s = checkingInStudent {
                CheckInSheet(student: s, date: Date()) {
                    checkingInStudent = nil
                }
            }
        }
        .onAppear {
            // 默认选中第一个学员（按 createdAt desc 排序后的第一个）
            if focusedStudentID == nil {
                focusedStudentID = allStudents.first?.id
            }
        }
    }

    // MARK: - 今日签到

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("今日签到", systemImage: "checkmark.square.fill")
                    .font(.headline)
                    .foregroundStyle(Color("CoursePink"))
                Spacer()
                Text(today.formatted(.dateTime.month().day().weekday(.abbreviated)))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            if allStudents.isEmpty {
                Text("还没有学员，先去「学员」Tab 添加")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(allStudents) { student in
                            todayCheckInCard(student: student)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    /// 单张签到卡（横滚）
    private func todayCheckInCard(student: Student) -> some View {
        let done = hasCheckedInToday(student)
        return VStack(spacing: 8) {
            // 头像
            ZStack {
                Circle()
                    .fill(student.courseType.color.opacity(done ? 0.45 : 0.85))
                    .frame(width: 52, height: 52)
                Image(systemName: student.courseType.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                if done {
                    // 右下角 ✓ 角标
                    Circle()
                        .fill(Color.green)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .offset(x: 18, y: 18)
                }
            }

            Text(student.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            // 主按钮：未签到 → 签到；已签到 → 再签一次（演示场景允许重复）
            Button {
                checkingInStudent = student
            } label: {
                Text(done ? "再签" : "签到")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(done ? Color.secondary : Color.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(done
                            ? Color.gray.opacity(0.18)
                            : student.courseType.color)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 110)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(student.courseType.color.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - 学员选择器

    private func studentPicker(selected: Student) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("本月概览")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allStudents) { student in
                        let isSelected = student.id == selected.id
                        Button {
                            focusedStudentID = student.id
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(student.courseType.color)
                                    .frame(width: 8, height: 8)
                                Text(student.name)
                                    .font(.subheadline)
                                    .fontWeight(isSelected ? .semibold : .regular)
                            }
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule().fill(isSelected
                                    ? student.courseType.color
                                    : Color.secondary.opacity(0.15))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - 空态

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text("还没有学员")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("先到「学员」Tab 添加学员，才能在这里签到")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
    }
}
