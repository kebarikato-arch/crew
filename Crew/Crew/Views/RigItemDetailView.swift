import SwiftUI
import Charts
import SwiftData

struct RigItemDetailView: View {
    @Bindable var item: RigItem
    
    //【修正点 1】グラフ用のデータを保持するための状態変数（@State）を追加します
    // 最初は空の配列で初期化します
    @State private var chartData: [(date: Date, value: Double)] = []

    var body: some View {
        VStack {
            // 現在のステータス表示（変更なし）
            VStack {
                Text(item.name).font(.largeTitle).bold()
                HStack {
                    Text("Current Status:")
                    Text(item.status.rawValue)
                    Image(systemName: "circle.fill")
                        .foregroundColor(item.statusColor)
                }
                .font(.headline)
                .foregroundColor(.secondary)
            }
            .padding()

            // グラフ表示
            //【修正点 2】グラフは、状態変数である chartData を元に描画します
            if chartData.count > 1 {
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
                .padding()
            } else {
                Spacer()
                Text("グラフを表示するには、少なくとも2つのデータポイントが必要です。")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
        }
        .navigationTitle("アイテム詳細")
        .navigationBarTitleDisplayMode(.inline)
        //【修正点 3】ビューが最初に表示された時に一度だけ、グラフ用のデータを計算します
        .onAppear {
            calculateChartData()
        }
    }
    
    /// グラフ用のデータを計算し、状態変数 `chartData` を更新する関数です
    private func calculateChartData() {
        // item.template?.boat という長いOptional Chainingを安全に解決します
        guard let boat = item.template?.boat else {
            self.chartData = []
            return
        }
        
        // 負荷の高い計算をここで行います
        let data = boat.rigDataSets
            .flatMap { dataSet -> [(Date, Double)] in
                dataSet.rigItems
                    .filter { $0.template == item.template }
                    .map { (dataSet.date, $0.value) }
            }
            .sorted { $0.0 < $1.0 }
        
        // 計算結果を状態変数に一度だけセットします
        self.chartData = data
    }
}
