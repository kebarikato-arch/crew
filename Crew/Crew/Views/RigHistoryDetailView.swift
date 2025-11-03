import SwiftUI
import SwiftData

struct RigHistoryDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var rigDataSet: RigDataSet
    
    // 日付のフォーマットを統一するための準備
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        Form {
            Section(header: Text("基本情報")) {
                Text("日時: \(rigDataSet.date, formatter: dateFormatter)")
                if !rigDataSet.memo.isEmpty {
                    Text("メモ: \(rigDataSet.memo)")
                }
            }
            
            Section(header: Text("リグアイテム")) {
                ForEach(rigDataSet.rigItems) { item in
                    NavigationLink(destination: RigItemDetailView(item: item)) {
                        HStack {
                            Text(item.name)
                            Spacer()
                            Text("\(item.value, specifier: "%.1f") \(item.unit)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section {
                Button("この設定を再現する", action: reproduceSetting)
            }
        }
        .navigationTitle("ログ詳細")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("削除", role: .destructive) {
                    deleteDataSet()
                }
            }
        }
    }
    
    /// このデータセットの設定を新しいデータセットとして復元する関数
    private func reproduceSetting() {
        guard let boat = rigDataSet.boat else { return }
        
        // 新しいデータセットを作成（メモも復元）
        let newDataSet = RigDataSet(date: Date(), memo: rigDataSet.memo, boat: boat)
        
        // 選択された履歴のリグアイテムの値をコピー
        newDataSet.rigItems = rigDataSet.rigItems.map {
            RigItem(name: $0.name, value: $0.value, unit: $0.unit, status: $0.status, template: $0.template)
        }
        
        // 新しいデータセットをボートのrigDataSetsに追加
        boat.rigDataSets.append(newDataSet)
        
        // 変更を保存
        do {
            try context.save()
            print("Debug: Setting restored as new entry successfully")
        } catch {
            print("Debug: Failed to save restored setting: \(error)")
        }
        
        // 画面を閉じる
        dismiss()
    }
    
    /// このデータセットを削除する関数
    private func deleteDataSet() {
        context.delete(rigDataSet)
        dismiss()
    }
}
