import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var boats: [Boat]
    @State private var selectedBoat: Boat?
    @State private var showingAddBoatAlert = false
    @State private var newBoatName = ""
    @State private var showingAddRigDataSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if boats.isEmpty {
                    ContentUnavailableView(
                        "ボートがありません",
                        systemImage: "sailboat.fill",
                        description: Text("右上の「+」ボタンから新しいボートを追加してください。")
                    )
                } else {
                    if let boat = selectedBoat ?? boats.first {
                        // Boat Picker
                        Picker("ボートを選択", selection: $selectedBoat) {
                            ForEach(boats) { boat in
                                Text(boat.name).tag(boat as Boat?)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                        // Rig Safety Score and Current Rig Setting
                        RigSettingCardView(currentBoat: boat)
                        
                        // History
                        List {
                            Section(header: Text("履歴")) {
                                ForEach(boat.rigDataSets.sorted(by: { $0.date > $1.date })) { dataSet in
                                    NavigationLink(destination: RigHistoryDetailView(rigDataSet: dataSet)) {
                                        RigDataSetRow(dataSet: dataSet)
                                    }
                                }
                                .onDelete(perform: { indexSet in
                                    deleteRigDataSet(at: indexSet, from: boat)
                                })
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Rig")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddBoatAlert = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        showingAddRigDataSheet = true
                    }) {
                        Image(systemName: "square.and.pencil")
                        Text("リグデータを記録")
                    }
                    .disabled(selectedBoat == nil)
                }
            }
            .sheet(isPresented: $showingAddRigDataSheet) {
                if let boat = selectedBoat {
                    AddRigDataView(currentBoat: boat)
                }
            }
            .alert("新しいボート", isPresented: $showingAddBoatAlert, actions: {
                TextField("ボート名", text: $newBoatName)
                Button("追加", action: {
                    if !newBoatName.isEmpty {
                        addBoat(name: newBoatName)
                        newBoatName = ""
                    }
                })
                Button("キャンセル", role: .cancel) {
                    newBoatName = ""
                }
            }, message: {
                Text("新しいボートの名前を入力してください。")
            })
            .onAppear {
                if selectedBoat == nil {
                    selectedBoat = boats.first
                }
            }
            .onChange(of: boats) {
                if selectedBoat == nil {
                    selectedBoat = boats.first
                }
            }
        }
    }
    
    private func addBoat(name: String) {
        let newBoat = Boat(name: name)
        modelContext.insert(newBoat)
        
        // 新しいデフォルトテンプレート
        let defaultTemplates = [
            // クラッチ
            RigItemTemplate(name: "スパン", unit: "cm", category: "クラッチ"),
            RigItemTemplate(name: "前傾", unit: "°", category: "クラッチ"),
            RigItemTemplate(name: "外傾", unit: "°", category: "クラッチ"),
            // ブッシュ
            RigItemTemplate(name: "ブッシュ", unit: "", category: "ブッシュ"), // 単位は空
            RigItemTemplate(name: "ワークハイトB", unit: "cm", category: "ブッシュ"),
            RigItemTemplate(name: "ワークハイトS", unit: "cm", category: "ブッシュ"),
            // ストレッチャー
            RigItemTemplate(name: "アングル", unit: "°", category: "ストレッチャー"),
            RigItemTemplate(name: "デプス", unit: "cm", category: "ストレッチャー"),
            RigItemTemplate(name: "ピンヒール", unit: "cm", category: "ストレッチャー"),
            RigItemTemplate(name: "ワークスルー", unit: "cm", category: "ストレッチャー"),
            // オール
            RigItemTemplate(name: "オール全長", unit: "cm", category: "オール"),
            RigItemTemplate(name: "インボード", unit: "cm", category: "オール")
        ]
        
        for template in defaultTemplates {
            newBoat.rigItemTemplates.append(template)
        }
        
        selectedBoat = newBoat
    }
    
    private func deleteRigDataSet(at offsets: IndexSet, from boat: Boat) {
        let sortedDataSets = boat.rigDataSets.sorted(by: { $0.date > $1.date })
        for index in offsets {
            let dataSetToDelete = sortedDataSets[index]
            modelContext.delete(dataSetToDelete)
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Boat.self, inMemory: true)
}
