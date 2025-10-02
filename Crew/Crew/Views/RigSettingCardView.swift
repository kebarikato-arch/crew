import SwiftUI

struct RigSettingCardView: View {
    let currentBoat: Boat
    
    // 最新のデータセットから安全スコアを計算する
    private var safetyScore: (score: Int, criticalItems: Int) {
        guard let latestDataSet = currentBoat.rigDataSets.sorted(by: { $0.date > $1.date }).first else {
            return (100, 0) // データがない場合は安全
        }
        
        let criticalCount = latestDataSet.rigItems.filter { $0.status == .critical }.count
        let cautionCount = latestDataSet.rigItems.filter { $0.status == .caution }.count
        
        // スコア計算ロジック（例: criticalは-20点, cautionは-5点）
        let score = 100 - (criticalCount * 20) - (cautionCount * 5)
        
        return (max(0, score), criticalCount)
    }
    
    private var scoreColor: Color {
        let score = safetyScore.score
        if score < 50 {
            return .red
        } else if score < 80 {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Rig Safety Score")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("\(safetyScore.score)")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundColor(scoreColor)
            
            if safetyScore.criticalItems > 0 {
                Text("\(safetyScore.criticalItems)個のアイテムが「要交換/調整」です")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            } else {
                Text("すべてのアイテムは正常です")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
