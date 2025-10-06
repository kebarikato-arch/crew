// WelcomeView.swift (新規作成)

import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingAddBoatAlert = false
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
            
            Text("まずはあなたのボートを登録しましょう。\nリギングデータの管理や分析を始める第一歩です。")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                showingAddBoatAlert = true
            }) {
                Text("最初のボートを追加する")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
        .alert("新しいボート", isPresented: $showingAddBoatAlert) {
            TextField("ボート名", text: $newBoatName)
            Button("追加", action: addBoat)
            Button("キャンセル", role: .cancel) {
                newBoatName = ""
            }
        } message: {
            Text("管理したいボートの名前を入力してください。")
        }
    }
    
    private func addBoat() {
        guard !newBoatName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newBoat = Boat(name: newBoatName)
        modelContext.insert(newBoat)
        // データを永続化するために保存
        try? modelContext.save()
        newBoatName = ""
    }
}

#Preview {
    WelcomeView()
        .modelContainer(for: Boat.self, inMemory: true)
}
