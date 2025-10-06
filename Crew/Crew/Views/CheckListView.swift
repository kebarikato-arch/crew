import SwiftUI
import SwiftData

struct CheckListView: View {
    @Binding var currentBoat: Boat
    
    @Environment(\.modelContext) private var context
    @State private var showingAddItemView = false
    @State private var itemToEdit: CheckListItem?

    private func filteredItems(for category: String) -> [CheckListItem] {
        currentBoat.checklist.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("セーリング前")) {
                    ForEach(filteredItems(for: "セーリング前")) { item in
                        CheckListItemRow(item: item)
                    }
                    .onDelete { indices in
                        deleteItems(at: indices, in: "セーリング前")
                    }
                }
                
                Section(header: Text("セーリング後")) {
                    ForEach(filteredItems(for: "セーリング後")) { item in
                        CheckListItemRow(item: item)
                    }
                    .onDelete { indices in
                        deleteItems(at: indices, in: "セーリング後")
                    }
                }
            }
            .navigationTitle("Checklist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        itemToEdit = nil
                        showingAddItemView = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddItemView) {
                AddEditChecklistItemView(boat: currentBoat, itemToEdit: $itemToEdit)
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet, in category: String) {
        let itemsToDelete = offsets.map { filteredItems(for: category)[$0] }
        for item in itemsToDelete {
            context.delete(item)
        }
    }
}

struct CheckListItemRow: View {
    @Bindable var item: CheckListItem

    var body: some View {
        Toggle(isOn: $item.isCompleted) {
            Text(item.task)
                .strikethrough(item.isCompleted, color: .secondary)
                .foregroundColor(item.isCompleted ? .secondary : .primary)
        }
    }
}

struct AddEditChecklistItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var boat: Boat
    @Binding var itemToEdit: CheckListItem?
    
    @State private var task: String = ""
    @State private var category: String = "セーリング前"
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("タスク", text: $task)
                Picker("カテゴリ", selection: $category) {
                    Text("セーリング前").tag("セーリング前")
                    Text("セーリング後").tag("セーリング後")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .navigationTitle(itemToEdit == nil ? "項目を追加" : "項目を編集")
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
                    .disabled(task.isEmpty)
                }
            }
            .onAppear {
                if let item = itemToEdit {
                    task = item.task
                    category = item.category
                }
            }
        }
    }
    
    private func saveItem() {
        if let item = itemToEdit {
            item.task = task
            item.category = category
        } else {
            //【修正点】CheckListItemの初期化時に、どのボートのものかを 'boat' 引数で指定します
            let newItem = CheckListItem(task: task, isCompleted: false, category: category, boat: boat)
            boat.checklist.append(newItem)
        }
    }
}
