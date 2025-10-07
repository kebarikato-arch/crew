import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Boat.name) private var boats: [Boat]
    
    // 他の画面と統一するため、Binding<Boat>でデータを受け取るように変更します
    @Binding var currentBoat: Boat
    
    @State private var showingAddRigDataView = false
    
    var body: some View {
        NavigationStack {
            VStack {
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
                    VStack(spacing: 20) {
                        RigSettingCardView(currentBoat: currentBoat)
                        
                        VStack(alignment: .leading) {
                            Text("リグ設定の履歴")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            if currentBoat.rigDataSets.isEmpty {
                                Text("データがありません")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(currentBoat.rigDataSets.sorted(by: { $0.date > $1.date })) { dataSet in
                                    NavigationLink(destination: RigHistoryDetailView(rigDataSet: dataSet)) {
                                        RigDataSetRow(dataSet: dataSet)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("My Rig")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    showingAddRigDataView = true
                }) {
                    Text("リグデータを記録")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding()
                }
                .background(.thinMaterial)
            }
            .sheet(isPresented: $showingAddRigDataView) {
                AddRigDataView(boat: currentBoat)
            }
        }
    }
}
