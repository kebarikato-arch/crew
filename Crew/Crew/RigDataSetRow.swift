//
//  RigDataSetRow.swift
//  Crew
//
//  Created by Gemini
//

import SwiftUI

struct RigDataSetRow: View {
    let dataSet: RigDataSet
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dataSet.memo.isEmpty ? "リグ設定ログ (\(dateFormatter.string(from: dataSet.date)))" : dataSet.memo)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("記録日: \(dateFormatter.string(from: dataSet.date))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 危険なアイテムの数を表示
                if dataSet.elements.contains(where: { $0.status == .expired }) {
                    Text("要交換/調整アイテムあり")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 5)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}
