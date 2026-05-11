//
//  SWSearchBar.swift
//  TutorTrack — ShipSwift Recipe: component-search-bar
//
//  胶囊形搜索栏，带 .ultraThinMaterial 磨砂背景 + 自动出现的 clear 按钮。
//  外层不自动加 horizontal padding，调用方需 `.padding(.horizontal)`。
//

import SwiftUI

struct SWSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 14))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: .capsule)
    }
}
