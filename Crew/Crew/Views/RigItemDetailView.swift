import SwiftUI
import Charts

struct RigItemDetailView: View {
    let item: RigItem
    let allDataSets: [RigDataSet]
    
    var itemHistory: [(date: Date, value: Double)] {
        return allDataSets
            .compactMap { dataSet -> (Date, Double)? in
                guard let historicItem = dataSet.rigItems.first(where: { $0.name == item.name }) else {
                    return nil
                }
                // 'value' (Double) を直接使用
                return (dataSet.date, historicItem.value)
            }
            .sorted(by: { $0.date < $1.date })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: 【修正】RigSettingCardViewの代わりに詳細を直接表示
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
                            .foregroundStyle(item.statusColor)
                            PointMark(
                                x: .value("日付", data.date),
                                y: .value("値 (\(item.unit))", data.value)
                            )
                            .foregroundStyle(item.statusColor)
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
    }
}
