import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Boat.name) private var boats: [Boat]
    
    @Binding var selectedBoatID: String?
    
    @State private var showingAddBoatAlert = false
    @State private var newBoatName = ""
    @State private var showingAddRigDataSheet = false
    
    private var currentBoat: Boat? {
        guard let selectedBoatID = selectedBoatID,
              let uuid = UUID(uuidString: selectedBoatID) else {
            return boats.first
        }
        return boats.first(where: { $0.id == uuid })
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if boats.isEmpty {
                    ContentUnavailableView("ボートがありません", systemImage: "sailboat.fill", description: Text("右上の「+」ボタンから新しいボートを追加してください。"))
                } else if let boat = currentBoat {
                    Picker("ボートを選択", selection: $selectedBoatID) {
                        ForEach(boats) { boat in
                            Text(boat.name).tag(boat.id.uuidString as String?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    RigSettingCardView(currentBoat: boat)
                    
                    List {
                        Section(header: Text("履歴")) {
                            // MARK: 【修正】 dataSets -> rigDataSets
                            ForEach(boat.rigDataSets.sorted(by: { $0.date > $1.date })) { dataSet in
                                NavigationLink(destination: RigHistoryDetailView(boat: boat, dataSet: dataSet)) {
                                    RigDataSetRow(dataSet: dataSet)
                                }
                            }
                            .onDelete(perform: { indexSet in
                                deleteRigDataSet(at: indexSet, from: boat)
                            })
                        }
                    }
                } else {
                    ContentUnavailableView("ボートを選択してください", systemImage: "questionmark.circle")
                }
            }
            .navigationTitle("My Rig")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button(action: { showingAddBoatAlert = true }) { Image(systemName: "plus") } }
                ToolbarItem(placement: .bottomBar) {
                    Button(action: { showingAddRigDataSheet = true }) {
                        Label("リグデータを記録", systemImage: "square.and.pencil")
                    }
                    .disabled(currentBoat == nil)
                }
            }
            .sheet(isPresented: $showingAddRigDataSheet) {
                if let boat = currentBoat {
                    AddRigDataView(boat: boat, dataSetToEdit: nil)
                }
            }
            .alert("新しいボート", isPresented: $showingAddBoatAlert, actions: {
                TextField("ボート名", text: $newBoatName)
                Button("追加") {
                    if !newBoatName.isEmpty {
                        addBoat(name: newBoatName)
                        newBoatName = ""
                    }
                }
                Button("キャンセル", role: .cancel) { newBoatName = "" }
            })
        }
    }
    
    private func addBoat(name: String) {
        let newBoat = Boat(name: name)
        modelContext.insert(newBoat)
        // (テンプレート追加のロジックは省略)
        selectedBoatID = newBoat.id.uuidString
    }
    
    private func deleteRigDataSet(at offsets: IndexSet, from boat: Boat) {
        // MARK: 【修正】 dataSets -> rigDataSets
        let sortedDataSets = boat.rigDataSets.sorted(by: { $0.date > $1.date })
        for index in offsets {
            let dataSetToDelete = sortedDataSets[index]
            modelContext.delete(dataSetToDelete)
        }
    }
}
