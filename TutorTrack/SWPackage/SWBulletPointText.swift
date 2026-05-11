//
//  SWBulletPointText.swift
//  TutorTrack — ShipSwift Recipe: component-bullet-point-text
//
//  文本前加彩色胶囊条 bullet。本 demo 用于学员详情页的签到评语历史列表，
//  bullet 颜色取课程色（钢琴粉 / 英语蓝 / 编程紫 / 数学橙 / 美术绿）。
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
