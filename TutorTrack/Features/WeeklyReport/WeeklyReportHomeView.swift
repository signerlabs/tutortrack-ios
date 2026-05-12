//
//  WeeklyReportHomeView.swift
//  TutorTrack
//
//  「周报」Tab 主页（**录屏 hero 画面**）。
//
//  交互流：
//  1. 顶部横滚 chips 选学员
//  2. 切换"本周 / 上周"
//  3. 点「生成周报」按钮 → SWPageLoadingView 全屏遮罩 + SWThinkingIndicator
//     - Task.sleep(.seconds(1.5))（演示用，制造 AI 感；实际本地计算 < 5ms）
//  4. 生成后展示 WeeklyReportPreviewCard
//  5. 底部「导出 PDF 分享」按钮：
//     - 调 SWExportShare.renderSinglePagePDF 把 WeeklyReportPDFView 渲成 A4 PDF
//     - ShareLink 弹系统 ShareSheet（可分享给家长微信 / 邮件 / 打印）
//

import SwiftUI
import SwiftData

struct WeeklyReportHomeView: View {
    @Query(sort: \Student.createdAt, order: .reverse) private var allStudents: [Student]

    /// 当前选中学员
    @State private var focusedStudentID: UUID?
    /// 本周 / 上周
    @State private var weekOffset: WeekOffset = .thisWeek
    /// 已生成的报告（nil = 未生成或重选了）
    @State private var currentReport: WeeklyReport?
    /// 已生成的 PDF URL（生成 PDF 后才有）
    @State private var pdfURL: URL?
    /// 正在生成中？
    @State private var isGenerating: Bool = false

    enum WeekOffset: String, CaseIterable, Identifiable {
        case thisWeek = "本周"
        case lastWeek = "上周"
        var id: String { rawValue }

        var dateAnchor: Date {
            let cal = Calendar.current
            switch self {
            case .thisWeek: return Date()
            case .lastWeek: return cal.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            }
        }
    }

