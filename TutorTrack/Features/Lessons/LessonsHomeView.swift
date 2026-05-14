//
//  LessonsHomeView.swift
//  TutorTrack
//
//  Lessons tab home: an at-a-glance lesson-progress list for every student.
//  Sorted ascending by remainingLessons so the most urgent ones land at the
//  top, creating a "time to renew" visual cue.
//  - Each row: large avatar + name + course badge + thick progress bar + attended/total
//  - When <= 3 lessons remain, attach a red "Renew" SWStatusBadge
//  - The bottom-right "Renew" button presents RenewLessonsSheet
//    (based on .presentationDetents(.medium))
//  - Tapping elsewhere on the card pushes StudentDetailView via NavigationLink
//

import SwiftUI
import SwiftData

struct LessonsHomeView: View {
    @Query private var allStudents: [Student]
    @Environment(\.modelContext) private var modelContext

    /// Student tied to the renewal sheet (nil = sheet hidden)
    @State private var renewingStudent: Student?

    /// Sorted ascending by remainingLessons. Ties broken by totalLessons,
    /// then by name for stable ordering.
    private var students: [Student] {
        allStudents.sorted { lhs, rhs in
            if lhs.remainingLessons != rhs.remainingLessons {
                return lhs.remainingLessons < rhs.remainingLessons
            }
            if lhs.totalLessons != rhs.totalLessons {
                return lhs.totalLessons < rhs.totalLessons
            }
            return lhs.name < rhs.name
        }
    }

    /// Number of students that need a renewal prompt (powers the header KPI)
    private var renewalCount: Int {
        students.filter(\.needsRenewal).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Header KPI cards (SWKPICard style)
                kpiSection
                    .padding(.horizontal)
                    .padding(.top, 4)

                if students.isEmpty {
                    emptyState
                        .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(students) { student in
                            LessonProgressRow(
                                student: student,
                                onRenew: { renewingStudent = student }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color("WarmIvory").ignoresSafeArea())
        .navigationTitle("Sessions")
        .navigationDestination(for: Student.self) { student in
            StudentDetailView(student: student)
        }
        .sheet(isPresented: Binding(
            get: { renewingStudent != nil },
            set: { if !$0 { renewingStudent = nil } }
        )) {
            if let renewingStudent {
                RenewLessonsSheet(student: renewingStudent) {
                    self.renewingStudent = nil
                }
            }
        }
    }

    // MARK: - Header KPI

    private var kpiSection: some View {
        HStack(spacing: 10) {
            kpiCard(
                title: "Total Students",
                value: "\(students.count)",
                color: Color("CoursePurple"),
                icon: "person.3.fill"
            )
            kpiCard(
                title: "Renewal Due",
                value: "\(renewalCount)",
                color: renewalCount > 0 ? .red : .secondary,
                icon: "exclamationmark.bubble.fill"
            )
        }
    }

    private func kpiCard(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(color)

            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text("No students yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add a student from the Students tab first")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Lesson progress row

/// A single student row tappable for the detail screen. The bottom-right
/// "Renew" button is an independent action.
private struct LessonProgressRow: View {
    let student: Student
    let onRenew: () -> Void

    var body: some View {
        // One outer card with two halves: the upper half is the NavigationLink,
        // the lower half is a separate Button row. This avoids the classic
        // NavigationLink + Button hit-test conflict (a common iOS 16+ pitfall).
        VStack(alignment: .leading, spacing: 12) {
            // Upper half: tappable area pushing the detail view
            NavigationLink(value: student) {
                upperPart
            }
            .buttonStyle(.plain)

            // Lower half: remaining lessons + renew button, lives outside the link
            HStack {
                Text("\(student.remainingLessons) sessions left")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.needsRenewal ? .red : .primary)

                Spacer()

                Button {
                    onRenew()
                } label: {
                    Label("Renew", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(student.courseType.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(student.courseType.color.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(student.courseType.color.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    /// Upper region: avatar + name + progress bar (the whole block is the NavigationLink hit area)
    private var upperPart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(student.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        // Course-color badge (matches StudentCard's style;
                        // we don't reuse SWStatusBadge because it only carries
                        // 5 semantic colors — we need 5 course-specific ones).
                        courseBadge
                    }

                    Text("\(student.attendedLessons) / \(student.totalLessons) sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 6)

                if student.needsRenewal {
                    SWStatusBadge(text: "Renew", style: .error)
                }
            }

            // Thick progress bar (course-color tint)
            ProgressView(value: Double(student.attendedLessons),
                         total: Double(max(student.totalLessons, 1)))
                .tint(student.courseType.color)
                .frame(height: 8)
        }
        .contentShape(Rectangle()) // The whole upper area is the link hit area
    }

    /// Circular avatar (matches StudentCard's style)
    private var avatar: some View {
        ZStack {
            Circle()
                .fill(student.courseType.color.opacity(0.85))
                .frame(width: 44, height: 44)
            Image(systemName: student.courseType.iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    /// Course badge (capsule shape, course-color fill; identical to StudentCard.courseBadge)
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
