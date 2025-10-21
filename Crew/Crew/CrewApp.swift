// CrewApp.swift の全文

import SwiftUI
import SwiftData

@main
struct CrewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // MARK: SwiftDataはトップレベルモデルから関係を解決できるためBoatのみを指定
        .modelContainer(for: Boat.self)
    }
}
