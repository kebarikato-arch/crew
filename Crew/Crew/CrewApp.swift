// CrewApp.swift の全文

import SwiftUI
import SwiftData // SwiftDataをインポート

@main
struct CrewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // MARK: SwiftData コンテナのセットアップ
        // ここで全ての @Model クラスを登録する
        .modelContainer(for: [Boat.self, RigDataSet.self, RigItem.self, CheckListItem.self])
    }
}
