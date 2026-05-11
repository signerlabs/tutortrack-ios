//
//  ContentView.swift
//  TutorTrack
//
//  根视图 = RootTabView（4-Tab：学员 / 课时 / 出勤 / 周报）。
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        RootTabView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Student.self, inMemory: true)
}
