//
//  SWAlert.swift
//  TutorTrack — ShipSwift Recipe: component-alert
//
//  全局 toast 风格 alert，4 种语义预设（info / success / warning / error）+ 自定义样式 + 自动消失。
//  通过 `.swAlert()` modifier 挂在 App 根视图，使用 `SWAlertManager.shared.show(...)` 调起。
//

import SwiftUI

// MARK: - SWAlertType

enum SWAlertType {
    case info
    case success
    case warning
    case error

    var icon: String {
        switch self {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.circle.fill"
        }
    }

    var textColor: Color {
        switch self {
        case .info: .primary
        case .success: .green
        case .warning: .orange
        case .error: .red
        }
    }

    var backgroundStyle: AnyShapeStyle {
        AnyShapeStyle(.ultraThinMaterial)
    }

    var borderColor: Color {
        switch self {
        case .info: .secondary.opacity(0.6)
        case .success: .green.opacity(0.6)
        case .warning: .orange.opacity(0.6)
        case .error: .red.opacity(0.6)
        }
    }
}

// MARK: - SWAlertManager

@MainActor
@Observable
final class SWAlertManager {
    static let shared = SWAlertManager()

    private(set) var isShowing = false
    private(set) var icon = SWAlertType.info.icon
    private(set) var message: LocalizedStringKey = ""
    private(set) var textColor = SWAlertType.info.textColor
    private(set) var backgroundStyle = SWAlertType.info.backgroundStyle
    private(set) var borderColor = SWAlertType.info.borderColor

    private var dismissTask: Task<Void, Never>?

    private init() {}

    func show(_ type: SWAlertType, message: LocalizedStringKey, duration: Duration = .seconds(2)) {
        showInternal(
            icon: type.icon,
            message: message,
            textColor: type.textColor,
            backgroundStyle: type.backgroundStyle,
            borderColor: type.borderColor,
            duration: duration
        )
    }

    func show(
        icon: String,
        message: LocalizedStringKey,
        textColor: Color = .white,
        backgroundStyle: AnyShapeStyle = AnyShapeStyle(.black),
        borderColor: Color = .secondary,
        duration: Duration = .seconds(2)
    ) {
        showInternal(
            icon: icon,
            message: message,
            textColor: textColor,
            backgroundStyle: backgroundStyle,
            borderColor: borderColor,
            duration: duration
        )
    }

    func show(_ type: SWAlertType, message: String, duration: Duration = .seconds(2)) {
        showInternal(
            icon: type.icon,
            message: LocalizedStringKey(message),
            textColor: type.textColor,
            backgroundStyle: type.backgroundStyle,
            borderColor: type.borderColor,
            duration: duration
        )
    }

    func show(
        icon: String,
        message: String,
        textColor: Color = .white,
        backgroundStyle: AnyShapeStyle = AnyShapeStyle(.black),
        borderColor: Color = .secondary,
        duration: Duration = .seconds(2)
    ) {
        showInternal(
            icon: icon,
            message: LocalizedStringKey(message),
            textColor: textColor,
            backgroundStyle: backgroundStyle,
            borderColor: borderColor,
            duration: duration
        )
    }

    private func showInternal(
        icon: String,
        message: LocalizedStringKey,
        textColor: Color,
        backgroundStyle: AnyShapeStyle,
        borderColor: Color,
        duration: Duration
    ) {
        dismissTask?.cancel()

        self.icon = icon
        self.message = message
        self.textColor = textColor
        self.backgroundStyle = backgroundStyle
        self.borderColor = borderColor

        withAnimation { isShowing = true }

        dismissTask = Task {
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            withAnimation { isShowing = false }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        withAnimation { isShowing = false }
    }
}

// MARK: - Alert View

private struct SWAlertView: View {
    let alertManager = SWAlertManager.shared

    var body: some View {
        if alertManager.isShowing {
            HStack(spacing: 6) {
                Image(systemName: alertManager.icon)
                    .font(.footnote)
                Text(alertManager.message)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(alertManager.textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                Capsule()
                    .fill(alertManager.backgroundStyle)
                    .strokeBorder(alertManager.borderColor, lineWidth: 0.5)
            }
            .transition(.scale.combined(with: .opacity))
            .onTapGesture { alertManager.dismiss() }
        }
    }
}

// MARK: - View Modifier

private struct SWAlertModifier: ViewModifier {
    let alertManager = SWAlertManager.shared

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                SWAlertView()
                    .padding(.top, 40)
            }
            .animation(.spring(duration: 0.3), value: alertManager.isShowing)
    }
}

extension View {
    func swAlert() -> some View {
        modifier(SWAlertModifier())
    }
}
