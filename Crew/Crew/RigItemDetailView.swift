//
//  RigItemDetailView.swift
//  Crew
//
//  Created by Gemini
//

import SwiftUI
import Charts // チャート表示に Charts フレームワークを使用

struct RigItemDetailView: View {
    let item: RigItem // 現在の詳細アイテム
    let allDataSets: [RigDataSet] // 履歴を抽出するために全てのデータセットを渡す
    
    // このアイテムの過去の値を抽出する
    var itemHistory: [(date: Date, value: Double)] {
        return allDataSets
            .compactMap { dataSet -> (Date, Double)? in
                // RigDataSetから同じ名前のRigItemを探す
                guard let historicItem = dataSet.elements.first(where: { $0.name == item.name }),
                      let value = Double(historicItem.value) else {
                    return nil
                }
                return (dataSet.date, value)
            }
            .sorted(by: { $0.date < $1.date }) // 日付が古い順にソート
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: 現在の値のサマリー
                RigSettingCardView(item: item)
                    .padding(.horizontal)
                
                Divider()
                
                // MARK: 履歴グラフ
                VStack(alignment: .leading) {
                    Text("\(item.name) テンション履歴")
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
                        Text("履歴データが不足しています。新しいデータを追加してください。")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                .padding(.horizontal)
                
                // MARK: メンテナンス情報 (今後の拡張用)
                VStack(alignment: .leading) {
                    Text("アクション")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Button("このアイテムのメンテナンスログを追加 (未実装)") {}
                    .buttonStyle(.borderedProminent)
                    
                    Button("設定を編集 (未実装)") {}
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal)
                
            }
            .padding(.top)
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
