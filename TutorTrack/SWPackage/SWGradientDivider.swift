//
//  SWGradientDivider.swift
//  TutorTrack — ShipSwift Recipe: component-gradient-divider
//
//  Horizontal divider with a centered gradient (clear -> color -> clear).
//  Used in the weekly report PDF layout: a thin course-colored stroke keeps
//  the PDF from looking like a slab of flat rules.
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
