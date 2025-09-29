// CheckListView.swift の全文

import SwiftUI
import SwiftData

// MARK: - カスタムToggleStyle
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .strikethrough(configuration.isOn)
                .foregroundColor(configuration.isOn ? .secondary : .primary)

            Spacer()

            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(configuration.isOn ? .blue : .gray)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - メインビュー

struct CheckListView: View {
    @Bindable var boat: Boat
    @Environment(\.modelContext) private var modelContext
    
    // MARK: 【✅ 新規追加】項目追加用のシート表示状態
    @State private var showingAddItemSheet = false
    @State private var selectedCategory: CheckListItem.Category = .beforeSail

    private func filteredChecklist(for category: CheckListItem.Category) -> [CheckListItem] {
        return boat.checklist.filter { $0.category == category }
    }

    var body: some View {
        NavigationView {
            Form {
                ForEach(CheckListItem.Category.allCases, id: \.self) { category in
                    Section(header: Text(category.rawValue)) {
                        ForEach(filteredChecklist(for: category)) { item in
                            Toggle(isOn: Binding(
                                get: { item.isCompleted },
                                set: { newValue in item.isCompleted = newValue }
                            )) {
                                Text(item.name)
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }
                        // MARK: 【✅ 新規追加】削除処理
                        .onDelete { indexSet in
                            deleteItems(at: indexSet, for: category)
                        }
                    }
                }
            }
            .navigationTitle("チェックリスト")
            // MARK: 【✅ 新規追加】ツールバーに編集ボタンを追加
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItemSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // MARK: 【✅ 新規追加】項目追加用のシート
            .sheet(isPresented: $showingAddItemSheet) {
                AddChecklistItemView(boat: boat)
            }
        }
    }
    
    // MARK: 【✅ 新規追加】チェックリスト項目を削除する関数
    private func deleteItems(at offsets: IndexSet, for category: CheckListItem.Category) {
        let itemsToDelete = offsets.map { filteredChecklist(for: category)[$0] }
        for item in itemsToDelete {
            modelContext.delete(item)
        }
    }
}

// MARK: - 【✅ 新規追加】チェックリスト項目を追加するためのビュー
struct AddChecklistItemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var boat: Boat
    
    @State private var itemName: String = ""
    @State private var selectedCategory: CheckListItem.Category = .beforeSail
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("新しい項目")) {
                    TextField("項目名", text: $itemName)
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(CheckListItem.Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("項目を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        addItem()
                        dismiss()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
        }
    }
    
    private func addItem() {
        let newItem = CheckListItem(name: itemName, isCompleted: false, category: selectedCategory)
        boat.checklist.append(newItem)
    }
}


#Preview {
    let exampleBoat = Boat.dummy
    return CheckListView(boat: exampleBoat)
        .modelContainer(for: Boat.self, inMemory: true)
}
