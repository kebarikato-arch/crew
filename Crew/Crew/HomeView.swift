// HomeView.swift の全文

import SwiftUI
import Charts
import SwiftData

struct HomeView: View {
    @Bindable var currentBoat: Boat
    
    @State private var selectedTab: RigDataType = .current
    @State private var isAddingData = false
    
    private var safetyScore: Int {
        guard let latestData = currentBoat.latestDataSet else { return 100 }
        
        let expiredCount = latestData.elements.filter { $0.status == .expired }.count
        let maintenanceCount = latestData.elements.filter { $0.status == .maintenance }.count
        
        return max(0, 100 - (expiredCount * 30) - (maintenanceCount * 10))
    }
    
    // ✅ ① 「.checklist」を削除
    enum RigDataType: String, CaseIterable {
        case current = "現在の設定"
        case history = "ログ履歴"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // MARK: - ヘッダー部分
                VStack(spacing: 15) {
                    HStack {
                        Text(currentBoat.name)
                            .font(.title2)
                            .fontWeight(.medium)
                        Spacer()
                        
                        Button {
                            isAddingData = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("\(safetyScore)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor(score: safetyScore))
                    + Text("/100")
                        .font(.title)
                        .foregroundColor(.secondary)
                    
                    Text("Rig Safety Score")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    SegmentedControl(selectedTab: $selectedTab)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                }
                .padding(.top)

                // MARK: - コンテンツリスト
                ScrollView {
                    VStack(spacing: 12) {
                        if selectedTab == .current,
                           let latestData = currentBoat.latestDataSet {
                            
                            ForEach(latestData.elements) { item in
                                NavigationLink {
                                    RigItemDetailView(item: item, allDataSets: currentBoat.dataSets)
                                } label: {
                                    RigSettingCardView(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text("最終更新日: \(latestData.date, style: .date) \(latestData.date, style: .time)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 10)

                        } else if selectedTab == .history {
                            if currentBoat.dataSets.isEmpty {
                                Text("ログ履歴がありません。")
                                    .foregroundColor(.gray)
                                    .padding(.top, 50)
                            } else {
                                ForEach(currentBoat.dataSets.sorted(by: { $0.date > $1.date })) { dataSet in
                                    NavigationLink {
                                        RigHistoryDetailView(boat: currentBoat, dataSet: dataSet)
                                    } label: {
                                        RigDataSetRow(dataSet: dataSet)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        // ✅ ① .checklist の分岐を削除
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isAddingData) {
                AddRigDataView(boat: currentBoat)
            }
        }
    }
    
    private func scoreColor(score: Int) -> Color {
        if score >= 90 { return .green }
        if score >= 70 { return .orange }
        return .red
    }
}

#Preview {
    let exampleBoat = Boat.dummy
    return HomeView(currentBoat: exampleBoat)
        .modelContainer(for: Boat.self, inMemory: true)
}
