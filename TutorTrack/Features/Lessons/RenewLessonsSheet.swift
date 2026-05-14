//
//  RenewLessonsSheet.swift
//  TutorTrack
//
//  Renewal bottom sheet (based on .presentationDetents(.medium); shares the
//  interaction skeleton with SWAddSheet).
//  - SWStepper adjusts the lessons to add (default +10, minimum 1)
//  - On confirm, student.totalLessons += addedLessons and try modelContext.save()
//  - SWAlertManager fires a success toast for feedback
//

import SwiftUI
import SwiftData

struct RenewLessonsSheet: View {
    @Bindable var student: Student
    @Environment(\.modelContext) private var modelContext

    /// Sheet-dismiss callback (parent sets its @State to nil)
    let onClose: () -> Void

    /// Lessons to add in this transaction (default 10)
    @State private var addLessons: Int = 10

    /// Binding for SWStepper; clamps to [1, 99] (no zero or negative renewals)
    private var addBinding: Binding<Int> {
        Binding(
            get: { addLessons },
            set: { addLessons = max(1, min(99, $0)) }
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(student.courseType.color.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(student.courseType.color)
                }
                Text("Renew sessions for \(student.name)")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(student.courseType.displayName)
                    .font(.caption)
                    .foregroundStyle(student.courseType.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(student.courseType.color.opacity(0.15))
                    )
            }
            .padding(.top, 8)

            // Current state summary
            HStack(spacing: 16) {
                summaryCell(label: "Attended", value: "\(student.attendedLessons)")
                Divider().frame(height: 28)
                summaryCell(label: "Total", value: "\(student.totalLessons)")
                Divider().frame(height: 28)
                summaryCell(label: "Remaining", value: "\(student.remainingLessons)",
                            tint: student.needsRenewal ? .red : .primary)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(student.courseType.color.opacity(0.15), lineWidth: 1)
            )

            // Renewal-amount row (SWStepper Recipe: component-stepper)
            HStack {
                Text("Add this time")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                SWStepper(quantity: addBinding)
                Text("sessions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 4)

            // Post-renewal state preview
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.caption)
                    .foregroundStyle(student.courseType.color)
                Text("After renewal: \(student.totalLessons + addLessons) total, \(student.remainingLessons + addLessons) remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // Button row (matches SWAddSheet's style)
            HStack(spacing: 10) {
                Button {
                    onClose()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    confirmRenew()
                } label: {
                    Text("Confirm Renewal +\(addLessons)")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(student.courseType.color)
                .disabled(addLessons < 1)
            }
        }
        .padding(20)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Subviews

    private func summaryCell(label: String, value: String, tint: Color = .primary) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(tint)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Submit

    private func confirmRenew() {
        let added = addLessons
        student.totalLessons += added
        do {
            try modelContext.save()
            SWAlertManager.shared.show(.success, message: "Renewal complete, added \(added) sessions")
        } catch {
            SWAlertManager.shared.show(.error, message: "Save failed: \(error.localizedDescription)")
        }
        onClose()
    }
}
