//
//  DataView.swift
//  Crew
//
//  Created by Gemini
//

import SwiftUI
import SwiftData

struct DataView: View {
    // MARK: 修正: Boat インスタンスを受け取る
    let boat: Boat
    
    var body: some View {
        // 仮の表示
        Text("Data View for \(boat.name)")
    }
}

#Preview {
    let exampleBoat = Boat.dummy
    return DataView(boat: exampleBoat)
        .modelContainer(for: Boat.self, inMemory: true)
}
