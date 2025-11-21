// CrewApp.swift の全文

import SwiftUI
import SwiftData

@main
struct CrewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // MARK: SwiftDataモデルコンテナにすべてのモデルを指定
        .modelContainer(for: [Boat.self, RigDataSet.self, RigItem.self, RigItemTemplate.self, CheckListItem.self, TrainingSession.self, TrainingMetric.self, WorkoutTemplate.self, WorkoutMetricTemplate.self])
    }
}
