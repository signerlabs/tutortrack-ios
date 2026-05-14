//
//  WeeklyReportHomeView.swift
//  TutorTrack
//
//  Weekly report tab home (**the hero screen for the demo video**).
//
//  Interaction flow:
//  1. Horizontal student chips at the top
//  2. Toggle between "This Week" and "Last Week"
//  3. Tap "Generate Weekly Report" -> full-screen SWPageLoadingView overlay
//     + SWThinkingIndicator
//     - Task.sleep(.seconds(1.5)) sells the "AI is thinking" feel; actual
//       local computation is < 5ms.
//  4. Render WeeklyReportPreviewCard after generation.
//  5. The bottom "Export & Share PDF" button:
//     - Calls SWExportShare.renderSinglePagePDF to rasterize WeeklyReportPDFView
//       into a single A4 page.
//     - ShareLink opens the system share sheet (Messages / email / print).
//

import SwiftUI
import SwiftData

struct WeeklyReportHomeView: View {
    @Query(sort: \Student.createdAt, order: .reverse) private var allStudents: [Student]

    /// Currently selected student
    @State private var focusedStudentID: UUID?
    /// This week / last week
    @State private var weekOffset: WeekOffset = .thisWeek
    /// Already-generated report (nil = not generated yet or inputs changed)
    @State private var currentReport: WeeklyReport?
    /// Generated PDF URL (only set after PDF export)
    @State private var pdfURL: URL?
    /// Currently generating?
    @State private var isGenerating: Bool = false

    enum WeekOffset: String, CaseIterable, Identifiable {
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
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
                    // Top: student chips
                    studentChips

                    // Week toggle
                    weekToggle
                        .padding(.horizontal)

                    // Generate button (hidden once generated; "Regenerate" brings it back)
                    if currentReport == nil {
                        if isGenerating {
                            // Generating: show SWThinkingIndicator + caption in
                            // the same slot. SWPageLoadingView is overlaid on
                            // top — together they sell the "AI thinking" feel.
                            thinkingPlaceholder
                                .padding(.horizontal)
                                .padding(.top, 8)
                        } else {
                            generateButton
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                    } else if let report = currentReport {
                        // Report preview
                        WeeklyReportPreviewCard(report: report)
                            .padding(.horizontal)

                        // Bottom action area
                        actionButtons(for: report)
                            .padding(.horizontal)
                            .padding(.top, 4)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color("WarmIvory").ignoresSafeArea())
        .navigationTitle("AI Weekly Report")
        .swPageLoading(.weeklyReport)  // Full-screen loading overlay
        .onAppear {
            if focusedStudentID == nil {
                focusedStudentID = allStudents.first?.id
            }
        }
        // Any input change invalidates the current preview, forcing the user to regenerate.
        .onChange(of: focusedStudentID) { _, _ in resetReport() }
        .onChange(of: weekOffset) { _, _ in resetReport() }
    }

    // MARK: - Subviews

    private var studentChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a Student")
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

    /// Placeholder card while generating (SWThinkingIndicator Recipe: component-thinking-indicator)
    private var thinkingPlaceholder: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(Color("CoursePurple"))
                    .symbolEffect(.pulse, options: .repeating)
                Text("AI is analyzing this week's performance")
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
                Text("Generate AI Weekly Report")
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
            // Row 1: regenerate + export PDF
            HStack(spacing: 10) {
                Button {
                    resetReport()
                } label: {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    exportPDF(for: report)
                } label: {
                    Label("Export PDF", systemImage: "doc.richtext")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(report.courseType.color)
            }

            // Row 2: once the PDF is generated, surface the share link
            if let pdfURL {
                ShareLink(
                    item: pdfURL,
                    preview: SharePreview("\(report.studentName)-\(report.weekRange).pdf")
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Share Weekly Report PDF")
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
            Text("No students yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add a student from the Students tab before generating a report")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
    }

    // MARK: - Actions

    private func resetReport() {
        currentReport = nil
        pdfURL = nil
    }

    /// Generate the weekly report. The demo sleeps for 1.5s to sell the
    /// "AI is working" feel; the real Engine.generate is pure local
    /// computation that takes < 5ms.
    private func generate() {
        guard let student = focusedStudent else { return }
        guard !isGenerating else { return }

        isGenerating = true
        SWLoadingManager.shared.show(
            page: .weeklyReport,
            message: "AI is analyzing this week's performance…",
            systemImage: "sparkles"
        )

        Task { @MainActor in
            // Demo-only sleep so LoadingView + ThinkingIndicator are visible.
            // The real generate() is synchronous and finishes in < 5ms
            // (deterministic LCG + string composition).
            try? await Task.sleep(for: .seconds(1.5))

            let report = WeeklyReportEngine.generate(for: student, weekOf: weekOffset.dateAnchor)
            currentReport = report
            pdfURL = nil  // Reset the PDF
            isGenerating = false
            SWLoadingManager.shared.hide(page: .weeklyReport)
        }
    }

    /// Export the PDF (ImageRenderer + PDFKit, zero network)
    private func exportPDF(for report: WeeklyReport) {
        let fileName = "\(report.studentName)-WeeklyReport-\(report.weekRange.replacingOccurrences(of: " ", with: ""))"
        do {
            let url = try SWExportShare.renderSinglePagePDF(
                view: WeeklyReportPDFView(report: report),
                fileName: fileName,
                title: "\(report.studentName) Weekly Report \(report.weekRange)",
                author: "TutorTrack"
            )
            pdfURL = url
            SWAlertManager.shared.show(.success, message: "PDF generated — share via the button below")
        } catch {
            SWAlertManager.shared.show(.error, message: "PDF generation failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Report preview card

/// On-screen report preview (different from the PDF layout — tighter, and
/// rendered onto a systemBackground card).
private struct WeeklyReportPreviewCard: View {
    let report: WeeklyReport

    private var courseColor: Color { report.courseType.color }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Student Weekly Report")
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

            // Attendance KPI row
            HStack(spacing: 10) {
                kpiBlock(value: report.attendedDays, label: "Present", color: .green)
                kpiBlock(value: report.absentCount, label: "Absent", color: .red)
                kpiBlock(value: report.excusedCount, label: "Excused", color: .gray)
            }

            // Practice highlights
            VStack(alignment: .leading, spacing: 8) {
                Label("This Week's Practice Highlights", systemImage: "checklist")
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

            // AI paragraph
            VStack(alignment: .leading, spacing: 8) {
                Label("AI Weekly Summary", systemImage: "sparkles")
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
