//
//  RenewLessonsSheet.swift
//  TutorTrack
//
//  续费 bottom sheet（基于 .presentationDetents(.medium)，与 SWAddSheet 同款交互骨架）。
//  - SWStepper 调整本次新增节数（默认 +10，下限 1）
//  - 确认后 student.totalLessons += addedLessons，try modelContext.save()
//  - SWAlertManager 弹 success toast 反馈
//

import SwiftUI
import SwiftData

struct RenewLessonsSheet: View {
    @Bindable var student: Student
    @Environment(\.modelContext) private var modelContext

    /// 关闭 sheet 的回调（外部 @State = nil）
    let onClose: () -> Void

    /// 本次要新增的节数（默认 10）
    @State private var addLessons: Int = 10

    /// SWStepper 用的 binding，下限钳到 1（不允许续费 0 节或负数）
    private var addBinding: Binding<Int> {
        Binding(
            get: { addLessons },
            set: { addLessons = max(1, min(99, $0)) }
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            // 顶部标题
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(student.courseType.color.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(student.courseType.color)
                }
                Text("为 \(student.name) 续费")
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

            // 当前状态摘要
            HStack(spacing: 16) {
                summaryCell(label: "已上", value: "\(student.attendedLessons)")
                Divider().frame(height: 28)
                summaryCell(label: "总计", value: "\(student.totalLessons)")
                Divider().frame(height: 28)
                summaryCell(label: "剩余", value: "\(student.remainingLessons)",
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

            // 续费数量行（SWStepper Recipe: component-stepper）
            HStack {
                Text("本次续费")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                SWStepper(quantity: addBinding)
                Text("节")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 4)

            // 续费后新状态预览
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.caption)
                    .foregroundStyle(student.courseType.color)
                Text("续费后共 \(student.totalLessons + addLessons) 节，剩余 \(student.remainingLessons + addLessons) 节")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            // 按钮组（与 SWAddSheet 一致风格）
            HStack(spacing: 10) {
                Button {
                    onClose()
                } label: {
                    Text("取消")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    confirmRenew()
                } label: {
                    Text("确认续费 +\(addLessons) 节")
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

    // MARK: - 子视图

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

    // MARK: - 提交

    private func confirmRenew() {
        let added = addLessons
        student.totalLessons += added
        do {
            try modelContext.save()
            SWAlertManager.shared.show(.success, message: "续费成功，新增 \(added) 节")
        } catch {
            SWAlertManager.shared.show(.error, message: "保存失败：\(error.localizedDescription)")
        }
        onClose()
    }
}
