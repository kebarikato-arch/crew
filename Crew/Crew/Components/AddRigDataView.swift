/// AddRigDataView.swift の全文

import SwiftUI
import SwiftData

struct AddRigDataView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var boat: Boat
    let dataSetToEdit: RigDataSet?
    
    @State private var recordDate: Date
    @State private var memo: String
    
    // MARK: 【✅ 修正】編集対象のアイテムを RigItemTemplate から生成するように変更
    private var templates: [RigItemTemplate] {
        boat.rigItemTemplates.sorted(by: { $0.name < $1.name })
    }
    
    // Formの各RigItemの値をバインドするための中間表現
    @State private var itemValues: [String]
    @State private var itemStatuses: [RigItem.Status]
    
    init(boat: Boat, dataSetToEdit: RigDataSet? = nil) {
        self._boat = Bindable(boat)
        self.dataSetToEdit = dataSetToEdit
        
        if let existingSet = dataSetToEdit {
            // --- 編集モード ---
            self._recordDate = State(initialValue: existingSet.date)
            self._memo = State(initialValue: existingSet.memo)
            
            // テンプレートに基づいて編集中の値を初期化
            let sortedTemplates = boat.rigItemTemplates.sorted(by: { $0.name < $1.name })
            var values: [String] = []
            var statuses: [RigItem.Status] = []
            
            for template in sortedTemplates {
                if let existingItem = existingSet.elements.first(where: { $0.name == template.name }) {
                    values.append(existingItem.value)
                    statuses.append(existingItem.status)
                } else {
                    // 既存データにテンプレート項目がなければデフォルト値
                    values.append("0")
                    statuses.append(.normal)
                }
            }
            self._itemValues = State(initialValue: values)
            self._itemStatuses = State(initialValue: statuses)
            
        } else {
            // --- 新規モード ---
            self._recordDate = State(initialValue: Date())
            self._memo = State(initialValue: "")
            
            // MARK: 【✅ 修正】Boatに保存されているテンプレートから初期値を生成
            let count = boat.rigItemTemplates.count
            self._itemValues = State(initialValue: Array(repeating: "0", count: count))
            self._itemStatuses = State(initialValue: Array(repeating: .normal, count: count))
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("ログ情報")) {
                    DatePicker("記録日", selection: $recordDate)
                    TextField("メモ（例：強風用セッティング）", text: $memo)
                }
                
                Section(header: Text("リグ設定値")) {
                    // MARK: 【✅ 修正】テンプレートの配列を元にループ処理
                    ForEach(templates.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(templates[index].name)
                                .font(.headline)
                            HStack {
                                TextField("値", text: $itemValues[index])
                                    .keyboardType(.decimalPad)
                                Text(templates[index].unit)
                                Spacer()
                                Picker("状態", selection: $itemStatuses[index]) {
                                    ForEach(RigItem.Status.allCases, id: \.self) { status in
                                        Text(status.rawValue).tag(status)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                }
            }
            .navigationTitle(dataSetToEdit == nil ? "新しいリグデータの追加" : "ログを編集")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveData()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveData() {
        // MARK: 【✅ 修正】永続化用のRigItem配列をテンプレートを元に生成
        let finalItems = templates.indices.map { index -> RigItem in
            let template = templates[index]
            return RigItem(
                name: template.name,
                value: itemValues[index],
                unit: template.unit,
                status: itemStatuses[index]
            )
        }
        
        if let dataSet = dataSetToEdit {
            // --- 編集モード ---
            dataSet.date = recordDate
            dataSet.memo = memo
            // 関連するRigItemを一度クリアして、新しいもので置き換える
            dataSet.elements.forEach { modelContext.delete($0) }
            dataSet.elements = finalItems
        } else {
            // --- 新規モード ---
            let newDataSet = RigDataSet(
                date: recordDate,
                memo: memo,
                elements: finalItems
            )
            boat.dataSets.append(newDataSet)
        }
    }
}
