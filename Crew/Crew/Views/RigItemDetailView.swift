import SwiftUI
import Charts

struct RigItemDetailView: View {
    let item: RigItem
    let allDataSets: [RigDataSet]
    
    // MARK: 【修正】計算結果を保持するための@State変数を追加
    @State private var itemHistory: [(date: Date, value: Double)] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: 現在の値のサマリー表示
                VStack(alignment: .leading) {
                    Text("現在の値")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.name)
                                .font(.headline)
                            HStack(alignment: .lastTextBaseline) {
                                Text(String(format: "%.1f", item.value))
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text(item.unit)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        VStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(item.statusColor)
                            Text(item.status.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Divider()
                
                // MARK: 履歴グラフ
                VStack(alignment: .leading) {
                    Text("\(item.name) 履歴")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.leading)
                    
                    if itemHistory.count > 1 {
                        Chart(itemHistory, id: \.date) { data in
                            LineMark(
                                x: .value("日付", data.date),
                                y: .value("値 (\(item.unit))", data.value)
                            )
                            .foregroundStyle(.blue) // statusColorだと複雑になるため一旦固定
                            PointMark(
                                x: .value("日付", data.date),
                                y: .value("値 (\(item.unit))", data.value)
                            )
                            .foregroundStyle(.blue)
                        }
                        .chartYAxisLabel("値 (\(item.unit))")
                        .frame(height: 250)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    } else {
                        Text("履歴データが不足しています。")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        // MARK: 【修正】画面が表示された時に一度だけデータを計算する
        .onAppear(perform: calculateHistory)
    }
    
    // MARK: 【修正】データ計算ロジックを別の関数に分離
    private func calculateHistory() {
        self.itemHistory = allDataSets
            .compactMap { dataSet -> (Date, Double)? in
                guard let historicItem = dataSet.rigItems.first(where: { $0.name == item.name }) else {
                    return nil
                }
                return (dataSet.date, historicItem.value)
            }
            .sorted(by: { $0.date < $1.date })
    }
}
