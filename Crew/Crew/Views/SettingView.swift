import SwiftUI
import SwiftData

struct SettingView: View {
    @Binding var currentBoat: Boat
    
    @Query private var boats: [Boat]
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            Form {
                Section("現在のボート") {
                    // ボート名の編集を可能にします
                    TextField("ボート名", text: $currentBoat.name)
                }

                Section("設定") {
                    NavigationLink("リグアイテムのテンプレートを編集") {
                        EditRigTemplatesView(boat: currentBoat)
                    }
                }

                Section("登録済みのボート") {
                    ForEach(boats) { boat in
                        Text(boat.name)
                    }
                    .onDelete(perform: deleteBoat)
                }
                
                Section("情報") {
                    Link("プライバシーポリシー", destination: URL(string: "https://www.example.com/privacy")!)
                    Link("利用規約", destination: URL(string: "https://www.example.com/terms")!)
                }
            }
            .navigationTitle("設定")
        }
    }

    private func deleteBoat(at offsets: IndexSet) {
        for index in offsets {
            let boatToDelete = boats[index]
            context.delete(boatToDelete)
        }
    }
}
