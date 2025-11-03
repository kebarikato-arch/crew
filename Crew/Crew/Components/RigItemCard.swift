import SwiftUI

struct RigItemCard: View {
    let item: RigItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.name)
                .font(.headline)
                .lineLimit(1)
            
            if item.name == "ブッシュ" {
                Text(item.stringValue ?? "未選択")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    Text(String(format: "%.1f", item.value))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(item.unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 旧ステータス表示を撤去（満足度はデータセット単位で表示）
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}
