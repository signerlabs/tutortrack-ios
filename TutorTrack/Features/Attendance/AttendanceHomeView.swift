//
//  AttendanceHomeView.swift
//  TutorTrack
//
//  Attendance tab home:
//  - Top "Today's Check-in" row: every student who has not checked in yet,
//    with a one-tap check-in button (demo simplification: any student can
//    check in any time — there's no class-schedule system).
//  - Middle picker switches the focused student.
//  - Bottom AttendanceCalendarView shows that student's past-60-day heatmap.
//

import SwiftUI
import SwiftData

struct AttendanceHomeView: View {
    @Query(sort: \Student.createdAt, order: .reverse) private var allStudents: [Student]
    @Environment(\.modelContext) private var modelContext

    /// Currently focused student's UUID (we use UUID instead of PersistentIdentifier
    /// because Student.id is already a UUID and value types are easier to thread.)
    @State private var focusedStudentID: UUID?
    /// Student awaiting check-in (non-nil presents CheckInSheet)
    @State private var checkingInStudent: Student?

    private let calendar = Calendar.current

    /// Midnight today (boundary for day-level aggregation)
    private var today: Date { calendar.startOfDay(for: Date()) }

    /// The currently focused student instance
    private var focusedStudent: Student? {
        guard let id = focusedStudentID else { return allStudents.first }
        return allStudents.first { $0.id == id } ?? allStudents.first
    }

    /// Whether this student has already checked in today
    private func hasCheckedInToday(_ s: Student) -> Bool {
        s.attendances.contains { calendar.isDateInToday($0.date) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Today's check-in section
                todaySection

                // Student picker + heatmap
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
            // Default to the first student (by createdAt desc)
            if focusedStudentID == nil {
                focusedStudentID = allStudents.first?.id
            }
        }
    }

    // MARK: - Today's check-in

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

    /// A single check-in card (horizontal scroll)
    private func todayCheckInCard(student: Student) -> some View {
        let done = hasCheckedInToday(student)
        return VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(student.courseType.color.opacity(done ? 0.45 : 0.85))
                    .frame(width: 52, height: 52)
                Image(systemName: student.courseType.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                if done {
                    // Bottom-right ✓ badge
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

            // Primary button: not checked in -> "Check in"; already checked in
            // -> "Check in again" (demo allows repeated check-ins).
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

    // MARK: - Student picker

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

    // MARK: - Empty state

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
