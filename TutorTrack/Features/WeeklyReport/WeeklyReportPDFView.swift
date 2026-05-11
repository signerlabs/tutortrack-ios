//
//  WeeklyReportPDFView.swift
//  TutorTrack
//
//  PDF 渲染专用 View（喂给 SWExportShare.renderSinglePagePDF）。
//
//  严格按 A4（595 × 842 pt）排版：
//  - 顶部 hero：学员名 + 周次大字 + 课程徽章
//  - SWGradientDivider（课程色）作分隔
//  - 出勤汇总三色统计行
//  - 练习要点 bullet 列表（SWBulletPointText）
//  - AI 段落（SWMarkdownText 渲染）
//  - 底部装饰：TutorTrack 品牌 + 生成时间
//
//  注意：PDF 用 ImageRenderer 渲染，不支持系统色（如 .red），但支持 Color("XXX")。
//  这里所有颜色都用具体 Color 实例，避免半透明叠加层在 PDF 里失真。
//

import SwiftUI

struct WeeklyReportPDFView: View {
    let report: WeeklyReport

    private var courseColor: Color { report.courseType.color }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // MARK: - 顶部 hero
            hero
            SWGradientDivider(color: courseColor, opacity: 0.6, height: 2)
                .padding(.vertical, 4)

            // MARK: - 出勤汇总
            attendanceSummary

            // MARK: - 本周练习要点
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(icon: "checklist", text: "本周练习要点")
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

            // MARK: - AI 段落
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(icon: "sparkles", text: "AI 周度总结")
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

            // MARK: - 页脚
            footer
        }
        .padding(36) // PDF 内边距 0.5 inch
        .frame(width: SWExportShare.a4Size.width, height: SWExportShare.a4Size.height, alignment: .topLeading)
        .background(Color.white)
    }

    // MARK: - 子视图

    private var hero: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("家长周报")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(courseColor)
                Text(report.studentName)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.black)
                HStack(spacing: 8) {
                    // 课程徽章
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
            // 右上角课程图标
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
                label: "出勤",
                color: Color(red: 0.20, green: 0.65, blue: 0.32) // 深绿，PDF 友好
            )
            statCard(
                value: report.absentCount,
                label: "缺勤",
                color: Color(red: 0.85, green: 0.25, blue: 0.25)
            )
            statCard(
                value: report.excusedCount,
                label: "请假",
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
                Text("由 TutorTrack 生成 · tutortrack.app")
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
