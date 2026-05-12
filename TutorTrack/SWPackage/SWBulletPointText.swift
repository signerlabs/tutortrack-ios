//
//  SWBulletPointText.swift
//  TutorTrack — ShipSwift Recipe: component-bullet-point-text
//
//  Prefixes text with a colored capsule bullet. This demo uses it for the
//  attendance-note history list on the student detail page; the bullet color
//  comes from the student's course color (pink / blue / purple / orange / green).
//

import SwiftUI

struct SWBulletPointText<Content: View>: View {
    var bulletColor: Color
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(bulletColor)
                .frame(width: 4, height: 12)

            content
                .font(.subheadline)
        }
    }
}
