import SwiftUI
import SwiftData

struct EditRigTemplatesView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var boat: Boat

    @State private var newTemplateName = ""
    @State private var newTemplateUnit = ""
    @State private var selectedCategory = "Mast"
    let categories = ["Mast", "Boom", "Hull", "Other"]

    var body: some View {
        Form {
            Section("Add New Template") {
                TextField("Item Name", text: $newTemplateName)
                TextField("Unit (e.g., mm, deg)", text: $newTemplateUnit)
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) {
                        Text($0)
                    }
                }
                Button("Add Template") {
                    addTemplate()
                }
                .disabled(newTemplateName.isEmpty)
            }

            Section("Existing Templates") {
                ForEach(boat.rigItemTemplates) { template in
                    VStack(alignment: .leading) {
                        Text(template.name).bold()
                        Text("Unit: \(template.unit), Category: \(template.category)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onDelete(perform: deleteTemplate)
            }
        }
        .navigationTitle("Edit Templates")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addTemplate() {
        //【修正点】RigItemTemplateの初期化時に、どのボートのものかを 'boat' 引数で指定します
        let newTemplate = RigItemTemplate(name: newTemplateName, unit: newTemplateUnit, category: selectedCategory, boat: boat)
        boat.rigItemTemplates.append(newTemplate)
        
        // 入力フィールドをリセット
        newTemplateName = ""
        newTemplateUnit = ""
    }

    private func deleteTemplate(at offsets: IndexSet) {
        boat.rigItemTemplates.remove(atOffsets: offsets)
    }
}
