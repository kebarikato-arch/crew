// RigSettingCardView.swift

import SwiftUI

struct RigSettingCardView: View {
    let item: RigItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .font(.headline)
                HStack(alignment: .lastTextBaseline) {
                    Text(item.value)
                        .font(.title)
                        .fontWeight(.bold)
                    Text(item.unit)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(item.statusColor)
                Text(item.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

