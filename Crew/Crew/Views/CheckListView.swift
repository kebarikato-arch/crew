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
                Section(header: Text("レース前チェック")) {
                    ForEach(filteredItems(for: "レース前チェック")) { item in
                        CheckListItemRow(item: item)
                    }
                    .onDelete { indices in
                        deleteItems(at: indices, in: "レース前チェック")
                    }
                }
                
                Section(header: Text("持ち物")) {
                    ForEach(filteredItems(for: "持ち物")) { item in
                        CheckListItemRow(item: item)
                    }
                    .onDelete { indices in
                        deleteItems(at: indices, in: "持ち物")
                    }
                }
            }
            .navigationTitle("チェックリスト")
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
        Button(action: {
            item.isCompleted.toggle()
        }) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22))
                    .foregroundColor(item.isCompleted ? .accentColor : .secondary)
                
                Text(item.task)
                    .foregroundColor(.primary)
                    .strikethrough(item.isCompleted, color: .secondary)
                    .opacity(item.isCompleted ? 0.6 : 1.0)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddEditChecklistItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var boat: Boat
    @Binding var itemToEdit: CheckListItem?
    
    @State private var task: String = ""
    @State private var category: String = "レース前チェック"
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("項目名", text: $task)
                Picker("カテゴリ", selection: $category) {
                    Text("レース前チェック").tag("レース前チェック")
                    Text("持ち物").tag("持ち物")
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
