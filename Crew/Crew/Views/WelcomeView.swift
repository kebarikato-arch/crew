import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var newBoatName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "sailboat.circle.fill")
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
        addDefaultRigTemplates(to: newBoat)
        
        // 念のためdo-catchでエラーを捕捉します
        do {
            try modelContext.save()
            DispatchQueue.main.async { newBoatName = "" }
        } catch {
            print("ボートの保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    private func addDefaultRigTemplates(to boat: Boat) {
        let defaultTemplates = [
            // クラッチ
            ("スパン", "cm", "クラッチ"),
            ("前傾", "°", "クラッチ"),
            ("後傾", "°", "クラッチ"),
            ("ブッシュ", "選択", "クラッチ"),
            
            // ストレッチャー
            ("アングル", "°", "ストレッチャー"),
            ("デプス", "cm", "ストレッチャー"),
            ("ピンヒール", "cm", "ストレッチャー"),
            ("ワークスルー", "cm", "ストレッチャー"),
            
            // オール
            ("全長", "cm", "オール"),
            ("インボード", "cm", "オール")
        ]
        
        for (name, unit, category) in defaultTemplates {
            let template = RigItemTemplate(name: name, unit: unit, category: category, boat: boat)
            boat.rigItemTemplates.append(template)
        }
    }
}
