import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Boat.name) private var boats: [Boat]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasMigratedNewTemplates") private var hasMigratedNewTemplates = false
    @AppStorage("hasMigratedChecklist") private var hasMigratedChecklist = false

    var body: some View {
        Group {
            if boats.isEmpty {
                WelcomeView()
                    .environment(\.modelContext, modelContext)
            } else {
                MainAppView(boats: boats)
            }
        }
        .task {
            if !hasMigratedNewTemplates && !boats.isEmpty {
                migrateNewTemplates()
                hasMigratedNewTemplates = true
            }
            if !hasMigratedChecklist && !boats.isEmpty {
                migrateChecklistItems()
                hasMigratedChecklist = true
            }
        }
    }
    
    private func migrateNewTemplates() {
        let newTemplates = [
            ("ワークハイトB", "cm", "クラッチ"),
            ("ワークハイトS", "cm", "クラッチ")
        ]
        
        for boat in boats {
            for (name, unit, category) in newTemplates {
                // 既に存在する場合はスキップ
                if boat.rigItemTemplates.contains(where: { $0.name == name && $0.category == category }) {
                    continue
                }
                
                // 新しいテンプレートを追加
                let template = RigItemTemplate(name: name, unit: unit, category: category, boat: boat)
                boat.rigItemTemplates.append(template)
            }
        }
        
        do {
            try modelContext.save()
            print("Migration: Added ワークハイトB and ワークハイトS to all boats")
        } catch {
            print("Migration failed: \(error)")
        }
    }
    
    private func migrateChecklistItems() {
        let defaultItems = [
            // レース前チェック
            ("オールの確認", "レース前チェック"),
            ("リグの確認", "レース前チェック"),
            ("ボートの点検", "レース前チェック"),
            
            // 持ち物
            ("ユニフォーム", "持ち物"),
            ("シューズ", "持ち物"),
            ("水筒", "持ち物"),
            ("タオル", "持ち物"),
            ("着替え", "持ち物")
        ]
        
        for boat in boats {
            // 既存のチェックリスト項目がある場合はスキップ（ユーザーが既にカスタマイズしている可能性がある）
            if !boat.checklist.isEmpty {
                continue
            }
            
            for (task, category) in defaultItems {
                let item = CheckListItem(task: task, isCompleted: false, category: category, boat: boat)
                boat.checklist.append(item)
            }
        }
        
        do {
            try modelContext.save()
            print("Migration: Added default checklist items to boats without existing items")
        } catch {
            print("Checklist migration failed: \(error)")
        }
    }
}

struct MainAppView: View {
    let boats: [Boat]
    @AppStorage("selectedBoatId") private var selectedBoatId: String?

    private var currentBoat: Boat? {
        if let boatId = selectedBoatId,
           let boat = boats.first(where: { $0.id.uuidString == boatId }) {
            return boat
        }
        return boats.first
    }
    
    private var boatBinding: Binding<Boat> {
        Binding<Boat>(
            get: { currentBoat! },
            set: { newBoat in selectedBoatId = newBoat.id.uuidString }
        )
    }

    var body: some View {
        TabView {
            HomeView(currentBoat: boatBinding)
                .tabItem { Label("My Rig", systemImage: "house") }

            CheckListView(currentBoat: boatBinding)
                .tabItem { Label("Checklist", systemImage: "list.bullet.clipboard.fill") }
            
            DataView(currentBoat: boatBinding)
                .tabItem { Label("Data", systemImage: "chart.xyaxis.line") }
            
            SettingView(currentBoat: boatBinding)
                .tabItem { Label("Setting", systemImage: "gear") }
        }
        .task(id: boats.count) {
            if !boats.contains(where: { $0.id.uuidString == selectedBoatId }) {
                selectedBoatId = boats.first?.id.uuidString
            }
        }
    }
}

