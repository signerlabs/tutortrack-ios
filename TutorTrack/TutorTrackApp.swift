//
//  TutorTrackApp.swift
//  TutorTrack
//
//  App entry point:
//  - Injects the SwiftData modelContainer (Student / AttendanceRecord)
//  - On launch, MockSeed seeds an empty store (5 mock students + past 2 weeks of attendance)
//  - Attaches .swAlert() to the root view to enable the global toast
//    (ShipSwift Recipe: component-alert)
//

import SwiftUI
import SwiftData

@main
struct TutorTrackApp: App {

    /// Shared SwiftData container
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Student.self,
                AttendanceRecord.self
            ])
            let config = ModelConfiguration(schema: schema)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("[TutorTrackApp] Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .swAlert()
                .task {
                    MockSeed.seedIfNeeded(in: modelContainer.mainContext)
                }
        }
        .modelContainer(modelContainer)
    }
}
