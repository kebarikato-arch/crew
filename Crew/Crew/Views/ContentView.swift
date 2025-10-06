import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Boat.name) private var boats: [Boat]
    @AppStorage("selectedBoatId") private var selectedBoatId: String?
    
    // 状態としてBoatオブジェクトそのものではなく、選択されたBoatのIDを保持します
    @State private var selection: Boat.ID?

    var body: some View {
        Group {
            if boats.isEmpty {
                // ボートが1件もなければ、ウェルカム画面を全画面で表示します
                WelcomeView()
            } else if let selection = selection,
                      // boats配列の中から、選択中のIDを持つボートを探します
                      let selectedBoat = boats.first(where: { $0.id == selection }) {
                
                // 見つかったボートへのBinding（参照）を生成します
                let boatBinding = Binding(
                    get: { selectedBoat },
                    set: { newBoat in
                        // 子ビューでボートが変更されたら、IDを更新します
                        self.selection = newBoat.id
                        self.selectedBoatId = newBoat.id.uuidString
                    }
                )
                
                // メインのタブ画面に、ここで生成した安全なBindingを渡します
                MainTabView(currentBoat: boatBinding)
                
            } else {
                // 起動直後や、選択中のボートが見つからない場合に読み込み中を表示します
                ProgressView()
            }
        }
        .onAppear {
             // アプリ起動時に最初のボートを選択します
            if selection == nil {
                validateSelection()
            }
        }
        .onChange(of: boats) {
            // ボートが削除された場合などに、選択を更新します
            validateSelection()
        }
    }

    /// 選択中のIDが有効かチェックし、無効なら先頭のボートを選択する関数です
    private func validateSelection() {
        // 現在の選択が有効でない場合、記憶されたIDか先頭のボートを再選択します
        if selection == nil || !boats.contains(where: { $0.id == selection }) {
            let boatToSelect = boats.first { $0.id.uuidString == selectedBoatId } ?? boats.first
            selection = boatToSelect?.id
        }
    }
}

/// MainTabViewはBinding<Boat>を受け取るだけのシンプルな構造です
struct MainTabView: View {
    @Binding var currentBoat: Boat
    
    var body: some View {
        TabView {
            // 全てのタブ画面に、受け取ったBindingをそのまま渡します
            HomeView(currentBoat: $currentBoat)
                .tabItem { Label("My Rig", systemImage: "ferry.fill") }
            
            CheckListView(currentBoat: $currentBoat)
                .tabItem { Label("Checklist", systemImage: "list.bullet.clipboard.fill") }
            
            DataView(currentBoat: $currentBoat)
                .tabItem { Label("Data", systemImage: "chart.xyaxis.line") }
            
            SettingView(currentBoat: $currentBoat)
                .tabItem { Label("Setting", systemImage: "gear") }
        }
    }
}
