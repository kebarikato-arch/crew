// SegmentedControl.swift

import SwiftUI

struct SegmentedControl: View {
    @Binding var selectedTab: HomeView.RigDataType
    
    var body: some View {
        Picker("データタイプ", selection: $selectedTab) {
            ForEach(HomeView.RigDataType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
}
