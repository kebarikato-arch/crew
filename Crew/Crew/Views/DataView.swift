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
            if availableTemplates.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("分析できるデータがありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("リグデータを記録すると、ここで分析できます")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Item selection section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("分析する項目を選択")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            // Group templates by category (ASCII-only categories go to "その他")
                            let templatesByCategory = Dictionary(grouping: availableTemplates) { template in
                                let raw = template.category
                                let isAsciiLetters = raw.range(of: "^[A-Za-z]+$", options: .regularExpression) != nil
                                return isAsciiLetters ? "その他" : raw
                            }
                            let preferredOrder = ["クラッチ", "ストレッチャー", "オール", "その他"]
                            let sortedCategories = templatesByCategory.keys.sorted { a, b in
                                let ia = preferredOrder.firstIndex(of: a) ?? Int.max
                                let ib = preferredOrder.firstIndex(of: b) ?? Int.max
                                return ia == ib ? a < b : ia < ib
                            }
                            
                            ForEach(sortedCategories, id: \.self) { category in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(category)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(templatesByCategory[category] ?? [], id: \.id) { template in
                                                ItemSelectionButton(
                                                    template: template,
                                                    isSelected: selectedItemTemplate?.id == template.id
                                                ) {
                                                    selectedItemTemplate = template
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                        
                        // Chart section
                        if let template = selectedItemTemplate, !chartData.isEmpty {
                            VStack(spacing: 16) {
                                // Chart
                                Chart(chartData, id: \.date) { dataPoint in
                                    LineMark(
                                        x: .value("Date", dataPoint.date),
                                        y: .value("Value", dataPoint.value)
                                    )
                                    .foregroundStyle(.blue)
                                    PointMark(
                                        x: .value("Date", dataPoint.date),
                                        y: .value("Value", dataPoint.value)
                                    )
                                    .foregroundStyle(.blue)
                                }
                                .frame(height: 250)
                                .chartYAxisLabel(template.unit)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                                .padding(.horizontal)
                                
                                // Statistics
                                StatisticsCardView(data: chartData.map { $0.value }, unit: template.unit)
                            }
                        } else if selectedItemTemplate != nil {
                            VStack(spacing: 12) {
                                Image(systemName: "chart.bar")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("データがありません")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                    }
                    .padding(.vertical)
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
}

// Item selection button component
struct ItemSelectionButton: View {
    let template: RigItemTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(template.name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(.systemGray6))
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
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
