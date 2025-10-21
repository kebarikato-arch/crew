import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Boat.name) private var boats: [Boat]
    @Binding var currentBoat: Boat
    
    @State private var showingAddRigDataView = false
    @State private var isAddingBoat = false
    @State private var showingHistory = false

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
                    VStack(spacing: 16) {
                        if currentBoat.rigDataSets.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("リグデータがありません")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("最初のリグデータを記録しましょう")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button("リグデータを記録") {
                                    showingAddRigDataView = true
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 8)
                            }
                            .padding()
                        } else {
                            // 最新のリグデータを取得
                            if let latestDataSet = currentBoat.rigDataSets.sorted(by: { $0.date > $1.date }).first {
                                VStack(spacing: 12) {
                                    // リグアイテムをカード形式で表示
                                    LazyVGrid(columns: [
                                        GridItem(.flexible()),
                                        GridItem(.flexible())
                                    ], spacing: 12) {
                                        ForEach(latestDataSet.rigItems, id: \.id) { item in
                                            RigItemCard(item: item)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("My Rig")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !currentBoat.rigDataSets.isEmpty {
                        Button("履歴") {
                            showingHistory = true
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("リグデータを記録") {
                            showingAddRigDataView = true
                        }
                        Button("ボートを追加") {
                            isAddingBoat = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isAddingBoat) {
                AddBoatView()
            }
            .sheet(isPresented: $showingAddRigDataView) {
                AddRigDataView(boat: currentBoat)
            }
            .sheet(isPresented: $showingHistory) {
                RigHistoryView(currentBoat: $currentBoat)
            }
            .safeAreaInset(edge: .bottom) {
                if !currentBoat.rigDataSets.isEmpty {
                    Button("リグデータを記録") {
                        showingAddRigDataView = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
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
