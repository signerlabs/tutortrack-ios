//
//  StudentDetailView.swift
//  TutorTrack
//
//  学员详情：头部卡（头像 + 姓名 + 课程徽章）+ 进度条（课程色 tint）+ 续费 Stepper
//  + 签到历史评语列表（SWBulletPointText 按课程色 bullet）+ 备注 / 联系方式。
//

import SwiftUI
import SwiftData

struct StudentDetailView: View {
    @Bindable var student: Student
    @Environment(\.modelContext) private var modelContext

    /// 按时间倒序的有评语的出勤记录（演示「签到历史评语」用）
    private var noteRecords: [AttendanceRecord] {
        student.attendances
            .filter { !$0.noteText.isEmpty }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // 头部
                header

                // 课时进度卡
                progressCard

                // 签到历史评语
                if !noteRecords.isEmpty {
                    notesCard
                }

                // 联系方式 + 备注
                infoCard
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color("WarmIvory").ignoresSafeArea())
        .navigationTitle(student.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - 头部卡

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(student.courseType.color.opacity(0.85))
                    .frame(width: 88, height: 88)
                Image(systemName: student.courseType.iconName)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(student.name)
                .font(.title2)
                .fontWeight(.bold)

            // 课程徽章
            Text(student.courseType.displayName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(student.courseType.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(student.courseType.color.opacity(0.18))
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    // MARK: - 进度卡

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("课时进度", systemImage: "graduationcap.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.courseType.color)
                Spacer()
                Text("\(student.attendedLessons) / \(student.totalLessons) 节")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // 原生进度条，按课程色 tint
            ProgressView(value: Double(student.attendedLessons),
                         total: Double(max(student.totalLessons, 1)))
                .tint(student.courseType.color)
                .frame(height: 10)

            HStack {
                Text("剩余 \(student.remainingLessons) 节")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.needsRenewal ? .red : .primary)

                if student.needsRenewal {
                    Text("· 建议续费")
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()

                // 续费 Stepper（SWStepper Recipe: component-stepper）
                HStack(spacing: 8) {
                    Text("续费")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    SWStepper(quantity: renewBinding)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(student.courseType.color.opacity(0.15), lineWidth: 1)
        )
    }

    /// SWStepper 通过递增递减 totalLessons 来模拟"续费"
    private var renewBinding: Binding<Int> {
        Binding(
            get: { student.totalLessons },
            set: { newValue in
                guard newValue > student.attendedLessons else { return }
                let delta = newValue - student.totalLessons
                student.totalLessons = newValue
                try? modelContext.save()
                if delta > 0 {
                    SWAlertManager.shared.show(.success, message: "+\(delta) 节")
                }
            }
        )
    }

    // MARK: - 签到历史评语

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("签到评语历史", systemImage: "text.bubble.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.courseType.color)
                Spacer()
                Text("\(noteRecords.count) 条")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(noteRecords.prefix(8)) { record in
                    // SWBulletPointText Recipe: component-bullet-point-text
                    SWBulletPointText(bulletColor: student.courseType.color) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(record.noteText)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(student.courseType.color.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - 联系方式 + 备注

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("家长信息", systemImage: "person.crop.rectangle.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(student.courseType.color)
                Spacer()
            }

            if !student.parentContact.isEmpty {
                row(icon: "phone.fill", text: student.parentContact)
            }
            if !student.notes.isEmpty {
                row(icon: "note.text", text: student.notes)
            }
            if student.parentContact.isEmpty && student.notes.isEmpty {
                Text("暂无家长联系方式 / 备注")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(student.courseType.color.opacity(0.15), lineWidth: 1)
        )
    }

    private func row(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 18)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}
