// HomeView.swift の全文

import SwiftUI
import SwiftData

struct HomeView: View {
    let boats: [Boat]
    @Binding var selectedBoatID: String?
    let currentBoat: Boat?
    
    @State private var selectedTab: RigDataType = .current
    @State private var isAddingData = false
    @State private var isAddingBoat = false
    
    private var safetyScore: Int {
        guard let latestData = currentBoat?.latestDataSet else { return 100 }
        let expiredCount = latestData.elements.filter { $0.status == .expired }.count
        let maintenanceCount = latestData.elements.filter { $0.status == .maintenance }.count
        return max(0, 100 - (expiredCount * 30) - (maintenanceCount * 10))
    }
    
    enum RigDataType: String, CaseIterable {
        case current = "現在の設定"
        case history = "ログ履歴"
    }

    var body: some View {
        NavigationView {
            if boats.isEmpty {
                // --- ボートが一つもない場合に「ようこそ画面」を表示 ---
                NoBoatView(isAddingBoat: $isAddingBoat)
            } else if let boat = currentBoat {
                // --- ボートが存在する場合に「ダッシュボード画面」を表示 ---
                VStack(spacing: 0) {
                    VStack(spacing: 15) {
                        HStack(alignment: .center) {
                            Picker("現在のボート", selection: $selectedBoatID) {
                                ForEach(boats) { boat in Text(boat.name).tag(boat.id.uuidString as String?) }
                            }
                            .pickerStyle(.menu).font(.title2).fontWeight(.bold)
                            Spacer()
                            Button { isAddingData = true } label: { Image(systemName: "plus.circle").font(.title2) }
                            Button { isAddingBoat = true } label: { Image(systemName: "sailboat.circle.fill").font(.title2) }
                        }
                        .padding(.horizontal)
                        
                        Text("\(safetyScore)").font(.system(size: 60, weight: .bold, design: .rounded)).foregroundColor(scoreColor(score: safetyScore))
                        + Text("/100").font(.title).foregroundColor(.secondary)
                        
                        Text("Rig Safety Score").font(.headline).foregroundColor(.secondary)
                        SegmentedControl(selectedTab: $selectedTab).padding(.horizontal).padding(.bottom, 10)
                    }
                    .padding(.top)

                    ScrollView {
                        VStack(spacing: 12) {
                            if selectedTab == .current, let latestData = boat.latestDataSet {
                                ForEach(latestData.elements) { item in
                                    NavigationLink {
                                        RigItemDetailView(item: item, allDataSets: boat.dataSets)
                                    } label: { RigSettingCardView(item: item) }
                                    .buttonStyle(.plain)
                                }
                                Text("最終更新日: \(latestData.date, style: .date) \(latestData.date, style: .time)")
                                    .font(.caption).foregroundColor(.gray).padding(.top, 10)
                            } else if selectedTab == .history {
                                if boat.dataSets.isEmpty {
                                    Text("ログ履歴がありません。").foregroundColor(.gray).padding(.top, 50)
                                } else {
                                    ForEach(boat.dataSets.sorted(by: { $0.date > $1.date })) { dataSet in
                                        NavigationLink {
                                            RigHistoryDetailView(boat: boat, dataSet: dataSet)
                                        } label: { RigDataSetRow(dataSet: dataSet) }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }.padding(.horizontal).padding(.bottom, 80)
                    }
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $isAddingData) { AddRigDataView(boat: boat) }
            }
        }
        .sheet(isPresented: $isAddingBoat) {
            // HomeViewからボート追加画面をシートで表示
            AddBoatView(selectedBoatID: $selectedBoatID)
        }
    }
    
    private func scoreColor(score: Int) -> Color {
        if score >= 90 { return .green }
        if score >= 70 { return .orange }
        return .red
    }
}

// MARK: - ボートがない場合に表示するビュー
struct NoBoatView: View {
    @Binding var isAddingBoat: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "sailboat.fill").font(.system(size: 60)).foregroundColor(.secondary)
            Text("ようこそ Crewへ！").font(.title).fontWeight(.bold)
            Text("まずはあなたのボートを登録しましょう。").font(.subheadline).foregroundColor(.secondary)
            Button("最初のボートを追加する") { isAddingBoat = true }
                .buttonStyle(.borderedProminent).padding(.top)
        }
    }
}

// MARK: - ボート追加用のビュー
struct AddBoatView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var boatName: String = ""
    @Binding var selectedBoatID: String?
    
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
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
            }
        }
    }
    
    private func addBoat() {
        let newBoat = Boat(name: boatName, dataSets: [], checklist: [], rigItemTemplates: [])
        modelContext.insert(newBoat)
        try? modelContext.save()
        selectedBoatID = newBoat.id.uuidString
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Boat.self, inMemory: true)
}
