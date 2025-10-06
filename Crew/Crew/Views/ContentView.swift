// ContentView.swift (修正後)

import SwiftUI
import SwiftData

struct ContentView: View {
    // AppStorageの変数はMainTabViewに移動
    var body: some View {
        // MainTabViewを直接表示する
        MainTabView()
    }
}


// MARK: - メインのタブ画面
struct MainTabView: View {
    // データをここで一元管理する
    @AppStorage("selectedBoatID") private var selectedBoatID: String?
    @Query(sort: \Boat.name) private var boats: [Boat]
    
    private var currentBoat: Boat? {
        // selectedBoatIDを基に現在選択中のボートを決定するロジックは変更なし
        if let boatID = selectedBoatID,
           let selectedID = UUID(uuidString: boatID),
           let boat = boats.first(where: { $0.id == selectedID }) {
            return boat
        }
        return boats.first
    }
    
    var body: some View {
        TabView {
            // MARK: HomeViewには選択中のボートIDをBindingで渡す
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
            // 選択中のボートIDがない場合、最初のボートを選択状態にする
            if selectedBoatID == nil || boats.first(where: { $0.id.uuidString == selectedBoatID }) == nil {
                selectedBoatID = boats.first?.id.uuidString
            }
        }
        .onChange(of: boats) {
            // ボートの数が変わった時に選択状態を見直す
            if selectedBoatID == nil {
                selectedBoatID = boats.first?.id.uuidString
            } else if let boatID = selectedBoatID, boats.first(where: { $0.id.uuidString == boatID }) == nil {
                // 選択中のボートが削除された場合など
                selectedBoatID = boats.first?.id.uuidString
            }
        }
        // 【修正】ボートが0件の場合、WelcomeViewをシートとして表示する
        .sheet(isPresented: .constant(boats.isEmpty)) {
            // WelcomeViewを表示
            WelcomeView()
                // 下にスワイプして閉じられないようにする
                .interactiveDismissDisabled()
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
