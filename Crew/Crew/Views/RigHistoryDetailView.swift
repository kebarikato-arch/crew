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
    
    /// このデータセットの設定を元に、新しいデータセットを作成する関数
    private func reproduceSetting() {
        // 【修正点 1】複雑だった処理を2段階に分け、コンパイラのフリーズを防ぎます
        // まず、元のメモが空かどうかで、新しいメモの元になる文字列を決めます
        let baseMemo = rigDataSet.memo.isEmpty ? dateFormatter.string(from: rigDataSet.date) : rigDataSet.memo
        // 次に、その文字列を使って最終的なメモを作成します
        let newMemo = "「\(baseMemo)」の設定を再現"
        
        // 【修正点 2】新しいRigDataSetを作成する際に、必須である 'boat' の情報を渡します
        let newDataSet = RigDataSet(date: Date(), memo: newMemo, boat: rigDataSet.boat)
        
        // 元のデータセットからリグアイテムの設定をコピーします
        newDataSet.rigItems = rigDataSet.rigItems.map {
            RigItem(name: $0.name, value: $0.value, unit: $0.unit, status: $0.status, template: $0.template)
        }
        
        // 新しいデータセットをデータベースに追加します
        context.insert(newDataSet)
    }
    
    /// このデータセットを削除する関数
    private func deleteDataSet() {
        context.delete(rigDataSet)
        dismiss()
    }
}
