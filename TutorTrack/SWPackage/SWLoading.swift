//
//  SWLoading.swift
//  TutorTrack — ShipSwift Recipe: component-loading (Page Loading Overlay)
//
//  Full-screen page-loading overlay (.ultraThinMaterial background + pulsing
//  icon animation + progress bar). Used as the 1.5-second "AI is thinking"
//  overlay while the weekly report is being generated.
//

import SwiftUI

// MARK: - Page Loading State

struct SWPageLoadingState {
    var isShowing: Bool = false
    var message: String = "Loading..."
    var systemImage: String? = nil
}

// MARK: - Page Identifier

/// Loading pages registered in this demo: just the weekly-report page
enum SWLoadingPage: String {
    case weeklyReport
}

// MARK: - SWLoadingManager

@MainActor
@Observable
final class SWLoadingManager {
    static let shared = SWLoadingManager()

    private var pageStates: [SWLoadingPage: SWPageLoadingState] = [:]

    private init() {}

    func show(page: SWLoadingPage, message: String = "Loading...", systemImage: String? = nil) {
        pageStates[page] = SWPageLoadingState(isShowing: true, message: message, systemImage: systemImage)
    }

    func updateMessage(page: SWLoadingPage, message: String) {
        pageStates[page]?.message = message
    }

    func hide(page: SWLoadingPage) {
        pageStates[page]?.isShowing = false
    }

    func state(for page: SWLoadingPage) -> SWPageLoadingState {
        pageStates[page] ?? SWPageLoadingState()
    }
}

// MARK: - Page Loading View

struct SWPageLoadingView: View {
    let page: SWLoadingPage

    private var state: SWPageLoadingState {
        SWLoadingManager.shared.state(for: page)
    }

    var body: some View {
        if state.isShowing {
            VStack(spacing: 24) {
                if let systemImage = state.systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(.primary.opacity(0.8))
                        .symbolEffect(.pulse, options: .repeating)
                }

                VStack(spacing: 12) {
                    Text(state.message)
                        .font(.headline)
                        .foregroundStyle(.primary.opacity(0.9))
                        .multilineTextAlignment(.center)

                    ProgressView()
                        .tint(.primary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.ultraThinMaterial)
            .ignoresSafeArea(.all)
            .transition(.opacity)
        }
    }
}

// MARK: - View Modifier

private struct SWPageLoadingModifier: ViewModifier {
    let page: SWLoadingPage

    private var state: SWPageLoadingState {
        SWLoadingManager.shared.state(for: page)
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                SWPageLoadingView(page: page)
            }
            .animation(.easeInOut(duration: 0.25), value: state.isShowing)
    }
}

extension View {
    func swPageLoading(_ page: SWLoadingPage) -> some View {
        modifier(SWPageLoadingModifier(page: page))
    }
}
