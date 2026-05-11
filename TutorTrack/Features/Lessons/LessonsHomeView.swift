//
//  LessonsHomeView.swift
//  TutorTrack
//
//  「课时」Tab 主页：所有学员的课时进度一览。
//  按 remainingLessons 升序排，剩余少的排前面，制造"该续费了"的视觉冲击。
//  - 每行：大头像 + 姓名 + 课程徽章 + 大进度条 + 已上/总数文字
//  - 剩余 ≤ 3 节挂红色"续费提醒" SWStatusBadge
//  - 点行右下角「续费」按钮弹 RenewLessonsSheet（基于 .presentationDetents(.medium)）
//  - 点卡片其他区域 → NavigationLink 推 StudentDetailView
//

import SwiftUI
import SwiftData

struct LessonsHomeView: View {
    @Query private var allStudents: [Student]
    @Environment(\.modelContext) private var modelContext

    /// 续费 sheet 关联的学员（nil = 不弹）
    @State private var renewingStudent: Student?

    /// 按"剩余课时升序"排，相同剩余时按总课时升序，再退到姓名稳定
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

    /// 需要提醒续费的学员数（用于顶部 KPI）
    private var renewalCount: Int {
        students.filter(\.needsRenewal).count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // 顶部 KPI 卡（SWKPICard 风格）
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
        .navigationTitle("课时")
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

    // MARK: - 顶部 KPI

    private var kpiSection: some View {
        HStack(spacing: 10) {
            kpiCard(
                title: "总学员",
                value: "\(students.count)",
                color: Color("CoursePurple"),
                icon: "person.3.fill"
            )
            kpiCard(
                title: "待续费",
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

    // MARK: - 空态

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text("还没有学员")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("先到「学员」Tab 添加学员")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 课时进度行

/// 单条学员课时进度，可点击进详情；右下角「续费」按钮独立 action
private struct LessonProgressRow: View {
    let student: Student
    let onRenew: () -> Void

    var body: some View {
        // 卡片整体一个外壳，内部上半 NavigationLink、下半独立 Button 行
        // 这样避免 NavigationLink 和 Button 的 hit-test 冲突（iOS 16+ 常见陷阱）
        VStack(alignment: .leading, spacing: 12) {
            // 上半：可点击进详情（NavigationLink）
            NavigationLink(value: student) {
                upperPart
            }
            .buttonStyle(.plain)

            // 下半：剩余课时 + 续费按钮，独立 HStack，不在 NavigationLink 内
            HStack {
                Text("剩余 \(student.remainingLessons) 节")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.needsRenewal ? .red : .primary)

                Spacer()

                Button {
                    onRenew()
                } label: {
                    Label("续费", systemImage: "plus.circle.fill")
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

    /// 上半区：头像 + 姓名 + 进度条（整块作为 NavigationLink 触发区）
    private var upperPart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                avatar

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(student.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        // 课程色徽章（与 StudentCard 风格一致，不复用 SWStatusBadge——
                        // 后者只支持 5 种语义色，我们要的是 5 种课程色）
                        courseBadge
                    }

                    Text("\(student.attendedLessons) / \(student.totalLessons) 节")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 6)

                if student.needsRenewal {
                    SWStatusBadge(text: "续费提醒", style: .error)
                }
            }

            // 大进度条（课程色 tint）
            ProgressView(value: Double(student.attendedLessons),
                         total: Double(max(student.totalLessons, 1)))
                .tint(student.courseType.color)
                .frame(height: 8)
        }
        .contentShape(Rectangle()) // 整个上半区域作为 link 命中区
    }

    /// 圆形头像（与 StudentCard 一致风格）
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

    /// 课程徽章（胶囊形，课程色填充；与 StudentCard.courseBadge 同款）
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