    private var focusedStudent: Student? {
        guard let id = focusedStudentID else { return allStudents.first }
        return allStudents.first { $0.id == id } ?? allStudents.first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if allStudents.isEmpty {
                    emptyState
                        .padding(.top, 80)
                } else {
                    // 顶部：学员 chips
                    studentChips

                    // 周次切换
                    weekToggle
                        .padding(.horizontal)

                    // 生成按钮（已生成过则隐藏；点击"重新生成"会回到这个按钮）
                    if currentReport == nil {
                        if isGenerating {
                            // 生成中：原位置展示 SWThinkingIndicator + 提示文字
                            // （SWPageLoadingView 同时全屏覆盖，二者协同"AI 思考"语义）
                            thinkingPlaceholder
                                .padding(.horizontal)
                                .padding(.top, 8)
                        } else {
                            generateButton
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                    } else if let report = currentReport {
                        // 报告预览
                        WeeklyReportPreviewCard(report: report)
                            .padding(.horizontal)

                        // 底部操作区
                        actionButtons(for: report)
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color("WarmIvory").ignoresSafeArea())
        .navigationTitle("AI 周报")
        .swPageLoading(.weeklyReport)  // 全屏 loading 遮罩
        .onAppear {
            if focusedStudentID == nil {
                focusedStudentID = allStudents.first?.id
            }
        }
        // 任意输入变化都失效当前预览，强制用户重新点"生成"
        .onChange(of: focusedStudentID) { _, _ in resetReport() }
        .onChange(of: weekOffset) { _, _ in resetReport() }
    }

    // MARK: - 子视图

    private var studentChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("选择学员")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allStudents) { student in
                        let isSelected = student.id == focusedStudentID
                        Button {
                            focusedStudentID = student.id
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: student.courseType.iconName)
                                    .font(.caption)
                                Text(student.name)
                                    .font(.subheadline)
                                    .fontWeight(isSelected ? .semibold : .regular)
                            }
                            .foregroundStyle(isSelected ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(isSelected
                                    ? student.courseType.color
                                    : Color.secondary.opacity(0.15))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var weekToggle: some View {
        HStack(spacing: 10) {
            ForEach(WeekOffset.allCases) { w in
                SWTabButton(
                    title: LocalizedStringKey(w.rawValue),
                    isSelected: weekOffset == w
                ) {
                    weekOffset = w
                }
            }
            Spacer()
            Text(weekOffset.dateAnchor.weekRangeDisplay)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// 生成中占位卡（SWThinkingIndicator Recipe: component-thinking-indicator）
    private var thinkingPlaceholder: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(Color("CoursePurple"))
                    .symbolEffect(.pulse, options: .repeating)
                Text("AI 正在分析本周表现")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                SWThinkingIndicator(dotSize: 4, dotColor: Color("CoursePurple"))
                    .padding(.leading, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color("CoursePurple").opacity(0.2), lineWidth: 1)
        )
    }

    private var generateButton: some View {
        Button {
            generate()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("生成 AI 周报")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [Color("CoursePink"), Color("CoursePurple")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(focusedStudent == nil || isGenerating)
    }

    private func actionButtons(for report: WeeklyReport) -> some View {
        VStack(spacing: 10) {
            // 第一行：重新生成 + 导出 PDF
            HStack(spacing: 10) {
                Button {
                    resetReport()
                } label: {
                    Label("重新生成", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    exportPDF(for: report)
                } label: {
                    Label("生成 PDF", systemImage: "doc.richtext")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(report.courseType.color)
            }

            // 第二行：PDF 生成完成后展示分享 link
            if let pdfURL {
                ShareLink(
                    item: pdfURL,
                    preview: SharePreview("\(report.studentName)-\(report.weekRange).pdf")
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("分享周报 PDF")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(Color.green.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.secondary)
            Text("还没有学员")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("先到「学员」Tab 添加学员，才能生成周报")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
    }

    // MARK: - 操作

    private func resetReport() {
        currentReport = nil
        pdfURL = nil
    }

    /// 生成周报：演示用 1.5s sleep 制造"AI 感"
    /// 实际 Engine.generate 是纯本地计算，耗时 < 5ms
    private func generate() {
        guard let student = focusedStudent else { return }
        guard !isGenerating else { return }

        isGenerating = true
        SWLoadingManager.shared.show(
            page: .weeklyReport,
            message: "AI 正在分析本周表现…",
            systemImage: "sparkles"
        )

        Task { @MainActor in
            // 演示用 sleep，让 LoadingView + ThinkingIndicator 露脸
            // 实际 generate() 是同步函数，耗时 < 5ms（deterministic LCG + 字符串拼接）
            try? await Task.sleep(for: .seconds(1.5))

            let report = WeeklyReportEngine.generate(for: student, weekOf: weekOffset.dateAnchor)
            currentReport = report
            pdfURL = nil  // 重置 PDF
            isGenerating = false
            SWLoadingManager.shared.hide(page: .weeklyReport)
        }
    }

    /// 导出 PDF（ImageRenderer + PDFKit，零网络）
    private func exportPDF(for report: WeeklyReport) {
        let fileName = "\(report.studentName)-周报-\(report.weekRange.replacingOccurrences(of: " ", with: ""))"
        do {
            let url = try SWExportShare.renderSinglePagePDF(
                view: WeeklyReportPDFView(report: report),
                fileName: fileName,
                title: "\(report.studentName) 学员周报 \(report.weekRange)",
                author: "TutorTrack"
            )
            pdfURL = url
            SWAlertManager.shared.show(.success, message: "PDF 已生成，下方可分享")
        } catch {
            SWAlertManager.shared.show(.error, message: "PDF 生成失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - 报告预览卡

/// 在屏上显示的报告预览（与 PDF 排版有差异：屏幕更紧凑、用 systemBackground 卡片）
private struct WeeklyReportPreviewCard: View {
    let report: WeeklyReport

    private var courseColor: Color { report.courseType.color }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 头部
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("学员周报")
                        .font(.caption)
                        .foregroundStyle(courseColor)
                    Text(report.studentName)
                        .font(.title2)
                        .fontWeight(.bold)
                    HStack(spacing: 8) {
                        Text(report.courseType.displayName)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(courseColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(courseColor.opacity(0.18)))
                        Text(report.weekRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(courseColor.opacity(0.18))
                        .frame(width: 52, height: 52)
                    Image(systemName: report.courseType.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(courseColor)
                }
            }

            SWGradientDivider(color: courseColor, opacity: 0.5)

            // 出勤汇总 KPI
            HStack(spacing: 10) {
                kpiBlock(value: report.attendedDays, label: "出勤", color: .green)
                kpiBlock(value: report.absentCount, label: "缺勤", color: .red)
                kpiBlock(value: report.excusedCount, label: "请假", color: .gray)
            }

            // 练习要点
            VStack(alignment: .leading, spacing: 8) {
                Label("本周练习要点", systemImage: "checklist")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(courseColor)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(report.practicedTopics.enumerated()), id: \.offset) { _, topic in
                        SWBulletPointText(bulletColor: courseColor) {
                            Text(topic)
                                .font(.subheadline)
                        }
                    }
                }
            }

            // AI 段落
            VStack(alignment: .leading, spacing: 8) {
                Label("AI 周度总结", systemImage: "sparkles")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(courseColor)

                SWMarkdownText(report.aiParagraph)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(courseColor.opacity(0.08))
                    )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(courseColor.opacity(0.2), lineWidth: 1)
        )
    }

    private func kpiBlock(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
    }
}
