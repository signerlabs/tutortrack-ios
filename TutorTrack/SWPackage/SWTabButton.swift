//
//  SWTabButton.swift
//  TutorTrack — ShipSwift Recipe: component-tab-button
//
//  胶囊形 tab 按钮，selected 用 AccentColor，否则灰色。
//  本 demo 用作签到状态切换 chip（出勤 / 缺勤 / 请假）。
//

import SwiftUI

struct SWTabButton: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
