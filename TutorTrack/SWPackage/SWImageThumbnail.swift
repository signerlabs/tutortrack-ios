//
//  SWImageThumbnail.swift
//  TutorTrack — ShipSwift Recipe: component-image-thumbnail
//
//  Rounded-square thumbnail with a same-name ColorSet as the automatic
//  background fallback. Student avatars in this demo have no real image — the
//  ColorSet match alone provides the solid background, with the SF Symbol
//  layered on top (see StudentCard.swift).
//

import SwiftUI

struct SWImageThumbnail: View {
    let imageName: String
    var size: CGFloat = 120
    var cornerRadius: CGFloat = 18

    var body: some View {
        Color(imageName)
            .overlay(
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            )
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 1)
            )
    }
}
