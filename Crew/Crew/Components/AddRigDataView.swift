import SwiftUI
import SwiftData

struct AddRigDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    // データ編集対象のボート
    @Bindable var boat: Boat
    // 編集対象のデータセット（nilの場合は新規作成）
    var rigDataSet: RigDataSet?
    
    @State private var date: Date = .now
    @State private var memo: String = ""
    @State private var rigItems: [RigItem] = []

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本情報")) {
                    DatePicker("日時", selection: $date)
                    TextField("メモ", text: $memo)
                }
                
                Section(header: Text("リグアイテム")) {
                    ForEach($rigItems) { $item in
                        VStack(alignment: .leading) {
                            Text(item.name)
                                .font(.headline)
                            
                            if item.name == "ブッシュ" {
                                Picker("選択", selection: $item.stringValue) {
                                    Text("1・7").tag("1・7")
                                    Text("2・6").tag("2・6")
                                    Text("3・5").tag("3・5")
                                    Text("4・4").tag("4・4")
                                }
                                .pickerStyle(.segmented)
                            } else {
                                HStack {
                                    TextField("数値", value: $item.value, format: .number)
                                        .keyboardType(.decimalPad)
                                    Text(item.unit)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(rigDataSet == nil ? "リグデータを記録" : "リグデータを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveRigData()
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 画面表示時の初期設定
                if let dataSet = rigDataSet {
                    // 編集の場合
                    date = dataSet.date
                    memo = dataSet.memo
                    rigItems = dataSet.rigItems
                } else {
                    // 新規作成の場合
                    rigItems = boat.rigItemTemplates.map { template in
                        RigItem(name: template.name, value: 0.0, unit: template.unit, template: template)
                    }
                }
            }
        }
    }
    
    private func saveRigData() {
        if let dataSet = rigDataSet {
            // 既存データの更新
            dataSet.date = date
            dataSet.memo = memo
            dataSet.rigItems = rigItems
        } else {
            // 新規データの作成
            //【修正点】RigDataSetの初期化時に、どのボートのものかを 'boat' 引数で指定します
            let newDataSet = RigDataSet(date: date, memo: memo, boat: boat)
            newDataSet.rigItems = rigItems
            
            // context.insert(newDataSet) は boat とのリレーションにより自動で行われます
            boat.rigDataSets.append(newDataSet)
        }
    }
}
