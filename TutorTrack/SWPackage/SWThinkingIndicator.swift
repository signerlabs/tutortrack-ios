//
//  SWThinkingIndicator.swift
//  TutorTrack — ShipSwift Recipe: component-thinking-indicator
//
//  Three-dot bouncing "AI is thinking" indicator. Used in WeeklyReportHomeView
//  alongside SWPageLoadingView during weekly report generation.
//

import SwiftUI

struct SWThinkingIndicator: View {
    var dotSize: CGFloat = 5
    var dotColor: Color = .secondary
    var spacing: CGFloat = 3

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.3)) { timeline in
            let phase = Int(timeline.date.timeIntervalSinceReferenceDate / 0.3) % 3
            HStack(spacing: spacing) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(dotColor)
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: phase == index ? -(dotSize * 0.6) : 0)
                        .animation(.easeInOut(duration: 0.2), value: phase)
                }
            }
        }
    }
}
