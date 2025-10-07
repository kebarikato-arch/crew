import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Boat.name) private var boats: [Boat]
    @Binding var currentBoat: Boat
    
    @State private var showingAddRigDataView = false
    @State private var isAddingBoat = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if boats.count > 1 {
                    Picker("ボートを選択", selection: $currentBoat) {
                        ForEach(boats) { boat in
                            Text(boat.name).tag(boat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                ScrollView {
                    // (中略：既存のScrollViewの内容は変更なし)
                }
            }
            .navigationTitle("My Rig")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isAddingBoat = true }) { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $isAddingBoat) {
                AddBoatView()
            }
            // (中略：safeAreaInsetとそれに続くsheetも変更なし)
        }
    }
}

// 2隻目以降のボート追加用のビュー
struct AddBoatView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var boatName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section { TextField("ボート名", text: $boatName) }
                Section {
                    Button("保存") { addBoat(); dismiss() }
                    .disabled(boatName.isEmpty)
                }
            }
            .navigationTitle("新しいボート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
            }
        }
    }
    
    private func addBoat() {
        let newBoat = Boat(name: boatName)
        modelContext.insert(newBoat)
    }
}
