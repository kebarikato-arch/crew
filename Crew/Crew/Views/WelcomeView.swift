import SwiftData
import SwiftUI
import SwiftData

struct WelcomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var newBoatName = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "sailboat.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            Text("Crewへようこそ")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("まずはあなたのボートを登録しましょう。")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("ボート名", text: $newBoatName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 40)

            Button("ボートを登録する", action: addBoat)
                .buttonStyle(.borderedProminent)
                .disabled(newBoatName.isEmpty)

            Spacer()
        }
        .padding()
    }
    
    private func addBoat() {
        guard !newBoatName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let newBoat = Boat(name: newBoatName)
        modelContext.insert(newBoat)
    }
}
