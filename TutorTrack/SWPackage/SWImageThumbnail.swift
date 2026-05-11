//
//  SWImageThumbnail.swift
//  TutorTrack — ShipSwift Recipe: component-image-thumbnail
//
//  圆角方形缩略图，自动 fallback 同名 ColorSet 作为底色。
//  本 demo 中学员头像没有真实图片，仅 ColorSet 命中即可显示纯色背景，
//  上层再叠 SF Symbol 即可（见 StudentCard.swift）。
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
