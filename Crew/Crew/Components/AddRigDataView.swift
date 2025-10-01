import SwiftUI
import SwiftData

struct AddRigDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var currentBoat: Boat
    var rigDataSet: RigDataSet? // 編集対象のデータセット
    
    @State private var date: Date
    @State private var memo: String
    @State private var rigItems: [RigItem] = []
    
    // カテゴリとブッシュの選択肢
    private let categories = ["クラッチ", "ブッシュ", "ストレッチャー", "オール", "その他"]
    private let bushOptions = ["1・7", "2・6", "5・3", "4・4"]
    
    init(currentBoat: Boat, rigDataSet: RigDataSet? = nil) {
        self.currentBoat = currentBoat
        self.rigDataSet = rigDataSet
        
        _date = State(initialValue: rigDataSet?.date ?? Date())
        _memo = State(initialValue: rigDataSet?.memo ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("日時", selection: $date)
                    TextField("メモ", text: $memo)
                }
                
                // カテゴリごとに項目をグループ化して表示
                ForEach(categories, id: \.self) { category in
                    let itemsForCategory = rigItems.filter { $0.template.category == category }
                    if !itemsForCategory.isEmpty {
                        Section(header: Text(category).font(.headline)) {
                            ForEach(itemsForCategory) { rigItem in
                                if let index = rigItems.firstIndex(where: { $0.id == rigItem.id }) {
                                    // ブッシュ項目の場合、ピッカーを表示
                                    if rigItem.template.name == "ブッシュ" {
                                        Picker(selection: Binding(
                                            get: { rigItems[index].stringValue ?? "" },
                                            set: { rigItems[index].stringValue = $0 }
                                        ), label: Text(rigItem.template.name)) {
                                            ForEach(bushOptions, id: \.self) {
                                                Text($0)
                                            }
                                        }
                                    } else {
                                        // それ以外の項目はこれまで通り
                                        HStack {
                                            Text(rigItem.template.name)
                                            Spacer()
                                            TextField("値", value: $rigItems[index].value, format: .number)
                                                .keyboardType(.decimalPad)
                                                .multilineTextAlignment(.trailing)
                                            Text(rigItem.template.unit)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(rigDataSet == nil ? "新規データ" : "データを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRigData()
                        dismiss()
                    }
                }
            }
            .onAppear(perform: setupRigItems)
        }
    }
    
    private func setupRigItems() {
        if let templates = currentBoat.rigItemTemplates {
            self.rigItems = templates.map { template in
                // 編集モードの場合、既存の値を探す
                if let rigDataSet = rigDataSet, let item = rigDataSet.rigItems.first(where: { $0.template.id == template.id }) {
                    return RigItem(name: item.name, value: item.value, stringValue: item.stringValue, unit: item.unit, status: item.status, template: template)
                } else {
                    // 新規作成の場合、デフォルト値を設定
                    return RigItem(name: template.name, value: 0.0, stringValue: template.name == "ブッシュ" ? bushOptions.first : nil, unit: template.unit, status: .normal, template: template)
                }
            }
        }
    }
    
    private func saveRigData() {
        let dataSetToSave: RigDataSet
        if let rigDataSet = rigDataSet {
            // 既存のデータを更新
            dataSetToSave = rigDataSet
            dataSetToSave.date = date
            dataSetToSave.memo = memo
            dataSetToSave.rigItems.removeAll()
        } else {
            // 新しいデータを作成
            dataSetToSave = RigDataSet(date: date, memo: memo)
            currentBoat.rigDataSets.append(dataSetToSave)
        }
        
        for item in rigItems {
            dataSetToSave.rigItems.append(item)
        }
    }
}
