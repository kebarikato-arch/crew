import SwiftUI
import SwiftData

struct RigHistoryView: View {
    @Environment(\.modelContext) private var context
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
                    .onDelete(perform: deleteDataSets)
                }
            }
        }
        .navigationTitle("履歴")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .sheet(item: $selectedDataSet) { dataSet in
            RigHistoryDetailView(rigDataSet: dataSet)
        }
    }

    private func deleteDataSets(at offsets: IndexSet) {
        let targets = offsets.map { sortedDataSets[$0] }
        for target in targets {
            context.delete(target)
        }
    }
}

struct RigHistoryRow: View {
    let dataSet: RigDataSet
    let onTap: () -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .long
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(dateFormatter.string(from: dataSet.date))
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
                    
                    Text(timeFormatter.string(from: dataSet.date))
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
