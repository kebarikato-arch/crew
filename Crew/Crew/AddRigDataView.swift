// AddRigDataView.swift の全文

import SwiftUI
import SwiftData

struct AddRigDataView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var boat: Boat
    let dataSetToEdit: RigDataSet?
    
    @State private var recordDate: Date
    @State private var memo: String
    @State private var editableItems: [RigItem]
    
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
            
            let copiedItems = existingSet.elements.map { item in
                return RigItem(name: item.name, value: item.value, unit: item.unit, status: item.status)
            }
            self._editableItems = State(initialValue: copiedItems)
            self._itemValues = State(initialValue: copiedItems.map { $0.value })
            self._itemStatuses = State(initialValue: copiedItems.map { $0.status })
            
        } else {
            // --- 新規モード ---
            self._recordDate = State(initialValue: Date())
            self._memo = State(initialValue: "")
            
            let copiedTemplate = boat.rigItemTemplate.map { item in
                return RigItem(name: item.name, value: "0", unit: item.unit, status: .normal)
            }
            self._editableItems = State(initialValue: copiedTemplate)
            self._itemValues = State(initialValue: copiedTemplate.map { $0.value })
            self._itemStatuses = State(initialValue: copiedTemplate.map { $0.status })
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
                    ForEach(editableItems.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(editableItems[index].name)
                                .font(.headline)
                            HStack {
                                TextField("値", text: $itemValues[index])
                                    .keyboardType(.decimalPad)
                                Text(editableItems[index].unit)
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
    
    // ✅ ② saveData() にロジックを実装
    private func saveData() {
        // Stateから永続化用のRigItem配列を生成
        let finalItems = editableItems.indices.map { index -> RigItem in
            let item = editableItems[index]
            // 新しいインスタンスを返すことで、SwiftDataが変更を検知
            return RigItem(
                name: item.name,
                value: itemValues[index],
                unit: item.unit,
                status: itemStatuses[index]
            )
        }
        
        if let dataSet = dataSetToEdit {
            // --- 編集モード ---
            // 既存のデータセットのプロパティを更新
            dataSet.date = recordDate
            dataSet.memo = memo
            // 関連するRigItemを一度クリアして、新しいもので置き換える
            dataSet.elements.forEach { modelContext.delete($0) }
            dataSet.elements = finalItems
        } else {
            // --- 新規モード ---
            // 新しいデータセットを作成
            let newDataSet = RigDataSet(
                date: recordDate,
                memo: memo,
                elements: finalItems
            )
            // Boatとのリレーションシップに追加
            boat.dataSets.append(newDataSet)
        }
    }
}
