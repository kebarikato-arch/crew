import SwiftUI
import SwiftData

struct HomeView: View {
    // ContentViewから渡されるデータ
    let boats: [Boat]
    @Binding var selectedBoatId: String?
    let currentBoat: Boat?
    
    @State private var showingAddRigDataView = false
    @State private var isAddingBoat = false // ボート追加画面の表示状態を管理

    var body: some View {
        NavigationStack {
            // boats配列が空の場合にWelcomeViewを表示します
            if boats.isEmpty {
                WelcomeView(isAddingBoat: $isAddingBoat)
            } else if let boat = currentBoat {
                // ボートが存在する場合のメイン画面
                VStack(spacing: 20) {
                    if boats.count > 1 {
                        Picker("ボートを選択", selection: $selectedBoatId) {
                            ForEach(boats) { boat in
                                Text(boat.name).tag(boat.id.uuidString as String?)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }

                    ScrollView {
                        VStack(spacing: 20) {
                            RigSettingCardView(currentBoat: boat)
                            
                            VStack(alignment: .leading) {
                                Text("リグ設定の履歴")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)

                                if boat.rigDataSets.isEmpty {
                                    Text("データがありません")
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding()
                                } else {
                                    ForEach(boat.rigDataSets.sorted(by: { $0.date > $1.date })) { dataSet in
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
                        Button(action: { isAddingBoat = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button(action: { showingAddRigDataView = true }) {
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
                    AddRigDataView(boat: boat)
                }
            }
        }
        .sheet(isPresented: $isAddingBoat) {
            AddBoatView(selectedBoatID: $selectedBoatId)
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
                Section {
                    TextField("ボート名", text: $boatName)
                }
                
                Section {
                    Button("保存") {
                        addBoat()
                        dismiss()
                    }
                    .disabled(boatName.isEmpty)
                }
            }
            .navigationTitle("新しいボート")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
    }
    
    private func addBoat() {
        // 【最重要修正点】Boatモデルで定義された正しい初期化方法を使用します
        let newBoat = Boat(name: boatName)
        modelContext.insert(newBoat)
        
        do {
            try modelContext.save() // 変更を確実に保存
            // 保存が成功した場合にのみ、新しいボートを選択状態にします
            selectedBoatID = newBoat.id.uuidString
        } catch {
            // エラーが発生した場合はコンソールに出力します
            print("ボートの保存に失敗しました: \(error)")
        }
    }
}
