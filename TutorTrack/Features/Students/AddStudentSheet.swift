//
//  AddStudentSheet.swift
//  TutorTrack
//
//  新增学员 bottom sheet。包含姓名 / 课程类型选择器 / 总课时输入 / 家长联系方式 / 备注。
//  录入后立即写入 SwiftData，并通过 SWAlertManager 弹 success toast。
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

    /// 表单是否可提交
    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && totalLessons > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - 基础信息
                Section {
                    TextField("学员姓名", text: $name)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("基础信息")
                }

                // MARK: - 课程类型
                Section {
                    // 5 个课程色 chip 横向铺开
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(CourseType.allCases, id: \.self) { course in
                                courseChip(course)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("课程类型")
                }

                // MARK: - 课时
                Section {
                    HStack {
                        Text("已购买课时")
                        Spacer()
                        SWStepper(quantity: $totalLessons)
                    }
                } header: {
                    Text("课时")
                }

                // MARK: - 联系方式 & 备注
                Section {
                    TextField("联系方式（X / 微信 / 邮箱，可选）", text: $parentContact)
                    TextField("备注（可选）", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("其他")
                }
            }
            .navigationTitle("新增学员")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSubmit)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - 课程 chip

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

    // MARK: - 保存

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

        SWAlertManager.shared.show(.success, message: "已添加 \(student.name)")
        isPresented = false
    }
}
