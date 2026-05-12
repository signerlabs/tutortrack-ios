//
//  RootTabView.swift
//  TutorTrack
//
//  Main 4-tab shell based on the SWRootTabView template
//  (ShipSwift Recipe: component-root-tab-view). Each tab points to the
//  Home view of one Features sub-module.
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    /// Persist the selected tab so users do not lose their position when switching back.
    @AppStorage("selectedTab") private var selectedTab: String = "students"

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - Students
            Tab(value: "students") {
                NavigationStack {
                    StudentsHomeView()
                }
            } label: {
                Label {
                    Text("学员")
                } icon: {
                    Image(systemName: selectedTab == "students" ? "person.3.fill" : "person.3")
                }
                .environment(\.symbolVariants, .none)
            }

            // MARK: - Lessons
            Tab(value: "lessons") {
                NavigationStack {
                    LessonsHomeView()
                }
            } label: {
                Label {
                    Text("课时")
                } icon: {
                    Image(systemName: selectedTab == "lessons" ? "graduationcap.fill" : "graduationcap")
                }
                .environment(\.symbolVariants, .none)
            }

            // MARK: - Attendance
            Tab(value: "attendance") {
                NavigationStack {
                    AttendanceHomeView()
                }
            } label: {
                Label {
                    Text("出勤")
                } icon: {
                    Image(systemName: selectedTab == "attendance" ? "checkmark.square.fill" : "checkmark.square")
                }
                .environment(\.symbolVariants, .none)
            }

            // MARK: - Weekly Report
            Tab(value: "report") {
                NavigationStack {
                    WeeklyReportHomeView()
                }
            } label: {
                Label {
                    Text("周报")
                } icon: {
                    Image(systemName: selectedTab == "report" ? "doc.text.fill" : "doc.text")
                }
                .environment(\.symbolVariants, .none)
            }
        }
        .tint(Color("CoursePink"))
        .sensoryFeedback(.increase, trigger: selectedTab)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: Student.self, inMemory: true)
}
