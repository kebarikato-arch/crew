// ContentView.swift の全文

import SwiftUI
import SwiftData

struct ContentView: View {
    // MARK: 【修正】@QueryをHomeViewに移動したため、ここでは削除
    // @Query(sort: \Boat.name, animation: .default) private var boats: [Boat]
    
    // ユーザーが最後に選択したボートのIDを記憶します
    @AppStorage("selectedBoatID") private var selectedBoatID: String?
    
    // MARK: 【修正】データベースからboatsを取得するロジックを削除
    var body: some View {
        // メインのタブ画面を常に表示する安定した構造
        MainTabView(
            selectedBoatID: $selectedBoatID
        )
    }
}

// MARK: - メインのタブ画面
struct MainTabView: View {
    // MARK: 【修正】HomeViewで@Queryを使うため、ここからboatsを削除
    // let boats: [Boat]
    @Query(sort: \Boat.name) private var boats: [Boat] // MainTabViewでboatsとcurrentBoatを解決
    @Binding var selectedBoatID: String?
    @State private var selection: Int = 0
    
    private var currentBoat: Boat? {
        if let boatID = selectedBoatID,
           let selectedID = UUID(uuidString: boatID),
           let boat = boats.first(where: { $0.id == selectedID }) {
            return boat
        }
        // 該当するボートがなければ、リストの最初のボートを返す
        return boats.first
    }
    
    var body: some View {
        TabView(selection: $selection) {
            // MARK: 【修正】HomeViewにboatsとcurrentBoatを渡すのをやめる
            HomeView(
                selectedBoatID: $selectedBoatID
            )
            .tabItem { Label("My Rig", systemImage: "water.waves") }
            .tag(0)
            
            Group {
                // MARK: 【修正】currentBoatをMainTabView内で解決
                if let boat = currentBoat {
                    CheckListView(boat: boat)
                } else {
                    PlaceholderView(title: "チェックリスト", message: "ボートを追加・選択してください。")
                }
            }
            .tabItem { Label("Checklist", systemImage: "checklist") }
            .tag(1)
            
            Group {
                if let boat = currentBoat {
                    DataView(boat: boat)
                } else {
                    PlaceholderView(title: "データ分析", message: "ボートを追加・選択してください。")
                }
            }
            .tabItem { Label("Data", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(2)
            
            SettingView(
                selectedBoatID: $selectedBoatID,
                currentBoat: currentBoat
            )
            .tabItem { Label("Setting", systemImage: "gear") }
            .tag(3)
        }
        .onAppear {
            // アプリ起動時にボートが選択されていなければ、最初のボートを選択状態にします
            if selectedBoatID == nil && !boats.isEmpty {
                selectedBoatID = boats.first?.id.uuidString
            }
        }
    }
}

// MARK: - 共通のプレースホルダービュー
struct PlaceholderView: View {
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "sailboat.circle").font(.system(size: 60)).foregroundColor(.secondary)
            Text(title).font(.title2).fontWeight(.bold)
            Text(message).font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Boat.self, inMemory: true)
}
