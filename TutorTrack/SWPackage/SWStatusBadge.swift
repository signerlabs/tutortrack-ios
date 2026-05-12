//
//  SWStatusBadge.swift
//  TutorTrack — ShipSwift Recipe: component-status-badge
//
//  Capsule status badge with 5 semantic presets (info / success / warning /
//  error / neutral). This demo also uses 5 course colors as a custom tint set
//  (pink / blue / purple / orange / green); those are applied separately via
//  a capsule wrapper around CourseType, leaving the recipe's semantic presets
//  untouched.
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
