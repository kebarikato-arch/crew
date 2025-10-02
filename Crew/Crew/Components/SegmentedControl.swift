import SwiftUI

// MARK: 【修正】HomeView内に定義を移動しましたが、このファイルが参照できるようここにも定義を残します。
// HomeViewの構造変更により、このViewは現在使用されていない可能性があります。
enum RigDataType: String, CaseIterable {
    case safetyScore = "安全性スコア"
    case history = "履歴"
}

struct SegmentedControl: View {
    @Binding var selectedTab: RigDataType
    
    var body: some View {
        Picker("データタイプ", selection: $selectedTab) {
            ForEach(RigDataType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
}
