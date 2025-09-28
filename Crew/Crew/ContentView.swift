// ContentView.swift の全文

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection = 0
    
    // UserDefaultsに選択中のボートIDを保存
    @AppStorage("selectedBoatID") private var selectedBoatID: String?
    
    // 全てのボートを取得
    @Query(sort: \Boat.name, animation: .default) private var boats: [Boat]
    
    // 現在選択されているボート
    private var currentBoat: Boat? {
        // 保存されたIDと一致するボートを探す
        if let boatID = selectedBoatID,
           let selectedID = UUID(uuidString: boatID),
           let boat = boats.first(where: { $0.id == selectedID }) {
            return boat
        }
        // 見つからなければ最初のボートを返す
        return boats.first
    }
    
    var body: some View {
        // 選択されたボートが存在する場合にのみUIを表示
        if let boat = currentBoat {
            TabView(selection: $selection){
                HomeView(currentBoat: boat)
                    .tabItem {
                        Label("My Rig",systemImage: "water.waves")
                    }
                    .tag(0)
                
                CheckListView(boat: boat)
                    .tabItem {
                        Label("Checklist", systemImage: "checklist")
                    }
                    .tag(1)
                
                DataView(boat: boat)
                    .tabItem {
                        Label("Data",systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(2)
                
                // ✅ SettingViewに全ボートリストと選択中IDのBindingを渡す
                SettingView(
                    boats: boats,
                    selectedBoatID: $selectedBoatID,
                    currentBoat: boat
                )
                    .tabItem {
                        Label("Setting",systemImage: "gear")
                    }
                    .tag(3)
            }
            .onAppear(perform: ensureInitialData)
        } else {
            // ボートが1つもない場合の表示
            VStack {
                Text("ボートがありません")
                Text("設定タブから新しいボートを追加してください。")
            }
            .onAppear(perform: ensureInitialData)
        }
    }
    
    // 初回起動時にダミーデータを作成し、選択状態にする
    private func ensureInitialData() {
        if boats.isEmpty {
            let dummyBoat = Boat.dummy
            modelContext.insert(dummyBoat)
            // 最初のボートを選択状態にする
            selectedBoatID = dummyBoat.id.uuidString
            print("ContentView: 初回起動のためダミーボートを挿入しました。")
        } else if selectedBoatID == nil {
            // データはあるが、選択IDがない場合は最初のボートを選択
            selectedBoatID = boats.first?.id.uuidString
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Boat.self, inMemory: true)
}
