//
//  DataView.swift
//  Crew
//
//  Created by Gemini
//

import SwiftUI
import SwiftData
import Charts

struct DataView: View {
    let boat: Boat
    
    @State private var selectedRigItemName: String = "フォアステイ"
    
    private var selectedItemHistory: [(date: Date, value: Double)] {
        guard !boat.dataSets.isEmpty else { return [] }
        
        return boat.dataSets
            .compactMap { dataSet -> (Date, Double)? in
                guard let historicItem = dataSet.elements.first(where: { $0.name == selectedRigItemName }),
                      let value = Double(historicItem.value) else {
                    return nil
                }
                return (dataSet.date, value)
            }
            .sorted(by: { $0.date < $1.date })
    }
    
    private var availableRigItemNames: [String] {
        let allItemNames = Set(boat.dataSets.flatMap { $0.elements.map { $0.name } })
        return Array(allItemNames).sorted()
    }
    
    private var selectedItemUnit: String {
        boat.dataSets.lazy
            .flatMap { $0.elements }
            .first { $0.name == selectedRigItemName }?
            .unit ?? ""
    }
    
    // MARK: 【新規追加】統計データを計算するプロパティ
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
                    
                    if !boat.dataSets.isEmpty && !availableRigItemNames.isEmpty {
                        
                        Picker("リグアイテムを選択", selection: $selectedRigItemName) {
                            ForEach(availableRigItemNames, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading) {
                            Text("\(selectedRigItemName) の履歴")
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
                        
                        // MARK: 【新規追加】統計情報表示エリア
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
                        
                    } else {
                        Text("分析できるデータがありません。\nまずはリグのログを追加してください。")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.top, 50)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("データ分析")
        }
    }
}

// MARK: 【新規追加】統計情報カードビュー
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


#Preview {
    let exampleBoat = Boat.dummy
    let items2: [RigItem] = [
        RigItem(name: "フォアステイ", value: "32", unit: "%", status: .normal),
        RigItem(name: "D1シュラウド", value: "30", unit: "%", status: .normal),
        RigItem(name: "V2シュラウド", value: "28", unit: "%", status: .maintenance)
    ]
    let dataSet2 = RigDataSet(date: Date(), memo: "軽風用", elements: items2)
    exampleBoat.dataSets.append(dataSet2)
    
    return DataView(boat: exampleBoat)
        .modelContainer(for: Boat.self, inMemory: true)
}
