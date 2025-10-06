import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var context
    @State private var newBoatName: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("ようこそ Crewへ")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("最初のボートを登録しましょう")
                .foregroundColor(.secondary)
            
            TextField("ボート名", text: $newBoatName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)
            
            Button("登録する", action: addBoat)
                .buttonStyle(.borderedProminent)
                .disabled(newBoatName.isEmpty)
            
            Spacer()
        }
    }
    
    private func addBoat() {
        guard !newBoatName.isEmpty else { return }
        let newBoat = Boat(name: newBoatName)
        context.insert(newBoat)
    }
}
