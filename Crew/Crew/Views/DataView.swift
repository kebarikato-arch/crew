import SwiftUI
import SwiftData
import Charts

struct DataView: View {
    let boat: Boat
    
    @State private var selectedRigItemName: String?
    
    private var selectedItemHistory: [(date: Date, value: Double)] {
        // MARK: 【修正】 rigDataSets を使用
        guard let name = selectedRigItemName, !boat.rigDataSets.isEmpty else { return [] }
        
        return boat.rigDataSets
            .compactMap { dataSet -> (Date, Double)? in
                // MARK: 【修正】 rigItems を使用し、Double(historicItem.value) を historicItem.value に変更
                guard let historicItem = dataSet.rigItems.first(where: { $0.name == name }) else {
                    return nil
                }
                // Double型の value を直接使用
                return (dataSet.date, historicItem.value)
            }
            .sorted(by: { $0.date < $1.date })
    }
    
    private var availableRigItemNames: [String] {
        // MARK: 【修正】 rigDataSets と rigItems を使用
        let allItemNames = Set(boat.rigDataSets.flatMap { $0.rigItems.map { $0.name } })
        return Array(allItemNames).sorted()
    }
    
    private var selectedItemUnit: String {
        guard let name = selectedRigItemName else { return "" }
        return boat.rigDataSets.lazy
            // MARK: 【修正】 rigDataSets と rigItems を使用
            .flatMap { $0.rigItems }
            .first { $0.name == name }?
            .unit ?? ""
    }
    
    private var statistics: (avg: Double, max: Double, min: Double)? {
        let values = selectedItemHistory.map { $0.value }
        guard !values.isEmpty else { return nil }
        
        let avg = values.reduce(0, +) / Double(values.count)
        let max = values.max() ?? 0
        let min = values.min() ?? 0
        
        return (avg, max, min)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: 【修正】 rigDataSets を使用
                    if !boat.rigDataSets.isEmpty && !availableRigItemNames.isEmpty {
                        
                        Picker("リグアイテムを選択", selection: $selectedRigItemName) {
                            ForEach(availableRigItemNames, id: \.self) { name in
                                Text(name).tag(name as String?)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        if let name = selectedRigItemName {
                            VStack(alignment: .leading) {
                                Text("\(name) の履歴")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding([.leading, .top])
                                
                                if selectedItemHistory.count > 1 {
                                    Chart(selectedItemHistory, id: \.date) { data in
                                        LineMark(
                                            x: .value("日付", data.date, unit: .day),
                                            y: .value("値 (\(selectedItemUnit))", data.value)
                                        )
                                        .foregroundStyle(.blue)
                                        PointMark(
                                            x: .value("日付", data.date, unit: .day),
                                            y: .value("値 (\(selectedItemUnit))", data.value)
                                        )
                                        .foregroundStyle(.blue)
                                    }
                                    .chartYAxisLabel("値 (\(selectedItemUnit))")
                                    .frame(height: 300)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(15)
                                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                    
                                } else {
                                    Text("グラフを表示するには、2つ以上のデータログが必要です。")
                                        .foregroundColor(.gray)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)
                            
                            if let stats = statistics {
                                VStack(alignment: .leading) {
                                    Text("統計情報")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    HStack(spacing: 15) {
                                        StatisticCard(label: "平均", value: stats.avg, unit: selectedItemUnit)
                                        StatisticCard(label: "最大", value: stats.max, unit: selectedItemUnit, color: .green)
                                        StatisticCard(label: "最小", value: stats.min, unit: selectedItemUnit, color: .orange)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                    } else {
                        ContentUnavailableView("データがありません", systemImage: "chart.bar.xaxis.ascending", description: Text("分析できるデータがありません。\nまずはリグデータを記録してください。"))
                        .padding(.top, 50)
                    }
                }
                .padding(.top)
                .onAppear {
                    if selectedRigItemName == nil {
                        selectedRigItemName = availableRigItemNames.first
                    }
                }
            }
            .navigationTitle("データ分析")
        }
    }
}

// 統計情報カードビュー
struct StatisticCard: View {
    let label: String
    let value: Double
    let unit: String
    var color: Color = .blue
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(String(format: "%.1f", value))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(unit)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
