//
//  WeeklyReportPDFView.swift
//  TutorTrack
//
//  Dedicated PDF rendering view (fed into SWExportShare.renderSinglePagePDF).
//
//  Strict A4 layout (595 x 842 pt):
//  - Top hero: student name + large week range + course badge
//  - SWGradientDivider (course-colored) as the separator
//  - Three-color attendance summary row
//  - Practice-highlights bullet list (SWBulletPointText)
//  - AI paragraph (rendered with SWMarkdownText)
//  - Footer decoration: TutorTrack brand + generation timestamp
//
//  Note: ImageRenderer-backed PDFs do not honor system-style colors like
//  `.red`, but they do support Color("XXX"). Every color here uses a
//  concrete Color value to avoid washed-out semi-transparent layers in the PDF.
//

import SwiftUI

struct WeeklyReportPDFView: View {
    let report: WeeklyReport

    private var courseColor: Color { report.courseType.color }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - Top hero
            hero
            SWGradientDivider(color: courseColor, opacity: 0.6, height: 2)
                .padding(.vertical, 4)

            // MARK: - Attendance summary
            attendanceSummary

            // MARK: - Practice highlights
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(icon: "checklist", text: "This Week's Practice Highlights")
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(report.practicedTopics.enumerated()), id: \.offset) { _, topic in
                        SWBulletPointText(bulletColor: courseColor) {
                            Text(topic)
                                .font(.system(size: 14))
                                .foregroundStyle(.black)
                        }
                    }
                }
                .padding(.leading, 4)
            }

            // MARK: - AI paragraph
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(icon: "sparkles", text: "AI Weekly Summary")
                SWMarkdownText(report.aiParagraph)
                    .foregroundStyle(.black)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(courseColor.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(courseColor.opacity(0.25), lineWidth: 0.8)
                    )
            }

            Spacer(minLength: 0)

            // MARK: - Footer
            footer
        }
        .padding(36) // 0.5-inch PDF margin
        .frame(width: SWExportShare.a4Size.width, height: SWExportShare.a4Size.height, alignment: .topLeading)
        .background(Color.white)
    }

    // MARK: - Subviews

    private var hero: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Student Weekly Report")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(courseColor)
                Text(report.studentName)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.black)
                HStack(spacing: 8) {
                    // Course badge
                    Text(report.courseType.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(courseColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(courseColor.opacity(0.15))
                        )
                    Text(report.weekRange)
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                }
            }
            Spacer()
            // Top-right course icon
            ZStack {
                Circle()
                    .fill(courseColor.opacity(0.18))
                    .frame(width: 64, height: 64)
                Image(systemName: report.courseType.iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(courseColor)
            }
        }
    }

    private var attendanceSummary: some View {
        HStack(spacing: 12) {
            statCard(
                value: report.attendedDays,
                label: "Present",
                color: Color(red: 0.20, green: 0.65, blue: 0.32) // PDF-friendly deep green
            )
            statCard(
                value: report.absentCount,
                label: "Absent",
                color: Color(red: 0.85, green: 0.25, blue: 0.25)
            )
            statCard(
                value: report.excusedCount,
                label: "Excused",
                color: Color(red: 0.55, green: 0.55, blue: 0.55)
            )
        }
    }

    private func statCard(value: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.25), lineWidth: 0.8)
        )
    }

    private func sectionTitle(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
            Text(text)
                .font(.system(size: 15, weight: .semibold))
        }
        .foregroundStyle(courseColor)
    }

    private var footer: some View {
        VStack(spacing: 4) {
            SWGradientDivider(color: courseColor, opacity: 0.4, height: 1)
            HStack {
                // "Generated by TutorTrack" footer label
                Text("Generated by TutorTrack · tutortrack.app")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
                Spacer()
                Text(report.generatedAt.formatted(.dateTime.year().month().day().hour().minute()))
                    .font(.system(size: 10))
                    .foregroundStyle(.gray)
            }
            .padding(.top, 4)
        }
    }
}
