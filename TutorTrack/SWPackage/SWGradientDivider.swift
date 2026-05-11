//
//  SWGradientDivider.swift
//  TutorTrack — ShipSwift Recipe: component-gradient-divider
//
//  水平分割线，中间渐显（clear → color → clear）。本 demo 用于周报 PDF 内排版，
//  按课程色绘细线，让 PDF 不再是死板等高线条。
//

import SwiftUI

struct SWGradientDivider: View {
    var color: Color = .cyan
    var opacity: Double = 0.3
    var height: CGFloat = 1

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, color.opacity(opacity), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
    }
}
