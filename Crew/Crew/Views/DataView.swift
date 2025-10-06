import SwiftUI
import Charts

struct DataView: View {
    @Binding var currentBoat: Boat
    
    @State private var selectedItemTemplate: RigItemTemplate?

    private var availableTemplates: [RigItemTemplate] {
        Array(Set(currentBoat.rigDataSets.flatMap { $0.rigItems.compactMap { $0.template } })).sorted { $0.name < $1.name }
    }
    
    private var chartData: [(date: Date, value: Double)] {
        guard let template = selectedItemTemplate else { return [] }
        return currentBoat.rigDataSets
            .flatMap { dataSet -> [(Date, Double)] in
                dataSet.rigItems
                    .filter { $0.template == template }
                    .map { (dataSet.date, $0.value) }
            }
            .sorted { $0.0 < $1.0 }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if availableTemplates.isEmpty {
                    Text("分析できるデータがありません")
                        .foregroundColor(.secondary)
                } else {
                    Picker("リグアイテム", selection: $selectedItemTemplate) {
                        ForEach(availableTemplates) { template in
                            Text(template.name).tag(template as RigItemTemplate?)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)

                    if let template = selectedItemTemplate, !chartData.isEmpty {
                        VStack {
                            Chart(chartData, id: \.date) { dataPoint in
                                LineMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Value", dataPoint.value)
                                )
                                PointMark(
                                    x: .value("Date", dataPoint.date),
                                    y: .value("Value", dataPoint.value)
                                )
                            }
                            .chartYAxisLabel(template.unit)
                            .padding()

                            StatisticsCardView(data: chartData.map { $0.value }, unit: template.unit)

                            Spacer()
                        }
                    } else {
                        Spacer()
                        Text("表示するデータを選択してください")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("データ分析")
            .onAppear {
                if selectedItemTemplate == nil {
                    selectedItemTemplate = availableTemplates.first
                }
            }
        }
    }
}

// 【追記 1】統計情報を表示するためのカードビュー
struct StatisticsCardView: View {
    let data: [Double]
    let unit: String
    
    private var average: Double {
        !data.isEmpty ? data.reduce(0, +) / Double(data.count) : 0
    }
    
    private var max: Double {
        data.max() ?? 0
    }
    
    private var min: Double {
        data.min() ?? 0
    }
    
    var body: some View {
        HStack {
            StatisticItem(title: "平均", value: average, unit: unit)
            StatisticItem(title: "最大", value: max, unit: unit)
            StatisticItem(title: "最小", value: min, unit: unit)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// 【追記 2】個々の統計項目（平均、最大、最小）を表示するためのビュー
struct StatisticItem: View {
    let title: String
    let value: Double
    let unit: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value, specifier: "%.1f")\(unit)")
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}
