// RigHistoryDetailView.swift の全文

import SwiftUI
import SwiftData

struct RigHistoryDetailView: View {
    @Bindable var boat: Boat
    let dataSet: RigDataSet
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
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
                                RigItemDetailView(item: item, allDataSets: boat.rigDataSets)
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
                
                // MARK: 【修正】アクションボタンエリア
                VStack(spacing: 10) {
                    // MARK: この設定を再現ボタン
                    Button {
                        reproduceDataSet()
                    } label: {
                        Label("この設定を再現する", systemImage: "arrow.counterclockwise.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    HStack {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("削除", systemImage: "trash.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)
                
                Divider()
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
            AddRigDataView(boat: boat, dataSetToEdit: dataSet)
        }
    }
    
    private func deleteDataSet() {
        modelContext.delete(dataSet)
        dismiss()
    }
    
    // MARK: 【新規追加】設定を再現する関数
    private func reproduceDataSet() {
        // 過去のRigItemを新しいインスタンスとしてコピー
        let copiedItems = dataSet.elements.map { item in
            return RigItem(name: item.name, value: item.value, unit: item.unit, status: item.status)
        }
        
        // 新しいデータセットを作成
        let newDataSet = RigDataSet(
            date: Date(), // 日付は現在の日時
            memo: "「\(dataSet.memo.isEmpty ? dateFormatter.string(from: dataSet.date) : dataSet.memo)」の設定を再現",
            elements: copiedItems
        )
        
        // Boatのデータセットに追加
        boat.rigDataSets.append(newDataSet)
        
        // 画面を閉じる
        dismiss()
    }
}

// RigItemSettingRow の定義は省略します
struct RigItemSettingRow: View {
    let item: RigItem
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
