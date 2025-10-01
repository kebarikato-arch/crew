/// CheckListView.swift の全文

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
    @Environment(\.editMode) private var editMode
    
    // MARK: 【修正】シート表示用の状態変数を整理
    @State private var showingAddItemSheet = false
    @State private var itemToEdit: CheckListItem?

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
                            // MARK: 【新規追加】項目タップで編集シートを表示
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if editMode?.wrappedValue.isEditing == false {
                                    itemToEdit = item
                                }
                            }
                        }
                        .onDelete { indexSet in
                            deleteItems(at: indexSet, for: category)
                        }
                        .onMove { from, to in
                            moveItems(from: from, to: to, for: category)
                        }
                    }
                }
            }
            .navigationTitle("チェックリスト")
            .toolbar {
                // MARK: 【修正】ツールバーに編集ボタンと追加ボタンを配置
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItemSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            // MARK: 【修正】追加用と編集用のシートを定義
            .sheet(isPresented: $showingAddItemSheet) {
                AddEditChecklistItemView(boat: boat, itemToEdit: nil)
            }
            .sheet(item: $itemToEdit) { item in
                AddEditChecklistItemView(boat: boat, itemToEdit: item)
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet, for category: CheckListItem.Category) {
        let itemsToDelete = offsets.map { filteredChecklist(for: category)[$0] }
        for item in itemsToDelete {
            modelContext.delete(item)
        }
    }
    
    // MARK: 【新規追加】項目を並べ替える関数
    private func moveItems(from source: IndexSet, to destination: Int, for category: CheckListItem.Category) {
        var categorizedItems = filteredChecklist(for: category)
        categorizedItems.move(fromOffsets: source, toOffset: destination)
        
        // 元のchecklist配列から該当カテゴリのアイテムを一旦削除
        boat.checklist.removeAll { $0.category == category }
        
        // 並べ替えた配列を再追加
        boat.checklist.append(contentsOf: categorizedItems)
    }
}

// MARK: - 【修正】チェックリスト項目を追加・編集するための汎用ビュー
struct AddEditChecklistItemView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var boat: Boat
    let itemToEdit: CheckListItem?
    
    @State private var itemName: String = ""
    @State private var selectedCategory: CheckListItem.Category = .beforeSail
    
    private var isEditing: Bool { itemToEdit != nil }
    private var title: String { isEditing ? "項目を編集" : "項目を追加" }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("項目情報")) {
                    TextField("項目名", text: $itemName)
                    Picker("カテゴリ", selection: $selectedCategory) {
                        ForEach(CheckListItem.Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(itemName.isEmpty)
                }
            }
        }
        .onAppear {
            // 編集モードの場合、既存の値をフォームに設定
            if let item = itemToEdit {
                itemName = item.name
                selectedCategory = item.category
            }
        }
    }
    
    private func saveItem() {
        if let item = itemToEdit {
            // --- 編集モード ---
            item.name = itemName
            item.category = selectedCategory
        } else {
            // --- 新規モード ---
            let newItem = CheckListItem(name: itemName, isCompleted: false, category: selectedCategory)
            boat.checklist.append(newItem)
        }
    }
}


#Preview {
    let exampleBoat = Boat.dummy
    return CheckListView(boat: exampleBoat)
        .modelContainer(for: Boat.self, inMemory: true)
}
