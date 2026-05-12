//
//  SWTabButton.swift
//  TutorTrack — ShipSwift Recipe: component-tab-button
//
//  Capsule tab button. Selected state uses AccentColor; otherwise gray.
//  Used here as the check-in status switch (present / absent / excused).
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
