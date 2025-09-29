// CrewApp.swift の全文

import SwiftUI
import SwiftData

@main
struct CrewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // MARK: 【✅ 修正】データベースのモデルをここでシンプルに定義します
        .modelContainer(for: [Boat.self, RigDataSet.self, RigItem.self, CheckListItem.self, RigItemTemplate.self])
    }
}
