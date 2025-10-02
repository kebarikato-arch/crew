import SwiftUI
import SwiftData

struct SettingView: View {
    @Query(sort: \Boat.name, animation: .default) private var allBoats: [Boat]
    @Binding var selectedBoatID: String?
    let currentBoat: Boat?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationView {
            Form {
                if let boat = currentBoat {
                    Section(header: Text("現在のボート")) {
                        HStack {
                            Text("ボート名")
                            Spacer()
                            TextField("ボート名", text: .constant(boat.name))
                                .multilineTextAlignment(.trailing)
                                .disabled(true)
                        }
                        NavigationLink("リグアイテムのテンプレートを編集") {
                            // MARK: 【修正】引数ラベルを boat: から currentBoat: に変更
                            EditRigTemplatesView(currentBoat: boat)
                        }
                    }
                }
                
                Section(header: Text("アプリケーション設定")) {
                    NavigationLink("プライバシーポリシー") { Text("プライバシーポリシーのページ") }
                    NavigationLink("利用規約") { Text("利用規約のページ") }
                }
                
                Section(header: Text("登録済みボートの管理")) {
                    if allBoats.isEmpty {
                        Text("ボートがありません").foregroundColor(.secondary)
                    } else {
                        List {
                            ForEach(allBoats) { boat in Text(boat.name) }
                            .onDelete(perform: deleteBoat)
                        }
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
    
    private func deleteBoat(at offsets: IndexSet) {
        for index in offsets {
            let boatToDelete = allBoats[index]
            // 削除するボートが現在選択中のボートだった場合、選択を解除または他のボートに切り替える
            if boatToDelete.id.uuidString == selectedBoatID {
                let remainingBoats = allBoats.filter { $0.id != boatToDelete.id }
                selectedBoatID = remainingBoats.first?.id.uuidString
            }
            modelContext.delete(boatToDelete)
        }
    }
}
