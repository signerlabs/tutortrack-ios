//
//  StudentsHomeView.swift
//  TutorTrack
//
//  Students tab home: search bar + student card list + top-right add button.
//

import SwiftUI
import SwiftData

struct StudentsHomeView: View {
    @Query(sort: \Student.createdAt, order: .reverse) private var students: [Student]
    @State private var searchText: String = ""
    @State private var showAddSheet: Bool = false

    /// Filter by the search keyword
    private var filteredStudents: [Student] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return students
        }
        let q = searchText.lowercased()
        return students.filter {
            $0.name.lowercased().contains(q) ||
            $0.courseType.displayName.lowercased().contains(q)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Search bar (ShipSwift Recipe: component-search-bar)
                SWSearchBar(text: $searchText, placeholder: "Search by name or course")
                    .padding(.horizontal)
                    .padding(.top, 4)

                if filteredStudents.isEmpty {
                    emptyState
                        .padding(.top, 80)
                } else {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredStudents) { student in
                            NavigationLink(value: student) {
                                StudentCard(student: student)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color("WarmIvory").ignoresSafeArea())
        .navigationTitle("Students")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color("CoursePink"))
                }
            }
        }
        .navigationDestination(for: Student.self) { student in
            StudentDetailView(student: student)
        }
        .sheet(isPresented: $showAddSheet) {
            AddStudentSheet(isPresented: $showAddSheet)
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "No students yet" : "No matching students")
                .font(.headline)
                .foregroundStyle(.secondary)
            if searchText.isEmpty {
                Text("Tap the + button in the top-right to add your first student")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
