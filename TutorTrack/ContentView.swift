//
//  ContentView.swift
//  TutorTrack
//
//  Root view = RootTabView (4 tabs: Students / Lessons / Attendance / Report).
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
