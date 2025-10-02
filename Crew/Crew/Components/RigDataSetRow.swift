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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dataSet.memo.isEmpty ? "リグ設定ログ" : dataSet.memo)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("記録日: \(dateFormatter.string(from: dataSet.date))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // MARK: 【修正】'elements' -> 'rigItems'、'.expired' -> '.critical'
                if dataSet.rigItems.contains(where: { $0.status == .critical }) {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("要交換/調整アイテムあり")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .fontWeight(.bold)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}
