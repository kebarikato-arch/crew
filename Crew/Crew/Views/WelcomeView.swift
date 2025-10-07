import SwiftUI

struct WelcomeView: View {
    @Binding var isAddingBoat: Bool // HomeViewのisAddingBoatと連携します

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

            // このボタンを押すとisAddingBoatがtrueになり、HomeViewがシートを表示します
            Button("最初のボートを追加する") {
                isAddingBoat = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)

            Spacer()
        }
        .padding()
    }
}
