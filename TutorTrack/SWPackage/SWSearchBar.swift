//
//  SWSearchBar.swift
//  TutorTrack — ShipSwift Recipe: component-search-bar
//
//  Capsule-shaped search field with a .ultraThinMaterial frosted background
//  and an auto-appearing clear button. It does not add horizontal padding
//  itself — the caller must apply `.padding(.horizontal)`.
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
