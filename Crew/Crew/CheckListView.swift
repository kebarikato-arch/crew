// CheckListView.swift の全文

import SwiftUI
import SwiftData

// MARK: - カスタムToggleStyle (変更なし)
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
    // MARK: 修正1: @Bindable を使用して Boat オブジェクトを受け取る (変更なし)
    @Bindable var boat: Boat
    
    // MARK: 【✅ 修正 2】カテゴリでフィルタリングされた生の配列を返す関数
    private func filteredChecklist(for category: CheckListItem.Category) -> [CheckListItem] {
        return boat.checklist.filter { $0.category == category }
    }
    
    var body: some View {
        NavigationView {
            Form {
                ForEach(CheckListItem.Category.allCases, id: \.self) { category in
                    Section(header: Text(category.rawValue)) {
                        
                        // MARK: 【✅ 修正 3】フィルタリング済みの生の配列を ForEach に渡し、要素を直接受け取る
                        ForEach(filteredChecklist(for: category)) { item in
                            // MARK: 【✅ 修正 4】カスタム Binding を作成
                            // item は @Model なので、プロパティの変更は自動で永続化される
                            Toggle(isOn: Binding(
                                get: { item.isCompleted },
                                set: { newValue in item.isCompleted = newValue }
                            )) {
                                Text(item.name)
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }
                    }
                }
            }
            .navigationTitle("チェックリスト")
        }
    }
}

#Preview {
    let exampleBoat = Boat.dummy
    return CheckListView(boat: exampleBoat)
        .modelContainer(for: Boat.self, inMemory: true)
}
