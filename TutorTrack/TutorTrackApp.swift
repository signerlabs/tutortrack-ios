//
//  TutorTrackApp.swift
//  TutorTrack
//
//  App 入口：
//  - 注入 SwiftData modelContainer（Student / AttendanceRecord）
//  - 启动时 MockSeed 检测空库自动 seed（5 个 mock 学员 + 过去 2 周出勤）
//  - 在根视图挂 .swAlert() 启用全局 toast（ShipSwift Recipe: component-alert）
//

import SwiftUI
import SwiftData

@main
struct TutorTrackApp: App {

    /// 共享的 SwiftData 容器
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
            fatalError("[TutorTrackApp] 无法创建 ModelContainer：\(error)")
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
