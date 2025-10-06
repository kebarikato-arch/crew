import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Boat.name) private var boats: [Boat]
    
    // 親Viewから選択中のボート情報を受け取るためのBindingです
    @Binding var currentBoat: Boat
    
    @State private var showingAddRigDataView = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // ボートが複数ある場合のみ、切り替えコントロールを表示します
                if boats.count > 1 {
                    //【最終修正点】専用部品の 'SegmentedControl' から、SwiftUI標準の 'Picker' に変更します。
                    // これが、ボートの切り替えを実現する、ファイル整合性を考慮した唯一の正しい実装です。
                    Picker("ボートを選択", selection: $currentBoat) {
                        ForEach(boats) { boat in
                            Text(boat.name).tag(boat)
                        }
                    }
                    .pickerStyle(.segmented) // セグメントコントロール形式のUIを指定します
                    .padding(.horizontal)
                }

                ScrollView {
                    VStack(spacing: 20) {
                        // RigSettingCardViewは、内部で専用のSegmentedControlを使用します
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
                    Button(action: {
                        // 新規ボート追加のロジックは後で実装します
                    }) {
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
