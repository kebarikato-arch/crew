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
                
                // リグアイテムをカテゴリごとに表示
                let categoryForIndex: (Int) -> String = { idx in
                    rigItems[idx].template?.category ?? "その他"
                }
                let groupedIndices: [String: [Int]] = Dictionary(grouping: rigItems.indices, by: categoryForIndex)
                let preferredOrder = ["クラッチ", "ストレッチャー", "オール", "その他"]
                let sortedCategories = groupedIndices.keys.sorted { a, b in
                    let ia = preferredOrder.firstIndex(of: a) ?? Int.max
                    let ib = preferredOrder.firstIndex(of: b) ?? Int.max
                    return ia == ib ? a < b : ia < ib
                }

                ForEach(sortedCategories, id: \.self) { category in
                    Section(header: Text(category)) {
                        // クラッチのみ指定順で並べ替え
                        let clutchOrder = ["ワークハイトB", "ワークハイトS", "スパン", "ブッシュ", "前傾", "後傾"]
                        let clutchIndex: [String: Int] = Dictionary(uniqueKeysWithValues: clutchOrder.enumerated().map { ($1, $0) })
                        let indices: [Int] = (groupedIndices[category] ?? []).sorted { a, b in
                            if category == "クラッチ" {
                                let ia = clutchIndex[rigItems[a].name] ?? Int.max
                                let ib = clutchIndex[rigItems[b].name] ?? Int.max
                                return ia == ib ? rigItems[a].name < rigItems[b].name : ia < ib
                            }
                            return rigItems[a].name < rigItems[b].name
                        }
                        ForEach(indices, id: \.self) { idx in
                            VStack(alignment: .leading) {
                                Text(rigItems[idx].name)
                                    .font(.headline)

                                if rigItems[idx].name == "ブッシュ" {
                                    Picker("選択", selection: $rigItems[idx].stringValue) {
                                        Text("1・7").tag("1・7" as String?)
                                        Text("2・6").tag("2・6" as String?)
                                        Text("3・5").tag("3・5" as String?)
                                        Text("4・4").tag("4・4" as String?)
                                    }
                                    .pickerStyle(.segmented)
                                } else {
                                    HStack {
                                        TextField("数値", value: $rigItems[idx].value, format: .number)
                                            .keyboardType(.decimalPad)
                                        Text(rigItems[idx].unit)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .environment(\.locale, Locale(identifier: "ja_JP"))
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
                    // 新規作成の場合：直近のデータセットの値を初期値として引き継ぐ
                    if let latest = boat.rigDataSets.sorted(by: { $0.date > $1.date }).first, !latest.rigItems.isEmpty {
                        // テンプレートIDでマッチング（無い場合は名前+単位でフォールバック）
                        let byTemplateId: [UUID: RigItem] = Dictionary(uniqueKeysWithValues:
                            latest.rigItems.compactMap { item in
                                guard let id = item.template?.id else { return nil }
                                return (id, item)
                            }
                        )
                        rigItems = boat.rigItemTemplates.map { template in
                            if let matched = byTemplateId[template.id] {
                                return RigItem(
                                    name: template.name,
                                    value: matched.value,
                                    stringValue: matched.stringValue,
                                    unit: template.unit,
                                    status: matched.status,
                                    template: template
                                )
                            } else if let fallback = latest.rigItems.first(where: { $0.name == template.name && $0.unit == template.unit }) {
                                return RigItem(
                                    name: template.name,
                                    value: fallback.value,
                                    stringValue: fallback.stringValue,
                                    unit: template.unit,
                                    status: fallback.status,
                                    template: template
                                )
                            } else {
                                return RigItem(name: template.name, value: 0.0, unit: template.unit, template: template)
                            }
                        }
                    } else {
                        // 直近が無ければテンプレートから空の行を生成
                        rigItems = boat.rigItemTemplates.map { template in
                            RigItem(name: template.name, value: 0.0, unit: template.unit, template: template)
                        }
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
