//
//  RootTabView.swift
//  TutorTrack
//
//  4-Tab 主框架。基于 SWRootTabView 模板（ShipSwift Recipe: component-root-tab-view），
//  4 个 Tab 各自指向 Features 子模块的 Home View。
//

import SwiftUI
import SwiftData

struct RootTabView: View {
    /// 持久化当前选中 Tab，避免来回切 Tab 丢失选择
    @AppStorage("selectedTab") private var selectedTab: String = "students"

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: - 学员
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

            // MARK: - 课时
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

            // MARK: - 出勤
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

            // MARK: - 周报
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
