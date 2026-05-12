//
//  SWRootTabView.swift
//  TutorTrack — ShipSwift Recipe: component-root-tab-view
//
//  Root TabView template (iOS 18+ Tab API). This demo derives its own
//  RootTabView from it (see App/RootTabView.swift).
//

import SwiftUI

struct SWRootTabView: View {
    @State private var selectedTab = "home"
    @State private var searchText = ""

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: "home") {
                NavigationStack {
                    ScrollView {
                        ContentUnavailableView("Home", systemImage: "house.fill", description: Text("Your main feed and dashboard content goes here."))
                            .containerRelativeFrame(.vertical)
                    }
                    .navigationTitle("Home")
                }
            } label: {
                Label {
                    Text("Home")
                } icon: {
                    Image(systemName: selectedTab == "home" ? "house.fill" : "house")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "outfit") {
                NavigationStack {
                    ScrollView {
                        ContentUnavailableView("Outfit", systemImage: "tshirt.fill", description: Text("Browse and manage your outfit collections here."))
                            .containerRelativeFrame(.vertical)
                    }
                    .navigationTitle("Outfit")
                }
            } label: {
                Label {
                    Text("Outfit")
                } icon: {
                    Image(systemName: selectedTab == "outfit" ? "tshirt.fill" : "tshirt")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "setting") {
                NavigationStack {
                    ScrollView {
                        ContentUnavailableView("Settings", systemImage: "gearshape.fill", description: Text("Adjust preferences, account, and app configuration."))
                            .containerRelativeFrame(.vertical)
                    }
                    .navigationTitle("Setting")
                }
            } label: {
                Label {
                    Text("Setting")
                } icon: {
                    Image(systemName: selectedTab == "setting" ? "gearshape.fill" : "gearshape")
                }
                .environment(\.symbolVariants, .none)
            }

            Tab(value: "search") {
                NavigationStack {
                    ScrollView {
                        ContentUnavailableView.search(text: searchText)
                    }
                    .navigationTitle("Search")
                }
                .searchable(text: $searchText, prompt: "Search...")
            } label: {
                Label {
                    Text("Search")
                } icon: {
                    Image(systemName: "magnifyingglass")
                }
                .environment(\.symbolVariants, .none)
            }
        }
        .sensoryFeedback(.increase, trigger: selectedTab)
    }
}
