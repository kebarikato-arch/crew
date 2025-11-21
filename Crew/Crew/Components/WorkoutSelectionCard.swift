import SwiftUI
import SwiftData

struct WorkoutSelectionCard: View {
    let workout: WorkoutTemplate
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(workout.name)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    Spacer()
                    if workout.isDefault {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .yellow)
                    }
                }
                
                if !workout.metricTemplates.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(workout.metricTemplates.prefix(3).sorted { $0.order < $1.order }) { metric in
                            HStack {
                                Text(metric.name)
                                    .font(.caption)
                                Text(metric.unit)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        if workout.metricTemplates.count > 3 {
                            Text("+\(workout.metricTemplates.count - 3) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }
            }
            .padding()
            .frame(width: 200, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

