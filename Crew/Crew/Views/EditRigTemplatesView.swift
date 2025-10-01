import SwiftUI
import SwiftData

struct EditRigTemplatesView: View {
    @Bindable var currentBoat: Boat
    @State private var newTemplateName = ""
    @State private var newTemplateUnit = ""
    @State private var selectedCategory = "クラッチ"
    private let categories = ["クラッチ", "ブッシュ", "ストレッチャー", "オール", "その他"]
    
    var body: some View {
        Form {
            Section(header: Text("リグ項目テンプレート")) {
                ForEach(currentBoat.rigItemTemplates) { template in
                    HStack {
                        Text(template.name)
                        Spacer()
                        Text(template.unit)
                            .foregroundColor(.gray)
                    }
                }
                .onDelete(perform: deleteTemplate)
            }
            
            Section(header: Text("新しい項目を追加")) {
                TextField("項目名", text: $newTemplateName)
                TextField("単位", text: $newTemplateUnit)
                
                Picker("カテゴリ", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) {
                        Text($0)
                    }
                }
                
                Button(action: addTemplate) {
                    Text("追加")
                }
                .disabled(newTemplateName.isEmpty)
            }
        }
        .navigationTitle("テンプレートを編集")
    }
    
    private func addTemplate() {
        let newTemplate = RigItemTemplate(name: newTemplateName, unit: newTemplateUnit, category: selectedCategory)
        currentBoat.rigItemTemplates.append(newTemplate)
        newTemplateName = ""
        newTemplateUnit = ""
    }
    
    private func deleteTemplate(at offsets: IndexSet) {
        currentBoat.rigItemTemplates.remove(atOffsets: offsets)
    }
}
