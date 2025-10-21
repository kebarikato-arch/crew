import SwiftUI
import SwiftData

struct RigHistoryView: View {
    @Binding var currentBoat: Boat
    @State private var selectedDataSet: RigDataSet?
    
    private var sortedDataSets: [RigDataSet] {
        currentBoat.rigDataSets.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        NavigationStack {
            if sortedDataSets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("履歴がありません")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("リグデータを記録すると、ここに履歴が表示されます")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    ForEach(sortedDataSets) { dataSet in
                        RigHistoryRow(dataSet: dataSet) {
                            selectedDataSet = dataSet
                        }
                    }
                }
            }
        }
        .navigationTitle("履歴")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedDataSet) { dataSet in
            RigHistoryDetailView(rigDataSet: dataSet)
        }
    }
}

struct RigHistoryRow: View {
    let dataSet: RigDataSet
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(dataSet.date, style: .date)
                        .font(.headline)
                    Spacer()
                }
                
                if !dataSet.memo.isEmpty {
                    Text(dataSet.memo)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("\(dataSet.rigItems.count) 項目")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(dataSet.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    RigHistoryView(currentBoat: .constant(Boat(name: "Test Boat")))
}
