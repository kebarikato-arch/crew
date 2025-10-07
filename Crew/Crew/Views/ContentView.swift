import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Boat.name) private var boats: [Boat]
    
    // ユーザーが最後に選択したボートのIDを記憶する、唯一の情報源です
    @AppStorage("selectedBoatId") private var selectedBoatId: String?

    var body: some View {
        Group {
            if boats.isEmpty {
                // ボートが1件もなければ、ウェルカム画面を表示します
                WelcomeView()
            } else {
                // 表示すべきボートを、記憶されたIDを元に安全に探し出します
                // 万が一見つからなくても、先頭のボートを選択するためクラッシュしません
                let boatToShow = boats.first { $0.id.uuidString == selectedBoatId } ?? boats.first!
                
                // 子ビュー（HomeViewなど）での変更を親（このView）に伝えるためのBindingを生成します
                let boatBinding = Binding<Boat>(
                    get: { boatToShow },
                    set: { newBoat in
                        // 子ビューでボートが切り替えられたら、記憶されているIDを更新します
                        selectedBoatId = newBoat.id.uuidString
                    }
                )
                // MainTabViewに、ここで生成した安全なBindingを渡します
                MainTabView(currentBoat: boatBinding)
            }
        }
        // .taskは、Viewが表示された時や、監視対象の値(ここではboats.count)が変化した時に
        // 安全に処理を実行するための現代的な方法です。これにより無限ループを防ぎます。
        .task(id: boats.count) {
            // 現在選択されているIDが有効かチェックし、無効なら先頭のボートを選択し直します
            if selectedBoatId == nil || !boats.contains(where: { $0.id.uuidString == selectedBoatId }) {
                selectedBoatId = boats.first?.id.uuidString
            }
        }
    }
}

/// MainTabViewは、すべてのタブ画面に同じ形式でデータを渡す役割に徹します
struct MainTabView: View {
    @Binding var currentBoat: Boat
    
    var body: some View {
        TabView {
            //【修正点】すべてのタブ画面に、同じ'currentBoat'という名前で、同じBinding($currentBoat)を渡します
            
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
