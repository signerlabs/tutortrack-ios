//
//  StudentDetailView.swift
//  TutorTrack
//
//  Student detail screen: header card (avatar + name + course badge) +
//  course-tinted progress bar + renew Stepper + attendance-note history list
//  (SWBulletPointText with course-color bullets) + notes / contact info.
//

import SwiftUI
import SwiftData

struct StudentDetailView: View {
    @Bindable var student: Student
    @Environment(\.modelContext) private var modelContext

    /// Attendance records with non-empty notes, newest first (powers the history list)
    private var noteRecords: [AttendanceRecord] {
        student.attendances
            .filter { !$0.noteText.isEmpty }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Header
                header

                // Lesson progress card
                progressCard

                // Attendance note history
                if !noteRecords.isEmpty {
                    notesCard
                }

                // Contact + notes
                infoCard
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color("WarmIvory").ignoresSafeArea())
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header card

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(student.courseType.color.opacity(0.85))
                    .frame(width: 88, height: 88)
                Image(systemName: student.courseType.iconName)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(student.name)
                .font(.title2)
                .fontWeight(.bold)

            // Course badge
            Text(student.courseType.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(student.courseType.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(student.courseType.color.opacity(0.18))
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - Progress card

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("课时进度", systemImage: "graduationcap.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.courseType.color)
                Spacer()
                Text("\(student.attendedLessons) / \(student.totalLessons) 节")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Native progress bar, tinted with course color
            ProgressView(value: Double(student.attendedLessons),
                         total: Double(max(student.totalLessons, 1)))
                .tint(student.courseType.color)
                .frame(height: 10)

            HStack {
                Text("剩余 \(student.remainingLessons) 节")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.needsRenewal ? .red : .primary)

                if student.needsRenewal {
                    Text("· 建议续费")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()

                // Renewal Stepper (SWStepper Recipe: component-stepper)
                HStack(spacing: 8) {
                    Text("续费")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SWStepper(quantity: renewBinding)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(student.courseType.color.opacity(0.15), lineWidth: 1)
        )
    }

    /// SWStepper simulates "renew" by incrementing / decrementing totalLessons
    private var renewBinding: Binding<Int> {
        Binding(
            get: { student.totalLessons },
            set: { newValue in
                guard newValue > student.attendedLessons else { return }
                let delta = newValue - student.totalLessons
                student.totalLessons = newValue
                try? modelContext.save()
                if delta > 0 {
                    SWAlertManager.shared.show(.success, message: "+\(delta) 节")
                }
            }
        )
    }

    // MARK: - Attendance note history

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("签到评语历史", systemImage: "text.bubble.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.courseType.color)
                Spacer()
                Text("\(noteRecords.count) 条")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(noteRecords.prefix(8)) { record in
                    // SWBulletPointText Recipe: component-bullet-point-text
                    SWBulletPointText(bulletColor: student.courseType.color) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(record.noteText)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(student.courseType.color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - Contact + notes

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("联系方式 / 备注", systemImage: "person.crop.rectangle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.courseType.color)
                Spacer()
            }

            if !student.parentContact.isEmpty {
                row(icon: "at", text: student.parentContact)
            }
            if !student.notes.isEmpty {
                row(icon: "note.text", text: student.notes)
            }
            if student.parentContact.isEmpty && student.notes.isEmpty {
                Text("暂无联系方式 / 备注")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(student.courseType.color.opacity(0.15), lineWidth: 1)
        )
    }

    private func row(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}
