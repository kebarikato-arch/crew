import SwiftUI
import SwiftData

struct AddRigDataView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var boat: Boat
    var dataSetToEdit: RigDataSet?
    
    @State private var date: Date
    @State private var memo: String
    @State private var rigItems: [RigItem] = []
    
    private let categories = ["クラッチ", "ブッシュ", "ストレッチャー", "オール", "その他"]
    private let bushOptions = ["1・7", "2・6", "5・3", "4・4"]
    
    init(boat: Boat, dataSetToEdit: RigDataSet? = nil) {
        self.boat = boat
        self.dataSetToEdit = dataSetToEdit
        _date = State(initialValue: dataSetToEdit?.date ?? Date())
        _memo = State(initialValue: dataSetToEdit?.memo ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    DatePicker("日時", selection: $date)
                    TextField("メモ", text: $memo)
                }
                
                ForEach(categories, id: \.self) { category in
                    let itemsForCategory = rigItems.filter { $0.template?.category == category }
                    if !itemsForCategory.isEmpty {
                        Section(header: Text(category).font(.headline)) {
                            ForEach($rigItems) { $item in
                                if item.template?.category == category {
                                    if item.template?.name == "ブッシュ" {
                                        Picker(item.name, selection: $item.stringValue.defaultValue("")) {
                                            ForEach(bushOptions, id: \.self) { Text($0).tag($0) }
                                        }
                                    } else {
                                        HStack {
                                            Text(item.name)
                                            Spacer()
                                            TextField("値", value: $item.value, format: .number)
                                                .keyboardType(.decimalPad)
                                                .multilineTextAlignment(.trailing)
                                            Text(item.unit)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(dataSetToEdit == nil ? "新規データ" : "データを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("キャンセル") { dismiss() } }
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
        if dataSetToEdit == nil {
            self.rigItems = boat.rigItemTemplates.map { template in
                RigItem(name: template.name, value: 0.0, stringValue: template.name == "ブッシュ" ? bushOptions.first : nil, unit: template.unit, status: .normal, template: template)
            }
        } else {
            // 編集時はdataSetToEditから直接読み込む
            self.rigItems = dataSetToEdit?.rigItems.sorted(by: { $0.name < $1.name }) ?? []
        }
    }
    
    private func saveRigData() {
        if let dataSet = dataSetToEdit {
            dataSet.date = date
            dataSet.memo = memo
            // 変更はrigItemsのプロパティに直接反映されているため、再代入は不要
        } else {
            let newDataSet = RigDataSet(date: date, memo: memo)
            newDataSet.rigItems = self.rigItems
            boat.rigDataSets.append(newDataSet)
        }
    }
}

// Optional<String>をBindingで扱うためのヘルパー
extension Binding where Value == String? {
    func defaultValue(_ value: String) -> Binding<String> {
        return Binding<String>(
            get: { self.wrappedValue ?? value },
            set: { self.wrappedValue = $0 }
        )
    }
}
