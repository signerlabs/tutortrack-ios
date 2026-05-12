//
//  CheckInSheet.swift
//  TutorTrack
//
//  Check-in bottom sheet:
//  - SWTabButton three-way switch (present / absent / excused)
//  - Multi-line TextField for the note (<= 50 chars, auto-truncates onChange)
//  - On confirm: insert AttendanceRecord(date:, status:, noteText:, student:);
//    when status == .present also bump student.attendedLessons += 1,
//    then try save() and surface SWAlert feedback.
//

import SwiftUI
import SwiftData

struct CheckInSheet: View {
    @Bindable var student: Student
    /// Check-in date. Defaults to today; AttendanceCalendarView passes an
    /// explicit date when backfilling.
    let date: Date
    @Environment(\.modelContext) private var modelContext

    /// Callback that dismisses the sheet
    let onClose: () -> Void

    @State private var status: AttendanceStatus = .present
    @State private var noteText: String = ""

    /// Maximum note length (kept in sync with AttendanceRecord.noteText)
    private let noteCharLimit = 50

    var body: some View {
        VStack(spacing: 18) {
            // Top hero
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

            // Status switch: SWTabButton x3.
            // Note: SWTabButton hard-codes Color.accentColor internally, so all
            // three segments share the same app accent. We rely on the large
            // hero avatar's SF Symbol (present = check, absent = x, excused = ?)
            // plus the status color to differentiate.
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

            // Note input
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
                    // Hard-truncate at <= 50 chars (each CJK character counts as 1)
                    if newValue.count > noteCharLimit {
                        noteText = String(newValue.prefix(noteCharLimit))
                    }
                }
            }

            Spacer(minLength: 0)

            // Button row
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
        // Create the attendance record
        let record = AttendanceRecord(
            date: Calendar.current.startOfDay(for: date),
            status: status,
            noteText: noteText.trimmingCharacters(in: .whitespacesAndNewlines),
            student: student
        )
        modelContext.insert(record)

        // Only count "present" toward attended lessons
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
