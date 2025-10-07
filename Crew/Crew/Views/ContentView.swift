import SwiftUI
import SwiftData

struct ContentView: View {
    // データベースからボートのリストを取得します
    @Query(sort: \Boat.name) private var boats: [Boat]
    
    // ユーザーが最後に選択したボートのIDを記憶します
    @AppStorage("selectedBoatId") private var selectedBoatId: String?

    var body: some View {
        // ボートが存在するかどうかにかかわらず、常にMainTabViewを表示します
        MainTabView(boats: boats, selectedBoatId: $selectedBoatId)
            .task(id: boats.count) {
                // 選択されているボートIDが無効、または未選択の場合に先頭のボートを選択し直します
                if !boats.contains(where: { $0.id.uuidString == selectedBoatId }) {
                    selectedBoatId = boats.first?.id.uuidString
                }
            }
    }
}

struct MainTabView: View {
    let boats: [Boat]
    @Binding var selectedBoatId: String?

    // 現在選択されているボートを特定します
    private var currentBoat: Boat? {
        if let boatId = selectedBoatId,
           let boat = boats.first(where: { $0.id.uuidString == boatId }) {
            return boat
        }
        return boats.first
    }
    
    // 他のビューに渡すためのBinding<Boat>を安全に生成します
    private var boatBinding: Binding<Boat>? {
        guard let boat = currentBoat else { return nil }
        return Binding<Boat>(
            get: { boat },
            set: { newBoat in selectedBoatId = newBoat.id.uuidString }
        )
    }

    var body: some View {
        TabView {
            // HomeViewにはボートの全リストと選択中のボート情報を渡します
            HomeView(boats: boats, selectedBoatId: $selectedBoatId, currentBoat: currentBoat)
                .tabItem { Label("My Rig", systemImage: "ferry.fill") }

            // 他のタブでは、選択中のボートが存在する場合のみ各ビューを表示します
            if let binding = boatBinding {
                CheckListView(currentBoat: binding)
                    .tabItem { Label("Checklist", systemImage: "list.bullet.clipboard.fill") }
                
                DataView(currentBoat: binding)
                    .tabItem { Label("Data", systemImage: "chart.xyaxis.line") }
                
                SettingView(currentBoat: binding)
                    .tabItem { Label("Setting", systemImage: "gear") }
            } else {
                // ボートが一つもない場合のプレースホルダー表示
                Text("ボートを追加してください")
                    .tabItem { Label("Checklist", systemImage: "list.bullet.clipboard.fill") }
                Text("ボートを追加してください")
                    .tabItem { Label("Data", systemImage: "chart.xyaxis.line") }
                Text("ボートを追加してください")
                    .tabItem { Label("Setting", systemImage: "gear") }
            }
        }
    }
}
