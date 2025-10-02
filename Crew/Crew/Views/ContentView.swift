// ContentView.swift の全文

import SwiftUI
import SwiftData

struct ContentView: View {
    // ユーザーが最後に選択したボートのIDを記憶します
    @AppStorage("selectedBoatID") private var selectedBoatID: String?
    
    var body: some View {
        MainTabView(selectedBoatID: $selectedBoatID)
    }
}

// MARK: - メインのタブ画面
struct MainTabView: View {
    @Query(sort: \Boat.name) private var boats: [Boat]
    @Binding var selectedBoatID: String?
    
    private var currentBoat: Boat? {
        if let boatID = selectedBoatID,
           let selectedID = UUID(uuidString: boatID),
           let boat = boats.first(where: { $0.id == selectedID }) {
            return boat
        }
        return boats.first
    }
    
    var body: some View {
        TabView {
            // MARK: 【修正】HomeViewに選択中のボートIDをBindingで渡す
            HomeView(selectedBoatID: $selectedBoatID)
                .tabItem { Label("My Rig", systemImage: "water.waves") }
            
            Group {
                if let boat = currentBoat {
                    CheckListView(boat: boat)
                } else {
                    PlaceholderView(title: "チェックリスト", message: "ボートを追加・選択してください。")
                }
            }
            .tabItem { Label("Checklist", systemImage: "checklist") }
            
            Group {
                if let boat = currentBoat {
                    DataView(boat: boat)
                } else {
                    PlaceholderView(title: "データ分析", message: "ボートを追加・選択してください。")
                }
            }
            .tabItem { Label("Data", systemImage: "chart.line.uptrend.xyaxis") }
            
            SettingView(
                selectedBoatID: $selectedBoatID,
                currentBoat: currentBoat
            )
            .tabItem { Label("Setting", systemImage: "gear") }
        }
        .onAppear {
            if selectedBoatID == nil, let firstBoat = boats.first {
                selectedBoatID = firstBoat.id.uuidString
            }
        }
        .onChange(of: boats) {
             // ボートが削除されるなどで選択中のIDが無効になった場合、先頭のボートを選択する
            if let boatID = selectedBoatID, boats.first(where: { $0.id.uuidString == boatID }) == nil {
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
