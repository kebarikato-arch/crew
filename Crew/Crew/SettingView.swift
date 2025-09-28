// SettingView.swift の全文

import SwiftUI
import SwiftData

struct SettingView: View {
    // ✅ ContentViewから受け取るプロパティ
    let boats: [Boat]
    @Binding var selectedBoatID: String?
    @Bindable var currentBoat: Boat
    
    @Environment(\.modelContext) private var modelContext
    @State private var isAddingBoat = false
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - ボート管理
                Section(header: Text("ボート管理")) {
                    // ボート選択ピッカー
                    Picker("現在のボート", selection: $selectedBoatID) {
                        ForEach(boats) { boat in
                            Text(boat.name).tag(boat.id.uuidString as String?)
                        }
                    }
                    
                    // 新しいボートを追加するボタン
                    Button("新しいボートを追加") {
                        isAddingBoat = true
                    }
                }
                
                // MARK: - ボート情報編集
                Section(header: Text("現在のボート情報")) {
                    HStack {
                        Text("ボート名")
                        Spacer()
                        TextField("ボート名", text: $currentBoat.name)
                            .multilineTextAlignment(.trailing)
                    }
                }

                // MARK: - 全ボートリストと削除
                Section(header: Text("登録済みボート")) {
                    List {
                        ForEach(boats) { boat in
                            Text(boat.name)
                        }
                        .onDelete(perform: deleteBoat)
                    }
                }
            }
            .navigationTitle("設定")
            .sheet(isPresented: $isAddingBoat) {
                AddBoatView()
            }
        }
    }
    
    // ボートを削除する関数
    private func deleteBoat(at offsets: IndexSet) {
        for index in offsets {
            let boatToDelete = boats[index]
            // もし削除するボートが現在選択中のボートだったら、選択をリセット
            if boatToDelete.id.uuidString == selectedBoatID {
                selectedBoatID = nil
            }
            modelContext.delete(boatToDelete)
        }
    }
}

// MARK: - 新しいボートを追加するためのView
struct AddBoatView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var boatName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("ボート名", text: $boatName)
                Button("保存") {
                    addBoat()
                    dismiss()
                }
                .disabled(boatName.isEmpty)
            }
            .navigationTitle("新しいボート")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
    
    private func addBoat() {
        // 新しいボートを空のデータで作成
        let newBoat = Boat(name: boatName, dataSets: [], checklist: [])
        modelContext.insert(newBoat)
    }
}

#Preview {
    // Preview用のダミーデータとState Binding
    @State var previewSelectedBoatID: String? = Boat.dummy.id.uuidString
    
    return SettingView(
        boats: [Boat.dummy],
        selectedBoatID: $previewSelectedBoatID,
        currentBoat: Boat.dummy
    )
    .modelContainer(for: Boat.self, inMemory: true)
}
