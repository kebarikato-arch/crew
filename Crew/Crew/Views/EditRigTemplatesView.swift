// EditRigTemplatesView.swift の全文

import SwiftUI
import SwiftData

struct EditRigTemplatesView: View {
    @Bindable var boat: Boat
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddItemSheet = false
    
    var body: some View {
        Form {
            Section(header: Text("リグアイテム テンプレート")) {
                // 保存されているテンプレートを一覧表示
                ForEach(boat.rigItemTemplates) { template in
                    HStack {
                        Text(template.name)
                        Spacer()
                        Text(template.unit)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: deleteTemplate)
                
                // 新しいテンプレートを追加するボタン
                Button("新しいテンプレートを追加") {
                    showingAddItemSheet = true
                }
            }
        }
        .navigationTitle("テンプレートを編集")
        .toolbar {
            // 編集ボタン（リストの移動や削除に使う標準UI）
            EditButton()
        }
        .sheet(isPresented: $showingAddItemSheet) {
            AddRigTemplateView(boat: boat)
        }
    }
    
    // テンプレートを削除する関数
    private func deleteTemplate(at offsets: IndexSet) {
        for index in offsets {
            let templateToDelete = boat.rigItemTemplates[index]
            modelContext.delete(templateToDelete)
        }
    }
}


// MARK: - 新しいテンプレートを追加するためのView
struct AddRigTemplateView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var boat: Boat
    
    @State private var name: String = ""
    @State private var unit: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("新しいテンプレート")) {
                    TextField("アイテム名 (例: フォアステイ)", text: $name)
                    TextField("単位 (例: %)", text: $unit)
                }
            }
            .navigationTitle("テンプレートを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        addTemplate()
                        dismiss()
                    }
                    .disabled(name.isEmpty || unit.isEmpty)
                }
            }
        }
    }
    
    private func addTemplate() {
        let newTemplate = RigItemTemplate(name: name, unit: unit)
        boat.rigItemTemplates.append(newTemplate)
    }
}


#Preview {
    // NavigationStackを追加してプレビュー
    NavigationView {
        EditRigTemplatesView(boat: Boat.dummy)
            .modelContainer(for: Boat.self, inMemory: true)
    }
}
