//
//  SWStatusBadge.swift
//  TutorTrack — ShipSwift Recipe: component-status-badge
//
//  胶囊状态徽章，5 种语义预设（info / success / warning / error / neutral）。
//  本 demo 用 5 种课程色（钢琴粉 / 英语蓝 / 编程紫 / 数学橙 / 美术绿）作为另一套自定义 tint，
//  通过 CourseType.badge(view) 包一层 capsule 实现，本组件保留原版语义预设不动。
//

import SwiftUI

// MARK: - SWStatusBadgeStyle

enum SWStatusBadgeStyle: CaseIterable {
    case info
    case success
    case warning
    case error
    case neutral

    var tint: Color {
        switch self {
        case .info:    .blue
        case .success: .green
        case .warning: .orange
        case .error:   .red
        case .neutral: .secondary
        }
    }

    var backgroundOpacity: Double {
        switch self {
        case .success: 0.20
        default:       0.18
        }
    }
}

// MARK: - SWStatusBadge

struct SWStatusBadge: View {
    let text: LocalizedStringKey
    let style: SWStatusBadgeStyle

    init(text: LocalizedStringKey, style: SWStatusBadgeStyle) {
        self.text = text
        self.style = style
    }

    init(text: String, style: SWStatusBadgeStyle) {
        self.text = LocalizedStringKey(text)
        self.style = style
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(style.tint)
            .background(
                Capsule().fill(style.tint.opacity(style.backgroundOpacity))
            )
            .overlay(
                Capsule().stroke(style.tint.opacity(0.35), lineWidth: 0.5)
            )
    }
}
