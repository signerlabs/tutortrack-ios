//
//  StudentsHomeView.swift
//  TutorTrack
//
//  学员 Tab 首页：搜索栏 + 学员卡片列表 + 右上角新增按钮。
//

import SwiftUI
import SwiftData

struct StudentsHomeView: View {
    @Query(sort: \Student.createdAt, order: .reverse) private var students: [Student]
    @State private var searchText: String = ""
    @State private var showAddSheet: Bool = false

    /// 按搜索关键词过滤
    private var filteredStudents: [Student] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return students
        }
        let q = searchText.lowercased()
        return students.filter {
            $0.name.lowercased().contains(q) ||
            $0.courseType.displayName.contains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // 搜索栏（ShipSwift Recipe: component-search-bar）
                SWSearchBar(text: $searchText, placeholder: "搜索学员姓名 / 课程")
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
        .navigationTitle("学员")
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

    // MARK: - 空态

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text(searchText.isEmpty ? "还没有学员" : "没有匹配的学员")
                .font(.headline)
                .foregroundStyle(.secondary)
            if searchText.isEmpty {
                Text("点击右上角 + 添加第一位学员")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
