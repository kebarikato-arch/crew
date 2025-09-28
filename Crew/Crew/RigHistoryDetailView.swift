// RigHistoryDetailView.swift の全文

import SwiftUI
import SwiftData

struct RigHistoryDetailView: View {
    // MARK: 【✅ 修正済み】Boat は @Bindable で受け取る
    @Bindable var boat: Boat // AddRigDataViewへのバインドを考慮
    
    // MARK: 【✅ 修正済み】dataSet はそのまま受け取る
    let dataSet: RigDataSet
    
    @Environment(\.dismiss) var dismiss
    // MARK: 【✅ 修正済み】ModelContext を追加
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false // 編集機能用
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // MARK: ログサマリー
                VStack(alignment: .leading, spacing: 5) {
                    Text("記録日: \(dateFormatter.string(from: dataSet.date))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("メモ:")
                        .font(.headline)
                    
                    Text(dataSet.memo.isEmpty ? "メモはありません" : dataSet.memo)
                        .font(.body)
                        .padding(5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(5)
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: 設定値リスト
                VStack(alignment: .leading) {
                    Text("リグ設定値")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 1) {
                        ForEach(dataSet.elements.sorted(by: { $0.name < $1.name })) { item in
                            NavigationLink {
                                // RigItemDetailView に Boat のデータセット全体を渡す
                                RigItemDetailView(item: item, allDataSets: boat.dataSets)
                            } label: {
                                RigItemSettingRow(item: item)
                            }
                            .listRowInsets(EdgeInsets())
                            .background(Color(.systemBackground))
                        }
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: 編集・削除ボタンを追加
                HStack {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("編集", systemImage: "pencil")
                    }
                    .padding(.vertical, 5).padding(.horizontal).buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("削除", systemImage: "trash.fill")
                    }
                    .padding(.vertical, 5).padding(.horizontal).buttonStyle(.bordered)
                }
                .padding(.horizontal)
                
                Divider()
                // ... (後略)
            }
        }
        .navigationTitle("ログ詳細")
        .alert("ログの削除", isPresented: $showingDeleteAlert) {
            Button("削除", role: .destructive) { deleteDataSet() }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このリグ設定ログを本当に削除しますか？")
        }
        .sheet(isPresented: $showingEditSheet) {
            // AddRigDataView を編集モードで表示
            // @Bindable boat をそのまま渡す
            AddRigDataView(boat: boat, dataSetToEdit: dataSet)
        }
    }
    
    // MARK: 【✅ 修正済み】ModelContext を使った削除ロジック
    private func deleteDataSet() {
        // RigDataSet の削除とカスケード削除により関連 RigItem も削除される
        modelContext.delete(dataSet)
        dismiss()
    }
}

// RigItemSettingRow の定義は省略します
struct RigItemSettingRow: View {
    let item: RigItem // 以前のコードには定義がありませんが、UIパーツとして存在すると想定
    var body: some View {
        HStack {
            Text(item.name).foregroundColor(.primary)
            Spacer()
            Text("\(item.value) \(item.unit)")
                .fontWeight(.bold)
            Image(systemName: "circle.fill")
                .foregroundColor(item.statusColor)
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}
