import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var newBoatName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "figure.outdoor.rowing.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Crewへようこそ")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("まずはあなたのボートを登録しましょう。")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("ボート名", text: $newBoatName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)

            Button("ボートを登録する", action: addBoat)
                .buttonStyle(.borderedProminent)
                .disabled(newBoatName.isEmpty)

            Spacer()
        }
        .padding()
    }
    
    private func addBoat() {
        guard !newBoatName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        // 修正された正しい初期化方法でBoatオブジェクトを作成します
        let newBoat = Boat(name: newBoatName)
        modelContext.insert(newBoat)
        
        // デフォルトのリグテンプレートを追加
        newBoat.addDefaultRigTemplates()
        
        // デフォルトのチェックリスト項目を追加
        addDefaultChecklistItems(to: newBoat)
        
        // デフォルトのワークアウトテンプレートを追加
        newBoat.addDefaultWorkoutTemplates()
        
        // 念のためdo-catchでエラーを捕捉します
        do {
            try modelContext.save()
            DispatchQueue.main.async { newBoatName = "" }
        } catch {
            print("ボートの保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func addDefaultChecklistItems(to boat: Boat) {
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
        
        for (task, category) in defaultItems {
            let item = CheckListItem(task: task, isCompleted: false, category: category, boat: boat)
            boat.checklist.append(item)
        }
    }
}
