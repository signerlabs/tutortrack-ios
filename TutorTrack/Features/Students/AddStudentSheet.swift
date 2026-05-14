//
//  AddStudentSheet.swift
//  TutorTrack
//
//  Add-student bottom sheet. Captures name / course-type picker / total lessons /
//  parent contact / notes. On submit it persists to SwiftData and fires a
//  success toast via SWAlertManager.
//

import SwiftUI
import SwiftData

struct AddStudentSheet: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var selectedCourse: CourseType = .piano
    @State private var totalLessons: Int = 20
    @State private var parentContact: String = ""
    @State private var notes: String = ""

    /// Whether the form can be submitted
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && totalLessons > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic info
                Section {
                    TextField("Student name", text: $name)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Basic Info")
                }

                // MARK: - Course type
                Section {
                    // 5 course-color chips laid out horizontally
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CourseType.allCases, id: \.self) { course in
                                courseChip(course)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Course Type")
                }

                // MARK: - Lessons
                Section {
                    HStack {
                        Text("Sessions purchased")
                        Spacer()
                        SWStepper(quantity: $totalLessons)
                    }
                } header: {
                    Text("Sessions")
                }

                // MARK: - Contact & notes
                Section {
                    TextField("Contact (X / WeChat / email, optional)", text: $parentContact)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Other")
                }
            }
            .navigationTitle("Add Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSubmit)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Course chip

    private func courseChip(_ course: CourseType) -> some View {
        let isSelected = selectedCourse == course
        return Button {
            selectedCourse = course
        } label: {
            HStack(spacing: 6) {
                Image(systemName: course.iconName)
                    .font(.caption)
                Text(course.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(isSelected ? .white : course.color)
            .background(
                Capsule().fill(isSelected ? course.color : course.color.opacity(0.15))
            )
            .overlay(
                Capsule().stroke(course.color.opacity(isSelected ? 0 : 0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private func save() {
        let student = Student(
            name: name.trimmingCharacters(in: .whitespaces),
            courseType: selectedCourse,
            totalLessons: totalLessons,
            attendedLessons: 0,
            parentContact: parentContact,
            notes: notes
        )
        modelContext.insert(student)
        try? modelContext.save()

        SWAlertManager.shared.show(.success, message: "Added \(student.name)")
        isPresented = false
    }
}
