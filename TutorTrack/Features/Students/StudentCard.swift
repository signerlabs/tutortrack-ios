//
//  StudentCard.swift
//  TutorTrack
//
//  A single student card: left side shows a circular course-colored avatar
//  (SF Symbol); the right side stacks name / course badge / remaining lessons.
//  Once <= 3 lessons remain, the count flips red to create a "time to renew"
//  urgency cue.
//

import SwiftUI
import SwiftData

struct StudentCard: View {
    let student: Student

    var body: some View {
        HStack(spacing: 14) {
            // Avatar: circular course-color fill + SF Symbol
            avatar

            VStack(alignment: .leading, spacing: 6) {
                // Name
                Text(student.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // Course-type badge
                courseBadge

                // Remaining lessons
                HStack(spacing: 4) {
                    Image(systemName: "graduationcap")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("剩余 \(student.remainingLessons) / \(student.totalLessons) 节")
                        .font(.caption)
                        .foregroundStyle(student.needsRenewal ? .red : .secondary)
                        .fontWeight(student.needsRenewal ? .semibold : .regular)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(student.courseType.color.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    // MARK: - Subviews

    /// Circular avatar = course-color background + course SF Symbol
    private var avatar: some View {
        ZStack {
            Circle()
                .fill(student.courseType.color.opacity(0.85))
                .frame(width: 52, height: 52)
            Image(systemName: student.courseType.iconName)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    /// Course badge (capsule shape, course-color fill)
    private var courseBadge: some View {
        Text(student.courseType.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(student.courseType.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(student.courseType.color.opacity(0.18))
            )
            .overlay(
                Capsule().stroke(student.courseType.color.opacity(0.35), lineWidth: 0.5)
            )
    }
}
