import SwiftUI
import SwiftData

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
    }
}

struct CheckListView: View {
    // MARK: 【修正】 @Bindableを使用してboatオブジェクトへのBindingを受け取る
    @Bindable var boat: Boat
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    
    @State private var showingAddItemSheet = false
    @State private var itemToEdit: CheckListItem?
    
    private let categories = CheckListItem.Category.allCases
    
    var body: some View {
        NavigationView {
            Form {
                ForEach(categories, id: \.self) { category in
                    Section(header: Text(category.rawValue)) {
                        // MARK: 【修正】 boat.checklistを直接ループし、中でフィルタリングする
                        ForEach(boat.checklist) { item in
                            if item.category == category.rawValue {
                                Toggle(isOn: Binding(
                                    get: { item.isCompleted },
                                    set: { item.isCompleted = $0 }
                                )) {
                                    Text(item.task)
                                }
                                .toggleStyle(CheckboxToggleStyle())
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if editMode?.wrappedValue.isEditing == false {
                                        itemToEdit = item
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("チェックリスト")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { EditButton() }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddItemSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                AddEditChecklistItemView(boat: boat, itemToEdit: nil)
            }
            .sheet(item: $itemToEdit) { item in
                AddEditChecklistItemView(boat: boat, itemToEdit: item)
            }
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let itemToDelete = boat.checklist[index]
            modelContext.delete(itemToDelete)
        }
        // boat.checklist.remove(atOffsets: offsets) を使わない
    }
}

struct AddEditChecklistItemView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var boat: Boat
    let itemToEdit: CheckListItem?
    
    @State private var itemTask: String = ""
    @State private var selectedCategory: CheckListItem.Category = .beforeSail
    
    private var isEditing: Bool { itemToEdit != nil }
    private var title: String { isEditing ? "項目を編集" : "項目を追加" }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("項目情報")) {
                    TextField("項目名", text: $itemTask)
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
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveItem()
                        dismiss()
                    }
                    .disabled(itemTask.isEmpty)
                }
            }
            .onAppear {
                if let item = itemToEdit {
                    itemTask = item.task
                    selectedCategory = CheckListItem.Category(rawValue: item.category) ?? .beforeSail
                }
            }
        }
    }
    
    private func saveItem() {
        if let item = itemToEdit {
            item.task = itemTask
            item.category = selectedCategory.rawValue
        } else {
            let newItem = CheckListItem(task: itemTask, isCompleted: false, category: selectedCategory.rawValue)
            boat.checklist.append(newItem)
        }
    }
}
