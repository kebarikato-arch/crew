// CrewApp.swift の全文

import SwiftUI
import SwiftData

@main
struct CrewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // MARK: 【修正】トップレベルのモデルのみを指定し、SwiftDataにリレーションの解決を任せる
        .modelContainer(for: [Boat.self, RigDataSet.self, RigItem.self, CheckListItem.self, RigItemTemplate.self])
    }
}
