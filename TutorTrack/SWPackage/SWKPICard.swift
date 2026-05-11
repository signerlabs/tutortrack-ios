//
//  SWKPICard.swift
//  TutorTrack — ShipSwift Recipe: component-kpi-card
//
//  Dashboard KPI 卡片：图标 + 标题 + 数值（numericText 动画）+ 自定义 trailing slot。
//  含配套 SWKPIDeltaTag（同环比百分比指示器）。
//

import SwiftUI

// MARK: - SWKPICard

struct SWKPICard<Trailing: View>: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let tint: Color
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: LocalizedStringKey,
        value: String,
        icon: String,
        tint: Color,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.tint = tint
        self.trailing = trailing
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(tint)
                .contentTransition(.numericText())

            trailing()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.swSystemBackground)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(tint.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Convenience Initializer (No Trailing)

extension SWKPICard where Trailing == EmptyView {
    init(
        title: LocalizedStringKey,
        value: String,
        icon: String,
        tint: Color
    ) {
        self.init(title: title, value: value, icon: icon, tint: tint) {
            EmptyView()
        }
    }
}

// MARK: - SWKPIDeltaTag

struct SWKPIDeltaTag: View {
    let delta: Double?
    var comparisonLabel: LocalizedStringKey = "vs yesterday"
    var upColor: Color = .green
    var downColor: Color = .red
    var emptyLabel: LocalizedStringKey = "No data"

    var body: some View {
        if let delta {
            let isUp = delta >= 0
            HStack(spacing: 4) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                Text("\(isUp ? "+" : "")\(delta, specifier: "%.1f")% \(Text(comparisonLabel))")
            }
            .font(.caption2)
            .foregroundStyle(isUp ? upColor : downColor)
        } else {
            Text(emptyLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Cross-platform System Background

private extension Color {
    static var swSystemBackground: Color {
        #if os(iOS)
        Color(.systemBackground)
        #else
        Color(.windowBackgroundColor)
        #endif
    }
}
