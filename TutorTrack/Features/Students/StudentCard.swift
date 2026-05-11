//
//  StudentCard.swift
//  TutorTrack
//
//  单张学员卡片：左侧课程色圆形头像（SF Symbol）+ 右侧姓名/课程徽章/剩余课时。
//  剩余 ≤ 3 节时整张卡的剩余课时数标红，引出"该续费了"的紧迫感。
//

import SwiftUI
import SwiftData

struct StudentCard: View {
    let student: Student

    var body: some View {
        HStack(spacing: 14) {
            // 头像：圆形课程色 + SF Symbol
            avatar

            VStack(alignment: .leading, spacing: 6) {
                // 姓名
                Text(student.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                // 课程类型徽章
                courseBadge

                // 剩余课时
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

    // MARK: - 子视图

    /// 圆形头像 = 课程色背景 + 课程 SF Symbol
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

    /// 课程徽章（胶囊形，课程色填充）
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
